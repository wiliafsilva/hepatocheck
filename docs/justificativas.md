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

