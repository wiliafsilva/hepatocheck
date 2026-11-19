# Arquitetura do Sistema HepatoCheck

Documento da Unidade I atualizado na Unidade II. Ele descreve a arquitetura como foi implementada na Unidade II: banco local Hive com criptografia AES, camadas Presentation, Domain e Data, Riverpod, sincronização em lote com anonimização e as funcionalidades que passaram a ser obrigatórias.

## Visão geral

O **HepatoCheck** é um aplicativo Flutter para Android com arquitetura **offline-first**: todas as funcionalidades principais funcionam sem internet.

Drinques, exames, metas e preferências são gravados primeiro no próprio aparelho, em um banco local criptografado (Hive com AES). A nuvem (**Cloud Firestore**, no Firebase) guarda uma cópia, enviada quando o usuário tem conta, autorizou o envio e está conectado a uma rede Wi-Fi. Cada documento da cópia tem uma parte legível anonimizada e uma parte selada, com os valores exatos criptografados por uma chave que só a senha da pessoa abre. Ao entrar na conta em outro aparelho ou depois de reinstalar o app, os dados voltam automaticamente.

O código segue três camadas, **Presentation**, **Domain** e **Data**, e o estado do aplicativo é gerenciado com **Riverpod**. As regras de negócio (FIB-4, drinque padrão, risco, relatórios, metas, anonimização) ficam na camada Domain, sem dependência do Flutter nem do Firebase, o que permite testá-las isoladamente.

---

## Tecnologias

| Finalidade | Tecnologia |
| --- | --- |
| Aplicativo | Flutter e Dart, Android 8.0 ou superior |
| Gerenciamento de estado | `flutter_riverpod` |
| Banco local | `hive_ce` com criptografia AES-256 |
| Chave de criptografia e código secreto | `flutter_secure_storage` (armazenamento seguro do Android) |
| Detecção de Wi-Fi | `connectivity_plus` |
| Autenticação | Firebase Authentication (e-mail e senha) |
| Nuvem | Cloud Firestore, região `southamerica-east1` (São Paulo) |
| Notificações | `flutter_local_notifications`, `timezone` e `flutter_timezone` |
| Gráficos | `fl_chart` |
| PDF e compartilhamento | `pdf` e `printing` |
| Hash do registro de alterações | `crypto` (SHA-256) |
| Criptografia da cópia na nuvem | `cryptography` e `cryptography_flutter` (AES-GCM 256 e PBKDF2-HMAC-SHA256, com a implementação nativa do Android) |
| Testes | `flutter_test`, `mocktail` e `fake_cloud_firestore` |

---

## Camadas

```text
┌──────────────────────────────────────────────────────────┐
│ PRESENTATION                                             │
│ Telas, widgets, tema, PDF e providers do Riverpod        │
│ Início │ Relatório │ Drinks │ Exames │ Perfil            │
│ Calculadora da camuflagem │ Login │ Consentimento        │
└───────────────────────────┬──────────────────────────────┘
                            │ usa
                            ▼
┌──────────────────────────────────────────────────────────┐
│ DOMAIN                                                   │
│ Entidades, interfaces dos repositórios e casos de uso    │
│ FIB-4 │ drinque padrão │ risco │ medidor │ relatórios    │
│ metas │ notificações │ anonimização │ sincronização      │
└───────────────────────────▲──────────────────────────────┘
                            │ implementa
┌───────────────────────────┴──────────────────────────────┐
│ DATA                                                     │
│ Repositórios Hive │ fila de sincronização │ Firestore    │
│ Firebase Authentication │ notificações locais            │
└──────────────┬────────────────────────────┬──────────────┘
               ▼                            ▼
  ┌────────────────────┐       ┌───────────────────────┐
  │ Hive criptografado │       │ Firebase              │
  │ no aparelho        │       │ Auth e Firestore      │
  │ (fonte principal)  │       │ (cópia criptografada) │
  └────────────────────┘       └───────────────────────┘
```

- **Presentation** mostra os dados e recebe as ações do usuário. As telas não acessam o banco diretamente: pedem tudo aos providers do Riverpod.
- **Domain** define o que o aplicativo faz. Os repositórios são apenas interfaces (por exemplo, `DrinkRepository`), e os casos de uso (por exemplo, `CalculateFib4`) são classes Dart puras.
- **Data** implementa as interfaces do Domain com Hive, Firestore e Firebase Authentication, e faz a conversão entre as entidades e os formatos de armazenamento.
- **Riverpod** liga as camadas: cada repositório e caso de uso é um provider, e os testes trocam os providers por versões em memória.

