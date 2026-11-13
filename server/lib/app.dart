import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'errors.dart';
import 'files.dart';
import 'notes.dart';

Handler createHandler() {
  final router = Router(notFoundHandler: (_) => notFound('Route not found'))
    ..get('/health', (_) => jsonResponse({'status': 'ok'}))
    ..post('/auth/register', register)
    ..post('/auth/login', login)
    ..get('/me', requireAuth(me))
    ..get('/notes', requireAuth(listNotes))
    ..post('/notes', requireAuth(createNote))
    ..get('/notes/<id>', requireAuth(getNote))
    ..put('/notes/<id>', requireAuth(updateNote))
    ..delete('/notes/<id>', requireAuth(deleteNote))
    ..post('/files', requireAuth(uploadFile))
    ..get('/files/<id>', downloadFile);
  return const Pipeline().addMiddleware(_cors).addHandler(router.call);
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

Handler _cors(Handler inner) => (request) async {
  if (request.method == 'OPTIONS') {
    return Response.ok('', headers: _corsHeaders);
  }
  return (await inner(request)).change(headers: _corsHeaders);
};
