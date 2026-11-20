import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/platform/app_switcher_privacy.dart';
import 'presentation/camouflage/camouflage_controller.dart';
import 'presentation/camouflage/camouflage_preferences_store.dart';
import 'presentation/camouflage/privacy_lock_pause.dart';
import 'presentation/screens/camouflage_calculator_screen.dart';
import 'presentation/screens/drinks_screen.dart';
import 'presentation/screens/exams_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/goals_screen.dart';
import 'presentation/providers/goal_providers.dart';
import 'presentation/providers/report_providers.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_theme.dart';

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
            ProfileScreen(
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
