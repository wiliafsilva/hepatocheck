# Modelagem do Firestore

Este documento descreve como os dados do HepatoCheck são guardados no Cloud Firestore (projeto `hepatocheck-unit`, região `southamerica-east1`), como as classes Dart do domínio são convertidas para os documentos da nuvem e como os dados voltam para o aparelho.

O aplicativo é **offline-first**: o banco local (Hive, criptografado) é a fonte principal dos dados. O Firestore guarda uma cópia, enviada pela fila de sincronização quando o usuário tem conta, autorizou o envio e está no Wi-Fi. Essa cópia tem duas partes:

- uma **parte legível e anonimizada**, sem nome, e-mail, idade exata nem horário;
- uma **parte selada**, com os valores exatos criptografados por uma chave que só a senha da pessoa abre. Nem quem administra o Firebase consegue lê-la.

Ao entrar na conta em outro aparelho ou depois de reinstalar o app, a parte selada é aberta com a senha e os dados voltam para o aparelho automaticamente (seção 5).

## 1. Estrutura das coleções

Todos os dados de um usuário ficam dentro do documento dele, identificado pelo `uid` do Firebase Authentication:

```
users/{uid}            chave de dados trancada pela senha (seção 2.4)
├── drinks/{drinkId}   registros do diário de álcool
├── exams/{examId}     exames de sangue (TGO, TGP, plaquetas)
└── goals/{goalId}     metas de redução
```

- **`users/{uid}`** não guarda nome, e-mail nem outro dado pessoal. O e-mail fica só no Firebase Authentication. O documento guarda apenas a chave de dados **trancada** (criptografada) pela senha.
- **Identificadores dos documentos** são os mesmos UUIDs gerados no aparelho (`id` das entidades). Eles não carregam nenhuma informação sobre o conteúdo.
- **Subcoleções por usuário** deixam as regras de segurança simples: cada pessoa só lê e grava dentro de `users/{seu uid}`.

## 2. Documentos

As tabelas abaixo mostram os documentos **como chegam à nuvem**. Na parte legível, as datas são gravadas como `timestamp` do Firestore só com o dia (meia-noite UTC do dia local), sem o horário. Valores calculados (drinques padrão, FIB-4, classificação de risco) **não** são guardados: o aplicativo recalcula a partir dos dados brutos, o que evita valores desatualizados na nuvem.

Todo documento de `drinks`, `exams` e `goals` também leva os três campos da parte selada:

| Campo | Tipo | Conteúdo |
| --- | --- | --- |
| `sealed` | string (base64) | Os valores exatos do registro (com idade exata e data e hora completas), em JSON, criptografados com AES-GCM 256 pela chave de dados |
| `sealedNonce` | string (base64) | Valor aleatório único deste documento, usado na criptografia |
| `keyVersion` | number (inteiro) | Versão da chave de dados usada; muda quando a senha é recuperada |

### 2.1 `users/{uid}/drinks/{drinkId}`

| Campo | Tipo | Origem (`DrinkEntry`) | Observação |
| --- | --- | --- | --- |
| `type` | string | `type` | `beer`, `wine`, `spirit`, `cocktail` ou `other` |
| `volumeMl` | number | `volumeMl` | Volume de uma unidade, em ml |
| `alcoholPercent` | number | `alcoholPercent` | Teor alcoólico, em % |
| `quantity` | number (inteiro) | `quantity` | Número de unidades |
| `consumedAt` | timestamp | `consumedAt` | Dia em que a bebida foi consumida, sem o horário |
| `createdAt` | timestamp | `createdAt` | |
| `updatedAt` | timestamp | `updatedAt` | |
| `sealed`, `sealedNonce`, `keyVersion` | | | Parte selada |

### 2.2 `users/{uid}/exams/{examId}`

| Campo | Tipo | Origem (`LabExam`) | Observação |
| --- | --- | --- | --- |
| `examDate` | timestamp | `examDate` | Data do exame |
| `ageRange` | string | `age` | Faixa etária de 10 anos (ex.: `40-49`). A idade exata vai só na parte selada |
| `ast` | number | `ast` | TGO (U/L) |
| `alt` | number | `alt` | TGP (U/L) |
| `platelets` | number | `platelets` | Plaquetas (×10⁹/L) |
| `createdAt` | timestamp | `createdAt` | |
| `updatedAt` | timestamp | `updatedAt` | |
| `sealed`, `sealedNonce`, `keyVersion` | | | Parte selada |

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
| `sealed`, `sealedNonce`, `keyVersion` | | | Parte selada |

### 2.4 `users/{uid}` (chave trancada)

