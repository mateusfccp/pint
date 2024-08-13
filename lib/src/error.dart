import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'ast/statement.dart';
import 'ast/token.dart';

part 'error.freezed.dart';

/// A Lox error.
sealed class PintoError {}

/// An error that happened while the program was being scanend.
sealed class ScanError implements PintoError {
  ScanLocation get location;
}

final class UnexpectedCharacterError implements ScanError {
  const UnexpectedCharacterError({
    required this.location,
    required this.character,
  });

  @override
  final ScanLocation location;

  final String character;
}

/// A location while the program is being scanned.
@freezed
sealed class ScanLocation with _$ScanLocation {
  const factory ScanLocation({
    required int offset,
    required int line,
    required int column,
  }) = _ScanLocation;
}

/// An error that happened while the program was being parsed.
sealed class ParseError implements PintoError {
  Token get token;
}

@freezed
sealed class ExpectError with _$ExpectError implements ParseError {
  const factory ExpectError({
    required Token token,
    required ExpectationType expectation,
  }) = _ExpectError;
}

@freezed
sealed class ExpectAfterError with _$ExpectAfterError implements ParseError {
  const factory ExpectAfterError({
    required Token token,
    required ExpectationType expectation,
    required ExpectationType after,
  }) = _ExpectAfterError;
}

@freezed
sealed class ExpectBeforeError with _$ExpectBeforeError implements ParseError {
  const factory ExpectBeforeError({
    required Token token,
    required ExpectationType expectation,
    required ExpectationType before,
  }) = _ExpectBeforeError;
}

@freezed
sealed class ExpectationType with _$ExpectationType {
  const ExpectationType._();

  const factory ExpectationType.oneOf({
    required List<ExpectationType> expectations,
    String? description,
  }) = OneOfExpectation;

  const factory ExpectationType.statement({
    required Statement statement,
    String? description,
  }) = StatementExpectation;

  const factory ExpectationType.token({
    required TokenType token,
    String? description,
  }) = TokenExpectation;

  @override
  String toString() {
    return description ??
        switch (this) {
          // ExpressionExpectation() => 'expression',
          OneOfExpectation(:final expectations) => "${expectations.length > 1 ? 'one of ' : ''}${expectations.join(', ')}",
          StatementExpectation() => 'a statement',
          TokenExpectation(:final token) => "'$token'",
        };
  }
}

/// An error that happened while the program was being resolved.
sealed class ResolveError implements PintoError {
  Token get token;
}

final class NoSymbolInScopeError implements ResolveError {
  const NoSymbolInScopeError(this.token);

  @override
  final Token token;
}

final class TypeAlreadyDefinedError implements ResolveError {
  const TypeAlreadyDefinedError(this.token);

  @override
  final Token token;
}

final class WrongNumberOfArgumentsError implements ResolveError {
  const WrongNumberOfArgumentsError({
    required this.token,
    required this.argumentsCount,
    required this.expectedArgumentsCount,
  }) : assert(argumentsCount != expectedArgumentsCount);

  @override
  final Token token;

  final int argumentsCount;

  final int expectedArgumentsCount;
}

/// An pint° error handler.
final class ErrorHandler {
  final _errors = <PintoError>[];
  final _listeners = <void Function()>[];

  /// The errors that were emitted by the handler.
  UnmodifiableListView<PintoError> get errors => UnmodifiableListView(_errors);

  /// Whether at least one error was emitted.
  bool get hasError => _errors.isNotEmpty;

  /// The last emitted error.
  ///
  /// If no error was emitted, `null` is returned.
  PintoError? get lastError => hasError ? _errors[_errors.length - 1] : null;

  /// Adds a [listener] to the handler.
  ///
  /// A listener will be called whenever an erro is emitted. The emmited error
  /// is passed to the listener.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes [listener] from the handler.
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Emits an [error].
  ///
  /// The listeners will be notified of the error.
  void emit(PintoError error) {
    _errors.add(error);
    for (final listener in _listeners) {
      listener.call();
    }
  }
}
