import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/fib4_result.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/usecases/validate_exam_input.dart';
import '../providers/exam_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

String formatScore(double score) =>
    score.toStringAsFixed(2).replaceAll('.', ',');

String _formatInput(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString().replaceAll('.', ',');
}

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  final _ageController = TextEditingController();
  final _astController = TextEditingController();
  final _altController = TextEditingController();
  final _plateletsController = TextEditingController();

  DateTime? _examDate = DateUtils.dateOnly(DateTime.now());
  LabExam? _editing;
  Map<ExamField, String> _errors = const {};
  double? _plateletSuggestion;
  Fib4Result? _lastResult;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_onAgeChanged);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _astController.dispose();
    _altController.dispose();
    _plateletsController.dispose();
    super.dispose();
  }

  void _onAgeChanged() => setState(() {});

  bool get _ageOutsideRange {
    final age = int.tryParse(_ageController.text.trim());
    return age != null && (age < 35 || age > 65);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Data do exame',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        _examDate = picked;
        _errors = Map.of(_errors)..remove(ExamField.examDate);
      });
    }
  }

  void _applyPlateletSuggestion() {
    final suggestion = _plateletSuggestion;
    if (suggestion == null) return;
    setState(() {
      _plateletsController.text = _formatInput(suggestion);
      _plateletSuggestion = null;
      _errors = Map.of(_errors)..remove(ExamField.platelets);
    });
  }

  Future<void> _save() async {
    final validation = ref.read(validateExamInputProvider)(
      age: _ageController.text,
      ast: _astController.text,
      alt: _altController.text,
      platelets: _plateletsController.text,
      examDate: _examDate,
    );

    setState(() {
      _errors = validation.errors;
      _plateletSuggestion = validation.plateletSuggestion;
    });
    if (!validation.isValid) return;

    final now = DateTime.now();
    final editing = _editing;
    final exam = editing == null
        ? LabExam(
            id: const Uuid().v4(),
            examDate: validation.examDate!,
            age: validation.age!,
            ast: validation.ast!,
            alt: validation.alt!,
            platelets: validation.platelets!,
            createdAt: now,
            updatedAt: now,
          )
        : editing.copyWith(
            examDate: validation.examDate,
            age: validation.age,
            ast: validation.ast,
            alt: validation.alt,
            platelets: validation.platelets,
            updatedAt: now,
          );

    setState(() => _saving = true);
    try {
      await ref.read(examsProvider.notifier).save(exam);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Não foi possível salvar o exame. Tente novamente.');
      return;
    }
    if (!mounted) return;

    setState(() {
      _saving = false;
      _lastResult = ref.read(calculateFib4Provider)(exam);
      _resetForm(keepAge: true);
    });
    _showMessage(editing == null ? 'Exame salvo.' : 'Exame atualizado.');
  }

  void _resetForm({bool keepAge = false}) {
    _editing = null;
    if (!keepAge) _ageController.clear();
    _astController.clear();
    _altController.clear();
    _plateletsController.clear();
    _examDate = DateUtils.dateOnly(DateTime.now());
    _errors = const {};
    _plateletSuggestion = null;
  }

  void _startEditing(LabExam exam) {
    setState(() {
      _editing = exam;
      _ageController.text = exam.age.toString();
      _astController.text = _formatInput(exam.ast);
      _altController.text = _formatInput(exam.alt);
      _plateletsController.text = _formatInput(exam.platelets);
      _examDate = exam.examDate;
      _errors = const {};
      _plateletSuggestion = null;
    });
  }

  Future<void> _confirmDelete(LabExam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir exame?'),
        content: Text(
          'O exame de ${_dateFormat.format(exam.examDate)} e o resultado do '
          'FIB-4 serão removidos do histórico.',
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
      await ref.read(examsProvider.notifier).delete(exam.id);
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível excluir o exame. Tente novamente.');
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      if (_editing?.id == exam.id) _resetForm(keepAge: true);
      if (_lastResult?.examId == exam.id) _lastResult = null;
    });
    _showMessage('Exame excluído.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(examsProvider);
    final calculate = ref.watch(calculateFib4Provider);
    final result =
        _lastResult ?? (exams.isEmpty ? null : calculate(exams.first));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionLabel(
                _editing == null ? 'NOVO EXAME' : 'EDITAR EXAME',
              ),
            ),
            if (_editing != null)
              TextButton(
                onPressed: () => setState(() => _resetForm(keepAge: true)),
                child: const Text('Cancelar edição'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildForm(),
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
            child: Text(
              _editing == null ? 'Calcular e salvar' : 'Salvar alterações',
            ),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 24),
          const _SectionLabel('RESULTADO'),
          const SizedBox(height: 8),
          _ResultCard(result: result),
        ],
        const SizedBox(height: 24),
        _SectionLabel(
          exams.isEmpty ? 'HISTÓRICO' : 'HISTÓRICO (${exams.length})',
        ),
        const SizedBox(height: 8),
        if (exams.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhum exame registrado ainda.',
              style: AppTextStyles.body,
            ),
          )
        else
          for (final (index, exam) in exams.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryTile(
                result: calculate(exam),
                previous: index + 1 < exams.length
                    ? calculate(exams[index + 1])
                    : null,
                exam: exam,
                selected: _editing?.id == exam.id,
                onTap: () => _startEditing(exam),
                onDelete: () => _confirmDelete(exam),
              ),
            ),
        const SizedBox(height: 8),
        const Text(
          'Triagem preventiva. Não substitui avaliação médica.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildForm() {
    final ageHintColor = _ageOutsideRange
        ? AppColors.riskYellow
        : AppColors.textSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Idade',
                    controller: _ageController,
                    suffix: 'anos',
                    error: _errors[ExamField.age],
                    decimal: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildDateField()),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info, size: 14, color: ageHintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'O FIB-4 é validado entre 35 e 65 anos.',
                    style: AppTextStyles.caption.copyWith(color: ageHintColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'AST / TGO',
                    controller: _astController,
                    suffix: 'U/L',
                    error: _errors[ExamField.ast],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'ALT / TGP',
                    controller: _altController,
                    suffix: 'U/L',
                    error: _errors[ExamField.alt],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _NumberField(
              label: 'Plaquetas',
              controller: _plateletsController,
              suffix: '×10³/mm³',
              error: _errors[ExamField.platelets],
            ),
            if (_plateletSuggestion != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _applyPlateletSuggestion,
                  child: Text('Usar ${_formatInput(_plateletSuggestion!)}'),
                ),
              ),
            const SizedBox(height: 6),
            const Text(
              'Valor típico de referência: 150 a 450',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final date = _examDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Data do exame', style: AppTextStyles.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _inputDecoration(
              error: _errors[ExamField.examDate],
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.olive,
                size: 20,
              ),
            ),
            child: Text(
              date == null ? 'Selecionar' : _dateFormat.format(date),
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
    this.decimal = true,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;
  final String? error;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textInputAction: TextInputAction.next,
          style: AppTextStyles.body,
          decoration: _inputDecoration(error: error, suffix: suffix),
        ),
      ],
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

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.result});

  final Fib4Result result;

  @override
  Widget build(BuildContext context) {
    final color = result.riskLevel.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(result.riskLevel.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            result.riskLevel.label.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final Fib4Result result;

  @override
  Widget build(BuildContext context) {
    final color = result.riskLevel.color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Resultado FIB-4', style: AppTextStyles.body),
                ),
                _RiskBadge(result: result),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatScore(result.score),
              style: AppTextStyles.display.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              result.riskLevel.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (result.ageOutsideValidatedRange) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.riskYellow,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'O FIB-4 não é validado para essa idade (35 a 65 anos). '
                      'Leia o resultado com cautela.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.riskYellow,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.exam,
    required this.result,
    required this.previous,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final LabExam exam;
  final Fib4Result result;
  final Fib4Result? previous;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = result.riskLevel.color;
    final previousScore = previous?.score;
    final delta = previousScore == null
        ? null
        : double.parse((result.score - previousScore).toStringAsFixed(2));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.olive : AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formatScore(result.score),
                  style: AppTextStyles.label.copyWith(color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateFormat.format(exam.examDate),
                      style: AppTextStyles.subtitle,
                    ),
                    Text.rich(
                      TextSpan(
                        text: 'Faixa: ',
                        style: AppTextStyles.caption,
                        children: [
                          TextSpan(
                            text: result.riskLevel.label,
                            style: AppTextStyles.caption.copyWith(color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (delta != null && delta != 0) _DeltaLabel(delta: delta),
              IconButton(
                tooltip: 'Excluir exame',
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

class _DeltaLabel extends StatelessWidget {
  const _DeltaLabel({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final improved = delta < 0;
    final color = improved ? AppColors.riskGreen : AppColors.riskRed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          improved ? Icons.arrow_downward : Icons.arrow_upward,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          formatScore(delta.abs()),
          style: AppTextStyles.caption.copyWith(color: color),
        ),
      ],
    );
  }
}
