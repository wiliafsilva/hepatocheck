import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/fib4_result.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/usecases/validate_exam_input.dart';
import '../formatters.dart';
import '../input/exam_number_input_formatter.dart';
import '../providers/exam_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';
import '../widgets/exam_history.dart';
import '../widgets/risk_badge.dart';
import '../widgets/section_label.dart';

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
  final _scrollController = ScrollController();

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
    _scrollController.dispose();
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
      _plateletsController.text = formatNumber(suggestion);
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
      _astController.text = formatNumber(exam.ast);
      _altController.text = formatNumber(exam.alt);
      _plateletsController.text = formatNumber(exam.platelets);
      _examDate = exam.examDate;
      _errors = const {};
      _plateletSuggestion = null;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _confirmDelete(LabExam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir exame?'),
        content: Text(
          'O exame de ${formatDate(exam.examDate)} e o resultado do '
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
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: SectionLabel(
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
          const SectionLabel('RESULTADO'),
          const SizedBox(height: 8),
          _ResultCard(result: result),
        ],
        const SizedBox(height: 24),
        SectionLabel(
          exams.isEmpty ? 'HISTÓRICO' : 'HISTÓRICO (${exams.length})',
        ),
        const SizedBox(height: 8),
        ExamHistory(
          exams: exams,
          calculate: calculate,
          summary: ref.watch(summarizeExamHistoryProvider)(
            exams,
            today: DateTime.now(),
          ),
          selectedId: _editing?.id,
          onEdit: _startEditing,
          onDelete: _confirmDelete,
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
                    maxIntegerDigits: 3,
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
                    maxIntegerDigits: 4,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'ALT / TGP',
                    controller: _altController,
                    suffix: 'U/L',
                    error: _errors[ExamField.alt],
                    maxIntegerDigits: 4,
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
              maxIntegerDigits: 6,
            ),
            if (_plateletSuggestion != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _applyPlateletSuggestion,
                  child: Text('Usar ${formatNumber(_plateletSuggestion!)}'),
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
              date == null ? 'Selecionar' : formatDate(date),
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
    required this.maxIntegerDigits,
    this.decimal = true,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;
  final String? error;
  final bool decimal;
  final int maxIntegerDigits;

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
          inputFormatters: [
            ExamNumberInputFormatter(
              decimal: decimal,
              maxIntegerDigits: maxIntegerDigits,
            ),
          ],
          style: AppTextStyles.body,
          decoration: _inputDecoration(error: error, suffix: suffix),
        ),
      ],
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
                RiskBadge(riskLevel: result.riskLevel),
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
