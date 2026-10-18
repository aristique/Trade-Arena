// Проверки полей для validator: у TextFormField.
// null — поле заполнено верно, строка — текст ошибки под полем.

final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Введите email';
  if (!_emailRegExp.hasMatch(email)) return 'Неверный формат email';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.length < 6) return 'Минимум 6 символов';
  return null;
}
