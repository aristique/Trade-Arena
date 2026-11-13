# Сервер TradeArena

Основан на Dart/Shelf-примере из материалов курса PAM.

Из папки `server`:

```powershell
dart pub get
dart run bin/server.dart
```

Проверка: `http://localhost:8080/health`.
SQLite создаёт `app.db` при первом запуске. Библиотека SQLite загружается
автоматически средствами пакета `sqlite3`, вручную копировать DLL не нужно.

Переменные окружения: `PORT` (8080), `JWT_SECRET` (учебный ключ по умолчанию),
`DB_PATH` (app.db), `UPLOAD_DIR` (uploads).
База, загруженные файлы и секреты не включаются в Git.

Исходные маршруты `/auth/register`, `/auth/login`, `/me`, `/notes` и `/files`
сохранены для совместимости с учебным примером. JWT действует семь дней.
Пароли хранятся в виде PBKDF2-хешей с индивидуальной солью.

```powershell
dart analyze
dart test
```
