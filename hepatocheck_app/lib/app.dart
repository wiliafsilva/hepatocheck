import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/platform/app_switcher_privacy.dart';
import 'presentation/camouflage/camouflage_controller.dart';
import 'presentation/camouflage/camouflage_preferences_store.dart';
import 'presentation/camouflage/privacy_lock_pause.dart';
import 'presentation/screens/camouflage_calculator_screen.dart';
import 'presentation/screens/drinks_screen.dart';
import 'presentation/screens/exams_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/goals_screen.dart';
import 'presentation/screens/follow_up_screen.dart';
import 'presentation/providers/goal_providers.dart';
import 'presentation/providers/report_providers.dart';
import 'presentation/screens/sync_status_screen.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/account_section.dart';
import 'presentation/widgets/erase_local_data_tile.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FollowUpCoordinator(
      child: MaterialApp(
        title: 'HepatoCheck',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AppNavigationShell(),
      ),
    );
  }
}

class AppNavigationShell extends ConsumerStatefulWidget {
  const AppNavigationShell({super.key});

  @override
  ConsumerState<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends ConsumerState<AppNavigationShell>
    with WidgetsBindingObserver {
  late final CamouflageController _camouflageController;
  int _selectedIndex = 0;
  bool _isReady = false;
  bool _lockDeferred = false;

  static const _tabs = <_AppTab>[
    _AppTab(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _AppTab(
      label: 'Relatório',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _AppTab(
      label: 'Drinks',
      icon: Icons.local_bar_outlined,
      selectedIcon: Icons.local_bar,
    ),
    _AppTab(
      label: 'Exames',
      icon: Icons.biotech_outlined,
      selectedIcon: Icons.biotech,
    ),
    _AppTab(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camouflageController = CamouflageController(CamouflagePreferencesStore())
      ..addListener(_onCamouflageChanged);
    _loadCamouflage();
  }

  Future<void> _loadCamouflage() async {
    await _camouflageController.load();
    if (_camouflageController.isEnabled) {
      await AppSwitcherPrivacy.setProtection(true);
    }
    if (mounted) setState(() => _isReady = true);
  }

  void _onCamouflageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lockDeferred = false;
      ref.read(todayProvider.notifier).refresh();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (ref.read(privacyLockPauseProvider.notifier).isPaused) {
        _lockDeferred = true;
        return;
      }
      _lockForPrivacy();
    }
  }

  void _onPrivacyPauseChanged(int? previous, int next) {
    if (next > 0 || !_lockDeferred) return;
    _lockDeferred = false;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      _lockForPrivacy();
    }
  }

  Future<void> _lockForPrivacy() async {
    if (!_camouflageController.isEnabled || _camouflageController.isLocked) {
      return;
    }
    _camouflageController.lockForBackground();
    await AppSwitcherPrivacy.setProtection(true);
  }

  Future<void> _enableCamouflage(String code) async {
    await _camouflageController.enable(code);
    await AppSwitcherPrivacy.setProtection(true);
    if (mounted) {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(localFollowUpProvider);
      setState(() => _selectedIndex = 2);
    }
  }

  Future<bool> _tryToUnlock(String code) async {
    final unlocked = await _camouflageController.unlock(code);
    if (unlocked) {
      if (mounted) setState(() => _selectedIndex = 2);
    }
    return unlocked;
  }

  Future<void> _disableCamouflage() async {
    await _camouflageController.disable();
    await AppSwitcherPrivacy.setProtection(false);
    if (mounted) {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(localFollowUpProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camouflageController
      ..removeListener(_onCamouflageChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(privacyLockPauseProvider, _onPrivacyPauseChanged);
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_camouflageController.isLocked) {
      return CamouflageCalculatorScreen(onSecretCodeAttempt: _tryToUnlock);
    }

    final tab = _tabs[_selectedIndex];
    return Scaffold(
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(tab.label),
              actions: [
                if (_selectedIndex == 2)
                  IconButton(
                    tooltip: 'Metas de redução',
                    icon: const Icon(Icons.flag_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const GoalsScreen(),
                      ),
                    ),
                  ),
              ],
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (final (index, child) in <Widget>[
            const HomeScreen(),
            const ReportScreen(),
            const DrinksScreen(),
            const ExamsScreen(),
            _ProfileScreen(
              camouflageEnabled: _camouflageController.isEnabled,
              onEnableCamouflage: _enableCamouflage,
              onDisableCamouflage: _disableCamouflage,
            ),
          ].indexed)
            HeroMode(enabled: index == _selectedIndex, child: child),
        ],
      ),
      bottomNavigationBar: _PillNavigationBar(
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _PillNavigationBar extends StatelessWidget {
  const _PillNavigationBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppTheme.navigationRadius);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: shape,
              border: Border.all(color: AppColors.outline),
            ),
            child: ClipRRect(
              borderRadius: shape,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppTab {
  const _AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({
    required this.camouflageEnabled,
    required this.onEnableCamouflage,
    required this.onDisableCamouflage,
  });

  final bool camouflageEnabled;
  final Future<void> Function(String code) onEnableCamouflage;
  final Future<void> Function() onDisableCamouflage;

  Future<void> _configureCamouflage(BuildContext context) async {
    final controller = TextEditingController();
    String? error;

    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Criar código secreto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use um código numérico de 4 a 8 dígitos para voltar ao diário. Ele funciona mesmo após uma conta; basta digitá-lo na calculadora.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Código secreto',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.length < 4) {
                  setDialogState(() => error = 'Use pelo menos 4 dígitos.');
                  return;
                }
                Navigator.pop(dialogContext, controller.text);
              },
              child: const Text('Ativar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (code != null) await onEnableCamouflage(code);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const AccountSection(),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Metas de redução'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notificações e lembretes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const FollowUpScreen()),
          ),
        ),
        const Divider(height: 32),
        Text('Privacidade', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text(
          'Disfarce o diário como uma calculadora e proteja sua visualização ao sair do aplicativo.',
        ),
        const SizedBox(height: 24),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Modo Camuflagem'),
          subtitle: Text(
            camouflageEnabled
                ? 'Ativo. O código secreto abre o diário.'
                : 'Use uma calculadora discreta para ocultar o diário.',
          ),
          value: camouflageEnabled,
          onChanged: (enabled) async {
            if (enabled) {
              await _configureCamouflage(context);
            } else {
              await onDisableCamouflage();
            }
          },
        ),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Sincronização'),
          subtitle: const Text('Envio dos registros para a nuvem'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SyncStatusScreen()),
          ),
        ),
        const EraseLocalDataTile(),
      ],
    );
  }
}
