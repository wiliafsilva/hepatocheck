import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/presentation/providers/repository_providers.dart';
import 'package:hepatocheck_app/presentation/screens/auth/login_screen.dart';
import 'package:hepatocheck_app/presentation/screens/auth/register_screen.dart';
import 'package:hepatocheck_app/presentation/screens/home_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

void main() {
  const sizes = <String, Size>{
    'phone-320x568': Size(320, 568),
    'phone-360x640': Size(360, 640),
    'phone-412x915': Size(412, 915),
    'tablet-768x1024': Size(768, 1024),
    'desktop-1280x800': Size(1280, 800),
  };
  const scales = [1.0, 2.0];

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
  };

  // Carrega a Inter de verdade; sem isso o teste usa a fonte de blocos (Ahem),
  // que é bem mais larga e falseia o resultado do overflow.
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/Inter-$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  for (final screen in screens.entries) {
    for (final size in sizes.entries) {
      for (final scale in scales) {
        testWidgets('${screen.key} ${size.key} fonte x$scale sem overflow', (
          tester,
        ) async {
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final container = ProviderContainer();
          addTearDown(container.dispose);
          await container
              .read(examRepositoryProvider)
              .save(
                LabExam(
                  id: 'e1',
                  date: DateTime(2026, 11, 1),
                  age: 45,
                  ast: 40,
                  alt: 36,
                  platelets: 200,
                ),
              );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.dark,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: screen.value(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
