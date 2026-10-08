import 'models.dart';

// Зашитые данные для L2. Начиная с L4 их заменит Repository.

/// «Текущее время» приложения, чтобы подписи вида «2 ч назад» не менялись.
final mockNow = DateTime(2026, 10, 9, 14, 30);

const currentUserId = 'u_1';
const currentUserName = 'Aristique';
const currentUserEmail = 'aristique@utm.md';

final assets = <Asset>[
  Asset(
    id: 'a_aapl',
    symbol: 'AAPL',
    name: 'Apple Inc.',
    market: Market.us,
    sector: 'Технологии',
    lastPrice: 248.30,
    changePct: 1.32,
    updatedAt: DateTime(2026, 10, 9, 14, 29),
  ),
  Asset(
    id: 'a_msft',
    symbol: 'MSFT',
    name: 'Microsoft Corp.',
    market: Market.us,
    sector: 'Технологии',
    lastPrice: 512.40,
    changePct: 0.47,
    updatedAt: DateTime(2026, 10, 9, 14, 29),
  ),
  Asset(
    id: 'a_nvda',
    symbol: 'NVDA',
    name: 'NVIDIA Corp.',
    market: Market.us,
    sector: 'Полупроводники',
    lastPrice: 186.75,
    changePct: 2.86,
    updatedAt: DateTime(2026, 10, 9, 14, 28),
  ),
  Asset(
    id: 'a_tsla',
    symbol: 'TSLA',
    name: 'Tesla Inc.',
    market: Market.us,
    sector: 'Автомобили',
    lastPrice: 312.60,
    changePct: -3.14,
    updatedAt: DateTime(2026, 10, 9, 14, 29),
  ),
  Asset(
    id: 'a_amzn',
    symbol: 'AMZN',
    name: 'Amazon.com Inc.',
    market: Market.us,
    sector: 'Потребительский',
    lastPrice: 228.15,
    changePct: -0.85,
    updatedAt: DateTime(2026, 10, 9, 14, 27),
  ),
  Asset(
    id: 'a_googl',
    symbol: 'GOOGL',
    name: 'Alphabet Inc. Class A',
    market: Market.us,
    sector: 'Технологии',
    lastPrice: 214.80,
    changePct: 0.62,
    updatedAt: DateTime(2026, 10, 9, 14, 29),
  ),
  Asset(
    id: 'a_jpm',
    symbol: 'JPM',
    name: 'JPMorgan Chase & Co.',
    market: Market.us,
    sector: 'Финансы',
    lastPrice: 286.40,
    changePct: -0.21,
    updatedAt: DateTime(2026, 10, 9, 14, 26),
  ),
  Asset(
    id: 'a_reliance',
    symbol: 'RELIANCE',
    name: 'Reliance Industries Ltd.',
    market: Market.india,
    sector: 'Энергетика',
    lastPrice: 35.42,
    changePct: 0.94,
    updatedAt: DateTime(2026, 10, 9, 10, 0),
  ),
  Asset(
    id: 'a_tcs',
    symbol: 'TCS',
    name: 'Tata Consultancy Services',
    market: Market.india,
    sector: 'Технологии',
    lastPrice: 41.18,
    changePct: -1.27,
    updatedAt: DateTime(2026, 10, 9, 10, 0),
  ),
  Asset(
    id: 'a_infy',
    symbol: 'INFY',
    name: 'Infosys Ltd.',
    market: Market.india,
    sector: 'Технологии',
    lastPrice: 19.86,
    changePct: -0.64,
    updatedAt: DateTime(2026, 10, 9, 10, 0),
  ),
  Asset(
    id: 'a_hdfcbank',
    symbol: 'HDFCBANK',
    name: 'HDFC Bank Ltd.',
    market: Market.india,
    sector: 'Финансы',
    lastPrice: 22.74,
    changePct: 0.38,
    updatedAt: DateTime(2026, 10, 9, 10, 0),
  ),
  Asset(
    id: 'a_sap',
    symbol: 'SAP',
    name: 'SAP SE',
    market: Market.europe,
    sector: 'Технологии',
    lastPrice: 268.50,
    changePct: 1.05,
    updatedAt: DateTime(2026, 10, 9, 14, 25),
  ),
  Asset(
    id: 'a_asml',
    symbol: 'ASML',
    name: 'ASML Holding N.V.',
    market: Market.europe,
    sector: 'Полупроводники',
    lastPrice: 812.30,
    changePct: -1.92,
    updatedAt: DateTime(2026, 10, 9, 14, 25),
  ),
  Asset(
    id: 'a_shel',
    symbol: 'SHEL',
    name: 'Shell plc',
    market: Market.europe,
    sector: 'Энергетика',
    lastPrice: 36.84,
    changePct: 0.15,
    updatedAt: DateTime(2026, 10, 9, 14, 24),
  ),
];

