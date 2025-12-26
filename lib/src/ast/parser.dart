import 'package:pinto/error.dart';
import 'package:pinto/lexer.dart'
    as token
    show DoubleLiteral, IntegerLiteral, StringLiteral, SymbolLiteral;
import 'package:pinto/lexer.dart'
    hide DoubleLiteral, IntegerLiteral, StringLiteral, SymbolLiteral;
import 'package:pinto/syntactic_entity.dart';

import 'ast.dart';
import 'import.dart';

/// A pint° parser.
final class Parser {
  /// Creates a pint° parser.
  Parser({required List<Token> tokens, ErrorHandler? errorHandler})
    : _errorHandler = errorHandler,
      _tokens = tokens;

  final List<Token> _tokens;
  final ErrorHandler? _errorHandler;

  int _current = 0;

  Token get _previous => _tokens[_current - 1];

  Token get _peek => _tokens[_current];

  bool get _isAtEnd => _peek.type == TokenType.endOfFile;

  bool get _isNotAtEnd => !_isAtEnd;

  List<Declaration> parse() {
    final body = <Declaration>[];

    while (_isNotAtEnd) {
      final declaration = _declaration();

      if (declaration != null) {
        if (body.isNotEmpty &&
            declaration is ImportDeclaration &&
            body[body.length - 1] is! ImportDeclaration) {
          final error = MisplacedImport(importDeclaration: declaration);

          _errorHandler?.emit(error);
        }

        body.add(declaration);
      }
    }

    return body;
  }

  Declaration? _declaration() {
    try {
      if (_match(TokenType.importKeyword)) {
        return _import();
      } else if (_match(TokenType.letKeyword)) {
        return _letDeclaration();
      } else if (_match(TokenType.typeKeyword)) {
        return _typeDefinition();
      } else {
        final error = ExpectedError(
          syntacticEntity: _peek,
          expectation: const DeclarationExpectation(),
        );

        _errorHandler?.emit(error);
        throw error;
      }
    } on ParseError {
      _synchronize();
      return null;
    }
  }

  void _synchronize() {
    _advance();
    while (_isNotAtEnd) {
      switch (_peek.type) {
        case TokenType.importKeyword || //
            TokenType.typeKeyword ||
            TokenType.letKeyword:
          return;
        default:
          _advance();
      }
    }
  }

  bool _match(
    TokenType type1, [
    TokenType? type2,
    TokenType? type3,
    TokenType? type4,
    TokenType? type5,
    TokenType? type6,
    TokenType? type7,
    TokenType? type8,
  ]) {
    final types = [
      type1,
      type2,
      type3,
      type4,
      type5,
      type6,
      type7,
      type8,
    ].nonNulls;

    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }

