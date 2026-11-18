# Fluxo de navegação real — HepatoCheck (A9)

Revisão de 18/11/2026, sobre a `main` no commit `4ad37eb` e as correções desta branch. Este documento descreve as telas implementadas, não o protótipo. A entrega solicitada é apenas documental; não inclui slides.

## Entrada e abas

O app inicia no modo convidado, na aba **Início**. Se a camuflagem estiver ativa, a calculadora aparece antes das abas. Login é opcional; sincronização exige conta, consentimento e Wi-Fi.

```mermaid
flowchart TD
    Abrir["Abrir aplicativo"] --> Ativa{"Camuflagem ativa?"}
    Ativa -->|Sim| Calculadora["Calculadora discreta"]
    Ativa -->|Não| Inicio["Início"]
    Calculadora -->|Código válido| Drinks["Drinks"]
    Calculadora -->|Código inválido ou conta comum| Calculadora
    Abas["Barra inferior: trocar de aba"] --> Inicio
    Abas --> Relatorio["Relatório"]
    Abas --> Drinks
    Abas --> Exames["Exames"]
    Abas --> Perfil["Perfil"]
    Inicio -->|Botão +| Rapido["Modal de registro rápido"]
    Rapido -->|Salvar ou fechar| Inicio
    Inicio -->|Ícone de conta| Conta{"Há sessão?"}
    Perfil -->|Entrar ou criar conta / Conta| Conta
    Conta -->|Não| Login["Entrar"]
    Conta -->|Sim| ContaAtiva["Conta autenticada"]
    Drinks -->|Bandeira no topo| Metas["Metas de redução"]
    Perfil -->|Metas de redução| Metas
    Relatorio -->|Metas / Gerenciar| Metas
    Metas -->|Criar meta ou editar| FormMeta["Formulário da meta"]
    FormMeta -->|Salvar ou cancelar| Metas
    Metas -->|Excluir| ConfirmaMeta["Confirmar exclusão"]
    ConfirmaMeta --> Metas
    Perfil -->|Notificações e lembretes| Avisos["Preferências e mensagens locais"]
    Perfil -->|Sincronização| Sync["Status da sincronização"]
    Perfil -->|Modo Camuflagem| Codigo["Criar código secreto"]
    Codigo -->|Ativar com 4 a 8 dígitos| Calculadora
    Perfil -->|Apagar dados locais| Excluir["Confirmação de exclusão local"]
    ContaAtiva -->|Sincronização na nuvem| Consent["Consentimento"]
    ContaAtiva -->|Sair| Convidado["Modo convidado e consentimento revogado"]
```

As abas usam índices 0 (Início), 1 (Relatório), 2 (Drinks), 3 (Exames) e 4 (Perfil). Trocar de aba substitui o conteúdo do shell. Telas de metas, preferências, conta e sincronização são rotas empilhadas; o botão Voltar retorna à origem.

## Autenticação e privacidade

```mermaid
flowchart TD
    Login["Entrar"] -->|Criar conta| Cadastro["Cadastro"]
    Login -->|Esqueci minha senha| Recuperar["Recuperação de senha"]
    Login -->|Continuar como convidado| Origem["Tela de origem"]
    Cadastro -->|Política de privacidade| Politica["Política de privacidade"]
    Login -->|Sucesso| Raiz["Retornar à navegação principal"]
    Cadastro -->|Sucesso| Raiz
    Raiz --> Autorizado{"Já autorizou sincronização?"}
    Autorizado -->|Não| Consentimento["Consentimento de sincronização"]
    Autorizado -->|Sim| Navegacao["App com sessão ativa"]
    Consentimento -->|Autorizar ou Agora não| Navegacao
    Consentimento -->|Ler política| Politica
    Recuperar -->|Enviar instruções| Confirmacao["Confirmação na própria tela"]
    Sensivel["Qualquer aba, rota ou diálogo sensível"] -->|App fica inativo e camuflagem está ativa| Bloqueio["Fechar rotas sobrepostas e mostrar calculadora"]
    Bloqueio -->|Código válido| Drinks["Drinks"]
```

