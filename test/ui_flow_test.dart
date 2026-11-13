import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/mock_trading_repository.dart';

import 'package:trade_arena/data/trading_repository.dart';
import 'package:trade_arena/main.dart';
import 'package:trade_arena/models/trading_model.dart';
import 'package:trade_arena/router.dart';

const capture = bool.fromEnvironment('CAPTURE_L4');
final boundaryKey = GlobalKey();

Future<void> screenshot(WidgetTester tester, String name) async {
  if (!capture) return;
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/l4/screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> start(
  WidgetTester tester,
  MockTradingRepository repo,
  TradingModel model,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  router.go('/market');
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TradingRepository>.value(value: repo),
        Provider<MockTradingRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => model),
      ],
      child: RepaintBoundary(key: boundaryKey, child: const TradeArenaApp()),
    ),
  );
}

Future<void> requestDone(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    // UI проверяется с настоящими шрифтами и без сохранения снимков.
    // Иначе Ahem меняет размеры текста и даёт ложные ошибки вёрстки.
    final config = File('.dart_tool/package_config.json').readAsStringSync();
    final sdk = RegExp(r'file:///([^"\n]+?)/packages/flutter"')
        .firstMatch(config)
        ?.group(1);
    if (sdk == null) throw StateError('Flutter SDK path not found');
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final path = entry.key == 'Roboto' && Platform.isWindows
          ? 'C:/Windows/Fonts/arial.ttf'
          : '${Uri.decodeComponent(sdk)}/bin/cache/artifacts/material_fonts/${entry.value}';
      final loader = FontLoader(entry.key)
        ..addFont(
          Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
        );
      await loader.load();
    }
    final fallback = FontLoader('Ahem')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${Uri.decodeComponent(sdk)}/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await fallback.load();
  });

  testWidgets('loading → ошибка → retry → данные; неизвестный id не зависает', (
    tester,
  ) async {
    final repo = MockTradingRepository();
    final model = TradingModel(repo);
    unawaited(model.load());
    await start(tester, repo, model);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await screenshot(tester, '01_loading');
    repo.simulateError = true;
    await requestDone(tester);
    expect(find.text('Повторить'), findsOneWidget);
    await screenshot(tester, '02_error');
    repo.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await requestDone(tester);
    expect(find.text('Apple Inc.'), findsOneWidget);
    await screenshot(tester, '03_market');
    router.go('/market/missing');
    await tester.pumpAndSettle();
    expect(find.text('Акция не существует'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Форма, общие данные, badge, отмена и сброс', (tester) async {
    final repo = MockTradingRepository();
    final model = TradingModel(repo);
    unawaited(model.load());
    await start(tester, repo, model);
    await requestDone(tester);
    router.go('/portfolio');
    await tester.pumpAndSettle();
    await screenshot(tester, '04_portfolio_before');
    router.go('/market/a_tsla');
    await tester.pumpAndSettle();
    await screenshot(tester, '05_detail_before');
    await tester.tap(find.text('Купить'));
    await tester.pumpAndSettle();
    await screenshot(tester, '06_form');
    repo.simulateError = true;
    await tester.tap(find.text('Купить 1 TSLA'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await requestDone(tester);
    expect(find.text('Сервер не отвечает — повторите попытку'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '1',
    );
    await screenshot(tester, '07_form_error');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    repo.simulateError = false;
    await tester.tap(find.text('Купить 1 TSLA'));
    await requestDone(tester);
    expect(model.positionFor('a_tsla')!.quantity, 1);
    await screenshot(tester, '08_detail_after');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    router.go('/portfolio');
    await tester.pumpAndSettle();
    await screenshot(tester, '09_portfolio_after');
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -550));
    await tester.pumpAndSettle();
    await screenshot(tester, '16_position_created');
    router.go('/leaderboard');
    await tester.pumpAndSettle();
    await screenshot(tester, '10_leaderboard');
    router.go('/market/a_tsla/order');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Лимитный'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '50');
    await tester.tap(find.text('Купить 1 TSLA'));
    await requestDone(tester);
    expect(model.pendingCount, 3);
    router.go('/portfolio');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ордера · 10'));
    await tester.pumpAndSettle();
    await screenshot(tester, '11_pending');
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey(model.orders.first.id)),
        matching: find.text('Покупка TSLA'),
      ),
    );
    await tester.pumpAndSettle();
    await screenshot(tester, '12_cancel_dialog');
    await tester.tap(find.widgetWithText(FilledButton, 'Отменить ордер'));
    await requestDone(tester);
    expect(model.pendingCount, 2);
    await screenshot(tester, '13_cancelled');
    router.go('/profile');
    await tester.pumpAndSettle();
    await screenshot(tester, '14_profile');
    repo.simulateError = true;
    await tester.tap(find.byTooltip('Обновить данные'));
    await requestDone(tester);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.byTooltip('Выйти из аккаунта'), findsOneWidget);
    repo.simulateError = false;
    await tester.tap(find.text('Повторить'));
    await requestDone(tester);
    await tester.ensureVisible(find.text('Сбросить портфель'));
    await tester.tap(find.text('Сбросить портфель'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сбросить'));
    await requestDone(tester);
    expect(model.positions, isEmpty);
    expect(model.orders, isEmpty);
    router.go('/portfolio');
    await tester.pumpAndSettle();
    await screenshot(tester, '15_reset');
    expect(find.text('Пока нет позиций'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
