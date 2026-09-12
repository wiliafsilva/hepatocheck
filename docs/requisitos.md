## Funcionalidades

Defina as principais funcionalidades do aplicativo.

**1. Calculadora de Risco Hepático (FIB-4)**

- **Descrição:** Tela de input de exames (idade, AST/TGO, ALT/TGP, plaquetas) que calcula automaticamente o escore FIB-4 e exibe a faixa de risco (baixo / intermediário / alto).
- **Necessidade do usuário:** Saber, de forma objetiva, se seus exames indicam risco de fibrose avançada sem precisar entender a fórmula ou interpretar valores clínicos sozinho.
- **Justificativa:** É o núcleo técnico do app e a principal proposta de valor citada no briefing. Como o FIB-4 não é validado para menores de 35 anos nem tem os mesmos cortes acima de 65, a funcionalidade precisa checar a idade informada e avisar quando o resultado deve ser lido com cautela, evitando falso alarme ou falsa segurança.

**2. Diário de Consumo de Álcool com Conversor de "Drinque Padrão"**

- **Descrição:** Registro rápido de bebidas (tipo + quantidade), com uma calculadora visual que converte automaticamente cada bebida em "drinques padrão" (ex.: 1 lata de cerveja = 1 drinque; 1 taça de vinho ≈ 1 drinque; 1 dose de destilado = 1 drinque).
- **Necessidade do usuário:** Entender quanto álcool está realmente consumindo, já que a maioria não sabe traduzir bebidas do dia a dia nessa unidade.
- **Justificativa:** A pesquisa mostrou que esse é o maior obstáculo de compreensão do público — sem o conversor, os dados que alimentam a classificação de risco ficam imprecisos desde a entrada. Precisa aparecer antes do primeiro registro, não escondido em um modal.

**3. Registro em até 3 Interações (Abrir → Registrar drinque → Selecionar bebida/quantidade)**

- **Descrição:** Fluxo de registro reduzido ao mínimo de toques possível, otimizado para ser feito em pé, em um bar, com pouca atenção disponível.
- **Necessidade do usuário:** Registrar o consumo quando ele acontece, sem fricção.
- **Justificativa:** O público "em negação" abandona o app na primeira semana se o registro for trabalhoso. Menos fricção = maior adesão, especialmente para quem baixou por indicação médica e não por vontade própria.

**4. Dashboard de Classificação de Risco (Verde/Amarelo/Vermelho) + Gráfico "Vida do Fígado"**

- **Descrição:** Tela central que cruza os dados do FIB-4 e do diário de álcool numa classificação simples de risco, com um gráfico de "saúde hepática" (0–100%) que muda de cor ao longo do tempo, e orientação objetiva de quando procurar um gastroenterologista/hepatologista.
- **Necessidade do usuário:** Visualizar a evolução do próprio risco de forma rápida e emocionalmente clara, tanto em casa (leitura calma) quanto em consulta (leitura rápida pelo profissional).
- **Justificativa:** Como a DHGNA é assintomática até fases avançadas, o recurso visual/emocional (incluindo o filtro amarelado simulando icterícia em risco alto) é a forma de tornar um problema invisível em algo perceptível, sem transformar o app numa ferramenta de diagnóstico ou terrorismo médico.

**5. Modo Convidado e Modo Camuflagem ("modo calculadora")**

- **Descrição:** Uso do app sem cadastro nem sincronização automática com a nuvem; opção de disfarçar a tela do diário de álcool como uma calculadora comum.
- **Necessidade do usuário:** Proteger dados sensíveis de terceiros (parceiro, colega, chefe) que possam ver o celular.
- **Justificativa:** O estudo de caso destaca que o dado de consumo de álcool "pode afetar emprego". Sem essa proteção, o app perde a confiança exatamente do público mais resistente a se expor — se essa camada falhar, todo o resto do produto perde sentido.

**6. Armazenamento 100% Offline com Sincronização apenas via Wi-Fi (opt-in)**

- **Descrição:** Todos os registros são salvos localmente no dispositivo; o envio para o Firebase só ocorre com conexão Wi-Fi e autorização explícita do usuário.
- **Necessidade do usuário:** Conseguir usar o app em qualquer lugar (bar, casa) mesmo sem internet, sem risco de perder dados nem de vazar informação sensível por rede móvel/pública.
- **Justificativa:** Atende à exigência de funcionamento offline-first e reforça a privacidade — a LGPD exige consentimento explícito para tratar dados sensíveis, e sincronizar sem permissão seria uma falha crítica de confiança, não só técnica.

**7. Modo de Consulta / Visão Rápida para o Profissional de Saúde**

- **Descrição:** Tela resumida (ou modo de compartilhamento pontual) com os principais indicadores — FIB-4, tendência do diário de álcool, classificação de risco — pensada para leitura em segundos durante o atendimento.
- **Necessidade do usuário:** O clínico geral, gastroenterologista ou hepatologista precisa entender rapidamente o quadro do paciente numa consulta curta, sem navegar por telas complexas.
- **Justificativa:** Um dos contextos de uso explicitados no estudo de caso é justamente "durante consulta médica". Sem esse recurso, o app perderia valor para metade do seu público-alvo (os profissionais), que são tão importantes quanto o paciente na jornada de cuidado.

## Requisitos funcionais

Transforme as principais funcionalidades em **requisitos funcionais**, descrevendo o que o sistema deverá fazer.

Exemplo:

> **RF01 — Cadastro de usuário:** O sistema deve permitir que o usuário realize seu cadastro informando os dados necessários.

Os requisitos devem ser numerados e escritos de forma clara e objetiva.

## Requisitos não funcionais

Defina as principais características e condições que o aplicativo deverá atender. Considere, quando aplicável:

- Usabilidade
- Acessibilidade
- Segurança e privacidade (LGPD)
- Desempenho
- Compatibilidade
- Armazenamento de dados
- Conectividade
- Dispositivos e sistema operacional
- Restrições definidas no estudo de caso

Exemplo:

> **RNF01 — Usabilidade:** O usuário deve conseguir acessar a funcionalidade principal em, no máximo, três interações.

## CRUD

Identifique, quando aplicável, quais informações do aplicativo precisarão ser:

- **C** — Criadas
- **R** — Consultadas
- **U** — Atualizadas
- **D** — Excluídas

Caso alguma operação não seja necessária, justifique.

## Priorização

Classifique as funcionalidades em:

- **Essenciais:** indispensáveis para a proposta principal
- **Importantes:** agregam valor, mas não são fundamentais
- **Secundárias:** podem ser desenvolvidas posteriormente
