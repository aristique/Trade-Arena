import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trade_arena/data/api_client.dart';
import 'package:trade_arena/models/auth_model.dart';

import 'package:trade_arena/main.dart';

import 'support/memory_token_store.dart';

void main() {
  testWidgets('Приложение запускается', (WidgetTester tester) async {
    final api = ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      client: MockClient((_) async => http.Response('{}', 500)),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthModel(api, MemoryTokenStore()),
        child: const TradeArenaApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
