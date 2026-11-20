import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/risk_level.dart';
import '../../domain/usecases/calculate_liver_health.dart';
import '../providers/liver_health_provider.dart';
import '../providers/risk_evolution_provider.dart';
import '../providers/risk_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';
import '../widgets/body_risk_figure.dart';
import '../widgets/content_width.dart';
import '../widgets/quick_drink_sheet.dart';
import '../widgets/risk_card.dart';
import '../widgets/risk_evolution_chart.dart';
import 'auth/account_screen.dart';
import 'medical_guidance_sheet.dart';

/// Tela Início: cartão de risco com o medidor e o botão + de registro rápido.
///
/// Os dados vêm do Riverpod: o último exame e o consumo das últimas 4 semanas.
final homeIntroProvider = Provider((ref) => HomeIntro());

final jaundiceNoticeDismissedProvider =
    NotifierProvider<JaundiceNoticeDismissed, bool>(
      JaundiceNoticeDismissed.new,
    );

class JaundiceNoticeDismissed extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

class HomeIntro {
  bool played = false;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const introDuration = Duration(milliseconds: 2000);
  static const loadTimeout = Duration(seconds: 3);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: HomeScreen.introDuration,
  );
  late final _reveal = CurvedAnimation(
    parent: _intro,
    curve: BodyRiskFigure.revealInterval,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final intro = ref.read(homeIntroProvider);
    if (intro.played || MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _startIntro();
    }
    intro.played = true;
  }

  Future<void> _startIntro() async {
    final health = ref.read(liverHealthProvider);
    final current = ref.read(currentRiskProvider);
    try {
      await BodyRiskFigure.precache(
        context,
        (current?.level ?? health.risk)?.color,
      ).timeout(HomeScreen.loadTimeout);
    } catch (_) {}
    if (mounted) _intro.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _skipIntro() {
    if (_intro.isAnimating) _intro.value = 1;
  }

  Widget _afterIntro(Widget child) => FadeTransition(
    opacity: _reveal,
    alwaysIncludeSemantics: true,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(liverHealthProvider);
    final current = ref.watch(currentRiskProvider);
    final jaundice = (current?.level ?? health.risk) == RiskLevel.high;

    final content = SafeArea(
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Entrar ou criar conta',
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => openAccount(context, ref),
              ),
            ),
            const SizedBox(height: 4),
            BodyRiskFigure(
              liverColor: (current?.level ?? health.risk)?.color,
              progress: _intro,
              child: RiskCard(health: health, current: current),
            ),
            const SizedBox(height: 16),
            _afterIntro(_ConsumptionCard(health: health)),
            const SizedBox(height: 16),
            _afterIntro(
              RiskEvolutionChart(points: ref.watch(riskEvolutionProvider)),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _skipIntro(),
        child: jaundice
            ? Stack(
                children: [
                  content,
                  Positioned.fill(child: _afterIntro(const JaundiceFilter())),
                  if (!ref.watch(jaundiceNoticeDismissedProvider))
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                          child: ContentWidth(
                            child: _afterIntro(
                              JaundiceNotice(
                                onClose: () => ref
                                    .read(
                                      jaundiceNoticeDismissedProvider.notifier,
                                    )
                                    .dismiss(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : content,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Registrar drinque',
        onPressed: () => showQuickDrinkSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class JaundiceFilter extends StatelessWidget {
  const JaundiceFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.4,
              colors: [
                AppColors.riskYellow.withValues(alpha: 0.16),
                AppColors.riskYellow.withValues(alpha: 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JaundiceNotice extends StatelessWidget {
  const JaundiceNotice({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Color.alphaBlend(
        AppColors.riskYellow.withValues(alpha: 0.16),
        AppColors.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.riskYellow.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showMedicalGuidance(context, currentRisk: RiskLevel.high),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: AppColors.riskYellow,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Por que a tela está amarelada?',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'O tom amarelo lembra a icterícia, quando a pele e os '
                      'olhos ficam amarelados por um problema no fígado. Ele '
                      'aparece porque o seu risco atual é alto. '
                      'Toque para ver quando procurar o médico.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fechar aviso',
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
        ),
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
