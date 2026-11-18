# Fluxo de navegação real — HepatoCheck (A9)

Este documento descreve a navegação implementada no código do aplicativo. A revisão foi feita pela leitura das rotas e ações das telas; não representa uma validação em aparelho. As capturas de tela serão incluídas posteriormente.

## 1. Entrada e navegação principal

O aplicativo inicia na aba **Início**, sem exigir login. Se o Modo Camuflagem estiver ativo, a navegação principal é substituída pela calculadora. O código secreto válido abre a aba **Drinks**.

```mermaid
flowchart TD
    Abrir["Abrir aplicativo"] --> Camuflagem{"Camuflagem ativa?"}
    Camuflagem -->|Sim| Calculadora["Calculadora discreta"]
    Camuflagem -->|Não| Inicio["Início"]
    Calculadora -->|Código válido| Drinks["Drinks"]
    Calculadora -->|Conta comum ou código inválido| Calculadora

    Barra["Barra de navegação inferior"] --> Inicio
    Barra --> Relatorio["Relatório"]
    Barra --> Drinks
    Barra --> Exames["Exames"]
    Barra --> Perfil["Perfil"]

    Inicio -->|Botão +| Rapido["Modal de registro rápido"]
    Rapido -->|Registrar ou fechar| Inicio
    Drinks -->|Bandeira no topo| Metas["Metas de redução"]
    Relatorio -->|Gerenciar metas| Metas
    Perfil -->|Metas de redução| Metas
    Perfil -->|Notificações e lembretes| Avisos["Notificações e lembretes"]
    Perfil -->|Sincronização| Sync["Status da sincronização"]
    Perfil -->|Ativar Modo Camuflagem| Codigo["Diálogo: criar código secreto"]
    Codigo -->|Confirmar código de 4 a 8 dígitos| Calculadora
    Codigo -->|Cancelar| Perfil
    Perfil -->|Apagar todos os dados| Apagar["Diálogo de confirmação"]
    Apagar -->|Confirmar ou cancelar| Perfil
```

A barra inferior troca o conteúdo da tela principal. Seus índices são: **0 — Início; 1 — Relatório; 2 — Drinks; 3 — Exames; 4 — Perfil**. Metas, notificações e sincronização são abertas sobre a tela de origem com `Navigator.push`; o botão Voltar retorna à tela anterior.

## 2. Conta, autenticação e consentimento

O ícone de conta do Início e o item de conta do Perfil abrem **Entrar**, no modo convidado, ou **Conta**, quando já existe sessão. Após login ou cadastro bem-sucedido, o app fecha as rotas até a navegação principal e solicita consentimento se ele ainda não foi concedido.

```mermaid
flowchart TD
    Inicio["Início: ícone de conta"] --> Sessao{"Existe sessão?"}
    Perfil["Perfil: item de conta"] --> Sessao
    Sessao -->|Não| Login["Entrar"]
    Sessao -->|Sim| Conta["Conta"]

    Login -->|Criar conta| Cadastro["Cadastro"]
    Login -->|Esqueci minha senha| Recuperar["Recuperação de senha"]
    Login -->|Continuar como convidado| Origem["Retornar à tela anterior"]
    Cadastro -->|Política de privacidade| Politica["Política de privacidade"]
    Cadastro -->|Voltar| Login
    Recuperar -->|Enviar instruções| Mensagem["Mensagem na própria tela"]
    Recuperar -->|Voltar| Login

    Login -->|Autenticação bem-sucedida| Raiz["Navegação principal"]
    Cadastro -->|Cadastro bem-sucedido| Raiz
    Raiz --> Autorizado{"Consentimento já concedido?"}
    Autorizado -->|Não| Consentimento["Consentimento de sincronização"]
    Autorizado -->|Sim| App["Continuar no aplicativo"]
    Consentimento -->|Autorizar ou Agora não| App
    Consentimento -->|Ler política| Politica
    Conta -->|Sincronização na nuvem| Consentimento
    Perfil -->|Consentimento, quando autenticado| Consentimento
    Conta -->|Sair da conta| Sair["Revogar consentimento e voltar à navegação principal"]
```

Recusar o consentimento mantém o uso local. Autorizar o envio não troca de aba: fecha a tela de consentimento. Ao sair da conta, o app revoga o consentimento e preserva os dados locais. A política de privacidade é uma rota de leitura que retorna à sua origem pelo botão Voltar.

## 3. Metas, formulários e ações internas

