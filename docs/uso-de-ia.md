# Registro do uso de IA

Este documento registra como o grupo usou inteligência artificial no desenvolvimento do HepatoCheck na Unidade II:

- os pedidos que funcionaram;
- os erros que a IA  ometeu e como cada um foi resolvido;
- a justificativa das bibliotecas do aplicativo.

## 1. Como a IA foi usada

A ferramenta usada foi o **Claude Code**, um assistente de programação que roda no terminal e lê e edita os arquivos do projeto. Ele foi usado para:

- planejar as tarefas de cada semana a partir dos documentos da Unidade I;
- escrever e corrigir código Dart e Flutter e os testes automatizados;
- revisar o código à procura de erros;
- atualizar a documentação.

O grupo combinou regras para que a IA ajudasse sem tirar a autoria de ninguém:

| Regra | Motivo |
| --- | --- |
| A IA não faz commit, não abre pull request e não roda comandos do Git que alterem o repositório | Cada integrante faz os próprios commits com a própria conta, o que vale nota individual |
| Cada integrante trabalha em uma branch própria por semana, e o pull request é revisado antes de entrar na `main` | O código gerado passa por uma pessoa antes de chegar ao app |
| Sem comentários no código | Regra do grupo; o código precisa se explicar pelos nomes |
| Toda mudança termina com `flutter analyze` e `flutter test` | O que a IA escreve só é aceito se compila e passa nos testes |
| Antes de editar, a IA lê o código existente e apresenta um plano | Evita reescrever o que já funciona e mexer na parte de outro integrante sem combinar |

## 2. Pedidos que funcionaram

Os pedidos que deram melhor resultado tinham três coisas: a tarefa do plano com o número, o arquivo ou a tela envolvida e a regra de negócio escrita por extenso. Pedidos vagos, como "melhora o relatório", geravam mudanças grandes demais e foram evitados.

### Gabriel de Oliveira Alves

| Semana | Pedido (resumo) | Resultado |
| --- | --- | --- |
| 1 | Calcular o FIB-4 no domínio com a fórmula `(Idade × TGO) / (Plaquetas × √TGP)`, recusar campos vazios, zero, negativos e valores fora da faixa fisiológica, e avisar quando a idade estiver fora de 35 a 65 anos | `CalculateFib4`, `ValidateExamInput` e os testes 1 e 2 |
| 1 | Classificar o risco em verde, amarelo e vermelho. Como nenhum documento dizia como o consumo entra na conta, a IA perguntou, e a regra escolhida foi: a faixa vem do FIB-4 e sobe um nível quando o consumo da semana passa da meta do usuário | `ClassifyRisk`, com a decisão registrada antes de programar |
| 2 | Montar as regras dos relatórios semanais e mensais no domínio e a tela Relatório com filtro de período | `BuildConsumptionReport`, `ReportPeriod` e a tela Relatório |
| 3 | Comparar o período em andamento de forma justa com o anterior, mostrando um aviso na tela | Comparação pelos mesmos dias, com o aviso abaixo dos cartões |
| 3 | Criar o dashboard de exames na aba Relatório e exportar o resumo em PDF, com confirmação antes de compartilhar | Dashboard com `fl_chart` e PDF com `pdf` e `printing` |
| 4 | "Corrigir os erros de Exames, Relatório e PDF, registro de uso de IA com a justificativa das bibliotecas, atualizar justificativas.md e modo consulta para o profissional de saúde" | Revisão das três áreas com a lista de erros abaixo, modo consulta seguindo o protótipo de alta fidelidade e esta documentação |

### Wilia Francisco da Silva

