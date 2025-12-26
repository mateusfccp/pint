import 'dart:collection';

import 'package:quiver/collection.dart';

import 'ast/ast.dart';
import 'lexer/token.dart';
import 'syntactic_entity.dart';
import 'semantic/type.dart';

/// A Pinto error.
sealed class PintoError {
  String get code;
}

/// An error that happened while the program was being lexed.
sealed class LexingError implements PintoError {
  int get offset;
}

final class InvalidIdentifierStart implements LexingError {
  const InvalidIdentifierStart({required this.offset});

  @override
  final int offset;

  @override
  String get code => 'invalid_identifier_start';
}

final class NumberEndingWithSeparatorError implements LexingError {
  const NumberEndingWithSeparatorError({required this.offset});

  @override
  final int offset;

  @override
  String get code => 'number_ending_with_separator';
}

final class UnexpectedCharacterError implements LexingError {
  const UnexpectedCharacterError({required this.offset});

  @override
  final int offset;

  @override
  String get code => 'unexpected_character';
}

final class UnterminatedStringError implements LexingError {
  const UnterminatedStringError({required this.offset});

  @override
  final int offset;

  @override
  String get code => 'unterminated_string';
}

/// An error that happened while the program was being parsed.
sealed class ParseError implements PintoError {
  SyntacticEntity get syntacticEntity;
}


final class ExpectedError implements ParseError {
  const ExpectedError({
    required this.syntacticEntity,
    required this.expectation,
  });

  @override
  final SyntacticEntity syntacticEntity;

  final ExpectationType expectation;

  @override
  String get code => 'expected_${expectation.code}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpectedError &&
        other.syntacticEntity == syntacticEntity &&
        other.expectation == expectation;
  }

  @override
  int get hashCode => Object.hash(syntacticEntity, expectation);
}

final class ExpectedAfterError implements ParseError {
  const ExpectedAfterError({
    required this.syntacticEntity,
    required this.expectation,
    required this.after,
  });

  @override
  final SyntacticEntity syntacticEntity;

  final ExpectationType expectation;

  final ExpectationType after;

  @override
  String get code => 'expected_${expectation.code}_after_${after.code}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpectedAfterError &&
        other.syntacticEntity == syntacticEntity &&
        other.expectation == expectation &&
        other.after == after;
  }

  @override
  int get hashCode => Object.hash(syntacticEntity, expectation, after);
}

final class ExpectedBeforeError implements ParseError {
  const ExpectedBeforeError({
    required this.syntacticEntity,
    required this.expectation,
    required this.before,
  });

  @override
  final SyntacticEntity syntacticEntity;

  final ExpectationType expectation;

  final ExpectationType before;

  @override
  String get code => 'expected_${expectation.code}_before_${before.code}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpectedBeforeError &&
        other.syntacticEntity == syntacticEntity &&
        other.expectation == expectation &&
        other.before == before;
  }

  @override
  int get hashCode => Object.hash(syntacticEntity, expectation, before);
}

sealed class ExpectationType {
  const ExpectationType();

  String get code;
}

final class DeclarationExpectation extends ExpectationType {
  const DeclarationExpectation({this.declaration});

  final Declaration? declaration;

  @override
  String get code {
    return switch (declaration) {
      ImportDeclaration() => 'import',
      LetDeclaration() => 'let_declaration',
      TypeDefinition() => 'type_definition',
      null => 'declaration',
    };
  }

  @override
  String toString() {
    return switch (declaration) {
      ImportDeclaration() => 'an import',
      LetDeclaration() => 'a let declaration',
      TypeDefinition() => 'a type definition',
      null => 'a declaration',
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeclarationExpectation && other.declaration == declaration;
  }

  @override
  int get hashCode => declaration.hashCode;
}

final class ExpressionExpectation extends ExpectationType {
  const ExpressionExpectation({this.expression});

  final Expression? expression;

  @override
  String get code => 'expression';

  @override
  String toString() => 'an expression';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpressionExpectation && other.expression == expression;
  }

  @override
  int get hashCode => expression.hashCode;
}

final class TypeIdentifierExpectation extends ExpectationType {
  const TypeIdentifierExpectation();

  @override
  String get code => 'type_identifier';

  @override
  String toString() => 'a type identifier';

  @override
  bool operator ==(Object other) => other is TypeIdentifierExpectation;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class OneOfExpectation extends ExpectationType {
  const OneOfExpectation({required this.expectations});

  final List<ExpectationType> expectations;

  @override
  String get code =>
      expectations.map((expectation) => expectation.code).join('_or_');

  @override
  String toString() {
    final prefix = expectations.length > 1 ? 'one of ' : '';
    return '$prefix${expectations.join(', ')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OneOfExpectation &&
        listsEqual(other.expectations, expectations);
  }

  @override
  int get hashCode => Object.hashAll(expectations);
}

final class TokenExpectation extends ExpectationType {
  const TokenExpectation({required this.token, this.description});

