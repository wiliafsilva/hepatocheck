# Escopo do Projeto

Este documento define o que o HepatoCheck entrega na Unidade II, o que fica de fora e as restrições que o projeto precisa respeitar. Ele parte do estudo de caso, das personas, dos requisitos RF01–RF16 e RNF01–RNF17 e das exigências do aditivo da Unidade II.

## Objetivo

Oferecer um aplicativo mobile de prevenção da Doença Hepática Gordurosa Não Alcoólica (DHGNA) que permita ao usuário:

- estimar o risco de fibrose hepática pelo escore FIB-4, a partir de exames de sangue comuns;
- registrar o consumo de álcool e entender quanto bebe em drinques padrão;
- acompanhar o próprio risco em uma linguagem visual simples (Verde, Amarelo e Vermelho) e saber quando procurar um médico.

O HepatoCheck é uma ferramenta preventiva, educativa e de acompanhamento. Ele não faz diagnóstico nem substitui o acompanhamento profissional (RNF17).

## Público-alvo

Adultos de 30 a 60 anos. A persona prioritária é **Ricardo, 45 anos, "o Negado"**: baixou o app por indicação médica, tem pouca paciência e medo de se expor. A persona secundária é **Marisa, 52 anos, "a Preocupada"**, que já faz acompanhamento e quer monitorar a evolução. O profissional de saúde é um usuário indireto, que lê o resumo durante a consulta.

## O que está dentro do escopo

### Núcleo clínico

| Entrega | Requisitos |
| --- | --- |
| Cálculo do FIB-4 no próprio aparelho, com validação das entradas e aviso quando a idade está fora de 35 a 65 anos | RF01, RF02 |
| Classificação do risco em Verde, Amarelo e Vermelho a partir do FIB-4, subindo um nível quando o consumo semanal passa do limite definido pelo usuário | RF06 |
| Cadastro, consulta, edição e exclusão de exames, com histórico e recálculo automático do FIB-4 | CRUD de exames |
| Medidor de saúde do fígado de 0 a 100%, com a cor do risco | RF07 |
| Orientação sobre quando procurar o médico | RF14 |

### Diário de álcool

| Entrega | Requisitos |
| --- | --- |
| Registro por tipo de bebida, com volume e teor alcoólico | RF03 |
| Conversão automática em drinque padrão, mostrada antes da confirmação | RF04 |
| Registro rápido em até 3 toques | RF05, RNF11 |
| Registro de alterações do diário sem expor o conteúdo | Aditivo |
| Metas de redução e dias sem consumo, com feedback | RF15 |

### Privacidade e dados

| Entrega | Requisitos |
| --- | --- |
| Funcionamento 100% offline, com banco local Hive | RF10, RNF05, RNF13 |
| Criptografia AES dos registros locais e do banco inteiro com a camuflagem ativa | RNF03, RNF07, aditivo |
| Modo Camuflagem: o diário se disfarça de calculadora, com troca instantânea | RF09 |
| Modo convidado e login opcional com Firebase Authentication | RF08, RNF16 |
| Sincronização em lote com o Cloud Firestore só por Wi-Fi e com autorização, com anonimização e tratamento de falhas parciais | RF11, RNF08, RNF14, RNF15 |

### Acompanhamento

| Entrega | Requisitos |
| --- | --- |
| Relatórios semanais e mensais de consumo | Aditivo |
| Evolução do risco e dashboard dos exames | RF07, aditivo |
| Notificações educativas personalizadas e lembretes | RF13, aditivo |
| Modo consulta para o profissional de saúde | RF12 |
| Exportação do resumo em PDF | RF16 |

### Qualidade e documentação

- Arquitetura em camadas Presentation, Domain e Data, com estado gerenciado pelo Riverpod.
- No mínimo três testes automatizados (cálculo do FIB-4, validação das entradas e criptografia), além dos testes da sincronização.
- Diagramas de casos de uso e de classes, modelagem do Firestore, fluxo de navegação, EAP, planejamento em sprints e registro do uso de IA.

## O que está fora do escopo

- **Diagnóstico clínico.** O app mostra uma estimativa de risco com fins educativos e sempre orienta a procurar um profissional.
- **Outros escores e outras doenças hepáticas.** Apenas o FIB-4 é calculado. Escores como NAFLD Fibrosis Score, APRI ou elastografia não entram.
- **Integração com laboratórios, prontuários ou planos de saúde.** Os exames são digitados pelo próprio usuário.
- **Registro de alimentação, peso e atividade física.** O foco desta versão é o álcool e os exames.
- **Servidor próprio.** A nuvem se limita ao Firebase (Authentication e Cloud Firestore), sem backend próprio nem processamento no servidor.
- **iOS, Windows, macOS e Linux.** As plataformas suportadas são Android 8.0 ou superior e Web.
- **Comunicação entre usuários ou com profissionais pelo app.** O profissional só lê o modo consulta ou o PDF que o usuário escolher mostrar.
- **Notificações enviadas por servidor.** Todas as notificações são locais.

## Restrições

| Restrição | Impacto no projeto |
| --- | --- |
| Prazo: entrega em 27/11/2026, em 4 sprints semanais | Funcionalidades congeladas em 23/11. Se faltar tempo, os itens são cortados da prioridade mais baixa para a mais alta |
| Android 8.0 ou superior (RNF06, RNF12) | Pacotes e APIs precisam funcionar a partir da API 26 |
| 100% offline (RF10, RNF05) | Todos os dados ficam no aparelho. A nuvem é opcional |
| Privacidade e LGPD (RNF03, RNF15) | Nada é enviado sem autorização. A sincronização só acontece por Wi-Fi e com dados anonimizados |
| Até 3 interações nas funções principais (RNF11) | O registro de drinque cabe em 3 toques a partir da tela Início |
| Escopo clínico (RNF17) | Todas as telas de resultado avisam que o app não substitui avaliação médica |
| Equipe de 5 integrantes sem experiência prévia em Flutter | Divisão por semana, branches por tarefa e revisão por pull request |

## Premissas

- O usuário tem acesso aos próprios exames de sangue (TGO, TGP e plaquetas) e sabe digitar os valores do laudo.
- As plaquetas são informadas em ×10³/mm³ (equivalente a 10⁹/L). Se o valor parecer digitado em /mm³, o app sugere a conversão.
- Os cortes do FIB-4 seguem a literatura: abaixo de 1,30 (ou de 2,0 a partir de 65 anos), de 1,30 a 2,67 e acima de 2,67.
- O limite semanal de drinques que influencia a classificação é definido pelo próprio usuário nas metas de redução.