| Semana | Pedido (resumo) | Resultado |
| --- | --- | --- |
| 1 | Montar a estrutura do projeto em camadas (Presentation, Domain e Data) com Riverpod, as dependências e o planejamento em sprints a partir dos documentos da Unidade I | Pastas e providers do projeto, `sprints.md` e o fluxo de branches e pull requests do grupo |
| 2 | Criar a fila offline de sincronização e a detecção de Wi-Fi, guardando cada criação, edição e exclusão no aparelho mesmo sem internet | `SyncQueueRepository`, `WifiMonitor` e os testes da fila |
| 3 | Enviar a fila em lote para o Firestore só com conta, consentimento e Wi-Fi, tratando a falha parcial ("5 enviados, 2 falharam"), anonimizando antes do envio e validando os campos nas regras do Firestore | `SyncPendingItems` com `WriteBatch`, tela de status da sincronização, `firestore.rules` e os testes 4 e 5 |
| 4 | "Monte os testes que devo fazer passo a passo, para testarmos tudo", com dados de um único paciente | Roteiro de teste no Android 8 e no Android 12, que encontrou os erros da tabela abaixo |
| 4 | Fazer os dados voltarem sozinhos ao entrar na conta em outro aparelho, sem perder a privacidade. A IA apresentou duas opções e a escolhida foi a B: parte legível anonimizada e parte selada com a chave trancada pela senha | Restauração automática (RF25), `CloudVault` com AES-GCM e PBKDF2, aviso da senha com "Entendi" e testes com dois aparelhos simulados |
| 4 | "Vamos começar pela tela de login, depois criar conta, esqueceu a senha e alterar a senha. Qualquer dúvida pergunte, não invente nada nem crie algo novo sem permissão" | Telas de conta no estilo do protótipo; a IA perguntou antes de cada desvio (nome, senha mínima, aceite da política, tela Alterar senha) |
| 4 | Comparar cada tela com o protótipo de alta fidelidade e só depois propor mudanças, separando o que é visual do que muda o funcionamento | Início com o corpo do protótipo e a animação de "scan", tipos de bebida com imagens, Perfil em cartões, PDF com a escala do FIB-4 e as decisões registradas em `justificativas.md` |
| 4 | "Verifique nas exigências de entrega e liste o que falta" | Tabela de pendências por integrante, comparando o repositório com o documento da avaliação e o estudo de caso |

Também funcionou pedir, antes de qualquer código, um plano com os arquivos que seriam alterados. No modo de planejamento, a IA só lê o projeto e devolve o plano para aprovação. Foi assim que surgiram as perguntas sobre o que pertencia à área de outro integrante, como a navegação do `app.dart` e a camuflagem.

### Lizandra Bispo Nascimento

| Semana | Pedido (resumo) | Resultado |
| --- | --- | --- |
| 1 | Montar a navegação inferior com Início, Relatório, Drinks, Exames e Perfil | Barra com cinco abas e troca de tela no `app.dart` |
| 2 | Criar o Modo Camuflagem com uma calculadora funcional, código secreto para voltar ao diário e bloqueio ao sair do primeiro plano | Calculadora, controlador de camuflagem e testes do código secreto e da tela |
| 3 | Permitir criar, editar, excluir e acompanhar metas de redução e configurar lembretes de exame e de registro | Telas de Metas e Notificações e lembretes, com testes de avaliação de metas e agendamento |
| 3 | Corrigir a precedência das operações e o uso de parênteses na calculadora, voltar à aba Drinks ao desbloquear e limitar as metas de consumo a 0–100 drinques | Calculadora e navegação ajustadas, com validação do limite no formulário e no repositório |
| 4 | Conferir o documento de navegação com o código atual sem editar o arquivo durante a revisão, e aplicar os ajustes depois da autorização | Diagramas atualizados com o Modo consulta e os destinos corretos após alterar a senha ou cancelar o compartilhamento do PDF |

### Victor Castelo Branco Brasileiro Pereira