---

## Estrutura de pastas

```text
hepatocheck_app/lib/
├── main.dart                 Inicia o Firebase, abre o banco criptografado,
│                             recupera envios interrompidos, reabre o cofre
│                             de quem já está logado e abre o app
├── app.dart                  Tema, navegação em 5 abas, Perfil e camuflagem
├── core/
│   ├── crypto/               Chave AES guardada no armazenamento seguro
│   ├── network/              Monitor de Wi-Fi
│   ├── platform/             Ocultação na tela de apps recentes
│   └── security/             Hash do código secreto da camuflagem
├── domain/
│   ├── entities/             DrinkEntry, LabExam, Fib4Result, RiskLevel,
│   │                         ReductionGoal, SyncItem, AuditEntry, AuthUser...
│   ├── repositories/         Interfaces dos repositórios
│   └── usecases/             Regras: FIB-4, drinque padrão, risco, medidor,
│                             relatórios, metas, mensagens, anonimização,
│                             envio da fila
├── data/
│   ├── auth/                 Firebase Authentication
│   ├── datasources/local/    Abertura do Hive e "Apagar todos os dados"
│   ├── models/               Adaptadores do Hive e conversão para o Firestore
│   ├── notifications/        Lembretes e mensagens educativas
│   ├── repositories/         Repositórios Hive (drinques, exames, metas,
│   │                         registro de alterações, consentimento)
│   └── sync/                 Fila de sincronização, envio ao Firestore,
│                             cofre da chave e restauração
└── presentation/
    ├── camouflage/           Calculadora e controle do Modo Camuflagem
    ├── pdf/                  Resumo em PDF
    ├── providers/            Providers do Riverpod
    ├── screens/              Telas (e auth/ para login, cadastro e senha)
    ├── theme/                Cores, tipografia e tema
    └── widgets/              Componentes reutilizados (medidor, gráficos...)
```

---

## Principais componentes

### 1. Navegação e telas

A navegação principal é uma barra inferior com 5 abas: **Início**, **Relatório**, **Drinks**, **Exames** e **Perfil**. O botão **+** do Início abre o registro rápido de bebida.

Outras telas são abertas a partir dessas abas: metas de redução, notificações e lembretes, sincronização, consentimento, conta (login, cadastro, recuperação de senha e política de privacidade) e a calculadora do Modo Camuflagem.

### 2. Drinks

- Registro por tipo de bebida (cerveja, vinho, destilado, drinque e outra), com porções prontas, volume, teor alcoólico, quantidade e data e hora.
- Conversão automática em **drinque padrão** (14 g de álcool puro), mostrada antes de confirmar (`ConvertToStandardDrinks`).
- Registro rápido em até 3 toques pelo botão + do Início.
- Histórico com edição e exclusão. Cada alteração recalcula os indicadores, entra na fila de sincronização e gera uma linha no registro de alterações.

### 3. Exames e FIB-4

- Cadastro de idade, AST/TGO, ALT/TGP, plaquetas e data do exame, com validação de valores vazios, zerados, negativos ou fora da faixa fisiológica (`ValidateExamInput`).
- Cálculo do FIB-4 (`CalculateFib4`), com aviso quando a idade está fora de 35 a 65 anos.
- O FIB-4 nunca é editado pelo usuário: ao corrigir um exame, ele é recalculado.
- Histórico dos exames e dashboard com a evolução do FIB-4, de AST/ALT e das plaquetas.

### 4. Risco e medidor do fígado

- Classificação **Verde**, **Amarelo** ou **Vermelho** a partir do FIB-4 (`ClassifyRisk`). O nível sobe quando o consumo da semana passa da meta definida pelo usuário (`AssessCurrentRisk`).
- Medidor de 0 a 100% no Início (`CalculateLiverHealth`): parte do FIB-4 e desconta o consumo das últimas 4 semanas acima do limite de baixo risco. É um indicador educativo, não um resultado clínico.
- Gráfico da evolução do risco ao longo dos exames (`BuildRiskEvolution`).

### 5. Relatórios e PDF

