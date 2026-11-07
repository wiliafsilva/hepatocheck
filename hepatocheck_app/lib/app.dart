import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _selectedIndex = 0;

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
  Widget build(BuildContext context) {
    final tab = _tabs[_selectedIndex];

    return Scaffold(
      appBar: _selectedIndex == 0 ? null : AppBar(title: Text(tab.label)),
      body: switch (_selectedIndex) {
        0 => const HomeScreen(),
        3 => const ExamsScreen(),
        _ => _TabPlaceholder(
          label: tab.label,
          showCamouflagePreview: _selectedIndex == 4,
        ),
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
  const _TabPlaceholder({
    required this.label,
    required this.showCamouflagePreview,
  });

  final String label;
  final bool showCamouflagePreview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          if (showCamouflagePreview)
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CamouflageCalculatorPage(),
                  ),
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Visualizar calculadora'),
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Layout visual da calculadora. A lógica de cálculo e a ativação do modo
/// camuflagem serão implementadas em uma sprint posterior.
class CamouflageCalculatorPage extends StatelessWidget {
  const CamouflageCalculatorPage({super.key});

  static const _rows = <List<String>>[
    ['C', '±', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['0', ',', '='],
  ];

  static const _operators = {'÷', '×', '−', '+', '='};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        foregroundColor: const Color(0xFF1B1B1B),
        titleTextStyle: Theme.of(context).textTheme.titleLarge
            ?.copyWith(color: const Color(0xFF1B1B1B)),
        title: const Text('Calculadora'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '0',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: const Color(0xFF1B1B1B),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (final (rowIndex, row) in _rows.indexed) ...[
                      if (rowIndex > 0) const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            for (final (keyIndex, key) in row.indexed) ...[
                              if (keyIndex > 0) const SizedBox(width: 12),
                              Expanded(
                                flex: key == '0' ? 2 : 1,
                                child: _CalculatorKey(
                                  label: key,
                                  highlighted: _operators.contains(key),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalculatorKey extends StatelessWidget {
  const _CalculatorKey({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF3D3D3D) : const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: highlighted ? Colors.white : const Color(0xFF1B1B1B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