| Semana | Pedido (resumo) | Resultado |
| --- | --- | --- |
| 1 | Configurar a fonte Inter com os níveis de texto e montar a estrutura da tela Início com o cartão de risco e o botão de registro rápido | Fonte Inter embutida no app, funcionando offline, com seis níveis de texto, tema escuro e tela Início com o cartão de risco e o botão `+`, ainda sem ação |
| 1 | Desenhar o layout do medidor do fígado de 0 a 100% e criar o diagrama de casos de uso | `LiverGauge` com valor fixo, ainda sem cálculo, e o diagrama de casos de uso em PDF |
| 2 | Calcular o medidor do fígado com dados reais, usando o exame mais recente e o consumo das últimas 4 semanas, e ligar a tela Início aos exames e ao diário | `CalculateLiverHealth`, com a base pelo FIB-4 e desconto de até 15 pontos pelo consumo acima do limite semanal, e tela Início com a cor do risco, com testes |
| 2 | Criar as telas de login e cadastro com validação de e-mail e senha, mantendo o modo convidado | Telas Entrar e Cadastro com `AuthValidators` e a opção de continuar como convidado, ainda sem autenticação, que entrou na semana 3 |
| 3 | Implementar a autenticação opcional com o Firebase mantendo o modo convidado, com cadastro, recuperação de senha e política de privacidade | `FirebaseAuthRepository` e telas de login, cadastro, recuperação de senha, conta e política de privacidade, com testes |
| 3 | Pedir consentimento antes de sincronizar, com opção de revogar, e anonimizar os dados antes do envio, com faixa etária no lugar da idade e datas sem horário | Tela de consentimento, `HiveSyncConsentRepository` e `AnonymizeSyncPayload`, com testes |
| 3 | Mostrar a evolução temporal do risco na tela Início | `BuildRiskEvolution` e `RiskEvolutionChart`, com testes |
| 4 | Corrigir os erros da tela Início, do login e da anonimização | O medidor passou a usar o exame cadastrado por último quando há dois na mesma data, o login passou a ignorar um segundo envio enquanto está entrando e datas inválidas deixaram de ir para a nuvem, com testes |
| 4 | Criar a orientação "Quando procurar o médico", aberta pelo selo de risco | `MedicalGuidanceSheet`, aberta pelo selo de risco no Início e no Relatório, com testes |
| 4 | Analisar se o diagrama de casos de uso atendia todas as funcionalidades do sistema e, caso não, gerar um atualizado | Diagrama refeito com as funcionalidades que faltavam, como restaurar os dados da nuvem, alterar a senha e apagar a conta, e com as relações corrigidas conforme o código |

## 3. Erros da IA e como foram resolvidos

### Gabriel de Oliveira Alves

| Erro | Como percebemos | Como foi resolvido |
| --- | --- | --- |
| A comparação do relatório da semana 3 usava janelas diferentes: no dia 30 de março, 30 dias do mês atual contra os 28 de fevereiro, e o dia de hoje pela metade contra o dia inteiro do período anterior | Revisão do código na semana 4, montando casos de mês curto e de manhã cedo | As duas janelas passaram a ter o mesmo tamanho e a ir até o mesmo horário. Testes para mês curto, mês longo e dia incompleto |
| A data "de hoje" era lida uma vez só. Com o app aberto na virada do dia, o risco da semana, o período do relatório e a data do PDF ficavam no dia anterior | Revisão do código: o provider do relógio nunca era recalculado | Novo `todayProvider`, que se atualiza à meia-noite e ao voltar ao app, e teste da virada do dia |
| Ao salvar um exame e falhar a fila de sincronização, tentar de novo criava um exame duplicado, porque cada tentativa gerava um ID novo | Revisão do repositório de exames: o exame era gravado antes da etapa que falhava | O formulário guarda o mesmo ID até salvar e a lista é recarregada mesmo com erro. Teste de tela que simula a falha |
| O FIB-4 1,296 aparecia como "1,30" e era classificado como verde, embora a legenda diga que 1,30 é amarelo | Comparação entre o valor mostrado e a regra das faixas | A classificação passou a usar o valor arredondado que aparece na tela |
| O gráfico e a legenda do dashboard usavam o corte de 1,30 mesmo para pessoas com 65 anos ou mais, cujo corte é 2,0 | Revisão do gráfico contra a regra do FIB-4 | Faixas, legenda e eixo do PDF passaram a usar o corte da idade do exame |
| Com o Modo Camuflagem ativo, abrir o compartilhamento do PDF bloqueava o app no meio da exportação | Revisão do ciclo de vida do app | O bloqueio espera o fim da exportação. Se o app continuar em segundo plano, ele bloqueia em seguida |
| Na semana 3, os cartões de resumo cortavam o texto com a fonte do celular ampliada | Teste de tela com fonte em 200% | Cartões com altura flexível e teste de fonte ampliada mantido na suíte |
| Na semana 4, ao formatar o código, a IA rodou `dart format` no projeto inteiro e alterou arquivos de outros integrantes | Conferência do `git status` antes de terminar | Os arquivos foram devolvidos ao conteúdo original e a formatação passou a ser feita só nos arquivos alterados |
| Ao atualizar `justificativas.md`, a IA descreveu a sincronização com espera crescente e divisão de lotes, como estava no plano, mas isso não existe no código | Conferência do texto com `sync_pending_items.dart` antes de entregar | O texto foi corrigido para descrever o que o código faz: lotes de até 20 e botão "Tentar de novo" |
| Os documentos da Unidade I falavam em SQLite, e a primeira versão do plano repetia isso | Decisão do grupo de usar Hive, que já tem AES | Arquitetura e justificativas atualizadas para o Hive |

