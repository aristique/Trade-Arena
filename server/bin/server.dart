import 'dart:io';

import 'package:server/app.dart';
import 'package:server/db.dart';
import 'package:server/files.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  initDb(Platform.environment['DB_PATH'] ?? 'app.db');
  initFileStorage(Platform.environment['UPLOAD_DIR'] ?? 'uploads');
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(createHandler());
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('TradeArena: http://localhost:${server.port}');
}
