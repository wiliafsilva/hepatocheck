# Arquitetura do Sistema — HepatoCheck

## Visão Geral

O **HepatoCheck** adota uma arquitetura **mobile offline-first**, na qual as principais funcionalidades do aplicativo continuam disponíveis mesmo sem conexão com a internet.

Os dados de consumo de álcool, exames laboratoriais, resultados do FIB-4, metas e preferências são armazenados primeiro no próprio dispositivo. A sincronização com o **Firebase** ocorre posteriormente, somente quando autorizada pelo usuário e quando houver conexão adequada, priorizando Wi-Fi.

A arquitetura foi pensada para manter o aplicativo simples, modular, seguro e independente de conexão constante com a internet.

---

## Visão Geral da Arquitetura

```text
┌─────────────────────────────────────┐
│          Interface Mobile           │
│                                     │
│ Home │ Drinks │ Exames │ Médico     │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│       Regras e Serviços do App      │
│                                     │
│ • Cálculo do FIB-4                  │
│ • Conversão de drinques             │
│ • Classificação de risco            │
│ • Metas e lembretes                 │
│ • Geração dos indicadores           │
│ • Validação dos dados               │
└──────────────────┬──────────────────┘
                   │
          ┌────────┴────────┐
          ▼                 ▼
┌─────────────────┐  ┌──────────────────┐
│ Banco de Dados  │  │ Serviço de       │
│ Local           │  │ Sincronização    │
│                 │  │                  │
│ Offline-first   │  │ Wi-Fi + opt-in   │
└────────┬────────┘  └─────────┬────────┘
         │                     │
         │                     ▼
         │             ┌────────────────┐
         │             │    Firebase    │
         │             │     Nuvem      │
         │             └────────────────┘
         │
         └── Fonte principal dos dados
             durante o uso do aplicativo
```

---

## Principais Componentes

### 1. Interface Mobile

Responsável pela interação entre o usuário e o sistema.

A interface é organizada principalmente nas seguintes telas:

- **Home**
- **Cadastro de Drinks**
- **Cadastro de Exames**
- **Quando Procurar o Médico**

A navegação principal utiliza uma barra inferior e um botão flutuante para facilitar o registro rápido.

---

### 2. Módulo de Drinks

Responsável pelo registro do consumo de bebidas alcoólicas.

Suas principais funções são:

- Registrar o tipo de bebida;
- Registrar a quantidade consumida;
- Registrar data e hora;
- Converter automaticamente o consumo para **drinques padrão**;
- Consultar o histórico de consumo;
- Atualizar registros;
- Excluir registros;
- Recalcular indicadores após alterações.

A conversão para drinques padrão deve ser apresentada antes da confirmação do registro.

---

### 3. Módulo de Exames e FIB-4

Responsável pelo cadastro dos exames laboratoriais e pelo cálculo do escore **FIB-4**.

Os principais dados utilizados são:

- Idade;
- AST/TGO;
- ALT/TGP;
- Plaquetas;
- Data do exame.

O sistema calcula automaticamente o FIB-4 e armazena o resultado no histórico.

Quando os dados de um exame forem modificados, o FIB-4 deve ser recalculado automaticamente, evitando que o usuário altere diretamente o resultado calculado.

---

### 4. Módulo de Classificação de Risco

Responsável por transformar os dados coletados em informações de fácil compreensão.

O sistema utiliza os dados de exames e do diário de consumo para gerar uma classificação de risco representada por:

- **Verde** — baixo risco;
- **Amarelo** — risco intermediário;
- **Vermelho** — alto risco.

Esse módulo também alimenta o indicador visual de saúde hepática apresentado na tela principal.

---

### 5. Armazenamento Local

O aplicativo deve armazenar os dados essenciais diretamente no dispositivo.

Esse componente permite que o usuário continue utilizando o aplicativo mesmo sem conexão com a internet.

Entre os dados armazenados localmente estão:

- Registros de bebidas;
- Exames laboratoriais;
- Resultados do FIB-4;
- Histórico;
- Metas;
- Preferências;
- Configurações de privacidade;
- Estado da sincronização.

O armazenamento local é a principal fonte de dados durante o uso normal do aplicativo.

---

### 6. Serviço de Sincronização

Responsável pela comunicação entre o armazenamento local e o Firebase.

A sincronização deve ocorrer apenas quando:

1. O usuário autorizar explicitamente;
2. Houver conexão disponível;
3. Preferencialmente o dispositivo estiver conectado a uma rede Wi-Fi.

O aplicativo não deve depender da sincronização para funcionar.

---

### 7. Firebase

O **Firebase** representa o serviço em nuvem utilizado para sincronização dos dados.

Sua função é permitir que dados locais autorizados pelo usuário possam ser enviados e recuperados posteriormente.

O Firebase não deve ser considerado a fonte principal de dados durante o funcionamento do aplicativo, pois o HepatoCheck possui funcionamento **offline-first**.

---

### 8. Módulo de Privacidade

Responsável por controlar funcionalidades relacionadas à proteção das informações do usuário.

Entre suas responsabilidades estão:

- Modo convidado;
- Controle da autorização de sincronização;
- Modo camuflagem;
- Preferências de privacidade;
- Controle dos dados armazenados;
- Exclusão de informações locais;
- Proteção de informações sensíveis em notificações.

Esse módulo é especialmente importante porque o aplicativo trabalha com informações relacionadas à saúde e ao consumo de álcool.

---

### 9. Módulo de Metas e Lembretes

Responsável por funcionalidades de acompanhamento do usuário.

Pode incluir:

- Metas de redução do consumo;
- Dias sem consumo;
- Lembretes para registro de bebidas;
- Lembretes para novos exames;
- Feedback relacionado ao progresso das metas.

Essas funcionalidades utilizam os dados armazenados localmente.

---

### 10. Módulo de Orientação

Responsável pela tela **Quando Procurar o Médico**.

O módulo apresenta informações educativas de acordo com a faixa de risco identificada.

As orientações devem explicar:

- O que a faixa de risco significa;
- O que o usuário pode fazer;
- Quando procurar um profissional;
- Quando realizar nova avaliação.

O HepatoCheck deve funcionar como uma ferramenta de **triagem, prevenção, educação e acompanhamento**, não como substituto de diagnóstico ou avaliação profissional.

## Funcionamento Offline-First

O funcionamento offline-first segue a seguinte lógica:

```text
Usuário registra informação
          │
          ▼
Aplicativo valida os dados
          │
          ▼
Dados são salvos localmente
          │
          ▼
Interface é atualizada
          │
          ▼
Existe autorização para sincronizar?
          │
     ┌────┴────┐
     │         │
    Não       Sim
     │         │
     ▼         ▼
 Mantém     Verifica
 local      conexão
               │
               ▼
          Sincroniza
          com Firebase
```

Dessa forma, uma falha de conexão não impede o funcionamento das funcionalidades essenciais.