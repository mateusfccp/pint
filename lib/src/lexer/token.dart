import 'package:meta/meta.dart';
import 'package:pinto/syntactic_entity.dart';

/// A program token.
@immutable
final class Token implements SyntacticEntity {
  /// Creates a program token.
  const Token({required this.type, required this.lexeme, required this.offset});

  /// The type of the token.
  final TokenType type;

  /// The string representation of the token.
  final String lexeme;

  /// The offset in which the token was scanned.
  @override
  final int offset;

  @override
  int get length => lexeme.length;

  @override
  int get end => offset + length;

  @override
  String toString() => 'Token(type: $type, lexeme: $lexeme, offset: $offset)';
}

sealed class ExpressionTokenType {}

/// The type of a token.
sealed class TokenType {
  /// Private constant constructor to ensure that all subtypes are also const
  /// and to prevent direct instantiation of TokenType itself.
  const TokenType._();

  /// A textual representation of the token type, often used for debugging or code generation.
  /// This corresponds to the `name` of an enum case or a specific string identifier.
  String get code;

  /// A human-readable representation of the token, often its literal string value
  /// or a descriptive name. This is what was previously in the `toString()` of the enum.
  @override
  String toString();

  // --- Static constant instances for each token type ---
  // By defining these as static const, we ensure that there's only one
  // instance of each token type, mimicking enum behavior.
  // Types are inferred by the analyzer.

  /// The arrow token (`->`).
  ///
  /// The arrow token is used to introduce a function type identifier.
  static const arrow = Arrow._();

  /// The at token (`@`).
  static const at = At._();

  /// The colon token (`:`).
  static const colon = Colon._();

  /// The comma token (`,`).
  static const comma = Comma._();

  /// The fat arrow token (`=>`).
  ///
  /// The fat arrow is used to introduce a function literal.
  static const doubleArrow = DoubleArrow._();

  /// The double literal.
  ///
  /// It follows the following grammar:
  /// ```ebnf
  /// <digit_separator> ::= "_"
  /// <integer_literal> ::= <digit> (<digit_separator>* <digit>+)*
  /// <double_literal>  ::= <integer_literal> "." <integer_literal>
  /// ```
  ///
  /// Some examples of valid double literals:
  /// ```
  /// 0.100
  /// 53.000_001
  /// 5_2.000_001
  /// 5__2.000___001
  /// ```
  static const doubleLiteral = DoubleLiteral._();

  /// The end-of-file token.
  static const endOfFile = EndOfFile._();

  /// The equality sign token (`=`).
  static const equalitySign = EqualitySign._();

  /// The eroteme token (`?`).
  ///
  /// The eroteme is also known as the quesiton mark.
  static const eroteme = Eroteme._();

  /// The false keyword.
  static const falseKeyword = FalseKeyword._();

  /// An identifier.
  ///
  /// pint°'s identifier follows Dart's one. The grammar is the following:
  ///
  /// ```bnf
  /// <identifier>       ::= <identifier_start> <identifier_part>*
  /// <identifier_start> ::= [A-Za-z_$]
  /// <identifier_part>  ::= <identifier_start> | [0-9]
  /// ```
  static const identifier = Identifier._();

  /// An import identifier.
  ///
  /// The import identifier follows the grammar:
  ///
  ///```bnf
  /// <import_identifier> ::= "@"? <identifier> ( "/" <identifier> )*
  ///```
  static const importIdentifier = ImportIdentifier._();

  /// The `import` keyword token.
  static const importKeyword = ImportKeyword._();

  /// The integer literal.
  ///
  /// It follows the following grammar:
  /// ```ebnf
  /// <digit_separator> ::= "_"
  /// <integer_literal> ::= <digit> (<digit_separator>* <digit>+)*
  /// ```
  ///
  /// Some examples of valid integer literals:
  /// ```
  /// 0100
  /// 1094812
  /// 100_000
  /// 1__000
  /// ```
  static const integerLiteral = IntegerLiteral._();

  /// The left brace token (`{`).
  static const leftBrace = LeftBrace._();

  /// The left bracket token (`[`).
  static const leftBracket = LeftBracket._();

