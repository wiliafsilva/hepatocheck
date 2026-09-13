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

**8. Alertas e Lembretes de Acompanhamento**

- **Descrição:** Notificações programadas que lembram o usuário de repetir os exames laboratoriais periodicamente (conforme a faixa de risco do FIB-4) e de registrar o consumo de álcool quando ele esquecer de fazê-lo por alguns dias.
- **Necessidade do usuário:** Manter a rotina de monitoramento mesmo sem lembrar sozinho, já que o problema (DHGNA) é silencioso e fácil de "esquecer" quando não há sintomas.
- **Justificativa:** Como o FIB-4 recomenda reavaliação periódica (a cada 1–2 anos em risco baixo, mais frequente em risco intermediário/alto) e o diário de álcool só é útil se alimentado com constância, o app perde valor de prevenção se depender só da iniciativa do usuário. Os lembretes reduzem o abandono, especialmente do perfil "em negação", que tende a esquecer o app depois da primeira semana.

**9. Tela "Quando Procurar o Médico" com Linguagem Educativa**

* **Descrição:** Tela dedicada que explica, em linguagem simples, o que cada faixa de risco (Verde/Amarelo/Vermelho) significa na prática, o que fazer em cada caso e reforça que o app é uma triagem, não um diagnóstico.
* **Necessidade do usuário:** Entender o próprio resultado sem interpretar sozinho um termo clínico e sem ficar em dúvida se precisa mesmo procurar um profissional.
* **Justificativa:** O estudo de caso lista essa tela como uma das 4 principais do protótipo, separada do dashboard de risco. A pesquisa reforça isso ao apontar que profissionais de saúde precisam confiar que o app deixa claro que a triagem não substitui avaliação clínica formal, e que o tom da experiência deve ser franco sem causar terrorismo médico.

**10. Metas de Redução e Dias sem Consumo**

* **Descrição:** Dentro do diário de álcool, o usuário pode definir metas pequenas e progressivas, como "3 dias sem beber por semana", com feedback positivo quando a meta é cumprida.
* **Necessidade do usuário:** Sentir que está no controle da própria mudança de hábito, sem uma abordagem punitiva.
* **Justificativa:** Esse recurso vem diretamente do benchmark do MyDrinkaware, apontado como algo a aproveitar por evitar uma abordagem punitiva e incentivar mudança gradual. Encaixa bem na persona de Ricardo, que precisa de baixa fricção e nenhum julgamento para continuar usando o app.

**11. Histórico e Linha do Tempo de Exames**

* **Descrição:** Na tela de input de exames, o usuário visualiza não só o resultado atual, mas um histórico dos exames já registrados, mostrando a evolução do FIB-4 ao longo do tempo.
* **Necessidade do usuário:** Entender se o risco está melhorando, piorando ou estável, e não apenas ver um número isolado.
* **Justificativa:** A pesquisa recomenda reavaliação periódica do FIB-4 conforme a faixa de risco, então o app só cumpre esse papel preventivo se guardar o histórico, não só o último resultado. Isso também alimenta diretamente o gráfico "vida do fígado" já previsto no estudo de caso, sem exigir uma tela nova.


## Requisitos funcionais

**RF01 - Cálculo do escore FIB-4:** O sistema deve calcular automaticamente o escore FIB-4 a partir dos dados informados pelo usuário (idade, AST/TGO, ALT/TGP e plaquetas).

**RF02 - Validação de idade para o FIB-4:** O sistema deve verificar a idade informada antes de exibir o resultado do FIB-4 e sinalizar quando o escore não é validado para essa faixa etária.

**RF03 - Registro de consumo de álcool:** O sistema deve permitir que o usuário registre o tipo e a quantidade de bebida consumida.

**RF04 - Conversão para drinque padrão:** O sistema deve converter automaticamente cada bebida registrada em unidades de "drinque padrão", exibindo essa conversão antes da confirmação do primeiro registro.

**RF05 - Registro rápido de drinque:** O sistema deve permitir que o usuário registre um drinque em no máximo 3 interações.

**RF06 - Classificação de risco:** O sistema deve cruzar os dados do FIB-4 e do diário de álcool para classificar o risco do usuário em Verde, Amarelo ou Vermelho.

**RF07 - Gráfico de evolução hepática:** O sistema deve exibir um gráfico "vida do fígado" (0 a 100%) que se atualiza e muda de cor conforme os dados registrados ao longo do tempo.

**RF08 - Modo Convidado:** O sistema deve permitir que o usuário utilize as funcionalidades principais sem necessidade de cadastro ou sincronização automática com a nuvem.

**RF09 - Modo Camuflagem:** O sistema deve permitir que o usuário oculte a tela do diário de álcool sob a aparência de uma calculadora comum.

