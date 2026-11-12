# Modelagem do Firestore

Este documento descreve como os dados do HepatoCheck são guardados no Cloud Firestore (projeto `hepatocheck-unit`, região `southamerica-east1`) e como as classes Dart do domínio são convertidas para os documentos da nuvem.

O aplicativo é **offline-first**: o banco local (Hive, criptografado) é a fonte principal dos dados. O Firestore guarda apenas uma cópia, enviada pela fila de sincronização quando o usuário tem conta, autorizou o envio e está no Wi-Fi.

## 1. Estrutura das coleções

Todos os dados de um usuário ficam dentro do documento dele, identificado pelo `uid` do Firebase Authentication:

```
users/{uid}
├── drinks/{drinkId}   registros do diário de álcool
├── exams/{examId}     exames de sangue (TGO, TGP, plaquetas)
└── goals/{goalId}     metas de redução
```

- **`users/{uid}`** não guarda nome, e-mail nem outro dado pessoal. O e-mail fica só no Firebase Authentication. O documento existe apenas como pasta das subcoleções.
- **Identificadores dos documentos** são os mesmos UUIDs gerados no aparelho (`id` das entidades). Eles não carregam nenhuma informação sobre o conteúdo.
- **Subcoleções por usuário** deixam as regras de segurança simples: cada pessoa só lê e grava dentro de `users/{seu uid}`.

## 2. Documentos

As datas são gravadas como `timestamp` do Firestore, sempre em UTC. Valores calculados (drinques padrão, FIB-4, classificação de risco) **não** são guardados: o aplicativo recalcula a partir dos dados brutos, o que evita valores desatualizados na nuvem.

### 2.1 `users/{uid}/drinks/{drinkId}`

| Campo | Tipo | Origem (`DrinkEntry`) | Observação |
| --- | --- | --- | --- |
| `type` | string | `type` | `beer`, `wine`, `spirit`, `cocktail` ou `other` |
| `volumeMl` | number | `volumeMl` | Volume de uma unidade, em ml |
| `alcoholPercent` | number | `alcoholPercent` | Teor alcoólico, em % |
| `quantity` | number (inteiro) | `quantity` | Número de unidades |
| `consumedAt` | timestamp | `consumedAt` | Quando a bebida foi consumida |
| `createdAt` | timestamp | `createdAt` | |
| `updatedAt` | timestamp | `updatedAt` | |

### 2.2 `users/{uid}/exams/{examId}`

| Campo | Tipo | Origem (`LabExam`) | Observação |
| --- | --- | --- | --- |
| `examDate` | timestamp | `examDate` | Data do exame |
| `age` | number (inteiro) | `age` | Idade na data do exame, usada no FIB-4 |
| `ast` | number | `ast` | TGO (U/L) |
| `alt` | number | `alt` | TGP (U/L) |
| `platelets` | number | `platelets` | Plaquetas (×10⁹/L) |
| `createdAt` | timestamp | `createdAt` | |
| `updatedAt` | timestamp | `updatedAt` | |

### 2.3 `users/{uid}/goals/{goalId}`

| Campo | Tipo | Origem (`ReductionGoal`) | Observação |
| --- | --- | --- | --- |
| `type` | string | `type` | `maxDrinksPerWeek` ou `alcoholFreeDaysPerWeek` |
| `target` | number (inteiro) | `target` | Valor da meta |
| `startDate` | timestamp | `startDate` | |
| `endDate` | timestamp ou null | `endDate` | Vazio enquanto a meta não tem fim |
| `active` | boolean | `active` | |
| `createdAt` | timestamp | `createdAt` | |
| `updatedAt` | timestamp | `updatedAt` | |

### Exemplo de documento

`users/Xy12.../drinks/3f6c2a0e-...`

```json
{
  "type": "beer",
  "volumeMl": 350,
  "alcoholPercent": 5,
  "quantity": 2,
  "consumedAt": "2026-11-14T22:30:00Z",
  "createdAt": "2026-11-14T22:31:10Z",
  "updatedAt": "2026-11-14T22:31:10Z"
}
```

