# Planejamento do Desenvolvimento em Sprints

O desenvolvimento do HepatoCheck na Unidade II está dividido em **4 sprints semanais**, de 04/11/2026 a 27/11/2026. Cada sprint tem um objetivo, uma entrega verificável no último dia e um checkpoint em que cada integrante apresenta o que fez.

A ordem das sprints segue a priorização definida em `requisitos.md`: primeiro a base técnica e as funcionalidades essenciais (cálculo do FIB-4, diário de álcool e privacidade), depois a nuvem e os recursos de acompanhamento, e por último a estabilização.

## Visão geral

| Sprint | Período | Objetivo | Entrega |
| --- | --- | --- | --- |
| 1 | 04/11 a 08/11 | Fundação e núcleo clínico | O app abre, navega entre as 5 abas, calcula o FIB-4 e salva o exame criptografado no aparelho |
| 2 | 09/11 a 14/11 | Diário, privacidade e medidor | Registro de drinques completo, Modo Camuflagem com troca instantânea, banco criptografado e medidor do fígado com dados reais, tudo sem internet |
| 3 | 16/11 a 22/11 | Nuvem, relatórios e metas | Login, sincronização em lote com o Firestore e tratamento de falhas parciais, relatórios, metas, notificações e exportação em PDF |
| 4 | 23/11 a 27/11 | Estabilização e entrega | App estável, testes passando, APK gerado, documentação atualizada e apresentação pronta |

Antes da Sprint 1, em 02/11, o Firebase foi configurado: projeto `hepatocheck-unit`, login por e-mail e senha e Cloud Firestore com regras de segurança.

Feriados no período: 15/11 (domingo) e 20/11 (sexta-feira).

## Sprint 1 — Fundação e núcleo clínico (04/11 a 08/11)

**Objetivo:** preparar a estrutura do app e entregar o cálculo do FIB-4, que é o núcleo da proposta.

**Entrega (08/11):** o app abre, navega entre as 5 abas, calcula o FIB-4 e salva o exame criptografado no aparelho.

| Integrante | Responsabilidade |
| --- | --- |
| Gabriel de Oliveira Alves | Cores do tema e do semáforo, cálculo do FIB-4, validação de entradas inconsistentes, classificação de risco, testes do FIB-4, escopo do projeto, tela Exames |
| Lizandra Bispo Nascimento | Barra de navegação com as 5 abas, telas iniciais de cada aba, EAP simplificada, layout da calculadora do Modo Camuflagem |
| Victor Castelo Branco | Fonte e tipografia, estrutura da tela Início, diagrama de casos de uso, layout do medidor do fígado |
| Wilia Francisco da Silva | Reunião de início, fluxo de branches e pull requests, dependências, estrutura em camadas (Presentation, Domain e Data), Riverpod, planejamento em sprints, README e CHANGELOG |
| Leon Mendonça | Entidades do domínio, rascunho do diagrama de classes, banco local Hive com criptografia AES |

## Sprint 2 — Diário, privacidade e medidor (09/11 a 14/11)

**Objetivo:** entregar o diário de álcool e as proteções de privacidade, funcionando 100% offline.

**Entrega (14/11):** registro de drinques completo, Modo Camuflagem com troca instantânea, banco criptografado e medidor do fígado com dados reais, tudo sem internet.

| Integrante | Responsabilidade |
| --- | --- |
| Gabriel de Oliveira Alves | Histórico de exames, regras de cálculo dos relatórios semanais e mensais, estrutura da tela Relatório |
| Lizandra Bispo Nascimento | Calculadora do Modo Camuflagem com troca instantânea, código secreto, camuflagem automática em segundo plano, criptografia do banco ao ativar a camuflagem, teste de criptografia |
| Victor Castelo Branco | Medidor do fígado de 0 a 100% com dados reais, ligação da tela Início com exames e diário, telas de login e cadastro |
| Wilia Francisco da Silva | Revisão dos pull requests, fila offline, detecção de Wi-Fi, atualização dos protótipos com as telas novas, README e CHANGELOG |
| Leon Mendonça | Registro detalhado por tipo de bebida, conversão em drinque padrão, tela Drinks, registro rápido em até 3 toques, registro de alterações do diário |

## Sprint 3 — Nuvem, relatórios e metas (16/11 a 22/11)

**Objetivo:** integrar a nuvem com privacidade e entregar os recursos de acompanhamento.

**Entrega (22/11):** todas as funcionalidades da Unidade II implementadas, incluindo a sincronização com falha parcial demonstrável.

| Integrante | Responsabilidade |
| --- | --- |
| Gabriel de Oliveira Alves | Relatórios semanais e mensais, dashboard de evolução dos exames, exportação e compartilhamento do PDF |
| Lizandra Bispo Nascimento | Metas de redução, feedback das metas, notificações educativas personalizadas, lembretes |
| Victor Castelo Branco | Autenticação opcional mantendo o modo convidado, consentimento da sincronização, anonimização dos dados, evolução temporal do risco, cadastro e recuperação de senha |
| Wilia Francisco da Silva | Sincronização em lote com o Firestore, tratamento de falhas parciais e recuperação, regras de segurança, testes da sincronização e da anonimização, status da sincronização, README e CHANGELOG |
| Leon Mendonça | Ligação do diário e dos exames à fila de sincronização, modelagem do Firestore, mapeamento das classes Dart para o Firestore, exclusão dos dados locais |

## Sprint 4 — Estabilização e entrega (23/11 a 27/11)

**Objetivo:** corrigir erros, completar a documentação e preparar a apresentação. A partir de 23/11 não entram funcionalidades novas.

**Entrega (27/11):** app estável, testes passando, APK gerado, documentação atualizada e apresentação pronta.

| Integrante | Responsabilidade |
| --- | --- |
| Gabriel de Oliveira Alves | Correções de Exames, Relatório e PDF, registro de uso de IA, atualização das justificativas, modo consulta |
| Lizandra Bispo Nascimento | Correções da camuflagem, metas e notificações, fluxo de navegação real, slides da apresentação |
| Victor Castelo Branco | Correções da tela Início, do login e da anonimização, orientação "Quando procurar o médico", vídeo de demonstração |
| Wilia Francisco da Silva | `flutter analyze` e `flutter test` sem erros, APK de release, conferência do app com o protótipo de alta fidelidade, README e CHANGELOG finais, revisão de acessibilidade |
| Leon Mendonça | Correções do Drinks e do banco local, versão final do diagrama de classes, atualização da arquitetura e dos requisitos |

Todos: teste em Android 8.0, ensaio da apresentação e entrega.

## Acompanhamento

- **Checkpoint semanal:** no último dia de cada sprint, cada integrante apresenta o que fez e os próprios commits.
- **README e CHANGELOG:** atualizados ao fim de cada sprint, com as responsabilidades e o que foi entregue.
- **Fluxo de trabalho:** cada tarefa é feita em uma branch própria criada a partir da `main` e entra na `main` por pull request, depois de revisada e de passar em `flutter analyze` e `flutter test`.
- **Commits:** cada integrante faz commit apenas do que desenvolveu, com a própria conta do GitHub.
