"""Build the L4 PDF using the supplied L3 PDF as the formatting reference.

Usage: python docs/l4/build_report.py --reference /path/to/PAM_L3_report.pdf
Requires reportlab and pypdf. Run UI capture tests before building.
The reference stays outside the repository; its first page is reused with
only the laboratory number and subject replaced. Embedded reference fonts
are reused, with ToUnicode restored for ReportLab.
"""
from pathlib import Path
from io import BytesIO
from xml.sax.saxutils import escape
import argparse
import re
import subprocess

from pypdf import PdfReader, PdfWriter
from pypdf.generic import ContentStream, NameObject
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas
from reportlab.lib.colors import HexColor, black
from reportlab.lib.enums import TA_JUSTIFY, TA_CENTER
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle,
    Image, Flowable, KeepTogether,
)

ROOT = Path(__file__).resolve().parents[2]
BLUE = HexColor('#2e74b5')
WIDTH, HEIGHT = 595.303937, 841.889764
BODY_WIDTH = 470.85
FONT_GROUPS = {'regular': [], 'bold': [], 'mono': []}


def fonts(reference):
    seen = set()
    for page in reference.pages:
        for ref in page['/Resources']['/Font'].values():
            obj = ref.get_object()
            name = str(obj.get('/BaseFont', ''))
            desc = obj.get('/FontDescriptor')
            if name in seen or not desc or '/ToUnicode' not in obj:
                continue
            stream = desc.get_object().get('/FontFile2')
            if not stream:
                continue
            seen.add(name)
            alias = 'Reference' + str(len(seen))
            font = TTFont(alias, BytesIO(stream.get_object().get_data()))
            old_glyphs = dict(font.face.charToGlyph)
            old_widths = dict(font.face.charWidths)
            cmap = obj['/ToUnicode'].get_object().get_data().decode('ascii')
            restored = {}
            widths = {}
            for block in re.findall(r'beginbfchar(.*?)endbfchar', cmap, re.S):
                for source, target in re.findall(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>', block):
                    code = int(source, 16)
                    text = bytes.fromhex(target).decode('utf-16-be')
                    if len(text) == 1 and code in old_glyphs:
                        restored[ord(text)] = old_glyphs[code]
                        widths[ord(text)] = old_widths.get(code, font.face.defaultWidth)
            font.face.charToGlyph = restored
            font.face.charWidths = widths
            # Different PDF subsets share an internal PostScript name. Without
            # unique names ReportLab aliases them and silently loses glyphs.
            font.face.name = alias.encode('ascii')
            pdfmetrics.registerFont(font)
            group = 'mono' if 'Mono' in name else 'bold' if 'Bold' in name else 'regular'
            FONT_GROUPS[group].append((alias, set(restored)))
    # Missing rare glyphs fall back to metrically similar system fonts.
    for group, filename in [('regular', 'times.ttf'), ('bold', 'timesbd.ttf'), ('mono', 'consola.ttf')]:
        path = Path('C:/Windows/Fonts') / filename
        if path.exists():
            name = 'Fallback' + group
            font = TTFont(name, str(path))
            pdfmetrics.registerFont(font)
            FONT_GROUPS[group].append((name, set(font.face.charToGlyph)))
    # Prefer the larger body subsets; all use the same Liberation typefaces.
    for group in FONT_GROUPS:
        FONT_GROUPS[group][:-1] = sorted(FONT_GROUPS[group][:-1], key=lambda f: -len(f[1]))


def rich(text, group='regular', preserve_spaces=False):
    def encoded(value):
        value = escape(value)
        return value.replace(' ', '&#160;') if preserve_spaces else value
    runs = []
    current = None
    chunk = ''
    for char in text:
        name = next((name for name, chars in FONT_GROUPS[group] if ord(char) in chars), None)
        if name is None:
            raise ValueError(f'Missing glyph {char!r} in {group}')
        if name != current and chunk:
            runs.append(f'<font name="{current}">{encoded(chunk)}</font>')
            chunk = ''
        current = name
        chunk += char
    if chunk:
        runs.append(f'<font name="{current}">{encoded(chunk)}</font>')
    return ''.join(runs)


def style(name, **kwargs):
    return ParagraphStyle(name, fontName=FONT_GROUPS['regular'][0][0], **kwargs)


class Architecture(Flowable):
    def __init__(self):
        Flowable.__init__(self)
        self.width, self.height = BODY_WIDTH, 245

    def draw(self):
        c = self.canv
        labels = [
            ('Экраны и AppShell', 'Отображают данные, передают действия'),
            ('TradingModel / ChangeNotifier', 'Хранит снимок, извещает подписчиков'),
            ('TradingRepository — интерфейс', 'Контракт запросов и торговых операций'),
            ('MockTradingRepository', 'Память + seed L2 + задержка + авария'),
        ]
        for i, (title, subtitle) in enumerate(labels):
            y = 201 - i * 62
            c.setStrokeColor(BLUE)
            c.setFillColor(HexColor('#f2f2f2'))
            c.rect(54, y, 364, 43, fill=1)
            for value, offset, size, group in [(title, 32, 11, 'bold'), (subtitle, 15, 10, 'regular')]:
                p = Paragraph(rich(value, group), style('diagram', fontSize=size, leading=size + 1, alignment=TA_CENTER))
                p.wrap(354, 30)
                p.drawOn(c, 59, y + offset - size)
            if i < 3:
                c.setStrokeColor(black)
                c.line(228, y, 228, y - 18)
                tip = y if i == 2 else y - 18
                tail = tip - 5 if i == 2 else tip + 5
                c.line(228, tip, 224, tail)
                c.line(228, tip, 232, tail)
                label = ['watch / read', 'Future<Result<T>>', 'implements'][i]
                p = Paragraph(rich(label), style('arrow', fontSize=8, leading=9))
                p.wrap(145, 15)
                p.drawOn(c, 236, y - 14)


def build(reference_path, output):
    reference = PdfReader(reference_path)
    fonts(reference)
    body_style = style('body', fontSize=12, leading=16.7, alignment=TA_JUSTIFY, spaceAfter=9)
    heading_style = style('heading', fontSize=15, leading=19, textColor=BLUE, spaceAfter=11)
    sub_style = style('subheading', fontSize=13, leading=17, textColor=BLUE, spaceAfter=7)
    code_style = style('code', fontSize=8.2, leading=10.5, spaceAfter=0)
    caption_style = style('caption', fontSize=9, leading=11, alignment=TA_CENTER)
    story = []

    def p(text): story.append(Paragraph(rich(text), body_style))
    def h(text): story.append(Paragraph(rich(text, 'bold'), heading_style))
    def sub(text): story.append(Paragraph(rich(text, 'bold'), sub_style))
    def page(): story.append(PageBreak())
    def code(text, size=None):
        st = code_style if size is None else style('small-code', fontSize=size, leading=size + 2.3)
        content = '<br/>'.join(rich(line, 'mono', True) for line in text.strip('\n').splitlines())
        table = Table([[Paragraph(content, st)]], colWidths=[BODY_WIDTH])
        table.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, -1), HexColor('#f2f2f2')),
            ('LEFTPADDING', (0, 0), (-1, -1), 5), ('RIGHTPADDING', (0, 0), (-1, -1), 5),
            ('TOPPADDING', (0, 0), (-1, -1), 7), ('BOTTOMPADDING', (0, 0), (-1, -1), 7)]))
        story.extend([table, Spacer(1, 9)])

    figure_no = 0

    def figure(title, filename, text):
        nonlocal figure_no
        figure_no += 1
        img = Image(str(ROOT / 'docs/l4/screenshots' / (filename + '.png')), width=114, height=114 * 932 / 430)
        left = [img, Paragraph(rich(f'Рисунок {figure_no}'), caption_style)]
        table = Table([[left, Paragraph(rich(text), body_style)]], colWidths=[136, BODY_WIDTH - 136])
        table.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LEFTPADDING', (0, 0), (0, 0), 9), ('LEFTPADDING', (1, 0), (1, 0), 7),
            ('RIGHTPADDING', (0, 0), (-1, -1), 0), ('BOTTOMPADDING', (0, 0), (-1, -1), 0)]))
        story.append(KeepTogether([Paragraph(rich(title, 'bold'), sub_style), table, Spacer(1, 18)]))

    h('1. Цель работы и продолжение проекта')
    p('Тема проекта: собственная тема «TradeArena — биржевой симулятор» (финансы / образование). '
      'Работа продолжает приложение ЛР2 и ЛР3: рынки США, Индии и Европы, виртуальный портфель '
      'и учебные ордера со стартовым балансом $10 000.')
    p('Цель ЛР4 — отделить экраны от источника данных, ввести общее состояние на ChangeNotifier '
      'и Provider, реализовать Repository с результатами Ok/Err и связать торговые формы с записью. '
      'Изменение из одного экрана должно немедленно отражаться во всех подписанных вкладках.')
    p('Источником пока служит память с демонстрационными данными. Настоящая авторизация и '
      'backend относятся к ЛР5. Навигация go_router, формы, темы Material 3 и история Git сохранены.')
    sub('Установка пакета и структура изменений')
    code('flutter pub add provider\nflutter pub get\n\n# pubspec.yaml\nprovider: ^6.1.5+1')
    p('Первый коммит ЛР4 — 8e6807b «L4: добавлен пакет provider». pubspec.lock фиксирует '
      'версию пакета и транзитивную зависимость nested.')
    code('lib/\n  main.dart                       # выбор источника, Provider\n  data/models.dart                # сущности, draft, снимок\n  data/result.dart                # sealed Result / Ok / Err\n  data/trading_repository.dart     # интерфейс CRUD\n  data/mock_trading_repository.dart # память и торговые операции\n  models/trading_model.dart        # ChangeNotifier\n  widgets/data_view.dart           # loading / error / data\n  widgets/app_shell.dart           # вкладки и Consumer badge\n  screens/                        # подписанные экраны')
    page()

    h('2. Архитектура приложения')
    p('UI знает модель состояния, модель знает только интерфейс хранилища, а mock-реализация '
      'единственная импортирует исходный mock_data.dart. Схема ниже построена для TradeArena.')
    story.extend([Architecture(), Spacer(1, 12)])
    sub('Назначение слоёв и переход на ЛР5')
    p('Экраны показывают данные и передают действия. TradingModel хранит согласованный снимок '
      'и вызывает notifyListeners. TradingRepository задаёт контракт. MockTradingRepository '
      'хранит данные в памяти и имитирует сетевые запросы.')
    p('На ЛР5 добавляется HTTP-реализация TradingRepository, а main.dart выбирает её вместо mock. '
      'Экраны и модель состояния сохраняются; демонстрационный переключатель аварии удаляется.')
    sub('Почему один снимок для торговли')
    p('Покупка одновременно меняет деньги, позицию и историю. Поэтому операции записи возвращают '
      'Result<TradingSnapshot>: подписчики получают все изменения вместе. Дополнительный запрос '
      'после успешной записи не нужен и не может скрыть уже исполненную сделку сетевой ошибкой.')
    page()

    h('Контракт Repository и ожидаемые ошибки')
    p('Ошибки запроса представлены значением Err, а не исключением в UI. sealed Result позволяет '
      'исчерпывающе обработать обе ветки через switch.')
    code((ROOT / 'lib/data/result.dart').read_text(encoding='utf-8'))
    sub('CRUD ордеров и сброс портфеля')
    code('abstract interface class TradingRepository {\n  Future<Result<TradingSnapshot>> fetchAll();\n  Future<Result<Order>> fetchById(String id);\n  Future<Result<TradingSnapshot>> create(OrderDraft draft);\n  Future<Result<TradingSnapshot>> update(String id, OrderDraft draft);\n  Future<Result<TradingSnapshot>> delete(String id);\n  Future<Result<TradingSnapshot>> resetPortfolio();\n}')
    p('fetchById возвращает ошибку для неизвестного id. create присваивает id и исполняет либо '
      'ставит заявку в ожидание. update заменяет ожидающую заявку с повторной проверкой резервов. '
      'delete выполняет логическое удаление — отмену с сохранением истории. Исполненный или уже '
      'отменённый ордер изменить и отменить нельзя.')
    p('Возврат снимка вместо отдельного Order или void — адаптация общего CRUD-примера к '
      'торговой транзакции. Обновление заявки реализовано в контракте и модели, проверено тестами; '
      'отдельная форма редактирования в существующем интерфейсе не добавляется.')
    page()

    h('Mock-хранилище: память, задержка и авария')
    p('Каждый публичный метод ждёт 800 мс и проверяет simulateError. При аварии возвращается '
      'Err с сообщением; торговая запись не выполняется. Начальные списки копируются из seed.')
    code('Future<Result<TradingSnapshot>> fetchAll() async {\n  await _wait(); // Future.delayed(latency), по умолчанию 800 мс\n  if (simulateError) return const Err(_networkError);\n  _expireDayOrders();\n  return Ok(_snapshot());\n}\n\nFuture<Result<TradingSnapshot>> create(OrderDraft draft) async {\n  await _wait();\n  if (simulateError) return const Err(_networkError);\n  _expireDayOrders();\n  return _place(draft);\n}')
    sub('Проверки до изменения данных')
    p('Хранилище повторно проверяет id акции, положительное целое количество, конечную лимитную '
      'цену, свободные деньги и акции. Проверка формы улучшает обратную связь, но не заменяет '
      'доменную проверку. Между окончательной проверкой и записью нет await: параллельные заявки '
      'не могут потратить один и тот же резерв.')
    sub('Неизменяемость ответа')
    code('TradingSnapshot({required List<Order> orders,\n  required List<Position> positions, /* остальные поля */})\n  : orders = List.unmodifiable(orders),\n    positions = List.unmodifiable(positions);\n\n// Вложенные symbols и история цены также защищены от записи.')
    p('Списки снимка, тикеры новостей и точки графика доступны только для чтения. Все изменения '
      'проходят через методы Repository и модели, поэтому обход notifyListeners невозможен.')
    page()

    h('3. Общее состояние и подписки экранов')
    p('TradingModel получает интерфейс через конструктор. Он не создаёт mock самостоятельно '
      'и не импортирует виджеты. Локальные поля поиска, фильтров и формы остаются в setState.')
    code('class TradingModel extends ChangeNotifier {\n  TradingModel(this._repository);\n  final TradingRepository _repository;\n  TradingSnapshot? _data;\n  bool _loading = false;\n  String? _error;\n\n  List<Order> get orders => _data?.orders ?? const [];\n\n  Future<void> load() async {\n    if (_loading || _saving || _disposed) return;\n    _loading = true;\n    _error = null;\n    notifyListeners();\n    switch (await _repository.fetchAll()) {\n      case Ok(:final value): _data = value;\n      case Err(:final msg): _error = msg;\n    }\n    _loading = false;\n    if (!_disposed) notifyListeners();\n  }\n}')
    sub('watch, read и Consumer')
    code('// DataView.build: подписка на изменения\nfinal model = context.watch<TradingModel>();\n\n// Повторная загрузка: действие в callback\nonRetry: () => context.read<TradingModel>().load(),\n\n// AppShell: только индикатор ожидающих заявок\nConsumer<TradingModel>(\n  builder: (context, model, child) => Badge(\n    isLabelVisible: model.pendingCount > 0,\n    label: Text("${model.pendingCount}"), child: child!),\n  child: const Icon(Icons.pie_chart_outline),\n)')
    page()

    h('Корень композиции и три состояния')
    code('void main() {\n  final repository = MockTradingRepository();\n  runApp(MultiProvider(providers: [\n    Provider<TradingRepository>.value(value: repository),\n    Provider<MockTradingRepository>.value(value: repository),\n    ChangeNotifierProvider(\n      create: (_) => TradingModel(repository)..load()),\n  ], child: const TradeArenaApp()));\n}')
    p('Provider с конкретным mock нужен только переключателю аварии. Жизненным циклом модели '
      'управляет ChangeNotifierProvider через create. MaterialApp.router и ветви вкладок из ЛР3 '
      'остаются прежними.')
    sub('Общий DataView')
    code('final model = context.watch<TradingModel>();\nif (model.isLoading) {\n  return const Center(child: CircularProgressIndicator());\n}\nif (model.error != null) {\n  return ErrorView(message: model.error!,\n    onRetry: () => context.read<TradingModel>().load());\n}\nreturn builder(context, model); // данные')
    p('Рынок, портфель, новости, рейтинг, профиль, детали и форма используют общий компонент '
      'для загрузки и ошибки. ErrorView всегда содержит сообщение и «Повторить». Если данные '
      'загрузились, но id акции не найден, детали и форма показывают «Акция не существует», '
      'а не вечный spinner. В профиле переключатель аварии находится вне DataView и доступен '
      'даже после неудачной загрузки.')
    page()

    h('Три состояния главного экрана')
    figure('Загрузка данных', '01_loading', 'После открытия рынка модель находится в isLoading. '
      'Виден CircularProgressIndicator. Задержка mock-хранилища делает ожидание наблюдаемым. '
      'Снимок получен во время запроса, до публикации данных.')
    figure('Ошибка с повторной попыткой', '02_error', 'При включённой аварии запрос завершается '
      'Err. Вместо списка показаны сообщение «Сервер не отвечает — повторите попытку» и кнопка '
      '«Повторить». После отключения аварии повторный запрос возвращает данные без перезапуска.')
    page()

    h('Успешная загрузка и общие данные')
    figure('Данные рынка после retry', '03_market', 'Загружены 14 акций. Поиск и фильтры рынка '
      'и сектора сохранены с ЛР3, но исходный список теперь приходит из TradingModel. '
      'Секторы вычисляются по загруженным акциям. Иконка обновления повторяет запрос через модель.')
    figure('Рейтинг на основании текущего портфеля', '10_leaderboard', 'Участник Aristique '
      'рассчитывается из текущей общей стоимости и числа исполненных ордеров. Рейтинг '
      'пересортировывается после каждой операции. Фактическое число демонстрационных участников '
      '— 10; прежнее неподтверждённое число 128 удалено.')
    page()

    h('4. Торговые операции и согласованность')
    p('Рыночный ордер исполняется сразу по текущей демонстрационной котировке. Лимитная '
      'покупка исполняется, когда цена не выше лимита; продажа — когда не ниже. В другом случае '
      'создаётся ожидающий ордер. Автоматического изменения котировок и фонового исполнения '
      'в этой лабораторной нет.')
    sub('Резервы и округление')
    p('Ожидающая покупка резервирует сумму и комиссию, ожидающая продажа — количество акций. '
      'Полный денежный остаток остаётся частью стоимости портфеля, а доступные для новых '
      'покупок средства равны остатку за вычетом резерва. Суммы и комиссия округляются до цента.')
    code('double money(double value) => (value * 100).roundToDouble() / 100;\ndouble orderFee(double amount) => money(amount * 0.001);\n\n// В исходном портфеле:\n// деньги: 1241.85; резерв AMZN: 3 * 215.00 + 0.65 = 645.65\n// свободно: 596.20\n\n// Рыночная покупка одной TSLA:\n// сумма: 312.60; комиссия: 0.31; к оплате: 312.91\n// остаток: 928.94; свободно: 283.29\n// общая стоимость: 10526.44 (уменьшилась на комиссию)')
    sub('Изменения позиции и история')
    p('Покупка добавляет позицию или увеличивает её количество. Средняя стоимость учитывает '
      'прежнюю стоимость, сумму покупки и комиссию. Продажа уменьшает количество без изменения '
      'средней цены остатка; нулевая позиция удаляется. Для новых продаж сохраняется реализованный '
      'результат, из которого профиль выбирает лучшую сделку.')
    p('Дневные лимитные заявки отменяются с наступлением следующей календарной даты при '
      'обращении к хранилищу. Заявки «до отмены» продолжают ожидать. Ошибка записи не меняет '
      'существующий ордер и не освобождает его резерв.')
    page()

    h('Мультиэкранная покупка: портфель до и после')
    figure('Портфель до сделки', '04_portfolio_before', 'До покупки в портфеле 6 позиций и '
      '8 ордеров. Общая стоимость $10 526,75, доступные средства $596,20. Ещё $645,65 '
      'зарезервированы исходной лимитной покупкой AMZN. Два ожидающих ордера отражены в badge.')
    figure('Портфель после покупки одной TSLA', '09_portfolio_after', 'Позиции выросли до 7, '
      'история — до 9 ордеров. Свободные средства уменьшились до $283,29, стоимость акций '
      'выросла до $9 597,50. Общая стоимость $10 526,44 учитывает комиссию $0,31. '
      'Портфель обновился автоматически, без ручного запроса после возврата из формы.')
    page()

    h('Новая позиция и детали акции')
    figure('TSLA появилась в списке позиций', '16_position_created', 'После прокрутки портфеля '
      'видна новая строка TSLA. Покупка одной акции по $312,60 с комиссией $0,31 дала '
      'среднюю стоимость $312,91. Список не получает результат через pop и не перезагружается: '
      'его обновляет notifyListeners общей модели.')
    figure('Детали после успешной покупки', '08_detail_after', 'После успешной отправки форма '
      'закрывается, а карточка TSLA уже читает обновлённую позицию. Сообщение об исполнении '
      'относится к выполненной записи, а не к имитации из ЛР3. Та же модель обслуживает '
      'портфель, профиль, новости и рейтинг.')
    page()

    h('5. Связь формы с моделью и Repository')
    p('Форма, контроллеры и локальная валидация ЛР3 сохранены. Submit строит OrderDraft, '
      'вызывает create модели и дожидается результата. Модель записывает через интерфейс '
      'Repository, принимает снимок и извещает подписчиков.')
    code('Future<void> _submit() async {\n  if (!_formKey.currentState!.validate()) return;\n  final model = context.read<TradingModel>();\n  final error = await model.create(OrderDraft(\n    assetId: widget.assetId, side: _side, type: _type,\n    quantity: _quantity, limitPrice: _limitPrice,\n    untilCancelled: _untilCancelled));\n  if (!mounted) return;\n  if (error != null) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(error)));\n    return; // поля остаются заполненными\n  }\n  // Успех: снимок уже опубликован для всех экранов.\n  context.pop();\n}')
    sub('Ожидание отправки и защита данных')
    p('Пока запрос выполняется, кнопка отправки отключена, показан индикатор, поля не принимают '
      'повторные действия. Модель дополнительно блокирует одновременные записи и перезагрузку '
      'во время записи. Проверка mounted защищает UI после закрытия экрана во время запроса.')
    p('После неудачного submit данные в контроллерах сохраняются. Для повторной попытки '
      'нужно устранить причину ошибки и отправить форму ещё раз. Вход и регистрация остаются '
      'на локальной проверке полей до backend и авторизации на ЛР5.')
    page()

    h('Форма: заполнение и ошибка записи')
    figure('Валидная форма рыночной покупки', '06_form', 'Покупка одной TSLA: цена $312,60, '
      'комиссия $0,31, итог $312,91. Проверка доступных средств учитывает уже ожидающие '
      'лимитные ордера. Для исполняемого лимита расчёт использует более выгодную текущую цену.')
    figure('Сбой не очищает введённые данные', '07_form_error', 'При включённом simulateError '
      'появляется SnackBar с сообщением Repository. Количество 1 остаётся в поле, форма '
      'не закрывается и позиция не создаётся. После выключения аварии тот же ввод успешно '
      'приводит к покупке, показанной на предыдущих рисунках.')
    page()

    h('6. Обратная связь и подтверждение действий')
    figure('Ожидающий ордер и индикатор', '11_pending', 'Лимитная покупка одной TSLA по $50 '
      'не исполняется при текущей цене $312,60. Заявка появляется в истории со статусом '
      '«Ожидает», а badge увеличивается с 2 до 3. Резерв новой заявки — $50,05.')
    figure('Подтверждение отмены', '12_cancel_dialog', 'Нажатие на ожидающую заявку открывает '
      'диалог из ЛР3. Отказ закрывает диалог без записи. Подтверждение вызывает cancel модели, '
      'который обращается к delete Repository. На время операции повторная отмена отключена.')
    page()

    h('Отмена, переключатель аварии и сброс')
    figure('Результат отмены', '13_cancelled', 'Ордер остаётся в истории со статусом «Отменён». '
      'Badge снова показывает 2; резерв $50,05 освобождён. Статус и индикатор меняются '
      'через общее состояние, а SnackBar подтверждает результат уже завершённой операции.')
    figure('Профиль и демонстрация ошибки', '14_profile', 'Переключатель «Симулировать сбой сети» '
      'меняет только флаг mock-источника. Для демонстрации загрузки после включения нужно '
      'нажать обновление. Чтобы восстановить данные, выключить переключатель и нажать '
      '«Повторить». Переключатель остаётся доступным при ошибке.')
    page()

    h('Сброс портфеля и проверка реализации')
    figure('Портфель после подтверждённого сброса', '15_reset', 'Баланс возвращается к $10 000, '
      'позиции и ордера удалены. Счётчик ожидающих заявок исчезает; рейтинг и новости '
      'также читают новое состояние. Пустой список показывает понятное сообщение.')
    sub('Автоматические проверки')
    p('Выполнены 19 тестов: 16 проверок Repository и модели, два пользовательских сценария '
      'через интерфейс и проверка запуска. Покрыты комиссии, средняя стоимость, полная продажа, '
      'резервы, выгодный лимит, CRUD, сброс, аварии всех методов, неизменяемость снимков, '
      'параллельные заявки, истечение дневного ордера, retry и неизвестный id.')
    p('Снимки отчёта получены настоящим рендером Flutter в widget-тестах при размере '
      '430 × 932 логических пикселя. Это тестовое окружение, а не снимки телефона или эмулятора.')
    code('flutter analyze --no-pub\nflutter test --no-pub\nflutter build web --release --no-pub\n\n# Обновление снимков реального UI для отчёта:\nflutter test --no-pub test/ui_flow_test.dart \\\n  --dart-define=CAPTURE_L4=true')
    page()

    h('7. История Git и непрерывность')
    head = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'], cwd=ROOT, text=True).strip()
    p('Репозиторий: https://github.com/aristique/Trade-Arena. Ниже приведена полная история '
      f'от ЛР2 до текущего этапа ЛР4, git log --oneline, от новых изменений к созданию проекта. '
      f'Код и проверки отчёта соответствуют коммиту {head}; сам отчёт добавляется следующим коммитом.')
    log = subprocess.check_output(['git', '-c', 'i18n.logOutputEncoding=utf-8', 'log', '--oneline'], cwd=ROOT, encoding='utf-8')
    # Keep each entry on a page; wrap long messages with the same mono styling.
    for line in log.splitlines():
        story.append(Paragraph(rich(line, 'mono'), style('history', fontSize=7.6, leading=10.1, spaceAfter=2)))
    page()
    h('8. Вывод')
    p('В TradeArena реализовано общее состояние на Provider и ChangeNotifier, интерфейс '
      'Repository, mock с задержкой и управляемой ошибкой, три состояния загрузки и retry. '
      'Форма ордера действительно записывает данные: покупка, продажа, отмена и сброс '
      'изменяют все подписанные экраны. Демонстрационный источник изолирован от UI; '
      'следующий этап может заменить его реализацией backend без переписывания экранов.')

    body = BytesIO()
    doc = SimpleDocTemplate(body, pagesize=(WIDTH, HEIGHT), leftMargin=85.15,
        rightMargin=39.3, topMargin=57, bottomMargin=49, title='TradeArena — PAM L4',
        author='Manolopoulos Aristeidis')
    doc.build(story)

    # Preserve the original title page verbatim except its laboratory number / subject.
    overlay = BytesIO()
    c = Canvas(overlay, pagesize=(WIDTH, HEIGHT))
    c.setFillColorRGB(1, 1, 1)
    c.rect(85, HEIGHT - 413, 465, 27, stroke=0, fill=1)
    c.rect(85, HEIGHT - 468, 465, 28, stroke=0, fill=1)
    def centered(text, top, size):
        paragraph = Paragraph(rich(text), style('cover', fontSize=size, leading=size * 1.1, alignment=TA_CENTER))
        _, height = paragraph.wrap(550, 50)
        paragraph.drawOn(c, (WIDTH - 550) / 2, HEIGHT - top - height)
    centered('по лабораторной работе Nr.4.', 388, 18)
    centered('Тема: Управление состоянием и Repository', 441.5, 18)
    c.save()
    cover = reference.pages[0]
    # Remove replaced text operators as well: the PDF must not retain an
    # invisible L3 number/subject underneath the new visible lines.
    content = ContentStream(cover.get_contents(), reference)
    filtered = []
    text_y = None
    for operands, operator in content.operations:
        if operator == b'BT':
            text_y = None
        if operator == b'Td':
            text_y = float(operands[1])
        if operator in (b'Tj', b'TJ') and text_y is not None and any(
                abs(text_y - old_y) < 0.1 for old_y in (437.339, 383.939)):
            continue
        filtered.append((operands, operator))
    content.operations = filtered
    cover[NameObject('/Contents')] = content
    cover.merge_page(PdfReader(overlay).pages[0])
    writer = PdfWriter()
    writer.add_page(cover)
    for body_page in PdfReader(body).pages:
        writer.add_page(body_page)
    writer.add_metadata({'/Title': 'PAM L4 — TradeArena', '/Author': 'Manolopoulos Aristeidis'})
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('wb') as file:
        writer.write(file)
    print(f'{output}: {len(writer.pages)} pages')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--reference', required=True, type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'output/pdf/PAM_L4_Manolopoulos_Aristeidis.pdf')
    args = parser.parse_args()
    build(args.reference, args.output)
