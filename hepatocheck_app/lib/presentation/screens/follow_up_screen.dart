import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/follow_up_settings.dart';
import '../providers/goal_providers.dart';
import '../providers/exam_providers.dart';

class FollowUpScreen extends ConsumerStatefulWidget {
  const FollowUpScreen({super.key});
  @override
  ConsumerState<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends ConsumerState<FollowUpScreen> {
  late final _initial = ref.read(followUpSettingsProvider);
  late bool _education = _initial.education;
  late bool _registration = _initial.registration;
  late bool _exam = _initial.exam;
  late TimeOfDay _time = TimeOfDay(
    hour: _initial.hour,
    minute: _initial.minute,
  );
  late DateTime? _examDate = _initial.examDate;
  bool _saving = false;
  final _form = GlobalKey<FormState>();
  late final _low = TextEditingController(
    text: _initial.lowRiskMonths?.toString() ?? '',
  );
  late final _intermediate = TextEditingController(
    text: _initial.intermediateRiskMonths?.toString() ?? '',
  );
  late final _high = TextEditingController(
    text: _initial.highRiskMonths?.toString() ?? '',
  );

  @override
  void dispose() {
    _low.dispose();
    _intermediate.dispose();
    _high.dispose();
    super.dispose();
  }

  Widget _intervalField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextFormField(
          controller: controller,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, suffixText: 'meses'),
          validator: (text) {
            if (text == null || text.isEmpty) return null;
            final months = int.tryParse(text);
            return months == null || months < 1 || months > 120
                ? 'Informe de 1 a 120 meses.'
                : null;
          },
        ),
      );

  Future<void> _save() async {
    final invalid = [_low, _intermediate, _high].any((controller) {
      if (controller.text.isEmpty) return false;
      final value = int.tryParse(controller.text);
      return value == null || value < 1 || value > 120;
    });
    if (!_form.currentState!.validate() || invalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe intervalos entre 1 e 120 meses ou deixe o campo vazio.',
          ),
        ),
      );
      return;
    }
    final date = _examDate;
    final examTime = date == null
        ? null
        : DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
    final settings = FollowUpSettings(
      education: _education,
      registration: _registration,
      exam: _exam,
      hour: _time.hour,
      minute: _time.minute,
      examDate: examTime,
      lowRiskMonths: int.tryParse(_low.text),
      intermediateRiskMonths: int.tryParse(_intermediate.text),
      highRiskMonths: int.tryParse(_high.text),
    );
    if (_exam && nextExamDate(settings, ref.read(examsProvider)) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escolha uma data ou configure o intervalo da sua faixa de risco com um exame cadastrado.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(localFollowUpProvider);
      var permitted = true;
      if ((_education || _registration || _exam) && service.supported) {
        permitted = await service.requestPermission();
      }
      await ref.read(followUpSettingsProvider.notifier).save(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              permitted ? 'Preferências salvas.' : 'Preferências salvas. Autorize as notificações nas configurações do aparelho.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar ou solicitar a permissão. Tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(followUpMessagesProvider);
    final status = ref.watch(notificationStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações e lembretes')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Seu acompanhamento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            for (final message in messages)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tips_and_updates_outlined),
                  title: Text(message.title),
                  subtitle: Text(message.body),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Os avisos são locais e funcionam sem internet após serem configurados. Com a camuflagem ativa, o conteúdo fica discreto.',
            ),
            if (status != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(status),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mensagens educativas e feedback de metas'),
              subtitle: const Text(
                'Uma dica por dia e avisos quando a situação da meta mudar.',
              ),
              value: _education,
              onChanged: _saving ? null : (v) => setState(() => _education = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembrete de registro'),
              subtitle: const Text(
                'Um aviso após três dias sem registro. A programação é renovada ao usar o aplicativo.',
              ),
              value: _registration,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _registration = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembrete de exame'),
              subtitle: const Text(
                'Escolha a data combinada com seu profissional de saúde.',
              ),
              value: _exam,
              onChanged: _saving ? null : (v) => setState(() => _exam = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Data do exame'),
              subtitle: Text(
                _examDate == null
                    ? 'Selecionar data'
                    : DateFormat('dd/MM/yyyy').format(_examDate!),
              ),
              onTap: _saving
                  ? null
                  : () async {
                      final today = DateUtils.dateOnly(DateTime.now());
                      final initial =
                          _examDate == null || _examDate!.isBefore(today)
                          ? today
                          : _examDate!;
                      final date = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: today,
                        lastDate: DateTime(today.year + 10),
                      );
                      if (date != null && mounted) {
                        setState(() => _examDate = date);
                      }
                    },
            ),
            if (_examDate != null)
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _examDate = null),
                child: const Text('Usar intervalo por faixa de risco'),
              ),
            const SizedBox(height: 12),
            const Text('Intervalos de exame orientados pelo profissional'),
            const Text(
              'Preencha somente os prazos que foram orientados. A data escolhida acima tem prioridade. Sem data manual, a faixa do FIB-4 determina qual intervalo usar.',
            ),
            _intervalField('Risco baixo', _low),
            _intervalField('Risco intermediário', _intermediate),
            _intervalField('Risco alto', _high),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horário dos avisos'),
              subtitle: Text(_time.format(context)),
              onTap: _saving
                  ? null
                  : () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (time != null && mounted) setState(() => _time = time);
                    },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvando...' : 'Salvar preferências'),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Android, a economia de bateria pode atrasar os avisos. Datas vencidas geram um aviso no próximo horário configurado. Um novo exame atualiza o prazo quando você usa intervalos por faixa.',
            ),
          ],
        ),
      ),
    );
  }
}