- Relatórios semanais e mensais (`BuildConsumptionReport`): total de drinques padrão, média por dia, dias sem álcool, consumo por tipo e por dia e comparação com o período anterior.
- Resumo em PDF (`BuildHealthSummary` e `HealthSummaryPdf`) com FIB-4, risco, evolução dos exames, consumo do período e metas, para visualizar, salvar ou compartilhar. O compartilhamento pede confirmação, e o PDF não leva nome, e-mail nem identificação da conta.

### 6. Metas e notificações

- Metas de redução: máximo de drinques por semana ou dias sem álcool por semana, com acompanhamento, edição e exclusão (`EvaluateGoal`).
- Notificações locais (`LocalFollowUpNotifications`), cada tipo ligado ou desligado pelo usuário: mensagens educativas escolhidas pelo consumo, pelas metas e pela faixa de risco (`BuildFollowUpMessages`), lembrete de exame e lembrete de registro.
- Com o Modo Camuflagem ativo, as notificações usam texto neutro ("Lembrete"), sem mencionar álcool ou saúde.

### 7. Privacidade e Modo Camuflagem

- **Modo convidado:** o aplicativo funciona inteiro sem conta.
- **Modo Camuflagem:** o diário fica atrás de uma calculadora funcional. O código secreto (4 a 8 dígitos) é guardado apenas como hash no armazenamento seguro. Ao ir para segundo plano, o aplicativo volta para a calculadora e oculta o conteúdo na tela de apps recentes.
- **Apagar todos os dados:** limpa drinques, exames, metas, preferências, consentimento, fila de sincronização e registro de alterações do aparelho, e esquece a chave do cofre neste aparelho.

### 8. Conta, consentimento e restauração

- Conta opcional com e-mail e senha no Firebase Authentication, usada para sincronizar e para recuperar os dados em outro aparelho.
- Tela de consentimento que mostra o que é enviado e o que nunca sai do aparelho, com opção de autorizar e de revogar.
- **Cofre** (`CloudVault`, implementado por `FirestoreCloudVault`): uma chave de dados aleatória criptografa a parte selada de cada documento. Essa chave fica na nuvem trancada pela senha (PBKDF2) e, no aparelho, no armazenamento seguro.
- **Entrar** (`AccountSession.signIn`): login, abertura do cofre com a senha e **restauração automática** (`FirestoreCloudRestore`), sem perguntar.
- **Criar conta:** aviso "Seus dados ficam trancados com a sua senha" com "Entendi" obrigatório; depois, conta e cofre são criados.
- **Esqueci minha senha:** o mesmo aviso antes de enviar o e-mail. No login seguinte, se a senha nova não abrir a chave antiga, o app cria uma chave nova, apaga a cópia antiga da nuvem e reenvia os dados do aparelho.
- **Sair:** revoga a autorização e esquece a chave no aparelho; os dados continuam no aparelho.

### 9. Armazenamento local

O Hive é a **fonte principal** dos dados. Todas as caixas são abertas com AES-256, e a chave é gerada no primeiro uso e guardada no armazenamento seguro do Android.

| Caixa | Conteúdo |
| --- | --- |
| `drinks` | Registros do diário de álcool |
| `exams` | Exames laboratoriais |
| `reduction_goals` | Metas de redução |
| `follow_up_preferences` | Preferências de notificação e avisos já enviados |
| `sync_consent` | Data da autorização de sincronização |
| `sync_queue` | Fila de sincronização |
| `audit_log` | Registro de alterações do diário |

### 10. Sincronização com o Firestore

Detalhada nas seções "Sincronização" e "Restauração" abaixo. A estrutura das coleções, a anonimização, a parte selada e as regras de segurança estão em [`modelagem-firestore.md`](modelagem-firestore.md).

---

## Funcionamento offline-first

```text
Usuário registra ou altera um dado
          │
          ▼
Aplicativo valida os dados (Domain)
          │
          ▼
Dado salvo no Hive criptografado
e colocado na fila de sincronização
          │
          ▼
Telas atualizadas na hora (Riverpod)
          │
          ▼
Tem conta, autorização e Wi-Fi?
          │
     ┌────┴────┐
    Não       Sim
     │         │
     ▼         ▼
 Fica na    Anonimiza, sela e envia
 fila       em lotes ao Firestore
```

Sem internet, nada deixa de funcionar: os itens ficam na fila e são enviados depois.

---

## Sincronização

```text
Repositório (Hive) → Fila (SyncQueueRepository) → AutoSync → SyncPendingItems
   → AnonymizeSyncPayload + CloudVault.seal → FirestoreSyncRemote → Cloud Firestore
```

