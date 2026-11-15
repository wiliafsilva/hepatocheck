import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/reduction_goal.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/usecases/evaluate_goal.dart';
import '../providers/drink_providers.dart';
import '../providers/goal_providers.dart';

String goalTitle(ReductionGoal goal) => goal.type == GoalType.maxDrinksPerWeek
    ? 'Até ${goal.target} drinques padrão por semana'
    : '${goal.target} dias sem consumo por semana';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.progress});
  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final goal = progress.goal;
    final color = switch (progress.status) {
      GoalStatus.achieved => Colors.green,
      GoalStatus.nearLimit => Colors.amber,
      GoalStatus.exceeded => Colors.redAccent,
      _ => Theme.of(context).colorScheme.primary,
    };
    final format = DateFormat('dd/MM');
    final value = goal.type == GoalType.maxDrinksPerWeek
        ? progress.value.toStringAsFixed(1).replaceAll('.', ',')
        : progress.value.toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goalTitle(goal),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Semana de ${format.format(progress.week.start)} a ${format.format(progress.week.lastDay)}',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.fraction,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '$value de ${goal.target} ${goal.type == GoalType.maxDrinksPerWeek ? 'drinques padrão' : 'dias'}',
            ),
            const SizedBox(height: 6),
            Text(progress.feedback, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

class GoalReportSection extends ConsumerWidget {
  const GoalReportSection({super.key, required this.period});
  final ReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final drinks = ref.watch(drinksProvider);
    final now = ref.watch(followUpNowProvider);
    final progress = <GoalProgress>[];
    var week = ReportPeriod.containing(period.start, ReportPeriodType.week);
    while (week.start.isBefore(period.end)) {
      for (final goal in goals.where(
        (goal) => goal.active && goalApplies(goal, week),
      )) {
        progress.add(const EvaluateGoal()(goal, drinks, week, now));
      }
      week = week.next;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Metas de redução',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
              ),
              child: const Text('Gerenciar'),
            ),
          ],
        ),
        const Text(
          'Metas de segunda a domingo. Dias sem consumo consideram apenas dias encerrados sem registro de bebida. Mantenha o diário atualizado.',
        ),
        if (period.type == ReportPeriodType.month)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Cada meta mostra a semana completa, inclusive dias fora do mês selecionado.',
            ),
          ),
        if (progress.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhuma meta para este período.'),
          ),
        for (final item in progress) GoalProgressCard(progress: item),
      ],
    );
  }
}

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ReductionGoal goal,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir meta?'),
        content: Text(goalTitle(goal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(goalsProvider.notifier).delete(goal.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir a meta.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final drinks = ref.watch(drinksProvider);
    final now = ref.watch(followUpNowProvider);
    final week = ReportPeriod.containing(now, ReportPeriodType.week);
    return Scaffold(
      appBar: AppBar(title: const Text('Metas de redução')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const GoalFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Criar meta'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'Defina seu objetivo pessoal e acompanhe a semana. O limite escolhido é uma meta pessoal de redução.',
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty) const Text('Você ainda não criou uma meta.'),
          for (final goal in goals) ...[
            if (goalApplies(goal, week))
              GoalProgressCard(
                progress: const EvaluateGoal()(goal, drinks, week, now),
              )
            else
              Card(
                child: ListTile(
                  title: Text(goalTitle(goal)),
                  subtitle: Text(
                    'Início em ${DateFormat('dd/MM/yyyy').format(goal.startDate)}',
                  ),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GoalFormScreen(goal: goal),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _delete(context, ref, goal),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ],
            ),
          ],
          const Text(
            'Dias sem registros não comprovam ausência de consumo. Confira seu diário antes de interpretar o progresso.',
          ),
        ],
      ),
    );
  }
}

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goal});
  final ReductionGoal? goal;
  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _target = TextEditingController(
    text: widget.goal?.target.toString() ?? '',
  );
  late GoalType _type = widget.goal?.type ?? GoalType.maxDrinksPerWeek;
  late DateTime _start =
      widget.goal?.startDate ??
      ReportPeriod.containing(DateTime.now(), ReportPeriodType.week).start;
  bool _saving = false;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  String? get _targetError {
    final target = int.tryParse(_target.text);
    if (target == null || target < 0 || target > 1000) {
      return 'Informe um número de 0 a 1000.';
    }
    if (_type == GoalType.alcoholFreeDaysPerWeek &&
        (target < 1 || target > 7)) {
      return 'Escolha de 1 a 7 dias.';
    }
    return null;
  }

  Future<void> _save() async {
    final error = _targetError;
    if (!_form.currentState!.validate() || error != null) {
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.goal;
    final goal = ReductionGoal(
      id: old?.id ?? const Uuid().v4(),
      type: _type,
      target: int.parse(_target.text),
      startDate: _start,
      endDate: old?.endDate,
      active: old?.active ?? true,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await ref.read(goalsProvider.notifier).save(goal);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a meta. Tente novamente.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.goal == null ? 'Criar meta' : 'Editar meta'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<GoalType>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo de meta'),
            items: const [
              DropdownMenuItem(
                value: GoalType.maxDrinksPerWeek,
                child: Text('Limite semanal de drinques'),
              ),
              DropdownMenuItem(
                value: GoalType.alcoholFreeDaysPerWeek,
                child: Text('Dias sem consumo na semana'),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _type = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _target,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _type == GoalType.maxDrinksPerWeek
                  ? 'Máximo de drinques padrão'
                  : 'Dias sem consumo (1 a 7)',
            ),
            validator: (_) => _targetError,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: const Text('Semana de início'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_start)),
            onTap: _saving
                ? null
                : () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _start,
                      firstDate:
                          widget.goal?.startDate ??
                          ReportPeriod.containing(
                            DateTime.now(),
                            ReportPeriodType.week,
                          ).start,
                      lastDate: DateTime(DateTime.now().year + 5),
                    );
                    if (date != null) {
                      setState(
                        () => _start = ReportPeriod.containing(
                          date,
                          ReportPeriodType.week,
                        ).start,
                      );
                    }
                  },
          ),
          const Text(
            'A data selecionada usa a segunda-feira da mesma semana. O acompanhamento vai até domingo.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Salvando...' : 'Salvar meta'),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}