    return false;
  }

  bool _check(TokenType type) => _isNotAtEnd && _peek.type == type;

  Token _advance() {
    if (_isNotAtEnd) _current++;
    return _previous;
  }

  Token _consume(TokenType tokenType, ParseError error) {
    if (_check(tokenType)) {
      return _advance();
    } else {
      _errorHandler?.emit(error);
      throw error;
    }
  }

  Token _consumeOneOf(List<TokenType> tokenTypes, ParseError error) {
    if (tokenTypes.any(_check)) {
      return _advance();
    } else {
      _errorHandler?.emit(error);
      throw error;
    }
  }

  Token _consumeExpecting(TokenType tokenType) {
    return _consume(
      tokenType,
      ExpectedError(
        syntacticEntity: _peek,
        expectation: TokenExpectation(token: tokenType),
      ),
    );
  }

  Token _consumeExpectingMany(List<TokenType> tokenTypes) {
    return _consumeOneOf(
      tokenTypes,
      ExpectedError(
        syntacticEntity: _peek,
        expectation: OneOfExpectation(
          expectations: [
            for (final tokenType in tokenTypes)
              TokenExpectation(token: tokenType),
          ],
        ),
      ),
    );
  }

  Token _consumeAfter({
    required TokenType type,
    required TokenType after,
    String? description,
  }) {
    return _consume(
      type,
      ExpectedAfterError(
        syntacticEntity: _peek,
        expectation: TokenExpectation(token: type),
        after: TokenExpectation(token: after, description: description),
      ),
    );
  }

  ImportDeclaration _import() {
    final keyword = _previous;

    final Token identifier = _consumeExpectingMany([
      TokenType.identifier,
      TokenType.importIdentifier,
    ]);

    final ImportType type;

    if (identifier.type == TokenType.importIdentifier) {
      type = ImportType.dart;
    } else {
      type = ImportType.package;
    }

    return ImportDeclaration(keyword, type, identifier);
  }

  Expression _expression() {
    if (_peek.type case final ExpressionTokenType tokenType) {
      if (tokenType is! LeftBrace && tokenType is! LeftBracket) {
        _advance();
      }

      return switch (tokenType) {
        token.DoubleLiteral() => DoubleLiteral(_previous),
        FalseKeyword() => BooleanLiteral(_previous),
        Identifier() => _identifierOrInvocation(),
        token.IntegerLiteral() => IntegerLiteral(_previous),
        LeftParenthesis() => _structLiteral(),
        token.StringLiteral() => StringLiteral(_previous),
        token.SymbolLiteral() => _symbolLiteral(),
        TrueKeyword() => BooleanLiteral(_previous),
        LeftBrace() || LeftBracket() => _typeIdentifier(),
      };
    } else {
      throw ExpectedError(
        syntacticEntity: _previous,
        expectation: const ExpressionExpectation(),
      );
    }
  }

  IdentifierExpression _identifier() {
    assert(_previous.type == TokenType.identifier);
    return IdentifierExpression(_previous);
  }

  Expression _identifierOrInvocation() {
    final identifier = _identifier();
    if (_peek.type is ExpressionTokenType) {
      return InvocationExpression(identifier, _expression());
    } else {
      return identifier;
    }
  }

  StructLiteral _structLiteral() {
    final leftParenthesis = _previous;

    final members = SyntacticEntityList<StructMember>();

    while (!_check(TokenType.rightParenthesis)) {
      members.add(_structMember());
      final comma = _match(TokenType.comma);

      if (!comma) break;
    }

    final rightParenthesis = _consumeExpecting(TokenType.rightParenthesis);

    return StructLiteral(leftParenthesis, members, rightParenthesis);
  }

  StructMember _structMember() {
    if (_match(TokenType.symbolLiteral)) {
      final name = _symbolLiteral();

      if (_peek.type is ExpressionTokenType) {
        final expression = _expression();

        return FullStructMember(name, expression);
      } else {
        return ValuelessStructMember(name);
      }
    } else {
      final value = _expression();

      return NamelessStructMember(value);
    }
  }

  SymbolLiteral _symbolLiteral() {
    assert(_previous.type == TokenType.symbolLiteral);
    return SymbolLiteral(_previous);
  }

  LetDeclaration _letDeclaration() {
    final keyword = _previous;
    final identifier = _consumeExpecting(TokenType.identifier);

    final StructLiteral? parameter;
    if (_check(TokenType.equalitySign)) {
      parameter = null;
    } else {
      _consumeExpecting(TokenType.leftParenthesis);
      parameter = _structLiteral();
    }

    final equals = _consume(
      TokenType.equalitySign,
      ExpectedAfterError(
        syntacticEntity: _peek,
        expectation: const TokenExpectation(token: TokenType.equalitySign),
        after: TokenExpectation(
          token: TokenType.identifier,
          description: parameter == null
              ? 'declaration name'
              : 'parameter name',
        ),
      ),
    );

    final body = _expression();

    return LetDeclaration(keyword, identifier, parameter, equals, body);
  }

  TypeDefinition _typeDefinition() {
    final keyword = _previous;

    final name = _consumeAfter(
      type: TokenType.identifier,
      after: TokenType.typeKeyword,
    );

    final typeParameters = <IdentifierExpression>[];

    final Token? leftParenthesis;
    final Token? rightParenthesis;

    if (_match(TokenType.leftParenthesis)) {
      leftParenthesis = _previous;

      final firstTypeParameter = _consumeExpecting(TokenType.identifier);

      typeParameters.add(IdentifierExpression(firstTypeParameter));

      while (!_check(TokenType.rightParenthesis)) {
        _consumeAfter(
          type: TokenType.comma,
          after: TokenType.identifier,
          description: 'type parameter',
        );

        final typeParameter = _consumeExpecting(TokenType.identifier);

        typeParameters.add(IdentifierExpression(typeParameter));
      }

      rightParenthesis = _consumeAfter(
        type: TokenType.rightParenthesis,
        after: TokenType.identifier,
        description: 'type parameter',
      );
    } else {
      leftParenthesis = null;
      rightParenthesis = null;
    }

    final equals = _consumeAfter(
      type: TokenType.equalitySign,
      after: TokenType.identifier,
      description: 'type name',
    );

    final variants = <TypeVariantNode>[_typeVariant(true)];

    while (_match(TokenType.plusSign)) {
      variants.add(_typeVariant(false));
    }

    return TypeDefinition(
      keyword,
      name,
      leftParenthesis,
      SyntacticEntityList(typeParameters),
      rightParenthesis,
      equals,
      SyntacticEntityList(variants),
    );
  }

  TypeVariantNode _typeVariant(bool isFirstVariation) {
    final name = _consumeAfter(
      type: TokenType.identifier,
      after:
          isFirstVariation //
          ? TokenType.equalitySign
          : TokenType.plusSign,
    );

    final StructLiteral? parameters;

    if (_match(TokenType.leftParenthesis)) {
      parameters = _structLiteral();
    } else {
      parameters = null;
    }

    return TypeVariantNode(name, parameters);
  }

  Expression _typeIdentifier() {
    if (_match(TokenType.leftBracket)) {
      final leftBracket = _previous;
      final literal = _typeIdentifier();

      _consumeAfter(
        type: TokenType.rightBracket,
        after: TokenType.identifier, // TODO(mateusfccp): Fix this
      );

      return _createDesugaredType(
        lexeme: 'List',
        offset: leftBracket.offset,
        argument: literal,
      );
    } else if (_match(TokenType.leftBrace)) {
      final leftBrace = _previous;
      final literal = _typeIdentifier();

      final Token? colon;
      final Expression? valueLiteral;

      if (_match(TokenType.colon)) {
        colon = _previous;
        valueLiteral = _typeIdentifier();
      } else {
        colon = null;
        valueLiteral = null;
      }

      final rightBrace = _consumeAfter(
        type: TokenType.rightBrace,
        after: TokenType.identifier, // TODO(mateusfccp): Fix this
      );

      if (colon == null || valueLiteral == null) {
        return _createDesugaredType(
          lexeme: 'Set',
          offset: leftBrace.offset,
          argument: literal,
        );
      } else {
        return _createDesugaredType(
          lexeme: 'Map',
          offset: leftBrace.offset,
          argument: StructLiteral(
            Token(
              type: TokenType.leftParenthesis,
              offset: leftBrace.offset,
              lexeme: '(',
            ),
            SyntacticEntityList([
              NamelessStructMember(literal),
              NamelessStructMember(valueLiteral),
            ]),
            Token(
              type: TokenType.rightParenthesis,
              offset: rightBrace.offset,
              lexeme: ')',
            ),
          ),
        );
      }
    } else {
      final expression = _expression();

      if (_match(TokenType.eroteme)) {
        return _createDesugaredType(
          lexeme: 'Option',
          offset: _previous.offset,
          argument: expression,
        );
      } else {
        return expression;
      }
    }
  }
}

@pragma('vm:prefer-inline')
Expression _createDesugaredType({
  required String lexeme,
  required int offset,
  required Expression argument,
}) {
  return InvocationExpression(
    IdentifierExpression(
      Token(type: TokenType.identifier, offset: offset, lexeme: lexeme),
    ),
    argument,
  );
}
