import 'package:sqlite3/sqlite3.dart';

import 'catalog.dart';

void initTradingSchema(Database db) {
  db.execute('''
    PRAGMA foreign_keys = ON;
    CREATE TABLE IF NOT EXISTS assets (
      id TEXT PRIMARY KEY, symbol TEXT NOT NULL, name TEXT NOT NULL,
      market TEXT NOT NULL, sector TEXT NOT NULL, price_cents INTEGER NOT NULL,
      change_pct REAL NOT NULL, updated_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS portfolios (
      user_id INTEGER PRIMARY KEY REFERENCES users(id),
      cash_cents INTEGER NOT NULL CHECK(cash_cents >= 0),
      starting_cents INTEGER NOT NULL, created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS positions (
      user_id INTEGER NOT NULL REFERENCES users(id),
      asset_id TEXT NOT NULL REFERENCES assets(id),
      quantity INTEGER NOT NULL CHECK(quantity > 0), avg_price REAL NOT NULL,
      PRIMARY KEY(user_id, asset_id)
    );
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id),
      asset_id TEXT NOT NULL REFERENCES assets(id),
      side TEXT NOT NULL CHECK(side IN ('buy', 'sell')),
      type TEXT NOT NULL CHECK(type IN ('market', 'limit')),
      quantity INTEGER NOT NULL CHECK(quantity > 0),
      limit_cents INTEGER, executed_cents INTEGER, fee_cents INTEGER NOT NULL,
      status TEXT NOT NULL CHECK(status IN ('pending', 'executed', 'cancelled')),
      created_at TEXT NOT NULL, executed_at TEXT,
      until_cancelled INTEGER NOT NULL, realized_cents INTEGER
    );
    CREATE INDEX IF NOT EXISTS orders_user_status ON orders(user_id, status);
  ''');
  for (final asset in initialAssets) {
    db.execute('''
      INSERT OR IGNORE INTO assets
        (id, symbol, name, market, sector, price_cents, change_pct, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', asset);
  }
  db.execute('''
    INSERT OR IGNORE INTO portfolios
      (user_id, cash_cents, starting_cents, created_at)
    SELECT id, 1000000, 1000000, created_at FROM users
  ''');
}

T transaction<T>(Database db, T Function() action) {
  db.execute('BEGIN IMMEDIATE');
  try {
    final result = action();
    db.execute('COMMIT');
    return result;
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
