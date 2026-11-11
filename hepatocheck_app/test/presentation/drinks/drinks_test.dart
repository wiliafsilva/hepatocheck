import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/repositories/drink_repository.dart';
import 'package:hepatocheck_app/presentation/providers/drink_providers.dart';
import 'package:hepatocheck_app/presentation/screens/drinks_screen.dart';
import 'package:hepatocheck_app/presentation/screens/home_screen.dart';
import 'package:hepatocheck_app/presentation/theme/app_theme.dart';

class _MemoryDrinkRepository implements DrinkRepository {
  final _items = <String, DrinkEntry>{};

  @override
  List<DrinkEntry> getAll() =>
      _items.values.toList()
        ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

  @override
  DrinkEntry? getById(String id) => _items[id];

  @override
  Future<void> save(DrinkEntry entry) async => _items[entry.id] = entry;

  @override
  Future<void> delete(String id) async => _items.remove(id);
}

void main() {
  late _MemoryDrinkRepository repository;

  setUp(() => repository = _MemoryDrinkRepository());

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [drinkRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: home),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('registro rápido em 3 toques a partir do botão + do Início', (
    tester,
  ) async {
    await pump(tester, const HomeScreen());

    await tester.tap(find.byTooltip('Registrar drinque'));
    await tester.pumpAndSettle();
    expect(find.text('Registro rápido'), findsOneWidget);

    await tester.tap(find.text('Cerveja'));
    await tester.pumpAndSettle();
    expect(
      find.text('1 lata de cerveja (350 ml, 5%) = 1,0 drinque padrão'),
      findsOneWidget,
    );

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    final saved = repository.getAll().single;
    expect(saved.type, DrinkType.beer);
    expect(saved.volumeMl, 350);
    expect(saved.alcoholPercent, 5);
    expect(saved.quantity, 1);
    expect(find.text('Registro rápido'), findsNothing);
    expect(find.textContaining('Registrado:'), findsOneWidget);
  });

  testWidgets('o botão Adicionar só funciona depois de escolher a bebida', (
    tester,
  ) async {
    await pump(tester, const HomeScreen());
    await tester.tap(find.byTooltip('Registrar drinque'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(repository.getAll(), isEmpty);
    expect(find.text('Registro rápido'), findsOneWidget);
  });

  testWidgets('a tela Drinks mostra a conversão antes de salvar', (
    tester,
  ) async {
    await pump(tester, const DrinksScreen());

    expect(
      find.text('1 lata de cerveja (350 ml, 5%) = 1,0 drinque padrão'),
      findsOneWidget,
    );

    await tester.tap(find.text('Vinho'));
    await tester.pumpAndSettle();
    expect(
      find.text('1 taça de vinho (150 ml, 12%) = 1,0 drinque padrão'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Aumentar quantidade'));
    await tester.pumpAndSettle();
    expect(
      find.text('2 taças de vinho (150 ml, 12%) = 2,0 drinques padrão'),
      findsOneWidget,
    );
    expect(repository.getAll(), isEmpty);
  });

  testWidgets('salva, edita e exclui um registro com confirmação', (
    tester,
  ) async {
    await pump(tester, const DrinksScreen());

    await tapVisible(tester, find.text('Destilado'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Adicionar'));

    expect(repository.getAll().single.type, DrinkType.spirit);
    await scrollTo(tester, find.text('HISTÓRICO (1)'));
    expect(find.text('HISTÓRICO (1)'), findsOneWidget);

    await scrollTo(tester, find.text('1 dose de destilado (45 ml, 40%)'));
    await tapVisible(tester, find.text('1 dose de destilado (45 ml, 40%)'));
    expect(find.text('EDITAR REGISTRO'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Aumentar quantidade'));
    await tapVisible(tester, find.text('Salvar alterações'));

    expect(repository.getAll().single.quantity, 2);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('NOVO REGISTRO'), findsOneWidget);

    await scrollTo(tester, find.byTooltip('Excluir registro'));
    await tapVisible(tester, find.byTooltip('Excluir registro'));
    expect(find.text('Excluir registro?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.getAll(), hasLength(1));

    await tapVisible(tester, find.byTooltip('Excluir registro'));
    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(repository.getAll(), isEmpty);
    await scrollTo(tester, find.text('Nenhum drinque registrado ainda.'));
    expect(find.text('Nenhum drinque registrado ainda.'), findsOneWidget);
  });

  testWidgets('mostra erro de validação e não salva', (tester) async {
    await pump(tester, const DrinksScreen());

    await tester.enterText(find.widgetWithText(TextField, '350'), '0');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Adicionar'));
    await tester.ensureVisible(find.text('Use um volume entre 1 e 3000 ml.'));

    expect(find.text('Use um volume entre 1 e 3000 ml.'), findsOneWidget);
    expect(repository.getAll(), isEmpty);
  });
}
