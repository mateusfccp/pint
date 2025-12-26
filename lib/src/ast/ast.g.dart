// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ast.dart';

// **************************************************************************
// TreeGenerator
// **************************************************************************

base mixin _AstNode {
  int get _length => (this as AstNode).length;
  @override
  String toString() => 'AstNode(length: $_length)';
}

base mixin _Node {
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() => 'Node';
}

base mixin _StructMember {
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() => 'StructMember';
}

base mixin _NamelessStructMember {
  Expression get _value => (this as NamelessStructMember).value;
  int get _offset => (this as NamelessStructMember).offset;
  int get _end => (this as NamelessStructMember).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitNamelessStructMember((this as NamelessStructMember));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {
    _value.accept(visitor);
  }

  @override
  String toString() =>
      'NamelessStructMember(value: $_value, offset: $_offset, end: $_end)';
}

base mixin _ValuelessStructMember {
  SymbolLiteral get _name => (this as ValuelessStructMember).name;
  int get _offset => (this as ValuelessStructMember).offset;
  int get _end => (this as ValuelessStructMember).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitValuelessStructMember((this as ValuelessStructMember));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {
    _name.accept(visitor);
  }

  @override
  String toString() =>
      'ValuelessStructMember(name: $_name, offset: $_offset, end: $_end)';
}

base mixin _FullStructMember {
  SymbolLiteral get _name => (this as FullStructMember).name;
  Expression get _value => (this as FullStructMember).value;
  int get _offset => (this as FullStructMember).offset;
  int get _end => (this as FullStructMember).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitFullStructMember((this as FullStructMember));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {
    _name.accept(visitor);
    _value.accept(visitor);
  }

  @override
  String toString() =>
      'FullStructMember(name: $_name, value: $_value, offset: $_offset, end: $_end)';
}

base mixin _TypeVariantNode {
  Token get _name => (this as TypeVariantNode).name;
  StructLiteral? get _parameters => (this as TypeVariantNode).parameters;
  int get _offset => (this as TypeVariantNode).offset;
  int get _end => (this as TypeVariantNode).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitTypeVariantNode((this as TypeVariantNode));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {
    _parameters?.accept(visitor);
  }

  @override
  String toString() =>
      'TypeVariantNode(name: $_name, parameters: $_parameters, offset: $_offset, end: $_end)';
}

base mixin _Expression {
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() => 'Expression';
}

base mixin _IdentifierExpression {
  Token get _identifier => (this as IdentifierExpression).identifier;
  int get _offset => (this as IdentifierExpression).offset;
  int get _end => (this as IdentifierExpression).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitIdentifierExpression((this as IdentifierExpression));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'IdentifierExpression(identifier: $_identifier, offset: $_offset, end: $_end)';
}

base mixin _InvocationExpression {
  IdentifierExpression get _identifier =>
      (this as InvocationExpression).identifier;
  Expression get _argument => (this as InvocationExpression).argument;
  int get _offset => (this as InvocationExpression).offset;
  int get _end => (this as InvocationExpression).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitInvocationExpression((this as InvocationExpression));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {
    _identifier.accept(visitor);
    _argument.accept(visitor);
  }

  @override
  String toString() =>
      'InvocationExpression(identifier: $_identifier, argument: $_argument, offset: $_offset, end: $_end)';
}

base mixin _Literal {
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() => 'Literal';
}

base mixin _BooleanLiteral {
  Token get _literal => (this as BooleanLiteral).literal;
  int get _offset => (this as BooleanLiteral).offset;
  int get _end => (this as BooleanLiteral).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitBooleanLiteral((this as BooleanLiteral));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'BooleanLiteral(literal: $_literal, offset: $_offset, end: $_end)';
}

base mixin _StringLiteral {
  Token get _literal => (this as StringLiteral).literal;
  int get _offset => (this as StringLiteral).offset;
  int get _end => (this as StringLiteral).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitStringLiteral((this as StringLiteral));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'StringLiteral(literal: $_literal, offset: $_offset, end: $_end)';
}

