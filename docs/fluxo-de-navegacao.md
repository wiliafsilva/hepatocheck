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
    Inicio -->|Cartão de risco| Orientacao["Painel de orientação médica"]
    Relatorio -->|Seção de risco| Orientacao
    Orientacao -->|Fechar| Origem["Tela de origem"]
    Relatorio -->|Modo consulta| Consulta["Modo consulta em tela cheia"]
    Consulta -->|Fechar| Relatorio
    Drinks -->|Bandeira no topo| Metas["Metas de redução"]
    Relatorio -->|Gerenciar metas| Metas
    Perfil -->|Status do envio| Sync["Status da sincronização"]
    Perfil -->|Ativar Modo camuflagem| Codigo["Diálogo: criar código secreto"]
    Codigo -->|Confirmar código de 4 a 8 dígitos| Calculadora
    Codigo -->|Cancelar| Perfil
    Perfil -->|Política de privacidade| Politica["Política de privacidade"]
    Perfil -->|Metas de redução| Metas
    Perfil -->|Notificações e lembretes| Avisos["Notificações e lembretes"]
    Perfil -->|Exportar resumo em PDF| ResumoPdf["Resumo em PDF"]
    Perfil -->|Apagar todos os dados| Apagar["Aviso: Apagar todos os dados?"]
    Apagar -->|Apagar tudo ou Cancelar| Perfil
```

Na primeira abertura do Início, uma animação curta (cerca de 2 segundos) mostra a silhueta do corpo, a linha do "scan" e o fígado acendendo na cor do risco antes de o cartão aparecer. Ela não se repete ao voltar para a aba, é pulada com um toque na tela e não roda quando o Android está com "remover animações".

O Perfil é organizado em cartões por assunto, nesta ordem: cartão do usuário; **Privacidade e sincronização** (Sincronização na nuvem, só com conta; Status do envio; Modo camuflagem; Política de privacidade); **Acompanhamento** (Metas de redução; Notificações e lembretes); **Relatório** (Exportar resumo em PDF); **Conta**, só com conta (Alterar senha; Sair da conta; Apagar a conta); e, separado no fim, **Apagar todos os dados**.

A barra inferior troca o conteúdo da tela principal. Seus índices são: **0 — Início; 1 — Relatório; 2 — Drinks; 3 — Exames; 4 — Perfil**. Metas, notificações e sincronização são abertas sobre a tela de origem com `Navigator.push`; o botão Voltar retorna à tela anterior.

## 2. Conta, autenticação e consentimento

O ícone de conta do Início abre **Entrar**, no modo convidado, ou **Conta**, quando já existe sessão. No Perfil, o cartão do usuário abre **Entrar** só no modo convidado; com a conta conectada ele apenas mostra o e-mail, porque sincronização, alterar senha, sair e apagar a conta já estão no próprio Perfil. No cadastro, o botão **Criar conta** só fica ativo depois de marcar "Li e aceito a Política de Privacidade". Antes de criar a conta e antes de enviar o e-mail de recuperação de senha, aparece o aviso **"Seus dados ficam trancados com a sua senha"**, que só deixa continuar depois de marcar "Entendi".

Após o login, o app tenta restaurar automaticamente os dados da conta. A mensagem com a contagem aparece quando há itens restaurados. A falha na restauração e a redefinição da chave do cofre após a recuperação da senha têm mensagens próprias. Após login ou cadastro bem-sucedido, o app fecha as rotas até a navegação principal e solicita consentimento se ele ainda não foi concedido.

```mermaid
flowchart TD
    Inicio["Início: ícone de conta"] --> Sessao{"Existe sessão?"}
    Sessao -->|Não| Login["Entrar"]
    Sessao -->|Sim| Conta["Conta"]
    Perfil["Perfil: cartão do usuário"] -->|Modo convidado| Login

    Login -->|Criar conta| Cadastro["Cadastro"]
    Login -->|Esqueci minha senha| Recuperar["Recuperação de senha"]
    Login -->|Continuar como convidado| Origem["Retornar à tela anterior"]
    Cadastro -->|Link no aceite| Politica["Política de privacidade"]
    Cadastro -->|Já tem conta? Entrar| Login
    Cadastro -->|Continuar como Convidado| Raiz
    Cadastro -->|Aceite marcado e Criar conta| AvisoCadastro["Aviso da senha"]
    AvisoCadastro -->|Cancelar| Cadastro
    AvisoCadastro -->|Entendi e Continuar| CriarConta["Conta e cofre criados"]
    Recuperar -->|Enviar link| AvisoRecuperar["Aviso da senha"]
    AvisoRecuperar -->|Cancelar| Recuperar
    AvisoRecuperar -->|Entendi e Continuar| Mensagem["Mensagem na própria tela"]
    Recuperar -->|Voltar| Login

    Login -->|Autenticação bem-sucedida| Restaurar["Tentativa de restauração automática"]
    Restaurar --> Raiz["Navegação principal"]
    CriarConta --> Raiz
    Raiz --> Autorizado{"Consentimento já concedido?"}
    Autorizado -->|Não| Consentimento["Consentimento de sincronização"]
    Autorizado -->|Sim| App["Continuar no aplicativo"]
    Consentimento -->|Autorizar ou Agora não| App
    Consentimento -->|Ler política| Politica
    Consentimento -->|Revogar autorização já concedida| Consentimento
    Conta -->|Sincronização na nuvem| Consentimento
    Perfil -->|Sincronização na nuvem, com conta| Consentimento
    Conta -->|Alterar senha| Alterar["Alterar senha"]
    Perfil -->|Alterar senha, com conta| Alterar
    Alterar -->|Não lembro minha senha atual| Recuperar
    Alterar -->|Salvar nova senha com sucesso| OrigemSenha["Conta ou Perfil, conforme a origem"]
    Conta -->|Sair da conta| AvisoSair["Aviso: Sair da conta?"]
    Perfil -->|Sair da conta, com conta| AvisoSair
    AvisoSair -->|Sair| Sair["Revogar consentimento, esquecer a chave e voltar à navegação principal"]
    AvisoSair -->|Cancelar| OrigemSair["Conta ou Perfil, conforme a origem"]
    Perfil -->|Apagar a conta, com conta| AvisoApagar["Aviso: Apagar a conta? com a senha"]
    AvisoApagar -->|Exclusão concluída| Apagada["Conta, nuvem e aparelho apagados; modo convidado"]
    AvisoApagar -->|Falha ao excluir a conta após apagar os dados| ContaMantida["Perfil com a conta ainda ativa e aviso"]
    AvisoApagar -->|Senha errada ou sem internet| Perfil
