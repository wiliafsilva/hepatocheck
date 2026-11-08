import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/platform/app_switcher_privacy.dart';
import 'presentation/camouflage/camouflage_controller.dart';
import 'presentation/camouflage/camouflage_preferences_store.dart';
import 'presentation/screens/camouflage_calculator_screen.dart';
import 'presentation/screens/exams_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HepatoCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppNavigationShell(),
    );
  }
}

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({super.key});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell>
    with WidgetsBindingObserver {
  late final CamouflageController _camouflageController;
  int _selectedIndex = 0;
  bool _isReady = false;

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
    if (_camouflageController.isLocked) {
      await AppSwitcherPrivacy.setProtection(true);
    }
    if (mounted) setState(() => _isReady = true);
  }

  void _onCamouflageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
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
    if (mounted) setState(() => _selectedIndex = 2);
  }

  Future<bool> _tryToUnlock(String code) async {
    final unlocked = await _camouflageController.unlock(code);
    if (unlocked) {
      await AppSwitcherPrivacy.setProtection(false);
      if (mounted) setState(() => _selectedIndex = 2);
    }
    return unlocked;
  }

  Future<void> _disableCamouflage() async {
    await _camouflageController.disable();
    await AppSwitcherPrivacy.setProtection(false);
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
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_camouflageController.isLocked) {
      return CamouflageCalculatorScreen(onSecretCodeAttempt: _tryToUnlock);
    }

    final tab = _tabs[_selectedIndex];
    return Scaffold(
      appBar: _selectedIndex == 0 ? null : AppBar(title: Text(tab.label)),
      body: switch (_selectedIndex) {
        0 => const HomeScreen(),
        3 => const ExamsScreen(),
        4 => _ProfileScreen(
          camouflageEnabled: _camouflageController.isEnabled,
          onEnableCamouflage: _enableCamouflage,
          onDisableCamouflage: _disableCamouflage,
        ),
        _ => _TabPlaceholder(label: tab.label),
      },
      bottomNavigationBar: NavigationBar(
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

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
  );
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
                'Use um código numérico de 4 a 8 dígitos para voltar ao diário.',
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
      ],
    );
  }
}
