# Justificativas

## Contexto das decisões

As decisões de interface e arquitetura do HepatoCheck partem de três fatos do estudo de caso: o público tem entre 30 e 60 anos, o consumo de álcool é um dado sensível e o app será usado em casa, no bar e no consultório.

A persona prioritária é **Ricardo**, que baixou o app por indicação médica, tem pouca paciência com aplicativos complexos e medo de que outras pessoas vejam quanto ele bebe. **Marisa**, a segunda persona, é engajada e quer gráficos e dados organizados para levar ao hepatologista. As escolhas abaixo foram feitas para atender Ricardo primeiro, sem perder o que Marisa precisa.

## Escolha das cores

O HepatoCheck usa **tema escuro** com **verde oliva** como cor de marca. O tema escuro reduz o brilho da tela em bares e ambientes com pouca luz, torna o uso mais discreto perto de outras pessoas e cansa menos a vista na leitura de gráficos em casa.

O verde oliva remete à saúde sem o tom frio do azul hospitalar e reforça a personalidade séria, objetiva e confiável definida no estudo de caso. Ele aparece com moderação: no botão de ação principal, no item ativo da navegação e no elemento selecionado. Assim, o usuário encontra rapidamente onde tocar.

A classificação de risco segue o **padrão de semáforo**, com verde, amarelo e vermelho, que qualquer adulto entende sem explicação. Nos selos de classificação, essas cores aparecem sempre com o nome da faixa, para não serem confundidas com outros usos: o vermelho também marca ações que apagam dados, como excluir e sair, e o verde indica melhora no histórico de exames. Em risco alto, está previsto um filtro amarelado que lembra a icterícia, sinal físico associado à doença hepática, para tornar perceptível um problema que costuma ser silencioso.

O contraste foi pensado para atender ao **nível AA da WCAG**: textos principais em tom claro sobre o fundo escuro e textos secundários em cinza esverdeado, com mínimo de **4,5:1** para texto comum.

## Tipografia

A fonte adotada é a **Inter**, desenhada especificamente para telas, com letras abertas e boa leitura em tamanhos pequenos. Ela é incorporada ao app e aparece igual no Android e no iOS, o que mantém a identidade visual em qualquer aparelho.

A hierarquia tem quatro níveis:

- **Título da tela**, maior e em negrito, mostra ao usuário onde ele está.
- **Títulos de seção**, menores e em caixa alta, separam blocos como Histórico e Privacidade.
- **Texto de apoio**, em tom secundário, explica campos e resultados sem competir com a informação principal.
- **Números de destaque**, como o valor do FIB-4 e a quantidade de drinks, têm o maior peso visual do cartão, porque são o que o usuário procura primeiro.

Para garantir a legibilidade, os textos são curtos e diretos, e os termos clínicos aparecem com o nome popular ao lado, como AST (TGO) e ALT (TGP). Isso atende à necessidade de Ricardo de entender o próprio risco sem estudar termos médicos.

## Organização das informações

Cada tela principal responde a uma única pergunta do usuário, o que respeita o limite de quatro telas principais do RNF10.

| Tela | Pergunta que responde | Ordem das informações |
| --- | --- | --- |
| Início | Como está meu fígado? | Silhueta do corpo com o fígado em destaque, cartão com idade, FIB-4 e classificação, botão de registro rápido |
| Drinks | Quanto eu bebi? | Tipo de bebida, data e hora, quantidade, botão Adicionar e histórico com opção de excluir cada registro |
| Exames | Qual é o meu resultado? | Formulário do exame com a nota de que o FIB-4 é validado entre 35 e 65 anos (RF02), resultado com a faixa de risco e histórico com a evolução |
| Relatório | Como estou evoluindo? | Filtro de período, risco atual, cartões de resumo, gráficos, modo consulta e exportação em PDF |

O fluxo visual segue sempre a mesma ordem, de cima para baixo: primeiro o resultado ou a ação principal, depois os detalhes e por último o histórico. Assim, Ricardo resolve o que precisa sem rolar a tela, e Marisa encontra a evolução completa logo abaixo.

Na tela Início, a silhueta do corpo cumpre o papel do gráfico "vida do fígado" do RF07: o fígado em destaque muda de cor conforme a classificação de risco, que é atualizada a cada exame e registro de consumo.

O estudo de caso previa a orientação sobre quando procurar o médico como uma das quatro telas principais. No protótipo, ela passou a ser uma sobreposição aberta a partir do selo de risco do Início e do cartão de risco do Relatório, para aparecer exatamente quando o usuário vê o próprio resultado, sem precisar navegar. A orientação continua sendo uma função essencial e apenas mudou de formato. A vaga de tela principal passou para o Relatório, que reúne a visualização de indicadores e o modo consulta.

Login, cadastro, recuperação e alteração de senha e política de privacidade são telas de apoio, acessadas apenas quando necessário. O Perfil reúne as configurações de privacidade, lembretes e conta.

As metas de redução (RF15), de prioridade secundária, ficam para uma versão futura. Nesta versão, o Relatório já mostra os dias sem álcool, que servirão de base para essas metas.

## Navegação

A navegação principal é uma barra inferior fixa com cinco itens: Início, Relatório, Drinks, Exames e Perfil.

Ela fica ao alcance do polegar, é um padrão conhecido tanto no Android quanto no iOS e mostra ícone e nome juntos, para que ninguém precise adivinhar o que cada ícone significa. O item ativo aparece em verde oliva e indica onde o usuário está.