```mermaid
flowchart TD
    Metas["Metas de redução"] -->|Criar meta| Nova["Formulário de nova meta"]
    Metas -->|Editar| Editar["Formulário com a meta existente"]
    Nova -->|Salvar com dados válidos ou cancelar| Metas
    Editar -->|Salvar com dados válidos ou cancelar| Metas
    Nova -->|Dados inválidos| Nova
    Editar -->|Dados inválidos| Editar
    Metas -->|Excluir| Confirmar["Confirmar exclusão"]
    Confirmar -->|Confirmar ou cancelar| Metas

    Relatorio["Relatório"] -->|Visualizar PDF| PDF["Visualização ou impressão do sistema"]
    Relatorio -->|Compartilhar PDF| Aviso["Confirmação de compartilhamento"]
    Aviso -->|Confirmar| Compartilhar["Compartilhamento do sistema"]
    Aviso -->|Cancelar| Relatorio
```

| Tela | Ações dentro da tela e destinos |
| --- | --- |
| Início | Medidor, resumo do consumo e evolução do risco. O botão `+` abre o modal de registro rápido; salvar fecha o modal e mostra a confirmação. |
| Drinks | Registro e histórico ficam na própria aba. Editar preenche o formulário; excluir abre confirmação. Data e hora usam seletores em diálogos. |
| Exames | Formulário, cálculo, resultado e histórico ficam na própria aba. Editar preenche o formulário; excluir abre confirmação; a data abre um calendário. |
| Relatório | Semana/mês e anterior/próximo atualizam a mesma tela. Gráficos, resumo do consumo, evolução dos exames e progresso das metas não são rotas separadas. |
| Metas de redução | Criar e editar abrem `GoalFormScreen`. Salvar retorna à lista; dados inválidos mantêm o formulário aberto. Excluir pede confirmação. |
| Notificações e lembretes | Preferências, mensagens e salvamento ficam na mesma tela. Data do exame e horário abrem seletores. A permissão de notificações depende do sistema operacional. |
| Sincronização | Contadores de pendências/falhas e resultado do envio ficam na mesma tela. O envio depende das condições de autenticação, consentimento e conexão. |
| Perfil | Reúne os acessos à conta, consentimento quando autenticado, metas, notificações, camuflagem, sincronização e exclusão local. |
| PDF | A visualização e o compartilhamento usam a interface do sistema; não existe uma aba PDF. Apenas o compartilhamento pede confirmação prévia no aplicativo. |

## 4. Camuflagem e retorno ao aplicativo

- Ativar o Modo Camuflagem no Perfil abre o diálogo de criação do código secreto. Após a confirmação, o shell passa a mostrar a calculadora.
- Digitar um código válido na calculadora desbloqueia o diário e seleciona Drinks (índice 2).
- Com a camuflagem ativa, os estados de ciclo de vida `inactive`, `paused` e `hidden` solicitam o bloqueio; a calculadora substitui o conteúdo do shell.
- Desativar a opção no Perfil desliga a camuflagem.

**Observação sobre o código atual:** `_lockForPrivacy` bloqueia o controlador, mas não remove explicitamente as rotas ou diálogos empilhados sobre o shell. Por isso, o bloqueio com uma tela como Metas aberta precisa de verificação específica; este documento não afirma que essas rotas sejam fechadas automaticamente. Nenhuma alteração no comportamento do aplicativo foi feita nesta tarefa documental.

## 5. Fontes consultadas

- [Navegação principal e Perfil](../hepatocheck_app/lib/app.dart)
- [Início](../hepatocheck_app/lib/presentation/screens/home_screen.dart)
- [Drinks](../hepatocheck_app/lib/presentation/screens/drinks_screen.dart)
- [Exames](../hepatocheck_app/lib/presentation/screens/exams_screen.dart)
- [Relatório](../hepatocheck_app/lib/presentation/screens/report_screen.dart)
- [Metas e formulário](../hepatocheck_app/lib/presentation/screens/goals_screen.dart)
- [Notificações e lembretes](../hepatocheck_app/lib/presentation/screens/follow_up_screen.dart)
- [Abertura da conta](../hepatocheck_app/lib/presentation/screens/auth/account_screen.dart)
- [Fluxo após login e cadastro](../hepatocheck_app/lib/presentation/screens/auth/auth_flow.dart)
- [Consentimento](../hepatocheck_app/lib/presentation/screens/sync_consent_screen.dart)
- [Exportação do PDF](../hepatocheck_app/lib/presentation/widgets/export_summary_card.dart)

## 6. Capturas de tela

Pendente para uma próxima revisão. Esta versão contém apenas os diagramas e a descrição da navegação, sem imagens.
