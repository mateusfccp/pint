import 'package:collection/collection.dart';
import 'package:pinto/error.dart';

import 'token.dart';

/// A Pinto lexer.
final class Lexer {
  /// Creates a Pinto lexer for [source].
  Lexer({required String source, ErrorHandler? errorHandler})
    : _errorHandler = errorHandler,
      _source = source;

  final String _source;
  final ErrorHandler? _errorHandler;
  final _tokens = <Token>[];
  final _lineBreaks = <int>[];

  var _start = 0;
  var _current = 0;

  // TODO(mateusfccp): Check what should be a contextual keyword or not
  static const _keywords = {
    'import': TokenType.importKeyword,
    'false': TokenType.falseKeyword,
    'let': TokenType
        .letKeyword, // TODO: Make it a contextual keyword for iteroperability reasons
    'true': TokenType.trueKeyword,
    'type': TokenType.typeKeyword,

    // Reserved for interoperability with Dart
    'assert': TokenType.reserved,
    'break': TokenType.reserved,
    'case': TokenType.reserved,
    'catch': TokenType.reserved,
    'class': TokenType.reserved,
    'const': TokenType.reserved,
    'continue': TokenType.reserved,
    'default': TokenType.reserved,
    'do': TokenType.reserved,
    'else': TokenType.reserved,
    'enum': TokenType.reserved,
    'extends': TokenType.reserved,
    'final': TokenType.reserved,
    'finally': TokenType.reserved,
    'for': TokenType.reserved,
    'if': TokenType.reserved,
    'in': TokenType.reserved,
    'is': TokenType.reserved,
    'new': TokenType.reserved,
    'null': TokenType.reserved,
    'rethrow': TokenType.reserved,
    'return': TokenType.reserved,
    'super': TokenType.reserved,
    'switch': TokenType.reserved,
    'this': TokenType.reserved,
    'throw': TokenType.reserved,
    'try': TokenType.reserved,
    'var': TokenType.reserved,
    'void': TokenType.reserved,
    'with': TokenType.reserved,
    'while': TokenType.reserved,
  };

  bool get _isAtEnd => _current >= _source.length;

  /// Scans the source and returns the tokens.
  List<Token> scanTokens() {
    while (!_isAtEnd) {
      _start = _current;
      _scanToken();
    }

    _tokens.add(Token(type: TokenType.endOfFile, lexeme: '', offset: _start));
    return _tokens;
  }

  (int line, int column) positionForOffset(int offset) {
    final bound = lowerBound(_lineBreaks, offset);
    final line = bound + 1;
    final start = bound == 0 ? -1 : _lineBreaks[bound - 1];
    final column = offset - start;

    return (line, column);
  }

  void _scanToken() {
    final character = _advance();
    return switch (character) {
      '@' => _identifier(true),
      '?' => _addToken(TokenType.eroteme),
      '(' => _addToken(TokenType.leftParenthesis),
      ')' => _addToken(TokenType.rightParenthesis),
      '[' => _addToken(TokenType.leftBracket),
      ']' => _addToken(TokenType.rightBracket),
      '{' => _addToken(TokenType.leftBrace),
      '}' => _addToken(TokenType.rightBrace),
      ',' => _addToken(TokenType.comma),
      '+' => _addToken(TokenType.plusSign),
      '-' => _minus(),
      '=' => _equals(),
      ':' => _symbolLiteral(),
      '"' => _string(),
      '/' => _slash(),
      ' ' || '\r' || '\t' => null,
      '\n' => _lineBreak(),
      final character when _isNumeric(character) => _numberLiteral(),
      final character => _character(character),
    };
  }

  void _minus() {
    if (_match('>')) {
      _addToken(TokenType.arrow);
    }
  }

  void _equals() {
    if (_match('>')) {
      _addToken(TokenType.doubleArrow);
    } else {
      _addToken(TokenType.equalitySign);
    }
  }