base mixin _IntegerLiteral {
  Token get _literal => (this as IntegerLiteral).literal;
  int get _offset => (this as IntegerLiteral).offset;
  int get _end => (this as IntegerLiteral).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitIntegerLiteral((this as IntegerLiteral));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'IntegerLiteral(literal: $_literal, offset: $_offset, end: $_end)';
}

base mixin _DoubleLiteral {
  Token get _literal => (this as DoubleLiteral).literal;
  int get _offset => (this as DoubleLiteral).offset;
  int get _end => (this as DoubleLiteral).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitDoubleLiteral((this as DoubleLiteral));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'DoubleLiteral(literal: $_literal, offset: $_offset, end: $_end)';
}

base mixin _StructLiteral {
  Token get _leftParenthesis => (this as StructLiteral).leftParenthesis;
  SyntacticEntityList<StructMember> get _members =>
      (this as StructLiteral).members;
  Token get _rightParenthesis => (this as StructLiteral).rightParenthesis;
  int get _offset => (this as StructLiteral).offset;
  int get _end => (this as StructLiteral).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitStructLiteral((this as StructLiteral));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'StructLiteral(leftParenthesis: $_leftParenthesis, members: $_members, rightParenthesis: $_rightParenthesis, offset: $_offset, end: $_end)';
}

base mixin _SymbolLiteral {
  Token get _literal => (this as SymbolLiteral).literal;
  int get _offset => (this as SymbolLiteral).offset;
  int get _end => (this as SymbolLiteral).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitSymbolLiteral((this as SymbolLiteral));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'SymbolLiteral(literal: $_literal, offset: $_offset, end: $_end)';
}

base mixin _Declaration {
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() => 'Declaration';
}

base mixin _ImportDeclaration {
  Token get _keyword => (this as ImportDeclaration).keyword;
  ImportType get _type => (this as ImportDeclaration).type;
  Token get _identifier => (this as ImportDeclaration).identifier;
  int get _offset => (this as ImportDeclaration).offset;
  int get _end => (this as ImportDeclaration).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitImportDeclaration((this as ImportDeclaration));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'ImportDeclaration(keyword: $_keyword, type: $_type, identifier: $_identifier, offset: $_offset, end: $_end)';
}

base mixin _TypeDefinition {
  Token get _keyword => (this as TypeDefinition).keyword;
  Token get _name => (this as TypeDefinition).name;
  Token? get _leftParenthesis => (this as TypeDefinition).leftParenthesis;
  SyntacticEntityList<Expression>? get _parameters =>
      (this as TypeDefinition).parameters;
  Token? get _rightParenthesis => (this as TypeDefinition).rightParenthesis;
  Token get _equals => (this as TypeDefinition).equals;
  SyntacticEntityList<TypeVariantNode> get _variants =>
      (this as TypeDefinition).variants;
  int get _offset => (this as TypeDefinition).offset;
  int get _end => (this as TypeDefinition).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitTypeDefinition((this as TypeDefinition));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {}
  @override
  String toString() =>
      'TypeDefinition(keyword: $_keyword, name: $_name, leftParenthesis: $_leftParenthesis, parameters: $_parameters, rightParenthesis: $_rightParenthesis, equals: $_equals, variants: $_variants, offset: $_offset, end: $_end)';
}

base mixin _LetDeclaration {
  Token get _keyword => (this as LetDeclaration).keyword;
  Token get _identifier => (this as LetDeclaration).identifier;
  StructLiteral? get _parameter => (this as LetDeclaration).parameter;
  Token get _equals => (this as LetDeclaration).equals;
  Expression get _body => (this as LetDeclaration).body;
  int get _offset => (this as LetDeclaration).offset;
  int get _end => (this as LetDeclaration).end;
  R? accept<R>(AstNodeVisitor<R> visitor) =>
      visitor.visitLetDeclaration((this as LetDeclaration));
  void visitChildren<R>(AstNodeVisitor<R> visitor) {
    _parameter?.accept(visitor);
    _body.accept(visitor);
  }

  @override
  String toString() =>
      'LetDeclaration(keyword: $_keyword, identifier: $_identifier, parameter: $_parameter, equals: $_equals, body: $_body, offset: $_offset, end: $_end)';
}
