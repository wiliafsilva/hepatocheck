import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/drink_serving.dart';
import '../../domain/entities/drink_type.dart';
import '../providers/drink_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/drink_type_labels.dart';

Future<void> showQuickDrinkSheet(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => const QuickDrinkSheet(),
  );
  if (saved == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Registrado: $saved.')));
}

class QuickDrinkSheet extends ConsumerStatefulWidget {
  const QuickDrinkSheet({super.key});

  static const types = [DrinkType.beer, DrinkType.wine, DrinkType.spirit];

  @override
  ConsumerState<QuickDrinkSheet> createState() => _QuickDrinkSheetState();
}

class _QuickDrinkSheetState extends ConsumerState<QuickDrinkSheet> {
  DrinkType? _selected;
  bool _saving = false;
  bool _failed = false;

  String _conversionText(DrinkServing serving) {
    final standard = ref.read(convertToStandardDrinksProvider)(
      volumeMl: serving.volumeMl,
      alcoholPercent: serving.alcoholPercent,
    );
    final description = describeDrink(
      type: serving.type,
      volumeMl: serving.volumeMl,
      alcoholPercent: serving.alcoholPercent,
    );
    return '$description = ${formatStandardDrinks(standard)}';
  }

  Future<void> _add() async {
    final type = _selected;
    if (type == null) return;
    final serving = DrinkServing.defaultFor(type);
    final now = DateTime.now();
    final entry = DrinkEntry(
      id: const Uuid().v4(),
      type: type,
      volumeMl: serving.volumeMl,
      alcoholPercent: serving.alcoholPercent,
      quantity: 1,
      consumedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref.read(drinksProvider.notifier).save(entry);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(_conversionText(serving));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registro rápido', style: AppTextStyles.subtitle),
            const SizedBox(height: 4),
            const Text(
              'Escolha a bebida. Para outra quantidade ou horário, use a aba Drinks.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (index, type) in QuickDrinkSheet.types.indexed) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _TypeOption(
                      type: type,
                      selected: type == selected,
                      onTap: _saving
                          ? null
                          : () => setState(() => _selected = type),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              selected == null
                  ? 'Toque em uma bebida para ver quanto ela vale em drinques padrão.'
                  : _conversionText(DrinkServing.defaultFor(selected)),
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                'Não foi possível registrar. Tente novamente.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.riskRed),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: selected == null || _saving ? null : _add,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  foregroundColor: AppColors.onOlive,
                  textStyle: AppTextStyles.subtitle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Adicionar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final DrinkType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: type.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.olive.withValues(alpha: 0.15)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.olive : AppColors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type.icon,
                size: 28,
                color: selected ? AppColors.olive : AppColors.textPrimary,
              ),
              const SizedBox(height: 6),
              Text(
                type.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
