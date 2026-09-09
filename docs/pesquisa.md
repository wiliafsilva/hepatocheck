# Pesquisa sobre o problema e o público do estudo de caso

## Informações relevantes sobre o problema

A DHGNA (hoje também chamada de MASLD — doença hepática esteatótica associada à disfunção metabólica) é o acúmulo excessivo de gordura no fígado em pessoas que não bebem álcool em quantidade considerada de risco. Estudos brasileiros que usaram ultrassonografia encontraram esteatose em cerca de 18–20% da população geral, chegando a 70% entre pacientes diabéticos. Globalmente, a prevalência estimada varia de 20% a 30% dos adultos.

A doença é altamente prevalente, silenciosa, e uma triagem simples (FIB-4 + diário de álcool) tem potencial real de capturar casos antes da progressão para cirrose.

## Necessidades e dificuldades dos usuários

### Pacientes (adultos 30–60 anos, sobrepeso, bebedores sociais)

Não sabem traduzir "quanto eu bebo" em risco real — a maior dificuldade identificada é a falta de compreensão do conceito de "drinque padrão" (uma lata de cerveja ≠ uma taça de vinho ≠ uma dose de destilado em termos de álcool puro). O próprio briefing do projeto já registra isso como aprendizado de usuário.

Dois perfis distintos de engajamento: os "em negação" (baixam por indicação médica, uso passivo) e os "preocupados" (quer ver gráficos, uso ativo) — a experiência precisa funcionar para ambos sem parecer "alarmista".

### Profissionais de saúde (clínicos gerais, gastroenterologistas, hepatologistas)

Precisam de um resultado rápido e acionável durante consulta curta — não de gráficos elaborados.

Ferramentas como o FIB-4 já são usadas nesse fluxo justamente por serem rápidas e baratas.

Precisam confiar na fonte dos dados inseridos pelo paciente (exames), então o app deve deixar claro que a triagem não substitui avaliação clínica formal.

## Dados que possam influenciar o aplicativo

1. Como o consumo de álcool é um dado sensível e estigmatizado, funções como o "modo calculadora" (camuflagem) e o modo convidado sem sincronização automática, já previstos no briefing, são coerentes com o que a literatura de privacidade em apps de saúde recomenda.
2. Como o público de risco é majoritariamente 25–54 anos com sobrepeso, o app pode priorizar linguagem e exemplos voltados a esse perfil (ex.: referências a happy hour, churrasco de fim de semana) em vez de foco em consumo pesado diário.
3. Como a doença é assintomática até fases avançadas, o gráfico "vida do fígado" e o filtro amarelado de alerta (simulando icterícia) têm respaldo: a literatura destaca a dificuldade de motivar mudança de comportamento quando não há sintoma perceptível, então um recurso visual e emocional de alerta é uma estratégia válida.
4. Como o FIB-4 não é válido para todas as idades, o fluxo de input de exames precisa checar a idade do usuário e sinalizar quando o resultado não é confiável, evitando falso senso de segurança ou alarme desnecessário.

## Fontes utilizadas

- https://whitebook.afya.com.br/escore-fib-4-como-calcular-e-interpretar-o-risco-de-fibrose-hepatica/
- https://www.sbhepatologia.org.br/pdf/reuniao_monotematica_dhgna_2012.pdf
- https://www.endocrino.org.br/noticias/dados-do-vigitel-apontam-avanco-da-obesidade-e-do-diabetes-na-populacao-brasileira/

> **Mínimo:** 3 fontes confiáveis.

## 3 descobertas importantes e como elas podem influenciar o projeto

### Descoberta 1 — O maior obstáculo do uso não é técnico, é de compreensão

As pessoas não sabem quanto álcool realmente estão bebendo. A confusão sobre "drinque padrão" já é citada no próprio changelog-exemplo do time.

Isso confirma que o diário de consumo precisa de uma calculadora visual de conversão (ex.: "1 lata de cerveja = 1 drinque; 1 garrafa de vinho = 5 drinques") acessível antes do primeiro registro, e não apenas em um modal esquecível — sem isso, os dados de risco calculados pelo app ficam imprecisos desde a entrada.

### Descoberta 2 — Privacidade percebida é pré-requisito de adoção, não um extra

Com boa parte dos usuários de apps de saúde preocupados com vazamento de dados sensíveis, e o próprio Ministério da Saúde lançando um app de álcool com ênfase explícita em "privacidade", fica claro que qualquer atrito ou dúvida sobre "quem vê meus dados" pode fazer o usuário abandonar o diário de álcool logo no início.

Isso reforça a prioridade de tornar o modo Convidado e a sincronização opcional bem visíveis na primeira execução do app (onboarding), não escondidos em configurações.

### Descoberta 3 — O público-alvo (30–60 anos, sobrepeso) está exatamente na faixa etária onde a obesidade mais cresceu no Brasil

Isso torna a triagem hepática combinada (álcool + exames) mais relevante que uma ferramenta isolada. Como excesso de peso e consumo de álcool são fatores de risco que se somam para a progressão da DHGNA, o app ganha força ao não tratar "diário de álcool" e "calculadora FIB-4" como recursos separados, mas cruzar essas informações na classificação de risco (Verde/Amarelo/Vermelho) — por exemplo, sinalizando risco mais alto quando IMC elevado e consumo de álcool coexistem, mesmo que cada fator isolado pareça moderado.