| Campo | Tipo | Conteúdo |
| --- | --- | --- |
| `keyVersion` | number (inteiro) | Versão da chave de dados, começando em 1 |
| `kdf` | string | `pbkdf2-sha256`, o método que transforma a senha em chave |
| `iterations` | number (inteiro) | Número de repetições do PBKDF2 (200.000); fica gravado para poder ser ajustado por conta |
| `salt` | string (base64) | Valor aleatório de 16 bytes usado com a senha |
| `wrappedKey` | string (base64) | Chave de dados de 32 bytes, criptografada com AES-GCM pela chave derivada da senha |
| `wrapNonce` | string (base64) | Valor aleatório usado para trancar a chave |
| `updatedAt` | timestamp | Momento da última troca (horário do servidor) |

A chave de dados aberta **nunca** vai para a nuvem. No aparelho, ela fica no armazenamento seguro do Android, separada por conta, para o app não pedir a senha toda vez que abre.

### Exemplo de documento

`users/Xy12.../exams/9b8a7c6d-...`

```json
{
  "examDate": "2026-11-10T00:00:00Z",
  "ageRange": "40-49",
  "ast": 38,
  "alt": 41,
  "platelets": 215,
  "createdAt": "2026-11-15T00:00:00Z",
  "updatedAt": "2026-11-15T00:00:00Z",
  "sealed": "q3l0vB...k9Zw==",
  "sealedNonce": "Nf2c8Ah1XoQe0b7p",
  "keyVersion": 1
}
```

O console do Firebase mostra as datas no horário de Brasília, por isso a meia-noite UTC aparece como 21:00 do dia anterior. O dado está certo.

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
- **`DateTime`** é enviado em UTC; na volta, `Timestamp`, `DateTime` e texto ISO 8601 são aceitos. A restauração converte as datas para o horário do aparelho.
- **Números** são lidos como `num` e convertidos para `int` ou `double`, porque o Firestore pode devolver `3` em vez de `3.0`.

O conteúdo da parte selada é o mesmo mapa de `toFirestore`, com as datas em texto ISO 8601. Na restauração, ele é aberto e passa por `fromFirestore`.

### 3.1 O que a anonimização remove ou generaliza

Antes do envio, a parte legível passa por `AnonymizeSyncPayload` (`hepatocheck_app/lib/domain/usecases/anonymize_sync_payload.dart`, tarefa 41). Só os campos da seção 2 passam; qualquer outro é descartado.

| Dado no aparelho | Parte legível | Parte selada |
| --- | --- | --- |
| Nome e e-mail | Nada | Nada. O e-mail fica só no Firebase Authentication |
| `uid` do Firebase | Só no caminho `users/{uid}/...`, nunca dentro do documento | Nada |
| Idade exata (`age`) | Faixa etária de 10 anos (`ageRange`, ex.: 47 → `40-49`) | Idade exata, criptografada |
| Data e hora (`consumedAt`, `examDate`, `startDate`, `endDate`, `createdAt`, `updatedAt`) | Só o dia, sem o horário | Data e hora exatas, criptografadas |
| Observações livres e campos não previstos | Nada | Nada |
| Registro de alterações do diário (log de auditoria) | Nada | Nada; não entra na fila |
| Código secreto da camuflagem e senha | Nada | Nada |
| ID do registro | O mesmo UUID aleatório | Nada |
| TGO, TGP, plaquetas, tipo, volume, teor e quantidade da bebida, metas | Valor original | Valor original, criptografado |

O teste automatizado 5 (`hepatocheck_app/test/data/sync/anonymized_sync_test.dart`) confere que a parte legível não tem nome, e-mail, observações, `uid`, idade exata nem horário. `sealed_sync_test.dart` confere que a parte selada não é legível sem a chave e que, aberta, devolve a idade e a data exatas.

## 4. Como os dados chegam ao Firestore

```
Tela → Repositório (Hive) → Fila de sincronização → SyncPendingItems → anonimização + selagem → FirestoreSyncRemote → Firestore
```

1. Ao salvar ou excluir um drinque, exame ou meta, o repositório grava no Hive e coloca a alteração na fila (`SyncQueueRepository`), já convertida pelo mapeamento acima. Exclusões entram na fila sem conteúdo.
2. Várias alterações do mesmo registro viram um só item na fila, com a última versão.
3. Quando há conta, consentimento, Wi-Fi e cofre aberto, a fila é enviada em lotes de 20 (`WriteBatch`). Criação e edição usam `set` (o documento inteiro é substituído) e exclusão usa `delete`.
4. Antes do envio, cada documento recebe a parte legível anonimizada (seção 3.1) e a parte selada, criada por `CloudVault.seal` com os valores exatos. Exclusões não têm conteúdo e vão direto.
5. O envio automático acontece ao conectar no Wi-Fi, ao voltar para o app, depois de alterar drinques, exames ou metas, ao entrar na conta e ao autorizar a sincronização. Ao sair da conta, o consentimento é revogado e a chave é esquecida no aparelho.

