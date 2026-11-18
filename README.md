# hepatocheck

## Integrantes
- Gabriel de Oliveira Alves
- Leon Mendonça
- Lizandra Bispo Nascimento
- Victor Castelo Branco
- Wilia Francisco da Silva

## Turma 
- GP0015NOT07A

## Breve descrição do projeto

### Este projeto trata-se de Aplicativo mobile voltado à prevenção da Doença Hepática Gordurosa Não Alcoólica (DHGNA) em adultos que consomem álcool socialmente ou possuem dieta rica em alimentos ultraprocessados, oferecendo uma calculadora de risco hepático baseada no escore **FIB-4**, a partir de exames de sangue, um **diário de consumo de álcool** em “drinques padrão” e uma classificação de risco em **Verde/Amarelo/Vermelho**, com orientações sobre quando procurar um gastroenterologista. O aplicativo é desenvolvido com foco em **privacidade**, garantindo que os dados relacionados ao consumo de álcool não sejam sincronizados sem permissão explícita, além de adotar uma abordagem **offline-first** e proporcionar leitura rápida tanto em ambientes cotidianos, como casa e bar, quanto durante consultas médicas.

## Como rodar o app

O código do aplicativo fica na pasta `hepatocheck_app`. A documentação do projeto fica em `docs`.

### O que é preciso ter instalado

- **Flutter 3.47.8** (canal stable), que já traz o Dart 3.13.7. Para conferir: `flutter --version`.
- **Android Studio** com o Android SDK da **API 37** e o **JDK 17**. A API 37 é exigida pelo pacote de notificações.
- Um **celular Android 8.0 ou superior** com a depuração USB ativada, ou um **emulador** criado no Android Studio.
- **Git**, para baixar o projeto.

Para ver se falta alguma coisa, rode `flutter doctor`.

A configuração do Firebase (projeto `hepatocheck-unit`) já está no repositório, em `hepatocheck_app/android/app/google-services.json` e `hepatocheck_app/lib/firebase_options.dart`. Não é preciso criar um projeto no Firebase para rodar o app.

### Passo a passo

```bash
git clone https://github.com/wiliafsilva/hepatocheck.git
cd hepatocheck/hepatocheck_app
flutter pub get
flutter devices
flutter run
```

- `flutter pub get` baixa as dependências do projeto.
- `flutter devices` mostra os aparelhos e emuladores conectados.
- `flutter run` instala e abre o app no aparelho. Se houver mais de um, escolha com `flutter run -d <id do aparelho>`.

O app abre no **modo convidado**, sem conta. Criar uma conta só é necessário para testar a sincronização com a nuvem, que também exige autorizar o envio no Perfil e estar conectado a uma rede Wi-Fi.

### Testes e análise do código

Dentro da pasta `hepatocheck_app`:

```bash
flutter analyze
flutter test
```

- `flutter analyze` confere o código e deve terminar com `No issues found!`.
- `flutter test` roda todos os testes automatizados e deve terminar com `All tests passed!`.

### Gerar o APK

Dentro da pasta `hepatocheck_app`:

```bash
flutter build apk --release
```

O arquivo fica em `hepatocheck_app/build/app/outputs/flutter-apk/app-release.apk`. Para instalar no celular conectado, use `flutter install` ou copie o arquivo para o aparelho e abra-o, permitindo a instalação de fontes desconhecidas.

### Regras de segurança do Firestore