/// Секторы для чипов фильтра на экране рынка.
const sectors = <String>[
  'Технологии',
  'Полупроводники',
  'Финансы',
  'Энергетика',
  'Потребительский',
  'Автомобили',
];

/// Поиск акции по id (для позиций и ордеров).
Asset assetById(String id) => assets.firstWhere((a) => a.id == id);

final portfolio = Portfolio(
  id: 'p_1',
  userId: currentUserId,
  cashBalance: 1241.85,
  startingBalance: 10000,
  createdAt: DateTime(2026, 9, 14),
);

const positions = <Position>[
  Position(
    id: 'pos_1',
    userId: currentUserId,
    assetId: 'a_nvda',
    quantity: 12,
    avgPrice: 168.20,
  ),
  Position(
    id: 'pos_2',
    userId: currentUserId,
    assetId: 'a_aapl',
    quantity: 8,
    avgPrice: 231.40,
  ),
  Position(
    id: 'pos_3',
    userId: currentUserId,
    assetId: 'a_msft',
    quantity: 3,
    avgPrice: 498.10,
  ),
  Position(
    id: 'pos_4',
    userId: currentUserId,
    assetId: 'a_reliance',
    quantity: 40,
    avgPrice: 33.80,
  ),
  Position(
    id: 'pos_5',
    userId: currentUserId,
    assetId: 'a_sap',
    quantity: 4,
    avgPrice: 255.00,
  ),
  Position(
    id: 'pos_6',
    userId: currentUserId,
    assetId: 'a_tcs',
    quantity: 25,
    avgPrice: 43.10,
  ),
];

/// Позиция пользователя по акции или null, если её нет.
Position? positionFor(String assetId) {
  for (final p in positions) {
    if (p.assetId == assetId) return p;
  }
  return null;
}

/// Текущая стоимость всех позиций.
double get positionsValue => positions.fold(
  0,
  (sum, p) => sum + p.quantity * assetById(p.assetId).lastPrice,
);

/// Общая стоимость портфеля = свободные деньги + позиции.
double get totalValue => portfolio.cashBalance + positionsValue;

/// Доходность в процентах относительно стартового баланса.
double get totalReturnPct =>
    (totalValue - portfolio.startingBalance) / portfolio.startingBalance * 100;