  /// The left parenthesis token (`(`).
  static const leftParenthesis = LeftParenthesis._();

  /// The let keyword.
  static const letKeyword = LetKeyword._();

  /// The plus sign token (`+`).
  static const plusSign = PlusSign._();

  /// A reserved token.
  static const reserved = Reserved._();

  /// The right brace token (`}`).
  static const rightBrace = RightBrace._();

  /// The right bracket token (`]`).
  static const rightBracket = RightBracket._();

  /// The right parenthesis token (`)`).
  static const rightParenthesis = RightParenthesis._();

  /// The slash token (`/`).
  static const slash = Slash._();

  /// The string literal.
  ///
  /// String literals are still underspecified. Currently, they will just be "something".
  static const stringLiteral = StringLiteral._();

  /// The symbol literal.
  ///
  /// It follows the following grammar:
  /// ```ebnf
  /// <symbol_literal> ::= ":" <identifier>
  /// ```
  static const symbolLiteral = SymbolLiteral._();

  /// The `true` keyword token.
  static const trueKeyword = TrueKeyword._();

  /// The `type` keyword token.
  static const typeKeyword = TypeKeyword._();
}

/// The arrow token (`->`).
///
/// The arrow token is used to introduce a function type identifier.
final class Arrow extends TokenType {
  const Arrow._() : super._();

  @override
  String get code => 'arrow';

  @override
  String toString() => '->';
}

/// The at token (`@`).
final class At extends TokenType {
  const At._() : super._();

  @override
  String get code => 'at';

  @override
  String toString() => '@';
}

/// The colon token (`:`).
final class Colon extends TokenType {
  const Colon._() : super._();

  @override
  String get code => 'colon';

  @override
  String toString() => ':';
}

/// The comma token (`,`).
final class Comma extends TokenType {
  const Comma._() : super._();

  @override
  String get code => 'comma';

  @override
  String toString() => ',';
}

/// The fat arrow token (`=>`).
///
/// The fat arrow is used to introduce a function literal.
final class DoubleArrow extends TokenType {
  const DoubleArrow._() : super._();

  @override
  String get code => 'double_arrow';

  @override
  String toString() => '=>';
}

/// The double literal.
///
/// It follows the following grammar:
/// ```ebnf
/// <digit_separator> ::= "_"
/// <integer_literal> ::= <digit> (<digit_separator>* <digit>+)*
/// <double_literal>  ::= <integer_literal> "." <integer_literal>
/// ```
///
/// Some examples of valid double literals:
/// ```
/// 0.100
/// 53.000_001
/// 5_2.000_001
/// 5__2.000___001
/// ```
final class DoubleLiteral extends TokenType implements ExpressionTokenType {
  const DoubleLiteral._() : super._();

  @override
  String get code => 'double_literal';

  @override
  String toString() => 'double literal';
}

/// The end-of-file token.
final class EndOfFile extends TokenType {
  const EndOfFile._() : super._();

  @override
  String get code => 'eof';

  @override
  String toString() => 'EOF';
}

/// The equality sign token (`=`).
final class EqualitySign extends TokenType {
  const EqualitySign._() : super._();

  @override
  String get code => 'equality_sign';

  @override
  String toString() => '=';
}

/// The eroteme token (`?`).
///
/// The eroteme is also known as the quesiton mark.
final class Eroteme extends TokenType {
  const Eroteme._() : super._();

  @override
  String get code => 'question_mark';

  @override
  String toString() => '?';
}

/// The false keyword.
final class FalseKeyword extends TokenType implements ExpressionTokenType {
  const FalseKeyword._() : super._();

  @override
  String get code => 'false';

  @override
  String toString() => 'false';
}

/// An identifier.
///
/// pint°'s identifier follows Dart's one. The grammar is the following:
///
/// ```bnf
/// <identifier>       ::= <identifier_start> <identifier_part>*
/// <identifier_start> ::= [A-Za-z_$]
/// <identifier_part>  ::= <identifier_start> | [0-9]
/// ```
final class Identifier extends TokenType implements ExpressionTokenType {
  const Identifier._() : super._();

  @override
  String get code => 'identifier';

  @override
  String toString() => 'identifier';
}