As regras ficam em `hepatocheck_app/firestore.rules`. Só quem tem acesso de editor ao projeto `hepatocheck-unit` pode publicá-las, com a [Firebase CLI](https://firebase.google.com/docs/cli), dentro da pasta `hepatocheck_app`:

```bash
firebase deploy --only firestore:rules --project hepatocheck-unit
```

### Observação para quem desenvolve no Windows

O `flutter pub get` pode marcar como alterados alguns arquivos gerados das pastas `linux`, `macos` e `windows`, só por causa do tipo de quebra de linha. Para descartar essa mudança antes de um commit ou de um `git pull`, rode na raiz do repositório:

```bash
git restore hepatocheck_app/linux hepatocheck_app/macos hepatocheck_app/windows
```


## Registro das responsabilidades 02/09/2026

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves | Contexto de uso-Objetivo e proposta de valor | Identificar diferentes contextos e o que o app oferece |
| Lizandra Bispo Nascimento | Problema-Público e usuários  | Problema que app atende e Análise publico alvo |
| Victor Castelo Branco  | Personalidade, identidade e experiência-Funcionalidades e características já definidas  | características deverão influenciar a solução e qual necessidade ela atende |
| Wilia Francisco da Silva | Restrições e condições-Pontos de atenção  | Desenvolvimento das telas e fluxos |
| Leon Mendonça | - | - |

## Registro das responsabilidades 09/09/2026

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves | Pesquisa | problema, Necessidades e dificuldades dos usuários, Dados que possam influenciar o aplicativo, Fontes |
| Lizandra Bispo Nascimento | Benchmark  | Principais funcionalidades, Pontos positivos, Pontos negativos |
| Victor Castelo Branco  | Benchmark  | Aspectos de interface/experiência, O que pode ser aproveitado ou melhorado no projeto, O que nosso aplicativo poderá fazer de diferente ou melhor? |
| Wilia Francisco da Silva | Restrições e condições-Pontos de atenção  | Desenvolvimento das telas e fluxos |
| Leon Mendonça | Personas | Crie 2 personas principais para o projeto (Nome fictício, Perfil/contexto, Objetivos, Necessidades, Dores, Comportamentos, Relação com o aplicativo) | 

## Registro das responsabilidades (16/09/2026) Atividade - 03 

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves |  Funcionalidades | Defina as principais funcionalidades do aplicativo. |
| Lizandra Bispo Nascimento | Requisitos não funcionais + apresentação  | Defina as principais características e condições que o aplicativo deverá atender. |
| Victor Castelo Branco  | CRUD  | Identifique, quando aplicável, quais informações do aplicativo precisarão ser. |
| Wilia Francisco da Silva | Requisitos funcionais  | Transforme as principais funcionalidades em requisitos funcionais, descrevendo o  que o sistema deverá fazer. |
| Leon Mendonça | Priorização | Classifique as funcionalidades (Essenciais, Importantes, Secundárias) | 

## Registro das responsabilidades (29/09/2026) Atividade - 04 e 05 - Prototipação Baixa Fidelidade, Alta Fidelidade, Justificativa e Slides deApresentação

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves |  Prototipação, Slides, justificativa | Telas relatório e Exames, elaboração de slides, Escolha das cores |
| Lizandra Bispo Nascimento | Prototipação, Justificativa, Slides  | Navegação do protótipo, Navegação, elaboração de slides |
| Victor Castelo Branco  | Prototipação, Slides, justificativa  | Telas Login e Home, Tipografia, elaboração de slides |
| Wilia Francisco da Silva | Prototipação baixa e alta fidelidade, Changelog e Readme, justificativa  | Protótipo de baixa e alta fidelidade, Changelog e Readme, Acessibilidade |
| Leon Mendonça | Prototipação, Justificativa | Tela Drinks, Arquitetura do sistema | 

## Registro das responsabilidades (02/11/2026) Atividade - Configuração do Firebase

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Wilia Francisco da Silva | Configuração do Firebase | Criação do projeto hepatocheck-unit, registro dos apps Android e Web, Authentication por e-mail e senha, Cloud Firestore em São Paulo, regras de segurança do Firestore e inicialização do Firebase no app |

## Registro das responsabilidades (04/11/2026) Semana 1 - Fundação e núcleo clínico

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves | FIB-4, Exames, Cores, Escopo | Cores do tema e do semáforo, cálculo do FIB-4, validação de entradas inconsistentes, classificação de risco Verde, Amarelo e Vermelho, testes automatizados do FIB-4, escopo do projeto, repositório e tela Exames |
| Lizandra Bispo Nascimento | Navegação, EAP | Barra de navegação inferior com as 5 abas, telas iniciais de cada aba, EAP simplificada, layout da calculadora do Modo Camuflagem |
| Victor Castelo Branco | Tipografia, Home, Casos de uso | Fonte Inter e níveis de texto, estrutura da tela Início com cartão de risco e botão de registro rápido, diagrama de casos de uso, layout do medidor do fígado |
| Wilia Francisco da Silva | Estrutura do projeto, Sprints, Changelog e Readme | Reunião de início, fluxo de branches e pull requests, regras de commit, dependências do projeto, estrutura em camadas (Presentation, Domain e Data), Riverpod, planejamento em sprints, Changelog e Readme |
| Leon Mendonça | Banco local, Diagrama de classes | Entidades do domínio, rascunho do diagrama de classes, banco local Hive com criptografia AES, adaptadores do Hive para exames e drinques |

## Registro das responsabilidades (09/11/2026) Semana 2 - Diário, privacidade e medidor

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves | Exames, Relatório | Histórico de exames na tela Exames, regras de cálculo dos relatórios semanais e mensais, estrutura da tela Relatório com filtro de período |
| Lizandra Bispo Nascimento | Modo Camuflagem | Calculadora funcional com troca instantânea para o diário, código secreto para voltar ao diário, camuflagem automática em segundo plano, criptografia do banco ao ativar a camuflagem, ocultação do app na tela de recentes, teste automatizado da criptografia |
| Victor Castelo Branco | Home, Medidor, Login | Medidor do fígado de 0 a 100% com dados reais e cor do risco, ligação da tela Início com os exames e o diário, telas de login e cadastro |
| Wilia Francisco da Silva | Fila offline, Changelog e Readme | Revisão dos pull requests, fila offline de sincronização, detecção de Wi-Fi, Changelog e Readme |
| Leon Mendonça | Drinks | Registro detalhado por tipo de bebida, conversão em drinque padrão, repositório do diário, tela Drinks com histórico, edição e exclusão, registro rápido em até 3 toques, registro de alterações do diário |

## Registro das responsabilidades (16/11/2026) Semana 3 - Nuvem, relatórios e metas

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves | Relatório, Dashboard, PDF | Relatórios semanais e mensais na tela com gráfico de consumo por dia e comparação justa do período em andamento, classificação de risco elevada quando o consumo passa da meta semanal, dashboard de evolução dos exames, exportação do relatório em PDF, compartilhamento do PDF com confirmação |
| Lizandra Bispo Nascimento | Metas, Notificações | Metas de redução com criação, acompanhamento, edição e exclusão, aviso de meta cumprida ou perto de ser ultrapassada, notificações educativas personalizadas, lembretes de exame e de registro, ajustes da calculadora do Modo Camuflagem e do limite das metas |
| Victor Castelo Branco | Login, Anonimização, Evolução do risco | Autenticação opcional mantendo o modo convidado, tela de consentimento da sincronização com opção de revogar, anonimização dos dados com faixa etária e datas sem horário, gráfico de evolução temporal do risco na tela Início, telas de cadastro, recuperação de senha e política de privacidade |
| Wilia Francisco da Silva | Sincronização, Changelog e Readme | Revisão dos pull requests, sincronização em lote com o Firestore, tratamento de falhas parciais, envio automático ao conectar no Wi-Fi, regras de segurança do Firestore com validação dos campos, metas na fila de sincronização, testes automatizados da sincronização e da anonimização, tela de status da sincronização, Changelog e Readme |
| Leon Mendonça | Drinks, Integração, Modelagem do Firebase | Ligação do diário e dos exames à fila de sincronização, modelagem das coleções e documentos do Firestore, mapeamento das classes Dart para o Firestore, ajustes do diário apontados nas revisões, opção de apagar todos os dados locais |

## Registro das responsabilidades (23/11/2026) Semana 4 - Estabilização e entrega

| Integrante | Responsabilidade | O que deverá realizar |
| --- | --- | --- |
| Gabriel de Oliveira Alves | Correções, Uso de IA, Justificativas, Modo consulta | Correção dos erros de Exames, Relatório e PDF, registro do uso de IA com a justificativa das bibliotecas, atualização das justificativas, modo consulta para o profissional de saúde |
| Lizandra Bispo Nascimento | Correções, Fluxo de navegação, Slides | Correção dos erros de camuflagem, metas e notificações, fluxo de navegação real com capturas de tela, slides da apresentação da Unidade II, filtro amarelado de icterícia em risco alto |
| Victor Castelo Branco | Correções, Orientação médica, Vídeo | Correção dos erros de Início, login e anonimização, orientação "Quando procurar o médico", vídeo de demonstração |
| Wilia Francisco da Silva | Validação, Protótipos, Changelog e Readme, Acessibilidade | Análise do código e testes automatizados sem erros, APK de release, conferência das telas com o protótipo de alta fidelidade, revisão final do Changelog e do Readme, revisão de acessibilidade |
| Leon Mendonça | Correções, Arquitetura do sistema, Diagrama de classes | Correção dos erros de Drinks e do banco local, versão final do diagrama de classes, atualização da arquitetura do sistema, atualização dos requisitos com os novos requisitos |

## Fluxo de navegação e revisão de estabilização

O [fluxo de navegação real](docs/fluxo-de-navegacao.md) reúne diagramas Mermaid, 15 capturas das telas implementadas, as verificações de camuflagem, metas e notificações e a descrição do filtro ilustrativo em risco alto. A partir de 23/11/2026, o escopo fica congelado para novas funcionalidades, conforme a Sprint 4.