final orders = <Order>[
  Order(
    id: 'o_8',
    userId: currentUserId,
    assetId: 'a_amzn',
    side: OrderSide.buy,
    type: OrderType.limit,
    quantity: 3,
    limitPrice: 215.00,
    fee: 0.65,
    status: OrderStatus.pending,
    createdAt: DateTime(2026, 10, 9, 11, 42),
  ),
  Order(
    id: 'o_7',
    userId: currentUserId,
    assetId: 'a_nvda',
    side: OrderSide.sell,
    type: OrderType.limit,
    quantity: 4,
    limitPrice: 205.00,
    fee: 0.82,
    status: OrderStatus.pending,
    createdAt: DateTime(2026, 10, 8, 16, 5),
  ),
  Order(
    id: 'o_6',
    userId: currentUserId,
    assetId: 'a_tcs',
    side: OrderSide.buy,
    type: OrderType.market,
    quantity: 25,
    executedPrice: 43.10,
    fee: 1.08,
    status: OrderStatus.executed,
    createdAt: DateTime(2026, 10, 7, 9, 31),
    executedAt: DateTime(2026, 10, 7, 9, 31),
  ),
  Order(
    id: 'o_5',
    userId: currentUserId,
    assetId: 'a_tsla',
    side: OrderSide.sell,
    type: OrderType.market,
    quantity: 5,
    executedPrice: 341.20,
    fee: 1.71,
    status: OrderStatus.executed,
    createdAt: DateTime(2026, 10, 3, 15, 48),
    executedAt: DateTime(2026, 10, 3, 15, 48),
  ),
  Order(
    id: 'o_4',
    userId: currentUserId,
    assetId: 'a_jpm',
    side: OrderSide.buy,
    type: OrderType.limit,
    quantity: 2,
    limitPrice: 270.00,
    fee: 0.54,
    status: OrderStatus.cancelled,
    createdAt: DateTime(2026, 9, 29, 12, 10),
  ),
  Order(
    id: 'o_3',
    userId: currentUserId,
    assetId: 'a_sap',
    side: OrderSide.buy,
    type: OrderType.limit,
    quantity: 4,
    limitPrice: 255.00,
    executedPrice: 255.00,
    fee: 1.02,
    status: OrderStatus.executed,
    createdAt: DateTime(2026, 9, 24, 10, 0),
    executedAt: DateTime(2026, 9, 25, 9, 14),
  ),
  Order(
    id: 'o_2',
    userId: currentUserId,
    assetId: 'a_reliance',
    side: OrderSide.buy,
    type: OrderType.market,
    quantity: 40,
    executedPrice: 33.80,
    fee: 1.35,
    status: OrderStatus.executed,
    createdAt: DateTime(2026, 9, 18, 9, 45),
    executedAt: DateTime(2026, 9, 18, 9, 45),
  ),
  Order(
    id: 'o_1',
    userId: currentUserId,
    assetId: 'a_nvda',
    side: OrderSide.buy,
    type: OrderType.market,
    quantity: 12,
    executedPrice: 168.20,
    fee: 2.02,
    status: OrderStatus.executed,
    createdAt: DateTime(2026, 9, 15, 16, 20),
    executedAt: DateTime(2026, 9, 15, 16, 20),
  ),
];