/// An import identifier.
///
/// The import identifier follows the grammar:
///
///```bnf
/// <import_identifier> ::= "@"? <identifier> ( "/" <identifier> )*
///```
final class ImportIdentifier extends TokenType {
  const ImportIdentifier._() : super._();

  @override
  String get code => 'import_identifier';

  @override
  String toString() => 'import identifier';
}

/// The `import` keyword token.
final class ImportKeyword extends TokenType {
  const ImportKeyword._() : super._();

  @override
  String get code => 'import';

  @override
  String toString() => 'import';
}

/// The integer literal.
///
/// It follows the following grammar:
/// ```ebnf
/// <digit_separator> ::= "_"
/// <integer_literal> ::= <digit> (<digit_separator>* <digit>+)*
/// ```
///
/// Some examples of valid integer literals:
/// ```
/// 0100
/// 1094812
/// 100_000
/// 1__000
/// ```
final class IntegerLiteral extends TokenType implements ExpressionTokenType {
  const IntegerLiteral._() : super._();

  @override
  String get code => 'integer_literal';

  @override
  String toString() => 'integer literal';
}

/// The left brace token (`{`).
final class LeftBrace extends TokenType implements ExpressionTokenType {
  const LeftBrace._() : super._();

  @override
  String get code => 'left_brace';

  @override
  String toString() => '{';
}

/// The left bracket token (`[`).
final class LeftBracket extends TokenType implements ExpressionTokenType {
  const LeftBracket._() : super._();

  @override
  String get code => 'left_bracket';

  @override
  String toString() => '[';
}

/// The left parenthesis token (`(`).
final class LeftParenthesis extends TokenType implements ExpressionTokenType {
  const LeftParenthesis._() : super._();

  @override
  String get code => 'left_parenthesis';

  @override
  String toString() => '(';
}

/// The let keyword.
final class LetKeyword extends TokenType {
  const LetKeyword._() : super._();

  @override
  String get code => 'let';

  @override
  String toString() => 'let';
}

/// The plus sign token (`+`).
final class PlusSign extends TokenType {
  const PlusSign._() : super._();

  @override
  String get code => 'plus_sign';

  @override
  String toString() => '+';
}

/// A reserved token.
final class Reserved extends TokenType {
  const Reserved._() : super._();

  @override
  String get code => 'reserved';

  @override
  String toString() => 'reserved token';
}

/// The right brace token (`}`).
final class RightBrace extends TokenType {
  const RightBrace._() : super._();

  @override
  String get code => 'right_brace';

  @override
  String toString() => '}';
}

/// The right bracket token (`]`).
final class RightBracket extends TokenType {
  const RightBracket._() : super._();

  @override
  String get code => 'right_bracket';

  @override
  String toString() => ']';
}

/// The right parenthesis token (`)`).
final class RightParenthesis extends TokenType {
  const RightParenthesis._() : super._();

  @override
  String get code => 'right_parenthesis';

  @override
  String toString() => ')';
}

/// The slash token (`/`).
final class Slash extends TokenType {
  const Slash._() : super._();

  @override
  String get code => 'slash';

  @override
  String toString() => '/';
}

/// The string literal.
///
/// String literals are still underspecified. Currently, they will just be "something".
final class StringLiteral extends TokenType implements ExpressionTokenType {
  const StringLiteral._() : super._();

  @override
  String get code => 'string_literal';

  @override
  String toString() => 'string literal';
}

/// The symbol literal.
///
/// It follows the following grammar:
/// ```ebnf
/// <symbol_literal> ::= ":" <identifier>
/// ```
final class SymbolLiteral extends TokenType implements ExpressionTokenType {
  const SymbolLiteral._() : super._();

  @override
  String get code => 'symbol_literal';

  @override
  String toString() => 'symbol literal';
}

/// The `true` keyword token.
final class TrueKeyword extends TokenType implements ExpressionTokenType {
  const TrueKeyword._() : super._();

  @override
  String get code => 'true';

  @override
  String toString() => 'true';
}

/// The `type` keyword token.
final class TypeKeyword extends TokenType {
  const TypeKeyword._() : super._();

  @override
  String get code => 'type';

  @override
  String toString() => 'type';
}