O registro rápido de bebida é o fluxo mais importante, porque acontece no bar, em pé e com pouca atenção. Ele cabe em três toques, conforme o RF05 e o RNF11:

1. Tocar no botão + da tela Início.
2. Escolher o tipo de bebida: cerveja, destilado ou vinho.
3. Tocar em Adicionar.

A quantidade começa em 1, e a data e a hora são preenchidas com o momento atual. Quem precisa registrar outra quantidade ou outro dia usa a aba Drinks, que tem todos os campos.

Ao escolher o tipo, uma linha abaixo dos seletores mostra a conversão em drinque padrão, por exemplo **"1 lata de cerveja = 1 drinque padrão"**. Assim, a conversão aparece antes da confirmação do registro, como pede o RF04, sem acrescentar nenhum toque.

A orientação sobre quando procurar o médico abre como uma sobreposição ao tocar no selo de risco do Início ou no cartão de risco do Relatório, sem tirar o usuário da tela em que ele está. Todas as telas, exceto o Início, têm a seta de voltar no canto superior esquerdo, que leva sempre à tela anterior.

## Componentes

A interface usa componentes do Material Design, que o Flutter oferece prontos e que funcionam da mesma forma no Android e no iOS.

| Componente | Onde aparece | Por que foi escolhido |
|---|---|---|
| Barra de navegação inferior | Telas principais | Acesso direto às quatro funções centrais e ao perfil |
| Botão flutuante + | Início | Atalho para o registro rápido, sempre no mesmo lugar |
| Cartões | Início, Exames, Relatório e Perfil | Agrupam uma informação por bloco e facilitam a leitura rápida |
| Seletores de tipo com ícone | Registro de drinks | O ícone é reconhecido mais rápido que uma lista, e o tipo escolhido ganha borda verde |
| Contador com botões de menos e mais | Drinks | Ajusta a quantidade sem abrir o teclado |
| Campos de data e hora com seletor | Drinks e Exames | Evitam erros de digitação |
| Campos de texto com rótulo | Login, Cadastro e Exames | O nome do campo continua visível depois de preenchido, e notas curtas abaixo dos campos orientam o preenchimento, como a faixa de idade validada do FIB-4 e o valor de referência das plaquetas |
| Selos de classificação | Início, Exames e Relatório | Mostram o risco com cor, ícone e texto |
| Gráficos de barras e de linha | Relatório | Mostram o consumo por semana e a evolução do FIB-4 |
| Interruptores | Perfil | Ligam e desligam sincronização, camuflagem e lembretes |
| Controle segmentado | Relatório e histórico de Drinks | Troca o período ou a ordenação com um toque |
| Sobreposição | Registro rápido e orientação médica | Mostra um conteúdo pontual sem trocar de tela |

## Acessibilidade

O estudo de caso pede leitura rápida, contraste adequado e elementos visuais simples, e lembra que parte do público tem dificuldade com tecnologia. O RNF02 transforma isso em requisito. As decisões seguem as diretrizes WCAG 2.1 no nível AA e as recomendações de acessibilidade do Material Design:

- **Contraste:** texto claro sobre fundo escuro, com mínimo de 4,5:1 para texto comum.
- **Cor nunca sozinha:** a classificação de risco sempre traz cor, ícone e nome da faixa, para que pessoas com daltonismo também entendam o resultado.
- **Áreas de toque:** botões e itens tocáveis com pelo menos 48 dp, o que facilita o uso em pé no bar e por quem tem menos precisão nos dedos.
- **Rótulos visíveis:** todo campo tem o nome acima dele, que continua visível depois de preenchido.
- **Linguagem simples:** termos clínicos explicados e orientações em frases curtas.
- **Poucas etapas:** as funções principais em até três interações (RNF11) reduzem o esforço de quem tem pouca familiaridade com aplicativos.
- **Leitor de tela e tamanho de fonte:** os componentes recebem descrições para o TalkBack, no Android, e para o VoiceOver, no iOS, e respeitam o tamanho de fonte escolhido nas configurações do aparelho.

## Decisões relacionadas ao contexto de uso

O mesmo aplicativo precisa funcionar em situações muito diferentes, por isso cada condição do estudo de caso gerou uma decisão concreta.

| Contexto ou condição                    | Decisão                                                                                                   |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| No bar, em pé e com distrações          | Registro rápido em três toques, botões grandes e tema escuro, que chama menos atenção                     |
| Pessoas próximas vendo o celular        | Modo camuflagem, que disfarça o diário como calculadora, e modo convidado, sem cadastro                   |
| Sem internet                            | Todos os dados são gravados no aparelho, e o app funciona 100% offline                                    |
| Rede móvel ou pública                   | Sincronização apenas via Wi-Fi e somente com autorização explícita do usuário                             |
| Em casa, com mais tempo                 | Relatório com gráficos e histórico para análise com calma                                                 |
| Durante a consulta médica               | Modo consulta com os principais indicadores e exportação do resumo em PDF                                 |
| Preocupação ao ver o resultado          | Classificação objetiva em três cores e orientação clara sobre quando procurar o médico, sem tom alarmista |
| Pouco conhecimento sobre dose de álcool | Conversão de cada bebida em drinque padrão                                                                |

Nas telas de resultado, como o Relatório, a orientação médica e o PDF, o app reforça que é uma ferramenta de triagem e não substitui o diagnóstico médico, conforme o RNF17.