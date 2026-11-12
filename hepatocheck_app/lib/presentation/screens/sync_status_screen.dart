import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sync_item.dart';
import '../../domain/usecases/sync_pending_items.dart';
import '../providers/sync_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/content_width.dart';
import '../widgets/section_label.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final notifier = ref.read(syncStatusProvider.notifier);
    final message = _reportMessage(status.lastReport);

    return Scaffold(
      appBar: AppBar(title: const Text('Sincronização')),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text(
                'Seus registros ficam guardados neste aparelho e são enviados para a nuvem quando você estiver no Wi-Fi.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _CounterCard(
                      label: 'Aguardando envio',
                      value: status.pending.length,
                      icon: Icons.schedule,
                      color: AppColors.olive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CounterCard(
                      label: 'Com falha',
                      value: status.failed.length,
                      icon: Icons.error_outline,
                      color: status.failed.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.riskRed,
                    ),
                  ),
                ],
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                _MessageCard(message: message),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: status.isSyncing || status.pending.isEmpty
                    ? null
                    : notifier.syncNow,
                icon: status.isSyncing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  status.isSyncing ? 'Sincronizando...' : 'Sincronizar agora',
                ),
              ),
              if (status.failed.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: status.isSyncing ? null : notifier.retryFailed,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar de novo'),
                ),
                const SizedBox(height: 24),
                SectionLabel('NÃO ENVIADOS (${status.failed.length})'),
                const SizedBox(height: 8),
                for (final item in status.failed) _FailedTile(item: item),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static _Message? _reportMessage(SyncReport? report) {
    if (report == null) return null;
    return switch (report.skipped) {
      SyncSkipReason.signedOut => const _Message(
        Icons.person_outline,
        'Entre na sua conta para sincronizar. Sem conta, os dados ficam só neste aparelho.',
      ),
      SyncSkipReason.noConsent => const _Message(
        Icons.lock_outline,
        'A sincronização está desligada. Seus dados ficam só neste aparelho até você autorizar o envio.',
      ),
      SyncSkipReason.noWifi => const _Message(
        Icons.wifi_off,
        'Conecte-se a uma rede Wi-Fi para sincronizar.',
      ),
      SyncSkipReason.alreadyRunning => null,
      null => _resultMessage(report),
    };
  }

  static _Message _resultMessage(SyncReport report) {
    if (report.failed == 0) {
      return _Message(
        Icons.cloud_done_outlined,
        report.sent == 0
            ? 'Nada para enviar. Tudo está em dia.'
            : '${_records(report.sent)} ${report.sent == 1 ? 'enviado' : 'enviados'}.',
      );
    }
    return _Message(
      Icons.cloud_off_outlined,
      '${_records(report.sent)} ${report.sent == 1 ? 'enviado' : 'enviados'} e '
      '${_records(report.failed)} com falha. Os que falharam continuam guardados neste aparelho e podem ser enviados de novo.',
      isError: true,
    );
  }

  static String _records(int count) =>
      '$count ${count == 1 ? 'registro' : 'registros'}';
}

class _Message {
  const _Message(this.icon, this.text, {this.isError = false});

  final IconData icon;
  final String text;
  final bool isError;
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text('$value', style: AppTextStyles.title.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final color = message.isError ? AppColors.riskRed : AppColors.olive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(message.icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(message.text, style: AppTextStyles.body)),
          ],
        ),
      ),
    );
  }
}

class _FailedTile extends StatelessWidget {
  const _FailedTile({required this.item});

  final SyncItem item;

  @override
  Widget build(BuildContext context) {
    final attempts = item.attempts == 1
        ? '1 tentativa'
        : '${item.attempts} tentativas';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_icon(item.entityType), color: AppColors.textSecondary),
      title: Text(
        '${_entityLabel(item.entityType)} · ${_operationLabel(item.operation)}',
      ),
      subtitle: Text('${_errorLabel(item.lastError)} · $attempts'),
    );
  }

  static IconData _icon(SyncEntityType type) => switch (type) {
    SyncEntityType.drink => Icons.local_bar_outlined,
    SyncEntityType.exam => Icons.biotech_outlined,
    SyncEntityType.goal => Icons.flag_outlined,
  };

  static String _entityLabel(SyncEntityType type) => switch (type) {
    SyncEntityType.drink => 'Drinque',
    SyncEntityType.exam => 'Exame',
    SyncEntityType.goal => 'Meta',
  };

  static String _operationLabel(SyncOperation operation) => switch (operation) {
    SyncOperation.create => 'novo',
    SyncOperation.update => 'alterado',
    SyncOperation.delete => 'excluído',
  };
}

String _errorLabel(String? code) => switch (code) {
  'permission-denied' || 'unauthenticated' => 'Sem permissão no servidor',
  'unavailable' || 'deadline-exceeded' => 'Servidor indisponível',
  'resource-exhausted' => 'Limite do servidor atingido',
  _ => 'Erro ao enviar',
};
