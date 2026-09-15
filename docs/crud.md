# 2.4 CRUD

O CRUD do HepatoCheck foi definido a partir das necessidades identificadas na pesquisa e nas personas: registrar o consumo de álcool com o mínimo de esforço, acompanhar exames e risco hepático ao longo do tempo e preservar a privacidade de informações sensíveis. Como o aplicativo funciona prioritariamente offline e pode ser usado como convidado, os dados devem ser mantidos localmente no dispositivo; qualquer sincronização depende de autorização explícita do usuário e de conexão Wi-Fi.

## Registros de consumo de álcool

| Operação | Como será aplicada | Justificativa |
| --- | --- | --- |
| **Criar** | O usuário registra tipo de bebida, quantidade e data/hora. O aplicativo converte o item para drinques padrão antes da confirmação. | É o dado principal para que o usuário entenda seu consumo real. O fluxo deve caber em até três interações, pois o registro pode ocorrer em um bar ou em outro contexto de pouca atenção. |
| **Consultar** | O usuário visualiza os registros do dia, da semana e do histórico, incluindo total de drinques padrão, dias sem consumo e tendência. | Permite identificar padrões sem exigir que a pessoa interprete cada bebida isoladamente. |
| **Atualizar** | O usuário pode corrigir uma bebida, quantidade ou data inserida por engano. Após a edição, os totais, metas e classificação de risco devem ser recalculados. | Corrigir erros evita que uma entrada incorreta distorça o acompanhamento. |
| **Excluir** | O usuário pode apagar um registro lançado indevidamente, mediante confirmação. Se houver sincronização autorizada, a exclusão também deverá ser refletida na próxima sincronização. | O dado é sensível e pertence ao usuário; ele deve manter controle sobre seu histórico. |

## Exames laboratoriais e resultado do FIB-4

| Operação | Como será aplicada | Justificativa |
| --- | --- | --- |
| **Criar** | O usuário informa idade, AST/TGO, ALT/TGP, plaquetas e a data do exame. O sistema calcula automaticamente o FIB-4 e registra o resultado no histórico. | Viabiliza a triagem não invasiva e permite acompanhar a evolução dos resultados. |
| **Consultar** | O usuário consulta o resultado atual, a faixa de risco e a linha do tempo dos exames anteriores. Em consulta, o profissional pode acessar uma visão resumida desses indicadores. | Pacientes precisam de linguagem simples; profissionais precisam de uma leitura rápida e objetiva. |
| **Atualizar** | O usuário pode corrigir os valores ou a data de um exame. O FIB-4 não é editado manualmente: ele é recalculado a partir dos dados corrigidos. | Preserva a confiabilidade do cálculo e reduz o risco de alteração indevida de um resultado derivado. |
| **Excluir** | O usuário pode excluir um exame registrado incorretamente, com confirmação, removendo também o resultado FIB-4 associado. | Mantém o histórico fiel aos exames reais e evita interpretações baseadas em dados errados. |

## Metas de redução e dias sem consumo

| Operação | Como será aplicada | Justificativa |
| --- | --- | --- |
| **Criar** | O usuário define uma meta gradual, como "três dias sem beber por semana" ou uma quantidade máxima de drinques. | A pesquisa e o benchmark indicam que metas pequenas e feedback positivo incentivam mudança de hábito sem julgamento. |
| **Consultar** | O usuário acompanha o progresso da meta e os dias sem consumo no período selecionado. | Mostra evolução de forma clara e reforça o autocuidado. |
| **Atualizar** | O usuário ajusta o período, a quantidade ou o objetivo da meta. | A meta deve acompanhar o ritmo e a realidade de cada usuário. |
| **Excluir** | O usuário pode encerrar ou apagar uma meta que não faça mais sentido. | Evita notificações e indicadores relacionados a objetivos abandonados. |

## Preferências de privacidade e lembretes

| Operação | Como será aplicada | Justificativa |
| --- | --- | --- |
| **Criar** | Ao configurar o aplicativo, o usuário pode criar preferências locais, como lembretes, modo camuflagem e autorização de sincronização. | A pessoa deve escolher como e quando o aplicativo acessa ou apresenta seus dados. |
| **Consultar** | O usuário visualiza as permissões, o estado da sincronização e os lembretes ativos. | Torna o tratamento de dados sensíveis transparente. |
| **Atualizar** | O usuário pode alterar lembretes, ativar ou desativar o modo camuflagem e conceder ou retirar a autorização de sincronização. | A autorização deve ser revogável; ela não pode ser presumida nem permanente. |
| **Excluir** | O usuário pode remover lembretes e apagar os dados locais do aplicativo. No modo convidado, não há conta obrigatória a ser excluída. | O modo convidado reduz a exposição de dados. A exclusão dos dados locais preserva o controle do usuário sobre informações de saúde e consumo de álcool. |

## Informações que não formam um CRUD próprio

O dashboard de risco, o gráfico "Vida do Fígado", a classificação Verde/Amarelo/Vermelho e a tela "Quando procurar o médico" não devem ser tratados como cadastros editáveis. O dashboard e a classificação são informações **derivadas** dos exames e dos registros de consumo: o sistema deve apenas recalculá-los e permitir sua consulta após cada alteração nos dados de origem. A orientação médica é conteúdo educativo e somente deve ser consultada, pois não cabe ao usuário criá-la, alterá-la ou excluí-la.

Da mesma forma, o resumo para o profissional de saúde e a exportação em PDF são gerados sob demanda a partir dos dados já existentes. Eles podem ser consultados ou exportados pelo usuário, mas não precisam de criação, edição ou exclusão como registros independentes. Isso mantém o aplicativo simples, evita duplicidade de dados e reforça que o HepatoCheck é uma ferramenta preventiva e educativa, não um diagnóstico clínico.