1. **Fila:** cada criação, edição ou exclusão de drinque, exame ou meta vira um item na fila, guardada no Hive. Várias alterações do mesmo registro viram um só item, com a última versão.
2. **Quando envia:** o `AutoSync` tenta enviar ao conectar no Wi-Fi, ao voltar para o aplicativo, logo depois de registrar ou alterar um drinque, exame ou meta, ao entrar na conta e ao autorizar a sincronização. O envio só acontece com conta, autorização, Wi-Fi e cofre aberto; em dados móveis, nada é enviado. O usuário também pode enviar pela tela de sincronização no Perfil.
3. **Anonimização e selagem:** a parte legível leva só os campos previstos, com a idade como faixa etária e as datas sem horário. A parte selada leva os valores exatos, criptografados com a chave de dados (AES-GCM 256).
4. **Envio em lotes:** a fila é dividida em lotes de 20, e cada lote é gravado com `WriteBatch`, que é tudo ou nada. Um lote recusado não impede os outros: os itens dele ficam marcados como falha, com o motivo, e podem ser reenviados pelo botão "Tentar de novo".
5. **Recuperação:** se o aplicativo fechar no meio do envio, os itens que estavam sendo enviados voltam para a fila na próxima abertura.

---

## Restauração

```text
Login → AccountSession.signIn → CloudVault.unlock (senha) → FirestoreCloudRestore
   → abre a parte selada → junta com o Hive → atualiza as telas e envia o que faltava
```

1. **Abrir o cofre:** a senha vira uma chave (PBKDF2) que destranca a chave de dados guardada em `users/{uid}`.
2. **Baixar e abrir:** drinques, exames e metas são baixados, e a parte selada de cada um é aberta para recuperar os valores exatos.
3. **Juntar:** vale a versão mais recente (`updatedAt`); alterações e exclusões que ainda estão na fila do aparelho não são desfeitas; o que só existe no aparelho entra na fila.
4. **Gravar:** a restauração grava direto no Hive, sem fila e sem registro de alterações, e mostra quanto foi restaurado.
5. **Falhas:** se não houver internet, o login acontece mesmo assim e a restauração fica para a próxima entrada.

---

## Segurança

| Camada de proteção | Como funciona |
| --- | --- |
| Dados no aparelho | Todas as caixas do Hive com AES-256; chave no armazenamento seguro do Android |
| Código secreto da camuflagem | Guardado só como hash, nunca o código em si |
| Registro de alterações | Cada linha guarda o hash da anterior (SHA-256 encadeado); uma alteração no meio quebra a corrente. Não guarda tipo de bebida nem quantidade, e não vai para a nuvem |
| Dados na nuvem | Parte legível anonimizada e parte selada criptografada com AES-GCM 256, guardadas em `users/{uid}/...` |
| Chave da cópia na nuvem | Aleatória, trancada pela senha com PBKDF2-HMAC-SHA256; a chave aberta e a senha nunca vão para a nuvem. Nem quem administra o Firebase consegue abrir a parte selada |
| Regras do Firestore | Cada usuário só lê e grava na própria pasta; os documentos precisam ter exatamente os campos previstos, com tipos e faixas válidos, inclusive a chave trancada |
| Notificações | Texto neutro com a camuflagem ativa |
| Compartilhamento do PDF | Confirmação antes de enviar; sem nome, e-mail ou identificação da conta |

O HepatoCheck é uma ferramenta de **triagem, prevenção, educação e acompanhamento**. Ele não substitui diagnóstico nem avaliação profissional, e todas as telas de risco e o PDF trazem esse aviso.

---

## Testes

Os testes automatizados ficam em `hepatocheck_app/test`, separados como o código (`core`, `data`, `domain` e `presentation`), e rodam com `flutter test`. Eles cobrem, entre outros:

- cálculo e validação do FIB-4;
- conversão em drinque padrão, relatórios e metas;
- criptografia do banco local e registro de alterações;
- fila de sincronização, envio em lotes com falha parcial e regras de recuperação;
- anonimização no envio ao Firestore e parte selada com os valores exatos;
- cofre da chave (senha certa, senha errada, outro aparelho, recuperação e troca de senha) e restauração entre dois aparelhos;
- login com restauração, aviso da senha no cadastro e na recuperação, e envio automático ao entrar, autorizar e mudar metas;
- telas principais, inclusive com fonte ampliada e em celular pequeno.