## 5. Como os dados voltam para o aparelho

Ao entrar na conta (tela de login), o app faz tudo sozinho, sem perguntar:

1. **Abre o cofre:** lê `users/{uid}`, transforma a senha em chave com PBKDF2 (com o `salt` e as `iterations` gravados) e destranca a chave de dados. Se a conta ainda não tem chave, uma nova é criada.
2. **Restaura** (`FirestoreCloudRestore`): baixa `drinks`, `exams` e `goals`, abre a parte selada de cada documento e monta as entidades com os valores exatos, com as datas no horário do aparelho.
3. **Junta com o aparelho:**
   - registro que existe nos dois lados: fica o de `updatedAt` mais recente;
   - registro com alteração ou exclusão ainda na fila do aparelho: o aparelho vence, para a nuvem não desfazer o que não foi enviado;
   - registro que só existe na nuvem: é gravado no aparelho;
   - registro que só existe no aparelho: entra na fila para subir.
4. A restauração grava direto no banco local, **sem** colocar na fila e **sem** gerar registro de alterações do diário.
5. O app mostra quanto foi restaurado (por exemplo, "Seus dados foram restaurados: 8 drinques, 2 exames e 1 meta.") e dispara o envio do que estava só no aparelho.

Documentos antigos, sem a parte selada, são contados como ilegíveis e ignorados. Uma falha na restauração (sem internet, por exemplo) não impede o login.

### 5.1 Esqueci minha senha

A recuperação de senha do Firebase troca a senha, mas a chave antiga continua trancada pela senha antiga. Por isso:

- antes de enviar o e-mail de recuperação, e também ao criar a conta, o app mostra o aviso "Seus dados ficam trancados com a sua senha", com "Entendi" obrigatório;
- no login seguinte, se a senha nova não abrir a chave, o app cria uma chave nova (`keyVersion` + 1), apaga a cópia antiga da nuvem e reenvia tudo o que está no aparelho;
- o histórico só se perde se a pessoa perder a senha **e** o aparelho.

## 6. Segurança

As regras ficam em `hepatocheck_app/firestore.rules`:

- só um usuário autenticado lê, grava e exclui em `users/{uid}` e nas subcoleções `drinks`, `exams` e `goals`, e somente quando `uid` é o dele;
- qualquer outro caminho é bloqueado;
- cada documento precisa ter exatamente os campos da seção 2, nem mais nem menos, o que impede gravar nome, e-mail, a chave aberta ou outro dado não previsto;
- os tipos e as faixas de valores são os mesmos que o aplicativo valida na entrada:

| Documento | Validação |
| --- | --- |
| `users/{uid}` | `keyVersion` inteiro de 1 a 1000; `kdf` igual a `pbkdf2-sha256`; `iterations` inteiro de 1.000 a 10.000.000; `salt` com 24 caracteres (16 bytes); `wrappedKey` com 64 caracteres (48 bytes); `wrapNonce` com 16 caracteres (12 bytes); `updatedAt` data |
| Parte selada (todas as coleções) | `sealed` texto de 1 a 20.000 caracteres; `sealedNonce` com 16 caracteres; `keyVersion` inteiro de 1 a 1000 |
| `drinks` | `type` entre os 5 tipos; `volumeMl` de 1 a 3000; `alcoholPercent` de 0,5 a 96; `quantity` inteiro de 1 a 50; `consumedAt` não pode estar mais de 1 dia no futuro |
| `exams` | `ageRange` texto no formato `40-49` (o campo `age` é recusado); `ast` e `alt` de 1 a 5000; `platelets` de 1 a 1000; `examDate` não pode estar mais de 1 dia no futuro |
| `goals` | `type` entre os 2 tipos; `target` inteiro de 0 a 100 (dias sem álcool: de 0 a 7); `endDate` vazio ou data; `active` verdadeiro ou falso |

Nas coleções, `createdAt` e `updatedAt` precisam ser datas. A tolerância de 1 dia no futuro cobre relógios de aparelho adiantados.

Como o envio é em lote, se um único documento for recusado, o lote inteiro é recusado e os itens dele ficam com falha na fila, prontos para nova tentativa.

As regras foram testadas no emulador do Firestore (`@firebase/rules-unit-testing`). Para publicar: `firebase deploy --only firestore:rules --project hepatocheck-unit`, na pasta `hepatocheck_app`.
