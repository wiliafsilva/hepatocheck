# ATIVIDADE 01 — ANÁLISE DO ESTUDO DE CASO

## 2.1. Problema

Explique:

• Qual problema o aplicativo pretende ajudar a solucionar?

O objetivo é auxiliar, prevenir e monitorar fatores de riscos relacionados ao consumo de álcool, má alimentação, coletar informações para ajudar a direcionar as pessoas a terem hábitos mais saudáveis para reduzir os riscos de problemas hepáticos e buscar acompanhamentos profissionais se necessário.

• Por que esse problema é relevante?

Ajudar as pessoas a transformarem os hábitos de vida, mostrar fatores de riscos com o monitoramento diário, auxilia no controle e na prevenção da saúde do fígado reduzindo maiores problemas.

• Qual é a principal necessidade que a solução deverá atender?

Prevenção, conscientização, monitoramento e autocuidado.

## 2.2. Público e usuários

Analise os públicos indicados no estudo de caso. Para cada público relevante, identifique:

• Quem é?

Adutos de 30 – 60 anos

• Qual relação possui com o aplicativo?

Usuário principal a ser monitorado com indicadores e acompanhamento.

• Quais necessidades possui:

Acompanhamento na prevenção e auxílio nos cuidados da saúde hepática.

• Em que situação poderá utilizar a solução?

Para acompanhar, analisar e orientar as pessoas que querer prevenir doenças. Pessoas que desejam melhorar seus hábitos alimentares, e reduzir riscos e sobrepesos.

Pessoas que já estão no alto risco e desejam ter um acompanhamento para monitorar.

Atenção: o estudo de caso já apresenta o público-alvo. O grupo deverá analisá-lo, e não simplesmente copiá-lo.

## 2.3. Contexto de uso

Identifique os diferentes contextos nos quais o aplicativo poderá ser utilizado. Considere as informações fornecidas no estudo de caso, como:

• Ambiente e momento de utilização: O aplicativo poderá ser utilizado em diferentes tipos de ambientes, como, em casa, bares e consultórios.

Casa: O usuário pode ter mais tempo e atenção para analisar gráficos, inserir exames e acompanhar sua evolução.

Bares: O contexto exige uma interação rápida e discreta. O usuário pode estar em um ambiente com distrações e outras pessoas próximas, por isso, o requisito de registrar um drinque em poucas interações é especialmente importante.

• Condições do usuário: O usuário pode estar sem internet: o aplicativo deve funcionar offline e registrar os dados localmente.

O usuário pode não conhecer o conceito de “dose padrão” de álcool: por isso essa informação deve ser explicada de forma simples.

O usuário pode estar preocupado com a privacidade: o diário de consumo de álcool contém informações sensíveis, então o usuário deve ter controle sobre o compartilhamento.

O usuário pode utilizar o aplicativo como convidado: sem necessidade de sincronizar seus dados com a nuvem

• Dispositivo: O aplicativo deve funcionar em Android 8.0 ou superior.

• Conectividade: O aplicativo precisa funcionar sem internet. Os dados devem ser registrados localmente e posteriormente sincronizados com o Firebase quando houver conexão à internet, desde que exista autorização para isso.

• Iluminação e atenção: Como o aplicativo pode ser utilizado em bares e outros ambientes variados, a interface deve priorizar leitura rápida, contraste adequado e elementos visuais simples.

• Situação de urgência: O usuário pode estar em uma situação em que precisa interpretar rapidamente seu estado de risco, principalmente ao consultar o resultado do cálculo de risco, por isso, a informação deve ser objetiva e destacar claramente quando procurar um profissional de sáude.

• Outras condições específicas: Uso durante consulta médica: o profissional pode precisar visualizar rapidamente os dados do paciente.

Explique como esses contextos podem influenciar o desenvolvimento do aplicativo.

A interface precisa ser simples e objetiva, com poucas etapas. Isso está relacionado à exigência de realizar a função principal em até 3 interações, as informações precisam ser apresentadas de forma clara e rápida, o aplicativo precisa seguir uma abordagem offline-first, armazenando os registros no dispositivo para que o usuário consiga utilizar as funções mesmo sem conexão, quando o sistema indicar uma situação de maior risco, a informação deve ser visualmente clara e objetiva, sem transformar o aplicativo em uma ferramenta de diagnóstico ou causar terror desnecessário.

## 2.4. Objetivo e proposta de valor

Explique, com suas próprias palavras: O que o aplicativo pretende oferecer e qual benefício deverá proporcionar ao usuário?

O objetivo do Hepatocheck é oferecer uma ferramenta mobile que permita ao usuário acompanhar fatores relacionados ao risco hepático, uma calculadora de escore laboratorial não invasivo utilizado para estimar o grau de fibrose hepática (FIB-4) e diário de consumo de álcool para reduzir a incidência de cirrose de maneira simples e rápida.

