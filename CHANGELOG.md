## (02/09/2026)

### Adicionado
- Análise inicial do estudo de caso.
- Readme atualizado

## (09/09/2026)

### Adicionado
- Pesquisa - Pesquisar sobre o problema e o público do estudo de caso.
- Benchmark - Analise 3 soluções existentes relacionadas ao problema do projeto.
- Personas - crie 2 personas principais para o projeto,
- Apresentação

## (16/09/2026)

### Adicionado 
- Funcionalidades - requisitos , Requisitos funcionais, Requisitos não funcionais, CRUD, Priorização.
- Apresentação dos requisitos 

## (26/09/2026)

### Adicionado
- Prototipação - Baixa Fidelidade
- Prototipação - Alta Fidelidade 
- Justificativas - Registre brevemente as principais decisões de interface e arquitetura
- Apresentação Final Unidade I - Slide da apresentação

## (02/11/2026)

### Adicionado
- Configuração do Firebase no app: projeto hepatocheck-unit com apps Android e Web
- Firebase Authentication com login por e-mail e senha
- Cloud Firestore em São Paulo (southamerica-east1) com regras de segurança (firestore.rules)
- Pacotes firebase_core, firebase_auth e cloud_firestore

### Alterado
- Identificador do app Android de com.example.hepatochec_app para br.com.hepatocheck
- main.dart passa a inicializar o Firebase antes de abrir o app

## (04/11/2026)

### Adicionado
- Semana 1 - Fundação e núcleo clínico
- Estrutura do projeto - Camadas Presentation, Domain e Data, dependências e Riverpod
- Tema - Cores, semáforo de risco e tipografia
- Navegação - Barra inferior com as 5 abas
- Modo Camuflagem - Layout da calculadora
- Idioma - App em português do Brasil
- FIB-4 - Cálculo, validação das entradas, classificação de risco e testes automatizados
- Exames - Repositório e tela de exames
- Tela Início - Cartão de risco, botão de registro rápido e layout do medidor do fígado
- Banco local - Entidades do domínio e Hive com criptografia AES
- Documentação - Escopo, EAP, planejamento em sprints, diagrama de casos de uso e rascunho do diagrama de classes
- Fluxo de trabalho - Guia de contribuição com branches, commits e pull requests
- Correções - Título e teclas da calculadora e cartão de risco com fonte grande
- Readme atualizado

## (09/11/2026)

### Adicionado
- Semana 2 - Diário, privacidade e medidor
- Diário de álcool - Registro por tipo de bebida, conversão em drinque padrão, registro rápido e tela Drinks
- Registro de alterações - Log do diário sem expor o conteúdo
- Modo Camuflagem - Calculadora funcional, código secreto, camuflagem em segundo plano e ocultação na tela de recentes
- Criptografia - Banco criptografado ao ativar a camuflagem e teste automatizado
- Tela Início - Medidor do fígado com dados reais e cor do risco e cartão de consumo das últimas 4 semanas
- Exames - Histórico com evolução do FIB-4 e campos que aceitam apenas números
- Relatório - Relatórios semanais e mensais com total, média por dia, dias sem álcool, consumo por tipo de bebida e comparação com o período anterior
- Login - Telas de login e cadastro
- Sincronização - Fila offline e detecção de Wi-Fi
- Layout - Largura máxima do conteúdo em telas largas
- Readme atualizado

## (16/11/2026)

### Adicionado
- Semana 3 - Nuvem, relatórios e metas
- Login - Autenticação opcional com Firebase mantendo o modo convidado, cadastro, recuperação de senha e política de privacidade
- Sincronização - Consentimento com opção de revogar, anonimização dos dados (faixa etária no lugar da idade e datas sem horário), envio em lote para o Firestore, tratamento de falhas parciais, envio automático ao conectar no Wi-Fi e tela de status no Perfil
- Segurança - Regras do Firestore que validam os campos e as faixas de valores de drinques, exames e metas
- Diário de álcool - Diário, exames e metas ligados à fila de sincronização e opção de apagar todos os dados locais
- Relatório - Relatórios semanais e mensais na tela com gráfico de consumo por dia e exportação em PDF com compartilhamento
- Exames - Dashboard de evolução dos exames
- Evolução do risco - Gráfico da evolução temporal do risco hepático na tela Início
- Metas - Metas de redução com aviso de meta cumprida ou perto de ser ultrapassada
- Notificações - Notificações educativas personalizadas e lembretes de exame e de registro
- Testes - Sincronização com falha parcial (teste 4) e anonimização no envio ao Firestore (teste 5), 318 testes passando
- Documentação - Modelagem do Firestore, mapeamento das classes Dart e o que a anonimização remove ou generaliza
- Readme atualizado

### Alterado
- Classificação de risco - Sobe de nível quando o consumo da semana passa da meta
- Relatório - Período em andamento comparado com os mesmos dias do período anterior e cartões ajustados para fonte ampliada
- Modo Camuflagem - Ajustes no layout da calculadora
- Metas - Limite da meta de drinques por semana de 0 a 100
- Repositório - Pasta tmp ignorada pelo Git
## (23/11/2026)

### Adicionado
- Semana 4 - Estabilização e entrega
- Modo consulta - Tela para o profissional de saúde
- Orientação médica - Quando procurar o médico
- Risco alto - Filtro amarelado de icterícia
- Documentação - Uso de IA com a justificativa das bibliotecas, justificativas, arquitetura do sistema, requisitos e versão final do diagrama de classes
- Fluxo de navegação - Fluxo real com capturas de tela
- Apresentação - Slides da Unidade II e vídeo de demonstração
- APK de release
- Readme atualizado

### Alterado
- Telas - Ajustes para ficar fiel ao protótipo de alta fidelidade
- Acessibilidade - Revisão de rótulos para leitor de tela e tamanho de fonte

### Corrigido
- Correções de Exames, Relatório, PDF, Drinks, banco local, camuflagem, metas, notificações, Início, login e anonimização


## (18/11/2026) — Revisão da navegação e privacidade

### Corrigido
- Camuflagem fecha rotas sensíveis ao bloquear e retorna a Drinks após o código válido.
- Porcentagem relativa da calculadora funciona dentro de parênteses ainda abertos.
- Teste de agendamento de lembretes fixa também o relógio do plugin, evitando falhas conforme a data da execução.

### Adicionado
- Filtro amarelo ilustrativo no medidor em risco alto, preservando o selo vermelho e explicando o significado do efeito.
- Documento A9 com diagramas Mermaid e 15 capturas reproduzíveis por teste de navegação.
- Testes de regressão de bloqueio com rota aberta e do filtro nas faixas de risco.

### Verificado
- `flutter analyze` sem problemas; `flutter test`: 325 testes aprovados.
- Metas de 0–100 drinques por semana e regras de notificações conferidas. Testes nativos simulados não substituem validação em Android.