### Wilia Francisco da Silva

| Erro | Como percebemos | Como foi resolvido |
| --- | --- | --- |
| A tela de Sincronização mostrava "0 aguardando" com o Wi-Fi desligado, embora o drinque estivesse na fila | Teste no emulador, desligando o Wi-Fi antes de registrar | A tela passou a recalcular os pendentes sempre que é aberta. Teste novo para esse caso |
| Os dados de teste sugeridos pela IA tinham idades incoerentes para um mesmo paciente (60 anos em março e 45 em junho) | Leitura do roteiro antes de testar | Os dados passaram a representar um único paciente. A ideia virou o aviso "Confira a idade" na tela Exames |
| Um teste falhava de vez em quando: ele conferia se o texto criptografado não tinha "47", mas o texto é aleatório e às vezes tem esses caracteres | Rodadas completas da suíte que falhavam sem mudança no código | O teste passou a decodificar os bytes e conferir que os dados não aparecem em texto claro |
| Na abertura do Início, o cartão aparecia antes da silhueta do corpo | Teste no emulador, que é lento para carregar os arquivos SVG | A figura passou a ser carregada antes de a animação começar, com limite de 3 segundos |
| Com risco alto, o aviso de icterícia empurrava o corpo e o cartão para baixo; ao virar sobreposição, ele esticava até o fim da tela | Simulação de exames ruins de propósito e imagem gerada no teste | Aviso por cima da tela, com botão para fechar, e coluna do texto com a altura do conteúdo |
| O selo dizia "Risco amarelo", mas o arco do medidor continuava verde | Simulação com consumo acima da meta | O arco passou a usar a mesma cor do selo. Teste confere a cor antes e depois |
| O cartão "Resultado" da tela Exames ficava preso no último exame salvo, mesmo não sendo o mais recente | Comparação entre a tela Exames, o Início e o Relatório | O cartão mostra sempre o exame mais recente, e o FIB-4 do exame salvo aparece na confirmação |
| O logo da tela de login ficou diferente do protótipo | Comparação lado a lado com o Figma | Logo redesenhado com o círculo tracejado, os anéis e a linha de pulso |
| A IA editou um documento da Unidade I quando isso ainda não estava liberado | Conferência do arquivo alterado | O original foi restaurado. Depois que a professora liberou, as mudanças foram feitas com permissão |
| A IA tentou rodar `git stash` sem pedir, contra a regra do grupo | O comando foi bloqueado antes de executar | Regra reforçada: a IA só passa os comandos do Git, e o integrante executa |
| A IA afirmou que "Sair da conta" pedia confirmação, mas o código saía direto | Conferência do código antes de aceitar a resposta | Correção registrada; depois, o aviso "Sair da conta?" foi criado a pedido |

### Lizandra Bispo Nascimento

| Erro | Como percebemos | Como foi resolvido |
| --- | --- | --- |
| O diagrama indicava que salvar a senha voltava sempre ao Perfil | A revisão mostrou que a tela Alterar senha pode ser aberta por Conta ou Perfil e fecha voltando à rota anterior | O diagrama passou a indicar o retorno à tela de origem |
| O fluxo do PDF indicava que cancelar o compartilhamento voltava sempre ao Relatório | A conferência do código mostrou que o mesmo diálogo também pode ser aberto pela tela Resumo em PDF do Perfil | O diagrama passou a mostrar as duas origens possíveis |
| A IA preencheu meu resumo, mas deixou meus pedidos e erros fora das tabelas do documento | Na leitura do arquivo, as seções 2 e 3 ainda continham apenas os exemplos já preenchidos | As duas seções ganharam tabelas com meus exemplos, e o registro individual passou a apontar para elas |

### Victor Castelo Branco Brasileiro Pereira