## 3. Mapeamento das classes Dart para o Firestore

A conversão fica em `hepatocheck_app/lib/data/models/firestore_mappers.dart`, na camada Data. As entidades do domínio continuam sem dependência do Firebase.

| Classe Dart | Para o Firestore | Do Firestore | Coleção |
| --- | --- | --- | --- |
| `DrinkEntry` | `FirestoreMappers.drinkToFirestore` | `FirestoreMappers.drinkFromFirestore` | `drinks` |
| `LabExam` | `FirestoreMappers.examToFirestore` | `FirestoreMappers.examFromFirestore` | `exams` |
| `ReductionGoal` | `FirestoreMappers.goalToFirestore` | `FirestoreMappers.goalFromFirestore` | `goals` |

Regras da conversão:

- **`id`** não vai dentro do documento; ele é o identificador do documento.
- **Enums** (`DrinkType`, `GoalType`) viram o nome do valor (`beer`, `maxDrinksPerWeek`) e voltam com `values.byName`.
- **`DateTime`** é enviado em UTC e chega como `Timestamp`; na volta, `Timestamp`, `DateTime` e texto ISO 8601 são aceitos.
- **Números** são lidos como `num` e convertidos para `int` ou `double`, porque o Firestore pode devolver `3` em vez de `3.0`.

## 4. Como os dados chegam ao Firestore

```
Tela → Repositório (Hive) → Fila de sincronização → SyncPendingItems → FirestoreSyncRemote → Firestore
```

1. Ao salvar ou excluir um drinque ou exame, o repositório grava no Hive e coloca a alteração na fila (`SyncQueueRepository`), já convertida pelo mapeamento acima. Exclusões entram na fila sem conteúdo.
2. Várias alterações do mesmo registro viram um só item na fila, com a última versão.
3. Quando há conta, consentimento e Wi-Fi, a fila é enviada em lotes (`WriteBatch`). Criação e edição usam `set` (o documento inteiro é substituído) e exclusão usa `delete`.
4. Antes do envio, o conteúdo passa pela anonimização (tarefa 41), que pode reduzir a precisão de campos sensíveis, como o horário exato de `consumedAt`.

## 5. Segurança

As regras ficam em `hepatocheck_app/firestore.rules`:

- só um usuário autenticado lê, grava e exclui em `users/{uid}/drinks`, `exams` e `goals`, e somente quando `uid` é o dele;
- o documento `users/{uid}` em si e qualquer outro caminho são bloqueados;
- cada documento precisa ter exatamente os campos da seção 2, nem mais nem menos, o que impede gravar nome, e-mail ou outro dado não previsto;
- os tipos e as faixas de valores são os mesmos que o aplicativo valida na entrada:

| Coleção | Validação |
| --- | --- |
| `drinks` | `type` entre os 5 tipos; `volumeMl` de 1 a 3000; `alcoholPercent` de 0,5 a 96; `quantity` inteiro de 1 a 50; `consumedAt` não pode estar mais de 1 dia no futuro |
| `exams` | `age` inteiro de 18 a 120; `ast` e `alt` de 1 a 5000; `platelets` de 1 a 1000; `examDate` não pode estar mais de 1 dia no futuro |
| `goals` | `type` entre os 2 tipos; `target` inteiro de 0 a 100 (dias sem álcool: de 0 a 7); `endDate` vazio ou data; `active` verdadeiro ou falso |

Em todas, `createdAt` e `updatedAt` precisam ser datas. A tolerância de 1 dia no futuro cobre relógios de aparelho adiantados.

Como o envio é em lote, se um único documento for recusado, o lote inteiro é recusado e os itens dele ficam com falha na fila, prontos para nova tentativa.

Para publicar as regras: `firebase deploy --only firestore:rules --project hepatocheck-unit`, na pasta `hepatocheck_app`.
