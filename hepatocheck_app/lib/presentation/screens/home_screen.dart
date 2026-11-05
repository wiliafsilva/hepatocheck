import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../widgets/risk_card.dart';

/// Tela Início: cartão de risco com o medidor e o botão + de registro rápido.
///
/// Valores fixos do protótipo (idade 45, FIB-4 1,45, risco amarelo) até a
/// ligação com os exames e o diário na Sprint 2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          children: const [
            Text('Seu fígado, sob controle.', style: AppTextStyles.title),
            SizedBox(height: 4),
            Text(
              'Resumo do seu risco hepático',
              style: AppTextStyles.body,
            ),
            SizedBox(height: 20),
            RiskCard(
              age: 45,
              fib4: '1,45',
              riskLabel: 'Risco amarelo',
              riskColor: RiskPalette.yellow,
              gaugeValue: 62,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Registrar drinque',
        // O registro rápido (até 3 toques) entra na Sprint 2 (tarefa 19).
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
