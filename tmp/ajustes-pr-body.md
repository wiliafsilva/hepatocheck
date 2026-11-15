Corrige a calculadora usada como disfarce do diário: a expressão completa agora respeita precedência, alterna parênteses com a tecla (), insere multiplicação implícita e fecha grupos ao pressionar =.

- Aplica AppColors e Inter/AppTextStyles, mostra expressão e resultado e mantém teclado uniforme no rodapé, com largura máxima de 440 e sem identidade visual do HepatoCheck.
- Restaura o desbloqueio na aba Drinks (índice 2).
- Limita metas a 0–100 drinques e testa os limites no formulário e no repositório.
- Usa compileSdk = maxOf(flutter.compileSdkVersion, 37).
- Atualiza testes de C, cores, operações e tela de 320x568 com fonte normal e em dobro.

Validação:
- flutter analyze: sem problemas.
- flutter test: suíte completa aprovada (255 testes).
- flutter build apk --debug: tentado, mas bloqueado neste ambiente por ausência do Android SDK (No Android SDK found). O build Android precisa ser confirmado em ambiente com SDK antes do merge.