| Erro | Como percebemos | Como foi resolvido |
| --- | --- | --- |
| Na anonimização da semana 3, uma data em formato inválido seguia sem tratamento para o documento da nuvem, e podia levar um texto livre junto | Revisão do código na semana 4, com um texto no lugar da data | A data inválida deixou de entrar no documento, e uma idade sem número válido passou a ser ignorada. Testes para os dois casos |
| Entre dois exames da mesma data, o medidor do fígado dependia da ordem da lista para escolher qual usar | Revisão do cálculo na semana 4 | O desempate passou a ser pela data de cadastro, valendo o exame mais recente. Teste de tela |
| O login podia ser enviado duas vezes enquanto a entrada ainda estava em andamento | Revisão da tela: o botão era desativado, mas a função de envio, também chamada pelo teclado, não tinha proteção | A função passou a ignorar um novo envio enquanto está entrando. Teste com dois toques seguidos |
| O diagrama de casos de uso ligava o RF02 à validação das entradas e indicava que o diário abria com o código seguido de "=", o que o app não faz | Comparação do diagrama com os requisitos e com o código na semana 4 | O RF02 passou a indicar o aviso de idade, a relação passou a ser "código digitado" e as funções que faltavam foram incluídas |
| Na primeira versão do diagrama refeito, a linha entre o registro do drinque e o log de auditoria passava por trás de outro caso de uso e parecia sair dele | Revisão visual da prévia do PDF antes de entregar | Os casos de uso foram reposicionados e o PDF foi gerado novamente |

O que o grupo aprendeu: a IA erra mais em **casos de borda**, como virada do dia, meses de tamanhos diferentes, falha no meio de uma gravação e arredondamento. Ela também erra quando **descreve o código sem conferir**. Por isso os erros acima foram encontrados com testes e com a leitura do código, não confiando na resposta.

## 4. Justificativa das bibliotecas

Versões conforme o `pubspec.yaml` do aplicativo.

### Dependências do aplicativo

| Pacote | Versão | Para que serve | Por que este |
| --- | --- | --- | --- |
| `flutter_riverpod` | ^3.4.3 | Estado da interface e injeção das dependências | Menos código repetitivo que o Bloc. Permite testar as regras sem montar a tela e trocar repositórios por versões falsas nos testes |
| `hive_ce` e `hive_ce_flutter` | ^2.22.0 e ^2.5.0 | Banco local | Já traz criptografia AES-256 (`HiveAesCipher`), exigida para os registros e para a camuflagem, sem biblioteca extra. É a versão mantida pela comunidade do Hive |
| `flutter_secure_storage` | ^11.2.0 | Guarda a chave AES e as preferências da camuflagem | Usa o Keystore do Android, então a chave nunca fica no código nem no banco |
| `crypto` | ^3.0.7 | Hash SHA-256 do log de alterações e do código secreto | Pacote oficial do time do Dart, sem dependências nativas |
| `cryptography` e `cryptography_flutter` | ^2.9.0 e ^2.3.4 | Criptografia da cópia na nuvem | O `crypto` só faz hash. Este pacote traz AES-GCM, que cifra e detecta qualquer alteração nos dados, e PBKDF2, que deriva a chave da senha do usuário. Com isso, o Firestore guarda só dados cifrados. O `cryptography_flutter` faz essas operações usarem a criptografia nativa do Android, e as 200.000 iterações do PBKDF2 não travam a tela |
| `uuid` | ^4.6.0 | ID de cada registro | O ID aleatório não revela nome nem data e serve de ID do documento no Firestore, o que evita duplicatas ao reenviar |
| `firebase_core`, `firebase_auth` e `cloud_firestore` | ^5.1.0, ^7.0.1 e ^7.1.0 | Login opcional e cópia na nuvem | Exigidos pela disciplina. O `WriteBatch` do Firestore grava o lote inteiro ou nada |
| `connectivity_plus` | ^7.3.2 | Saber se a conexão é Wi-Fi | A sincronização só pode acontecer no Wi-Fi (RNF14) |
| `fl_chart` | ^1.3.1 | Gráficos do Início e do Relatório | Biblioteca leve, escrita só em Dart, sem código nativo, testada no Android 8. Faz os gráficos de linha e de barras com faixas de fundo e toque nos pontos. O medidor do fígado, que é o gráfico exigido pelo estudo de caso, é desenhado com `CustomPainter` em `liver_gauge.dart` |
| `flutter_svg` | ^2.5.0 | Imagens do corpo, do fígado e das bebidas | O Flutter não abre SVG sozinho. Em SVG, as imagens ficam nítidas em qualquer tamanho de tela, e a cor do fígado pode mudar conforme o risco |
| `pdf` | ^3.13.1 | Montar o resumo em PDF | Gera o PDF no próprio aparelho, sem servidor, e aceita a fonte Inter do app |
| `printing` | ^5.15.1 | Visualizar, salvar e compartilhar o PDF | Abre a visualização e o menu de compartilhar do Android, e baixa o arquivo na versão web |
| `flutter_local_notifications` | ^23.0.2 | Notificações educativas e lembretes | Notificações locais, sem servidor e sem internet |
| `timezone` e `flutter_timezone` | ^0.11.2 e ^5.1.1 | Horário certo dos lembretes | Os agendamentos precisam do fuso do aparelho para tocar na hora escolhida |
| `intl` | ^0.20.3 | Datas e números em português | Formatação no padrão brasileiro |
| `cupertino_icons` | ^1.0.8 | Ícones do iOS | Veio no projeto padrão do Flutter. O app não usa esses ícones e roda só em Android e Web, então o pacote pode ser removido |