```

Recusar o consentimento mantém o uso local. Autorizar o envio fecha a tela de consentimento e mantém a aba selecionada. Se o envio já estiver autorizado, a própria tela permite revogar a autorização sem sair da conta. A revogação interrompe novos envios e preserva os dados que já estão na nuvem. Ao sair da conta, depois de confirmar no aviso, o app revoga o consentimento e preserva os dados locais.

Alterar senha confirma a senha atual e tenta proteger a chave da nuvem com a nova senha antes de atualizar a autenticação. Se houver incompatibilidade com a chave do cofre, o código permite atualizar a senha da conta. Apagar a conta pede a senha e começa pelos dados da nuvem, depois apaga os dados locais e por fim exclui a conta. Se essa última etapa falhar, o Perfil informa que os dados foram apagados e a conta continua ativa. Para uma conta conectada, **Apagar todos os dados** só inicia a exclusão local depois que a exclusão da cópia na nuvem termina com sucesso. A política de privacidade é uma rota de leitura que retorna à sua origem pelo botão Voltar.

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

    Relatorio["Relatório"] -->|Visualizar / salvar| PDF["Visualização ou impressão do sistema"]
    Relatorio -->|Compartilhar| Aviso["Confirmação de compartilhamento"]
    ResumoPdf["Perfil: Resumo em PDF"] -->|Visualizar / salvar| PDF
    ResumoPdf -->|Compartilhar| Aviso
    Aviso -->|Confirmar| Compartilhar["Compartilhamento do sistema"]
    Aviso -->|Cancelar| OrigemPdf["Relatório ou Resumo em PDF, conforme a origem"]
```

