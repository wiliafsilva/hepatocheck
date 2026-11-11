import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/calculate_liver_health.dart';
import '../providers/liver_health_provider.dart';
import '../theme/app_text_styles.dart';
import '../widgets/risk_card.dart';
import 'auth/login_screen.dart';
import '../widgets/content_width.dart';

/// Tela Início: cartão de risco com o medidor e o botão + de registro rápido.
///
/// Os dados vêm do Riverpod: o último exame e o consumo das últimas 4 semanas.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(liverHealthProvider);

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Entrar ou criar conta',
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                ),
              ),
              const Text(
                'Seu fígado, sob controle.',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 4),
              const Text(
                'Resumo do seu risco hepático',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              RiskCard(health: health),
              const SizedBox(height: 16),
              _ConsumptionCard(health: health),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Registrar drinque',
        // O registro rápido (até 3 toques) é a tarefa 19 (Drinks).
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ConsumptionCard extends StatelessWidget {
  const _ConsumptionCard({required this.health});

  final LiverHealth health;

  @override
  Widget build(BuildContext context) {
    final average = health.weeklyAverage
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    final limit = CalculateLiverHealth.weeklyLowRiskLimit.toStringAsFixed(0);
    final over = health.consumptionPenalty > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumo das últimas 4 semanas',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Média de $average drinques padrão por semana',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 4),
            Text(
              over
                  ? 'Acima do limite de baixo risco ($limit por semana): '
                        'isso reduz o medidor do fígado.'
                  : 'Dentro do limite de baixo risco ($limit por semana).',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
