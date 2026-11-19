import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../camouflage/privacy_lock_pause.dart';
import '../pdf/health_summary_pdf.dart';
import '../providers/pdf_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum _PdfAction { preview, share }

class ExportSummaryCard extends ConsumerStatefulWidget {
  const ExportSummaryCard({super.key});

  @override
  ConsumerState<ExportSummaryCard> createState() => _ExportSummaryCardState();
}

class _ExportSummaryCardState extends ConsumerState<ExportSummaryCard> {
  _PdfAction? _running;

  Future<void> _run(_PdfAction action) async {
    if (_running != null) return;
    if (action == _PdfAction.share && !await _confirmShare()) return;
    if (!mounted) return;

    setState(() => _running = action);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final summary = ref.read(currentHealthSummaryProvider)();
      final bytes = await ref.read(healthSummaryPdfProvider)(summary);
      final output = ref.read(pdfOutputProvider);
      final name = HealthSummaryPdf.fileName(summary.generatedAt);
      await ref
          .read(privacyLockPauseProvider.notifier)
          .during(
            () => action == _PdfAction.preview
                ? output.preview(bytes, name)
                : output.share(bytes, name),
          );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar o PDF.')),
      );
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<bool> _confirmShare() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartilhar o resumo?'),
        content: const Text(
          'O PDF contém seus exames e seu consumo de álcool. '
          'Compartilhe apenas com quem você confia, como o seu médico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined, color: AppColors.olive),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Resumo em PDF', style: AppTextStyles.subtitle),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'FIB-4, classificação de risco, evolução dos exames, consumo do '
              'período selecionado e metas, para levar à consulta.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _running == null
                      ? () => _run(_PdfAction.preview)
                      : null,
                  icon: _icon(_PdfAction.preview, Icons.visibility_outlined),
                  label: const Text('Visualizar / salvar'),
                ),
                FilledButton.icon(
                  onPressed: _running == null
                      ? () => _run(_PdfAction.share)
                      : null,
                  icon: _icon(_PdfAction.share, Icons.share_outlined),
                  label: const Text('Compartilhar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(_PdfAction action, IconData icon) {
    if (_running != action) return Icon(icon);
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