final newsArticles = <NewsArticle>[
  NewsArticle(
    id: 'n_1',
    title: 'NVIDIA растёт на фоне новых заказов на ускорители Blackwell Ultra',
    summary: 'Крупнейшие облачные провайдеры увеличили закупки на следующий год, аналитики повысили целевую цену акций.',
    url: 'https://www.reuters.com/technology/',
    source: 'Reuters',
    publishedAt: DateTime(2026, 10, 9, 13, 10),
    market: Market.us,
    symbols: ['NVDA'],
  ),
  NewsArticle(
    id: 'n_2',
    title: 'Apple готовит обновление линейки Mac на чипах M6',
    summary: 'По данным источников, презентация пройдёт в конце октября. Поставщики уже нарастили производство.',
    url: 'https://www.bloomberg.com/technology',
    source: 'Bloomberg',
    publishedAt: DateTime(2026, 10, 9, 11, 45),
    market: Market.us,
    symbols: ['AAPL'],
  ),
  NewsArticle(
    id: 'n_3',
    title: 'Reliance расширяет розничную сеть и инвестирует в солнечную энергетику',
    summary: 'Компания объявила о вложениях в гигафабрику в Джамнагаре и открытии 300 новых магазинов.',
    url: 'https://economictimes.indiatimes.com/markets',
    source: 'The Economic Times',
    publishedAt: DateTime(2026, 10, 9, 8, 20),
    market: Market.india,
    symbols: ['RELIANCE'],
  ),
  NewsArticle(
    id: 'n_4',
    title: 'ФРС сохранила ставку, рынок ждёт снижения в декабре',
    summary: 'Индекс S&P 500 закрылся вблизи исторического максимума, лидерами роста стали технологические компании.',
    url: 'https://www.cnbc.com/markets/',
    source: 'CNBC',
    publishedAt: DateTime(2026, 10, 8, 22, 5),
    market: Market.us,
    symbols: ['MSFT', 'AAPL', 'NVDA'],
  ),
  NewsArticle(
    id: 'n_5',
    title: 'TCS отчиталась за второй квартал: выручка выше прогнозов',
    summary: 'Рост заказов из Северной Америки компенсировал слабый спрос в Европе. Маржа осталась на уровне 24,6 %.',
    url: 'https://www.moneycontrol.com/news/business/',
    source: 'Moneycontrol',
    publishedAt: DateTime(2026, 10, 8, 17, 40),
    market: Market.india,
    symbols: ['TCS'],
  ),
  NewsArticle(
    id: 'n_6',
    title: 'SAP повысил прогноз по облачной выручке на 2026 год',
    summary: 'Спрос на бизнес-ИИ ускорил переход клиентов в облако. Акции подорожали на торгах во Франкфурте.',
    url: 'https://www.handelsblatt.com/finanzen/',
    source: 'Handelsblatt',
    publishedAt: DateTime(2026, 10, 8, 14, 15),
    market: Market.europe,
    symbols: ['SAP'],
  ),
  NewsArticle(
    id: 'n_7',
    title: 'Microsoft подписала контракт на поставку ИИ-сервисов для европейских банков',
    summary: 'Сделка рассчитана на пять лет и включает размещение данных в дата-центрах ЕС.',
    url: 'https://www.ft.com/technology',
    source: 'Financial Times',
    publishedAt: DateTime(2026, 10, 7, 19, 30),
    market: Market.us,
    symbols: ['MSFT'],
  ),
  NewsArticle(
    id: 'n_8',
    title: 'Индекс Nifty 50 обновил максимум на притоке иностранного капитала',
    summary: 'За неделю иностранные инвесторы вложили в индийские акции более 2 млрд долларов.',
    url: 'https://www.livemint.com/market',
    source: 'Mint',
    publishedAt: DateTime(2026, 10, 7, 11, 0),
    market: Market.india,
    symbols: ['RELIANCE', 'HDFCBANK', 'INFY'],
  ),
];

const leaderboard = <Participant>[
  Participant(
    rank: 1,
    name: 'Даниил Руснак',
    totalValue: 11842.60,
    returnPct: 18.43,
    tradesCount: 41,
  ),
  Participant(
    rank: 2,
    name: 'Мария Чебан',
    totalValue: 11205.10,
    returnPct: 12.05,
    tradesCount: 27,
  ),
  Participant(
    rank: 3,
    name: 'Ion Popescu',
    totalValue: 10931.75,
    returnPct: 9.32,
    tradesCount: 58,
  ),
  Participant(
    rank: 4,
    name: 'Анна Гуцу',
    totalValue: 10688.40,
    returnPct: 6.88,
    tradesCount: 19,
  ),
  Participant(
    rank: 5,
    name: currentUserName,
    totalValue: 10526.75,
    returnPct: 5.27,
    tradesCount: 23,
    isMe: true,
  ),
  Participant(
    rank: 6,
    name: 'Cristina Rotaru',
    totalValue: 10314.20,
    returnPct: 3.14,
    tradesCount: 12,
  ),
  Participant(
    rank: 7,
    name: 'Артём Лунгу',
    totalValue: 10120.05,
    returnPct: 1.20,
    tradesCount: 34,
  ),
  Participant(
    rank: 8,
    name: 'Victor Ceban',
    totalValue: 9975.30,
    returnPct: -0.25,
    tradesCount: 9,
  ),
  Participant(
    rank: 9,
    name: 'Елена Морару',
    totalValue: 9712.90,
    returnPct: -2.87,
    tradesCount: 16,
  ),
  Participant(
    rank: 10,
    name: 'Andrei Bivol',
    totalValue: 9238.45,
    returnPct: -7.62,
    tradesCount: 47,
  ),
];