| Tela | Ações dentro da tela e destinos |
| --- | --- |
| Início | Corpo ao fundo com o fígado na cor do risco, cartão com o medidor, resumo do consumo e evolução do risco. O botão `+` abre o modal de registro rápido; salvar fecha o modal e mostra a confirmação. |
| Drinks | Registro, consumo por tipo (Semana, Mês ou Ano, em drinques padrão) e histórico ficam na própria aba. Editar preenche o formulário; excluir abre confirmação. Data e hora usam seletores em diálogos. |
| Exames | Formulário, cálculo, resultado e histórico ficam na própria aba. Editar preenche o formulário; excluir abre confirmação; a data abre um calendário. Se a idade não combinar com a de outro exame, o aviso "Confira a idade" oferece Corrigir ou Salvar assim mesmo. |
| Relatório | Semana/mês e anterior/próximo atualizam os dados na própria aba. A seção de risco abre o painel de orientação médica. **Modo consulta** abre o resumo para o profissional de saúde em tela cheia e volta ao Relatório ao fechar. |
| Metas de redução | Criar e editar abrem `GoalFormScreen`. Salvar retorna à lista; dados inválidos mantêm o formulário aberto. Excluir pede confirmação. |
| Notificações e lembretes | Preferências, mensagens e salvamento ficam na mesma tela. Data do exame e horário abrem seletores. A permissão de notificações depende do sistema operacional. |
| Sincronização | Contadores de pendências/falhas e resultado do envio ficam na mesma tela. O envio depende das condições de autenticação, consentimento e conexão. |
| Perfil | Cartões por assunto: usuário, privacidade e sincronização, acompanhamento, relatório, conta e apagar todos os dados. Sair, apagar a conta e apagar os dados pedem confirmação. |
| Alterar senha | Senha atual, nova senha e confirmação, com a lista do que a nova senha precisa ter. "Não lembro minha senha atual" abre a recuperação. Ao salvar, volta para a tela anterior. |
| PDF | A visualização e o compartilhamento usam a interface do sistema; não existe uma aba PDF. O resumo abre pelo Relatório ou pelo atalho do Perfil. Apenas o compartilhamento pede confirmação prévia no aplicativo. |

## 4. Camuflagem e retorno ao aplicativo

- Ativar o Modo Camuflagem no Perfil abre o diálogo de criação do código secreto. Após a confirmação, o shell passa a mostrar a calculadora.
- Digitar um código válido na calculadora desbloqueia o diário e seleciona Drinks (índice 2).
- Com a camuflagem ativa, os estados de ciclo de vida `inactive`, `paused` e `hidden` solicitam o bloqueio; a calculadora substitui o conteúdo do shell.
- Durante a visualização ou o compartilhamento do PDF pela interface do sistema, o bloqueio pode ser adiado. Ao encerrar essa operação, o app aplica o bloqueio pendente se ainda estiver fora do primeiro plano.
- Desativar a opção no Perfil desliga a camuflagem.

`_lockForPrivacy` bloqueia o controlador e mantém a pilha de navegação. O que aparece ao voltar para o app com uma rota ou um diálogo aberto, como Metas, depende de verificação em aparelho.

## 5. Fontes consultadas

- [Navegação principal](../hepatocheck_app/lib/app.dart)
- [Perfil e Resumo em PDF](../hepatocheck_app/lib/presentation/screens/profile_screen.dart)
- [Início](../hepatocheck_app/lib/presentation/screens/home_screen.dart)
- [Drinks](../hepatocheck_app/lib/presentation/screens/drinks_screen.dart)
- [Exames](../hepatocheck_app/lib/presentation/screens/exams_screen.dart)
- [Relatório](../hepatocheck_app/lib/presentation/screens/report_screen.dart)
- [Modo consulta](../hepatocheck_app/lib/presentation/screens/consultation_screen.dart)
- [Painel de orientação médica](../hepatocheck_app/lib/presentation/screens/medical_guidance_sheet.dart)
- [Metas e formulário](../hepatocheck_app/lib/presentation/screens/goals_screen.dart)
- [Notificações e lembretes](../hepatocheck_app/lib/presentation/screens/follow_up_screen.dart)
- [Abertura da conta](../hepatocheck_app/lib/presentation/screens/auth/account_screen.dart)
- [Alterar senha](../hepatocheck_app/lib/presentation/screens/auth/change_password_screen.dart)
- [Sessão da conta](../hepatocheck_app/lib/presentation/providers/account_session.dart)
- [Apagar a conta](../hepatocheck_app/lib/presentation/widgets/delete_account_tile.dart)
- [Fluxo após login e cadastro](../hepatocheck_app/lib/presentation/screens/auth/auth_flow.dart)
- [Consentimento](../hepatocheck_app/lib/presentation/screens/sync_consent_screen.dart)
- [Exportação do PDF](../hepatocheck_app/lib/presentation/widgets/export_summary_card.dart)

## 6. Capturas de tela

Pendente para uma próxima revisão. Esta versão contém apenas os diagramas e a descrição da navegação, sem imagens.