Ao bloquear, rotas abertas (como Metas) e diálogos são fechados para a raiz. Ao desbloquear, o app volta a Drinks, sem reabrir a tela sensível anterior. A proteção de prévia no alternador de aplicativos usa o canal nativo Android. A calculadora não mostra nome, logo ou ícone do HepatoCheck.

## Ações dentro de cada tela

| Origem | Ação e destino real |
| --- | --- |
| Início | Exibe medidor, resumo do consumo e evolução do risco; `+` abre registro rápido. |
| Drinks | Formulário e histórico na própria aba; editar preenche o formulário; excluir abre confirmação; seletores de data/hora abrem diálogos. |
| Exames | Cadastro/cálculo e histórico na própria aba; editar preenche o formulário; excluir pede confirmação; data abre calendário. |
| Relatório | Semana/mês e anterior/próximo atualizam a própria tela; evolução e gráficos ficam nela; Gerenciar abre Metas. |
| Relatório → PDF | O cartão de exportação pede confirmação e abre a impressão/compartilhamento nativo; não existe uma aba PDF. |
| Metas | Lista de metas → criar/editar → formulário → salvar/cancelar → lista. Máximo de drinques: 0–100 por semana; dias sem consumo: 1–7. |
| Notificações | Preferências, horário, lembretes de exame e mensagens na mesma tela. A permissão e o agendamento fora do app são serviços nativos. |
| Perfil | Conta, metas, notificações, camuflagem, sincronização e exclusão local. |
| Sincronização | Contadores de pendências/falhas e envio manual. A tela não representa autorização automática de envio. |

## Capturas das telas implementadas

As imagens abaixo foram produzidas pelo teste `test/presentation/navigation_evidence_test.dart`, navegando pelo `AppNavigationShell` real e seus botões. São renderizações Flutter em viewport **390 × 844**, com PNG em escala 2, fonte Inter e Material Icons. Os repositórios são substituídos por dados fictícios em memória; o armazenamento das preferências é temporário e a proteção nativa é simulada. Não são fotografias de um aparelho Android, nem prova de entrega de notificações, login real no Firebase ou sincronização em produção. Barras do sistema e teclado nativo não fazem parte das capturas.

### Início, registro rápido e relatório

| Início | Registro rápido | Relatório |
| --- | --- | --- |
| <img src="imagens/navegacao/01-inicio.png" width="240" alt="Início com medidor e navegação inferior"> | <img src="imagens/navegacao/02-registro-rapido.png" width="240" alt="Modal de registro rápido aberto a partir do botão mais"> | <img src="imagens/navegacao/03-relatorio.png" width="240" alt="Relatório com filtro semanal e evolução dos exames"> |

### Drinks e metas

| Drinks | Metas | Criar meta |
| --- | --- | --- |
| <img src="imagens/navegacao/04-drinks.png" width="240" alt="Formulário de registro na aba Drinks"> | <img src="imagens/navegacao/05-metas.png" width="240" alt="Metas de redução acessadas pela bandeira em Drinks"> | <img src="imagens/navegacao/06-criar-meta.png" width="240" alt="Formulário de criação de meta"> |

### Exames e preferências

| Exames | Perfil | Notificações e lembretes |
| --- | --- | --- |
| <img src="imagens/navegacao/07-exames.png" width="240" alt="Cadastro de exames"> | <img src="imagens/navegacao/08-perfil.png" width="240" alt="Perfil e seus acessos"> | <img src="imagens/navegacao/09-notificacoes.png" width="240" alt="Preferências de mensagens e lembretes"> |

### Acesso opcional à conta

| Entrar | Cadastro | Recuperar senha |
| --- | --- | --- |
| <img src="imagens/navegacao/10-login.png" width="240" alt="Tela de login opcional"> | <img src="imagens/navegacao/11-cadastro.png" width="240" alt="Tela de criação de conta"> | <img src="imagens/navegacao/12-recuperacao.png" width="240" alt="Tela de recuperação de senha"> |

### Sincronização, filtro visual e camuflagem