**RF10 - Armazenamento local dos dados:** O sistema deve armazenar 100% dos dados registrados localmente no dispositivo, garantindo o funcionamento do aplicativo sem conexão à internet.

**RF11 - Sincronização condicionada e autorizada:** O sistema deve sincronizar os dados com o Firebase somente quando houver conexão Wi-Fi disponível e mediante autorização explícita do usuário.

**RF12 - Modo de consulta para profissionais de saúde:** O sistema deve disponibilizar uma visão resumida dos principais indicadores (FIB-4, tendência do diário de álcool e classificação de risco) para leitura rápida durante o atendimento clínico.

**RF13 - Lembretes de acompanhamento:** O sistema deve enviar notificações para lembrar o usuário de repetir os exames laboratoriais periodicamente e de registrar o consumo de álcool.

**RF14 - Orientação sobre quando procurar o médico:** O sistema deve exibir uma tela explicativa que informa, para cada faixa de risco, o que ela significa e quando o usuário deve buscar um profissional de saúde.

**RF15 - Definição de metas de redução:** O sistema deve permitir que o usuário defina metas de redução do consumo de álcool, incluindo dias sem consumo, com feedback ao atingi-las.

**RF16 - Exportação de resumo em PDF:** O sistema deve permitir a exportação de um resumo em PDF contendo o resultado do FIB-4, a tendência do diário de álcool e a classificação de risco.

## Requisitos não funcionais

**RNF01 — Usabilidade:** A interface deve ser simples, intuitiva e de fácil compreensão considerando o público-alvo de pessoas entre 30 e 60 anos.

**RNF02 — Acessibilidade:** O sistema deve utilizar textos legíveis, botões com tamanhos adequados, contrastes apropriados e elementos visuais que facilitem a utilização do usuário.

**RNF03 — Segurança e privacidade LGPD:** O sistema deve proteger as informações dos usuários por meio de autenticação e controle de acesso, garantir a privacidade dos dados pessoais e das informações de saúde fornecidas pelos usuários, em conformidade com as normas aplicáveis de proteção de dados, incluindo a LGPD.

**RNF04 — Desempenho:** O aplicativo deve apresentar suas telas e funcionalidades principais em tempo adequado, evitando atrasos que prejudiquem a experiência dos usuários.

**RNF05 — Disponibilidade:** O sistema deve permitir a utilização das funcionalidades essenciais mesmo sem conexão com a internet, incluindo o registro de dados e o acesso à calculadora de risco, respeitando as limitações definidas para o funcionamento offline.

**RNF06 — Compatibilidade com dispositivo e sistema operacional:** O aplicativo deve ser compatível com smartphones que utilizam o sistema operacional Android 8.0 ou superior.

**RNF07 — Armazenamento de dados:** O sistema deve armazenar os dados dos usuários de forma segura, garantindo sua integridade, persistência e recuperação, inclusive durante o funcionamento offline.

**RNF08 — Conectividade:** O aplicativo deve permitir a sincronização dos dados registrados localmente com o firebase quando houver conexão com a internet, desde que exista autorização explícita do usuário, priorizando a utilização de redes wi-fi para evitar o consumo de dados móveis.

**RNF09 — Escalabilidade:** O sistema deve possuir uma arquitetura que permita o aumento de usuários e registros armazenados sem comprometer seu desempenho.

**RNF10 — Limitações do número de telas:** O protótipo deve possuir, no máximo, 4 telas, priorizando as funcionalidades essenciais, como registro  de álcool, cálculo de risco, visualização de indicadores e orientação de prevenção.

**RNF11 — Limitações do número de interações:** As principais funcionalidades deverão ser executadas em até 3 interações, priorizando uma navegação simples, rápida e objetiva.

**RNF12 — Compatibilidade:** O aplicativo deve ser desenvolvido para dispositivos móveis Android 8.0, ou superior, não sendo obrigatória, nesta versão, a compatibilidade com outros sistemas operacionais.

**RNF13 — Funcionalidade offline:** O aplicativo deve permitir o registro e o armazenamento local dos dados essenciais sem conexão com a internet, possibilitando a sincronização posterior quando houver conectividade.

**RNF14 — Sincronização wi-fi:** A sincronização dos dados com o firebase deverá ocorrer somente quando o dispositivo estiver conectado a uma rede wi-fi e mediante autorização explícita do usuário.

**RNF15 — Privacidade:** Os dados sensíveis não poderão ser compartilhados ou sincronizados sem autorização do usuário.

**RNF16 — Uso como convidado:** O aplicativo deve permitir o acesso a funcionalidades específicas sem exigir obrigatoriamente cadastro ou sincronização com a nuvem.

**RNF17 — Escopo clínico:** O aplicativo deve atuar como ferramenta preventiva, educativa e de acompanhamento, não substituindo diagnóstico ou acompanhamento profissional.

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