### Dependências de desenvolvimento

| Pacote | Versão | Para que serve | Por que este |
| --- | --- | --- | --- |
| `flutter_test` | SDK | Testes de unidade e de tela | Vem com o Flutter |
| `flutter_lints` | ^6.0.0 | Regras do `flutter analyze` | Conjunto de regras recomendado pelo Flutter |
| `hive_ce_generator` e `build_runner` | ^1.12.1 e ^2.17.1 | Geram os adaptadores do Hive | Evitam escrever à mão a conversão de cada entidade |
| `fake_cloud_firestore` | ^4.5.0 | Firestore simulado nos testes | Permite testar a sincronização com falha parcial e a anonimização sem internet e sem mexer no banco real |
| `mocktail` | ^1.0.5 | Objetos simulados nos testes | Estava previsto no plano, mas os testes acabaram usando repositórios falsos escritos à mão. Pode ser removido |

## 5. Registro por integrante

Cada integrante descreve aqui o próprio uso da IA, com os pedidos que funcionaram e os erros que encontrou.

### Gabriel de Oliveira Alves

Tarefas: FIB-4 e validação, classificação de risco, tela Exames, relatórios, dashboard de exames, PDF, correções da semana 4, modo consulta e esta documentação. Os pedidos estão na seção 2 e os erros na seção 3. A IA foi mais útil para encontrar casos de borda e escrever testes, e menos confiável para decidir regras de negócio. Nesses casos, a decisão foi sempre do integrante, como a regra do risco com a meta semanal e a comparação entre períodos.

### Wilia Francisco da Silva

Tarefas: estrutura do projeto e sprints, configuração do Firebase, fila offline e detecção de Wi-Fi, sincronização em lote com falha parcial, regras do Firestore, restauração dos dados com a cópia na nuvem criptografada pela senha, revisão dos pull requests, testes no Android 8 e no Android 12, refinamento das telas com base no protótipo, Changelog e Readme. Os pedidos estão na seção 2 e os erros na seção 3. A IA foi mais útil para montar roteiros de teste, comparar telas com o protótipo e encontrar a causa de um erro depois de ele aparecer no aparelho. Foi menos confiável quando descrevia o código sem conferir e quando sugeria dados de teste. Por isso, cada mudança foi testada no emulador, e as decisões de produto, como a opção B da restauração, apagar a conta e o que seguir ou não do protótipo, foram sempre do integrante.

### Victor Castelo Branco

Utilizei alguns Agentes de IA para o desenvolvimento e estruturação do projeto, Claude, codex e Athenas Agent. Tanto para desenvolvimento das atividades referente a cada entrega como para validações e busca de erros.

### Lizandra Bispo Nascimento

Tarefas: navegação principal, Modo Camuflagem, metas de redução, notificações e lembretes, testes e documentação do fluxo de navegação. Os pedidos estão na seção 2 e os erros na seção 3. A IA ajudou a transformar regras claras em testes e a conferir se os diagramas descreviam os caminhos disponíveis no aplicativo.

### Leon Mendonça

_A preencher._