## 2.5. Personalidade, identidade e experiência

• Palavras conceituais: vão orientar quais funcionalidades serão priorizadas, como cálculo do FIB-4, registro de álcool, exames e acompanhamento da saúde do fígado.

• Personalidade da identidade: fará com que novas telas e recursos mantenham uma comunicação séria, objetiva e confiável, sem causar medo no usuário.

• Tom da interface: irá direcionar a evolução para uma navegação cada vez mais simples, rápida e com poucas etapas para realizar as principais ações.

• Tom da experiência do usuário: fará com que futuras funcionalidades priorizem facilidade, acompanhamento da evolução e informações claras sobre riscos.

• Como deseja ser lembrado: o aplicativo deseja ser lembrado como uma ferramenta importantíssima no auxílio prático de prevenção e conscientização sobre a saúde do fígado.

## 2.6. Funcionalidades e características já definidas

Identifique as principais funcionalidades e características que já foram estabelecidas no estudo de caso.

Para cada uma, explique brevemente qual necessidade ela atende. Por exemplo:

1 - Funcionalidade: Calculadora de risco hepático baseada em exames de sangue

1.1 - Necessidade atendida: Mostrar ao usuário o grau de risco que ele ocupa

2 -Funcionalidade: Diário de consumo de álcool

2.2 - Necessidade atendida: Ajudar o usuário a ter uma noção da quantidade ingerida semanalmente.

3 -Funcionalidade: Dashboard de classificação de risco e orientações para graus avançandos.

3.2 - Necessidade atendida: mostrar ao usuário o nivel de risco que ele se encaixa e sinalizar que necessita de um acompanhamento com gastroenterologista

## 2.7. Restrições e condições

Identifique as restrições apresentadas no estudo de caso que deverão ser respeitadas durante o projeto. Podem estar relacionadas a:

• Quantidade de telas (Protótipo deverá ter máx. 4): limita o escopo do protótipo e força a equipe a priorizar só o essencial como gráfico de saúde, registro de drinque, input de exames e "quando procurar o médico" Caso nescessário adicionar.

• Número de interações (até 3 / 2 toques): Porque o público inclui pessoas resistentes a admitir o próprio consumo; quanto mais fácil registrar, menor a fricção para manter o hábito, além de pessoas com dificuldades de aderir a tecnologias.

• Dispositivos/SO (Android 8.0+): Define o piso técnico de compatibilidade, evita usar APIs ou pacotes Flutter que exijam versões mais recentes do Android ou IOS, para evitar mal funcionamento ou bugs.

• Privacidade: Restrição mais crítica do caso, porque o dado (consumo de álcool) tem implicação social e trabalhista, não só médica, por isso a sincronização exige opt-in (como a LGPD no Brasil e o GDPR na Europa) explícito, além de políticas de privacidade claras para manter a privacidade dos usuários.

• Armazenamento (100% offline): Função para armazenar os dados quando estiver em locais ex: (bar, casa) onde o sinal de internet nem sempre está disponível no momento em que o dado precisa ser registrado.

• Conectividade (sync só via Wi-Fi):Reforça a privacidade (evita vazar dados sensíveis por redes móveis/públicas) e poupa dados móveis do usuário.

• Navegação (Convidado + modo calculadora): Para evitar expor os dados do usuário mascarando o app (camuflando) ou precisa ser "invisível" se necessário.

• Ambiente de utilização (casa, bar, consultório): Exige que a mesma interface funcione tanto para uso pessoal descontraído quanto para leitura clínica rápida em consulta, são contextos de uso muito diferentes, porém com critérios informativos e acompanhamento dos usuários.

• Outras condições específicas: performance/visual (CustomPainter, filtro amarelado): garante leveza do app (poucos assets pesados) e cria um alerta visual memorável e biologicamente associado ao problema (icterícia).

## 2.8. Pontos de atenção

1. Privacidade do diário de álcool — o estudo de caso deixa explícito que esse dado "pode afetar emprego". Isso não é um detalhe técnico, é o motivo pelo qual existem o modo Convidado, o modo calculadora e a regra de não sincronizar sem permissão. Se essa proteção falhar, o app perde a confiança do exato público que mais precisa dele (o "Negado", que já é resistente a se expor).

2. Fluxo em até 3 interações — Muita atenção com os usuários: usuário 01 (baixou por indicação médica, não por vontade própria) e outro (que achou o app na playstore ou outro local para download). Para o primeiro perfil, qualquer fricção no registro do drinque é motivo suficiente para abandonar o app na primeira semana, por isso a simplicidade do fluxo é tratada como requisito, não como "opcional ou bom ter".

3. Funcionamento offline-first — o app deve ser projetado para ser usado no momento exato em que o consumo acontece (bar, casa), não depois. Se o registro dependesse de internet, o app perderia justamente o dado mais importante, o consumo em tempo real. Nos ambientes onde ele é mais usado.