  void _symbolLiteral() {
    if (!_isIdentifierStart(_peek)) {
      _errorHandler?.emit(InvalidIdentifierStart(offset: _current));
    }

    while (_isIdentifierPart(_peek)) {
      _advance();
    }

    _addToken(TokenType.symbolLiteral);
  }

  void _string() {
    while (_peek != '"' && _peek != '\n' && !_isAtEnd) {
      _advance();
    }

    // Strings should not span to more than one line, and should be closed
    if (_peek == '\n' || _isAtEnd) {
      _errorHandler?.emit(UnterminatedStringError(offset: _current));
      _lineBreak();
    } else {
      // Advance to the closing quotes (")
      _advance();
      _addToken(TokenType.stringLiteral);
    }
  }

  void _slash() {
    if (_match('/')) {
      while (_peek != '\n' && !_isAtEnd) {
        _advance();
      }
    } else if (_match('*')) {
      _advanceUntilCommentEnd();
    } else {
      _addToken(TokenType.slash);
    }
  }

  void advanceNumbersAndSeparators() {
    String? lastRead;
    while ((_isNumeric(_peek) || _peek == '_') && !_isAtEnd) {
      lastRead = _peek;
      _advance();
    }

    if (lastRead == '_') {
      _errorHandler?.emit(NumberEndingWithSeparatorError(offset: _current - 1));
    }
  }

  void _numberLiteral() {
    advanceNumbersAndSeparators();

    // Found dot. Try parsing double
    if (_peek == '.' && !_isAtEnd && _isNumeric(_source[_current + 1])) {
      // Advance the dot
      _advance();
      advanceNumbersAndSeparators();
      _addToken(TokenType.doubleLiteral);
    } else {
      _addToken(TokenType.integerLiteral);
    }
  }

  void _lineBreak() => _lineBreaks.add(_current - 1);

  void _character(String character) {
    assert(character.length == 1);

    if (_isIdentifierStart(character)) {
      _identifier(false);
    } else {
      _errorHandler?.emit(UnexpectedCharacterError(offset: _current - 1));
    }
  }

  void _addToken(TokenType type) {
    final text = _source.substring(_start, _current);

    final token = Token(type: type, lexeme: text, offset: _start);

    _tokens.add(token);
  }

  String _advance() => _source[_current++];

  void _advanceUntilCommentEnd() {
    int commentLevel = 1;

    while (commentLevel > 0 && !_isAtEnd) {
      if (_match('/') && _peek == '*') {
        commentLevel = commentLevel + 1;
      } else if (_match('*') && _peek == '/') {
        commentLevel = commentLevel - 1;
      }

      if (_peek == '\n') {
        _lineBreak();
      }

      _advance();
    }
  }

  bool _match(String expected) {
    if (_isAtEnd || _source[_current] != expected) {
      return false;
    } else {
      _current++;
      return true;
    }
  }

  String get _peek => _isAtEnd ? '\x00' : _source[_current];

  bool _isIdentifierStart(String character) {
    assert(character.length == 1);
    return RegExp(r'[A-Za-z_$]').hasMatch(character);
  }

  bool _isIdentifierPart(String character) {
    assert(character.length == 1);
    return RegExp(r'[A-Za-z_$0-9]').hasMatch(character);
  }

  void _identifier(bool isImportIdentifier) {
    while (_isIdentifierPart(_peek)) {
      _advance();
    }

    while (_peek == '/') {
      isImportIdentifier = true;

      _advance();

      while (_isIdentifierPart(_peek)) {
        _advance();
      }
    }

    final text = _source.substring(_start, _current);
    final TokenType tokenType;

    if (isImportIdentifier) {
      tokenType = TokenType.importIdentifier;
    } else if (_keywords[text] case final keyword?) {
      tokenType = keyword;
    } else {
      tokenType = TokenType.identifier;
    }

    _addToken(tokenType);
  }
}

bool _isNumeric(String character) {
  assert(character.length == 1);
  return RegExp(r'[\d]').hasMatch(character);
}
