import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/drink_serving.dart';
import '../../domain/entities/drink_type.dart';
import '../../domain/usecases/convert_to_standard_drinks.dart';
import '../../domain/usecases/validate_drink_input.dart';
import '../providers/drink_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/drink_type_labels.dart';

final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

class DrinksScreen extends ConsumerStatefulWidget {
  const DrinksScreen({super.key});

  @override
  ConsumerState<DrinksScreen> createState() => _DrinksScreenState();
}

class _DrinksScreenState extends ConsumerState<DrinksScreen> {
  final _scrollController = ScrollController();
  final _volumeController = TextEditingController();
  final _alcoholController = TextEditingController();

  DrinkType _type = DrinkType.beer;
  int _quantity = 1;
  DateTime _consumedAt = DateTime.now();
  DrinkEntry? _editing;
  Map<DrinkField, String> _errors = const {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyServing(DrinkServing.defaultFor(_type));
    _volumeController.addListener(_onChanged);
    _alcoholController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _volumeController.dispose();
    _alcoholController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  DrinkServing? get _currentServing {
    final volume = _parse(_volumeController);
    final alcohol = _parse(_alcoholController);
    if (volume == null || alcohol == null) return null;
    final serving = DrinkServing.matching(_type, volume);
    return serving != null && serving.alcoholPercent == alcohol
        ? serving
        : null;
  }

  void _applyServing(DrinkServing serving) {
    _volumeController.text = formatDecimal(serving.volumeMl);
    _alcoholController.text = formatDecimal(serving.alcoholPercent);
  }

  void _selectType(DrinkType type) {
    setState(() {
      _type = type;
      _applyServing(DrinkServing.defaultFor(type));
      _errors = const {};
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _consumedAt,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Data do consumo',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_consumedAt),
      helpText: 'Horário do consumo',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (time == null) return;
    setState(() {
      _consumedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _errors = Map.of(_errors)..remove(DrinkField.consumedAt);
    });
  }

  Future<void> _save() async {
    final validation = ref.read(validateDrinkInputProvider)(
      volume: _volumeController.text,
      alcohol: _alcoholController.text,
      quantity: _quantity,
      consumedAt: _consumedAt,
    );
    setState(() => _errors = validation.errors);
    if (!validation.isValid) return;

    final now = DateTime.now();
    final editing = _editing;
    final entry = editing == null
        ? DrinkEntry(
            id: const Uuid().v4(),
            type: _type,
            volumeMl: validation.volumeMl!,
            alcoholPercent: validation.alcoholPercent!,
            quantity: validation.quantity!,
            consumedAt: validation.consumedAt!,
            createdAt: now,
            updatedAt: now,
          )
        : editing.copyWith(
            type: _type,
            volumeMl: validation.volumeMl,
            alcoholPercent: validation.alcoholPercent,
            quantity: validation.quantity,
            consumedAt: validation.consumedAt,
            updatedAt: now,
          );

    setState(() => _saving = true);
    try {
      await ref.read(drinksProvider.notifier).save(entry);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Não foi possível salvar o registro. Tente novamente.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _resetForm();
    });
    _showMessage(editing == null ? 'Registro salvo.' : 'Registro atualizado.');
  }

  void _resetForm() {
    _editing = null;
    _type = DrinkType.beer;
    _applyServing(DrinkServing.defaultFor(_type));
    _quantity = 1;
    _consumedAt = DateTime.now();
    _errors = const {};
  }

  void _startEditing(DrinkEntry entry) {
    setState(() {
      _editing = entry;
      _type = entry.type;
      _volumeController.text = formatDecimal(entry.volumeMl);
      _alcoholController.text = formatDecimal(entry.alcoholPercent);
      _quantity = entry.quantity;
      _consumedAt = entry.consumedAt;
      _errors = const {};
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmDelete(DrinkEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text(
          'O registro de ${_dateTimeFormat.format(entry.consumedAt)} será '
          'removido do histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.riskRed),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(drinksProvider.notifier).delete(entry.id);
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível excluir o registro. Tente novamente.');
      }
      return;
    }
    if (!mounted) return;
    if (_editing?.id == entry.id) setState(_resetForm);
    _showMessage('Registro excluído.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _conversionText(ConvertToStandardDrinks convert) {
    final volume = _parse(_volumeController);
    final alcohol = _parse(_alcoholController);
    if (volume == null || alcohol == null || volume <= 0 || alcohol <= 0) {
      return 'Informe o volume e o teor para ver a conversão.';
    }
    final standard = convert(
      volumeMl: volume,
      alcoholPercent: alcohol,
      quantity: _quantity,
    );
    final description = describeDrink(
      type: _type,
      volumeMl: volume,
      alcoholPercent: alcohol,
      quantity: _quantity,
    );
    return '$description = ${formatStandardDrinks(standard)}';
  }

  @override
  Widget build(BuildContext context) {
    final drinks = ref.watch(drinksProvider);
    final convert = ref.watch(convertToStandardDrinksProvider);
    final today = DateUtils.dateOnly(DateTime.now());
    final todayTotal = convert.total(
      drinks.where((entry) => DateUtils.isSameDay(entry.consumedAt, today)),
    );

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionLabel(
                _editing == null ? 'NOVO REGISTRO' : 'EDITAR REGISTRO',
              ),
            ),
            if (_editing != null)
              TextButton(
                onPressed: () => setState(_resetForm),
                child: const Text('Cancelar edição'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildForm(convert),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: AppColors.onOlive,
              textStyle: AppTextStyles.subtitle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(_editing == null ? 'Adicionar' : 'Salvar alterações'),
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel(
          drinks.isEmpty ? 'HISTÓRICO' : 'HISTÓRICO (${drinks.length})',
        ),
        const SizedBox(height: 4),
        Text(
          'Hoje: ${formatStandardDrinks(todayTotal)}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 8),
        if (drinks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhum drinque registrado ainda.',
              style: AppTextStyles.body,
            ),
          )
        else
          for (final entry in drinks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryTile(
                entry: entry,
                standardDrinks: convert.ofEntry(entry),
                selected: _editing?.id == entry.id,
                onTap: () => _startEditing(entry),
                onDelete: () => _confirmDelete(entry),
              ),
            ),
        const SizedBox(height: 8),
        const Text(
          'Um drinque padrão equivale a 14 g de álcool puro.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildForm(ConvertToStandardDrinks convert) {
    final currentServing = _currentServing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de bebida', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in DrinkType.values)
                  _OptionChip(
                    label: type.label,
                    icon: type.icon,
                    selected: type == _type,
                    onTap: () => _selectType(type),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Porção', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final serving in DrinkServing.forType(_type))
                  _OptionChip(
                    label:
                        '${serving.name} ${formatDecimal(serving.volumeMl)} ml',
                    selected: serving == currentServing,
                    onTap: () => setState(() => _applyServing(serving)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Volume',
                    controller: _volumeController,
                    suffix: 'ml',
                    error: _errors[DrinkField.volume],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'Teor alcoólico',
                    controller: _alcoholController,
                    suffix: '%',
                    error: _errors[DrinkField.alcohol],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildQuantity()),
                const SizedBox(width: 12),
                Expanded(child: _buildDateTimeField()),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.olive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.oliveDark),
              ),
              child: Text(
                _conversionText(convert),
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantidade', style: AppTextStyles.label),
        const SizedBox(height: 6),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Diminuir quantidade',
              onPressed: _quantity > ValidateDrinkInput.minQuantity
                  ? () => setState(() => _quantity--)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                '$_quantity',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Aumentar quantidade',
              onPressed: _quantity < ValidateDrinkInput.maxQuantity
                  ? () => setState(() => _quantity++)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (_errors[DrinkField.quantity] case final error?)
          Text(
            error,
            style: AppTextStyles.caption.copyWith(color: AppColors.riskRed),
          ),
      ],
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Data e hora', style: AppTextStyles.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDateTime,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _inputDecoration(
              error: _errors[DrinkField.consumedAt],
              suffixIcon: const Icon(
                Icons.schedule,
                color: AppColors.olive,
                size: 20,
              ),
            ),
            child: Text(
              _dateTimeFormat.format(_consumedAt),
              style: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration({
  String? error,
  String? suffix,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  return InputDecoration(
    filled: true,
    fillColor: AppColors.surfaceVariant,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    suffixText: suffix,
    suffixStyle: AppTextStyles.caption,
    suffixIcon: suffixIcon,
    errorText: error,
    errorMaxLines: 3,
    enabledBorder: border(AppColors.outline),
    focusedBorder: border(AppColors.olive),
    errorBorder: border(AppColors.riskRed),
    focusedErrorBorder: border(AppColors.riskRed),
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.error,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          style: AppTextStyles.body,
          decoration: _inputDecoration(error: error, suffix: suffix),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
              color: selected ? AppColors.onOlive : AppColors.textPrimary,
            ),
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.olive,
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: AppTextStyles.label.copyWith(
        color: selected ? AppColors.onOlive : AppColors.textPrimary,
      ),
      side: BorderSide(color: selected ? AppColors.olive : AppColors.outline),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.standardDrinks,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final DrinkEntry entry;
  final double standardDrinks;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.olive : AppColors.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Icon(entry.type.icon, color: AppColors.olive),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      describeDrink(
                        type: entry.type,
                        volumeMl: entry.volumeMl,
                        alcoholPercent: entry.alcoholPercent,
                        quantity: entry.quantity,
                      ),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_dateTimeFormat.format(entry.consumedAt)} · '
                      '${formatStandardDrinks(standardDrinks)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir registro',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.riskRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
