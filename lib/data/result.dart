/// Ожидаемая ошибка — значение, которое вызывающий код обязан обработать.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.msg);
  final String msg;
}