| Sincronização | Risco alto | Calculadora discreta |
| --- | --- | --- |
| <img src="imagens/navegacao/13-sincronizacao.png" width="240" alt="Status da sincronização sem pendências fictícias"> | <img src="imagens/navegacao/14-risco-alto.png" width="240" alt="Medidor com filtro amarelo ilustrativo e selo vermelho preservado"> | <img src="imagens/navegacao/15-camuflagem.png" width="240" alt="Calculadora sem identificação do aplicativo"> |

O filtro inspirado na icterícia aparece **somente no medidor quando `health.risk == RiskLevel.high`**. O selo de classificação continua vermelho; a interface de leitura e a calculadora não recebem o filtro. A explicação na tela distingue o efeito ilustrativo da presença real de icterícia. A classificação e o cálculo do FIB-4 não foram alterados.

## Correções e evidências da revisão (tarefa 56)

| Área | Verificação ou correção | Evidência automatizada |
| --- | --- | --- |
| Camuflagem | Corrigido bloqueio com rota sensível aberta; rotas são fechadas antes de mostrar a calculadora. Código válido retorna a Drinks. | `navigation_evidence_test.dart` simula inatividade com Metas aberta e confere bloqueio/desbloqueio. |
| Calculadora | Corrigida porcentagem relativa dentro de grupo ainda aberto; preservadas precedência, multiplicação implícita e parênteses automáticos. | `calculator_engine_test.dart`, incluindo `2 × (200 + 10%) = 440`. |
| Metas | Conferidos limites 0–100 drinques e 1–7 dias, validação do formulário, persistência e integração com fila de sincronização da main atual. | `goals_screen_test.dart`, `hive_goal_repository_test.dart` e testes de avaliação das metas. |
| Notificações | Conferidos conteúdo discreto com camuflagem, cancelamento quando desligadas, permissão negada, horário local e feedback emitido uma vez por situação. | `local_follow_up_notifications_test.dart` usa canais nativos simulados e relógio fixo para não depender da data de execução; `follow_up_screen_test.dart` cobre preferências. |
| Risco alto | Filtro ilustrativo amarelo restrito ao medidor, com selo de risco vermelho preservado. Sem filtro nas demais faixas ou sem exame. | `risk_card_filter_test.dart` e captura 14. |

### Resultado da validação

Em 18/11/2026, `flutter analyze` terminou sem problemas e `flutter test` aprovou **325 testes**. A geração das capturas também passou pelos testes de navegação. A execução em aparelho Android permanece uma etapa de aceitação manual.

### Reproduzir as verificações

Na raiz do repositório:

```powershell
cd hepatocheck_app
flutter analyze
flutter test
flutter test test/presentation/navigation_evidence_test.dart --dart-define=CAPTURE_NAVIGATION=true
```

O último comando regenera os 15 PNGs em `docs/imagens/navegacao/`. Sem a opção `CAPTURE_NAVIGATION`, os testes verificam a navegação sem regravar as imagens.

### Congelamento em 23/11/2026

Conforme a Sprint 4 de [sprints.md](sprints.md), a partir de **23/11/2026 não entram novas funcionalidades**. A revisão e a implementação deste filtro previsto nos requisitos são preparadas antes dessa data. De 23 a 27/11, aceitar somente correções, testes, documentação e preparação da entrega. Novas ideias ficam para uma versão posterior.

Antes da entrega, ainda é necessário validar em aparelho Android: retorno do segundo plano e prévia de aplicativos recentes, fonte do sistema ampliada, permissão e entrega dos lembretes, login/sincronização reais com consentimento e geração/compartilhamento do PDF. Os testes de widgets e canais simulados não substituem essa conferência.

## Fontes no repositório

- [Navegação principal e Perfil](../hepatocheck_app/lib/app.dart)
- [Fluxo após autenticação](../hepatocheck_app/lib/presentation/screens/auth/auth_flow.dart)
- [Metas](../hepatocheck_app/lib/presentation/screens/goals_screen.dart)
- [Notificações locais](../hepatocheck_app/lib/data/notifications/local_follow_up_notifications.dart)
- [Relatório](../hepatocheck_app/lib/presentation/screens/report_screen.dart)
- [Cartão de risco e filtro](../hepatocheck_app/lib/presentation/widgets/risk_card.dart)
- [Teste e gerador das capturas](../hepatocheck_app/test/presentation/navigation_evidence_test.dart)
