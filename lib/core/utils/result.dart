/// 通用 Result 错误封装（Ok/Failure union），数据层/服务层返回。
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = _Ok<T>;
  const factory Result.failure(String message) = _Failure<T>;

  bool get isOk => this is _Ok<T>;
  bool get isFailure => this is _Failure<T>;

  T? get valueOrNull => switch (this) {
        _Ok<T>(:final value) => value,
        _Failure<T>() => null,
      };

  String? get errorOrNull => switch (this) {
        _Ok<T>() => null,
        _Failure<T>(:final message) => message,
      };

  Result<U> map<U>(U Function(T value) fn) => switch (this) {
        _Ok<T>(:final value) => Result.ok(fn(value)),
        _Failure<T>(:final message) => Result.failure(message),
      };
}

class _Ok<T> extends Result<T> {
  const _Ok(this.value);
  final T value;
}

class _Failure<T> extends Result<T> {
  const _Failure(this.message);
  final String message;
}