  final TokenType token;
  final String? description;

  @override
  String get code => token.code;

  @override
  String toString() => description ?? "'$token'";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokenExpectation &&
        other.token == token &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(token, description);
}

final class MisplacedImport implements ParseError {
  const MisplacedImport({required ImportDeclaration importDeclaration})
    : syntacticEntity = importDeclaration;

  @override
  final ImportDeclaration syntacticEntity;

  @override
  String get code => 'misplaced_import';
}

/// An error that happened while the program was being resolved.
sealed class ResolveError implements PintoError {
  SyntacticEntity get syntacticEntity;
}

final class IdentifierAlreadyDefinedError implements ResolveError {
  const IdentifierAlreadyDefinedError(this.syntacticEntity);

  @override
  final Token syntacticEntity;

  @override
  String get code => 'identifier_already_defined';
}

final class ImportedPackageNotAvailableError implements ResolveError {
  const ImportedPackageNotAvailableError(this.syntacticEntity);

  @override
  final SyntacticEntity syntacticEntity;

  @override
  String get code => 'imported_package_not_available';
}

/// An error that indicates that the passed argument is invalid.
final class InvalidArgumentTypeError implements ResolveError {
  const InvalidArgumentTypeError({
    required this.syntacticEntity,
    required this.expectedType,
    required this.argumentType,
  });

  @override
  final SyntacticEntity syntacticEntity;

  /// The expected type of the argument.
  final Type expectedType;

  /// The type of the provided argument.
  final Type argumentType;

  @override
  String get code => 'invalid_argument_type';
}

/// An error that indicates that the type of a parameter is invalid.
///
/// A parameter should be a [TypeType] or a [PolymorphicType] that resolves to
/// a [TypeType].
final class InvalidParameterTypeError implements ResolveError {
  const InvalidParameterTypeError({
    required this.syntacticEntity,
    required this.parameterType,
  });

  @override
  final SyntacticEntity syntacticEntity;

  /// The type of the parameter.
  final Type parameterType;

  @override
  String get code => 'invalid_parameter_type';
}

/// An error that indicates that the type parameter not valid.
///
/// A type parameter should be a full struct with a name and a identifier.
///
/// Example:
///
/// ```pinto
/// type Person = Person(:name String, :age int) // Valid
/// type Person = Person(:name String, :age) // Invalid, missing type
/// type Person = Person(:name String, int) // Invalid, missing name
/// type Person = Person(:name String, :age 10) // Invalid, unexpected value
/// ```
final class InvalidTypeParameterError implements ResolveError {
  const InvalidTypeParameterError({required this.syntacticEntity});

  @override
  final SyntacticEntity syntacticEntity;

  @override
  String get code => 'invalid_type_parameter';
}

final class NotAFunctionError implements ResolveError {
  const NotAFunctionError({
    required this.syntacticEntity,
    required this.calledType,
  });

  @override
  final SyntacticEntity syntacticEntity;

  final Type calledType;

  @override
  String get code => 'not_a_function';
}

final class SymbolNotInScopeError implements ResolveError {
  const SymbolNotInScopeError(this.syntacticEntity);

  @override
  final Token syntacticEntity;

  @override
  String get code => 'symbol_not_in_scope';
}

final class TypeParameterAlreadyDefinedError implements ResolveError {
  const TypeParameterAlreadyDefinedError(this.syntacticEntity);

  @override
  final Token syntacticEntity;

  @override
  String get code => 'type_parameter_already_defined';
}

final class WrongNumberOfArgumentsError implements ResolveError {
  const WrongNumberOfArgumentsError({
    required this.syntacticEntity,
    required this.argumentsCount,
    required this.expectedArgumentsCount,
  }) : assert(argumentsCount != expectedArgumentsCount);

  @override
  final SyntacticEntity syntacticEntity;

  final int argumentsCount;

  final int expectedArgumentsCount;

  @override
  String get code => 'wrong_number_of_arguments';
}

/// An pint° error handler.
final class ErrorHandler {
  final _errors = <PintoError>[];
  final _listeners = <void Function(PintoError)>[];

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
  /// A listener will be called whenever an error is emitted. The emmited error
  /// is passed to the listener.
  void addListener(void Function(PintoError) listener) =>
      _listeners.add(listener);

  /// Removes [listener] from the handler.
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Emits an [error].
  ///
  /// The listeners will be notified of the error.
  void emit(PintoError error) {
    _errors.add(error);
    for (final listener in _listeners) {
      listener.call(error);
    }
  }
}
