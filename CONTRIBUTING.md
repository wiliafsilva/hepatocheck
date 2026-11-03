# Como contribuir

Este é o fluxo de trabalho do grupo no repositório do HepatoCheck. Ele existe para que os cinco integrantes trabalhem ao mesmo tempo sem conflitos e para que cada commit fique registrado na conta de quem o fez.

## Antes de começar (uma vez só)

Confira se o e-mail do git é o mesmo cadastrado na sua conta do GitHub. Se não for, os seus commits não aparecem no seu perfil.

```powershell
git config user.email
```

Para corrigir:

```powershell
git config --global user.name "Seu Nome Completo"
git config --global user.email "email-da-sua-conta-do-github@exemplo.com"
```

## Regras

1. **Ninguém faz commit direto na `main`.** Todo código entra por pull request.
2. **Uma branch por tarefa**, sempre criada a partir da `main` atualizada.
3. **Cada um faz commit só do que fez**, com a própria conta.
4. **Antes de abrir o pull request**, `flutter analyze` e `flutter test` precisam passar sem erros.

## Passo a passo de cada tarefa

### 1. Atualizar a `main` e criar a branch

```powershell
git checkout main
git pull
git checkout -b feat/calculo-fib4
```

Nome da branch: `tipo/descricao-curta`, com os mesmos tipos usados nos commits.

### 2. Fazer os commits

```powershell
git add caminho/do/arquivo
git commit -m "feat: calcula escore FIB-4"
```

Tipos de commit:

| Tipo | Quando usar | Exemplo |
| --- | --- | --- |
| `feat` | Funcionalidade nova | `feat: adiciona tela de registro de drinques` |
| `fix` | Correção de erro | `fix: corrige validação de plaquetas acima de 1000` |
| `test` | Testes | `test: adiciona teste de falha parcial na sincronização` |
| `docs` | Documentação | `docs: adiciona diagrama de classes` |
| `refactor` | Mudança de código sem alterar o comportamento | `refactor: separa validação do FIB-4 em caso de uso` |

A mensagem diz **o que mudou**. Evite mensagens como "correção", "ajustes" ou "pdf".

Prefira `git add` com o caminho do arquivo em vez de `git add .`, para não enviar arquivos que não fazem parte da tarefa.

### 3. Conferir antes de enviar

```powershell
cd hepatochec_app
flutter analyze
flutter test
```

### 4. Enviar a branch

```powershell
git push -u origin feat/calculo-fib4
```

### 5. Abrir o pull request

1. No GitHub, abra um **Pull Request** da sua branch para a `main`.
2. No título, use o mesmo padrão dos commits.
3. Na descrição, diga o que foi feito e como testar.
4. Peça a revisão de outro integrante.

### 6. Juntar na `main`

Depois de aprovado, junte com **"Create a merge commit"**. Não use "Squash and merge": ele junta todos os commits em um só e pode apagar a autoria de cada integrante.

## Se a `main` mudou enquanto você trabalhava

Traga as mudanças da `main` para a sua branch antes de abrir o pull request:

```powershell
git checkout main
git pull
git checkout feat/calculo-fib4
git merge main
```

Se aparecer conflito, resolva nos arquivos indicados, rode `flutter analyze` de novo e faça o commit do merge. Na dúvida, peça ajuda ao grupo antes de apagar o trabalho de alguém.
