import 'package:pinto/annotations.dart';
import 'package:pinto/ast.dart' hide Node;
import 'package:pinto/lexer.dart';
import 'package:pinto/syntactic_entity.dart';

part 'ast.g.dart';

@TreeRoot()
sealed class AstNode with _AstNode implements SyntacticEntity {
  const AstNode();

  @override
  int get length => end - offset;

  R? accept<R>(AstNodeVisitor<R> visitor);

  void visitChildren<R>(AstNodeVisitor<R> visitor);
}

sealed class Node extends AstNode with _Node {
  const Node();
}

sealed class StructMember extends Node with _StructMember {
  const StructMember();
}

final class NamelessStructMember extends StructMember
    with _NamelessStructMember {
  const NamelessStructMember(this.value);

  final Expression value;

  @override
  int get offset => value.offset;

  @override
  int get end => value.end;
}

final class ValuelessStructMember extends StructMember
    with _ValuelessStructMember {
  const ValuelessStructMember(this.name);

  final SymbolLiteral name;

  @override
  int get offset => name.offset;

  @override
  int get end => name.end;
}

final class FullStructMember extends StructMember with _FullStructMember {
  const FullStructMember(this.name, this.value);

  final SymbolLiteral name;

  final Expression value;

  @override
  int get offset => name.offset;

  @override
  int get end => value.end;
}

final class TypeVariantNode extends Node with _TypeVariantNode {
  const TypeVariantNode(this.name, this.parameters);

  final Token name;

  final StructLiteral? parameters;

  @override
  int get offset => name.offset;

  @override
  int get end => parameters?.end ?? name.end;
}

sealed class Expression extends AstNode with _Expression {
  const Expression();
}

final class IdentifierExpression extends Expression with _IdentifierExpression {
  const IdentifierExpression(this.identifier);

  final Token identifier;

  @override
  int get offset => identifier.offset;

  @override
  int get end => identifier.end;
}

final class InvocationExpression extends Expression with _InvocationExpression {
  const InvocationExpression(this.identifier, this.argument);

  final IdentifierExpression identifier;

  final Expression argument;

  @override
  int get offset => identifier.offset;

  @override
  int get end => argument.end;
}

sealed class Literal extends Expression with _Literal {
  const Literal();
}

final class BooleanLiteral extends Literal with _BooleanLiteral {
  const BooleanLiteral(this.literal);

  final Token literal;

  @override
  int get offset => literal.offset;

  @override
  int get end => literal.end;
}

final class StringLiteral extends Literal with _StringLiteral {
  const StringLiteral(this.literal);

  final Token literal;

  @override
  int get offset => literal.offset;

  @override
  int get end => literal.end;
}

final class IntegerLiteral extends Literal with _IntegerLiteral {
  const IntegerLiteral(this.literal);

  final Token literal;

  @override
  int get offset => literal.offset;

  @override
  int get end => literal.end;
}

final class DoubleLiteral extends Literal with _DoubleLiteral {
  const DoubleLiteral(this.literal);

  final Token literal;

  @override
  int get offset => literal.offset;

  @override
  int get end => literal.end;
}

final class StructLiteral extends Literal with _StructLiteral {
  const StructLiteral(
    this.leftParenthesis,
    this.members,
    this.rightParenthesis,
  );

  final Token leftParenthesis;

  final SyntacticEntityList<StructMember> members;

  final Token rightParenthesis;

  @override
  int get offset => leftParenthesis.offset;

  @override
  int get end => rightParenthesis.end;
}

final class SymbolLiteral extends Literal with _SymbolLiteral {
  const SymbolLiteral(this.literal);

  final Token literal;

  @override
  int get offset => literal.offset;

  @override
  int get end => literal.end;
}

sealed class Declaration extends AstNode with _Declaration {
  const Declaration();
}

final class ImportDeclaration extends Declaration with _ImportDeclaration {
  const ImportDeclaration(this.keyword, this.type, this.identifier);

  final Token keyword;

  final ImportType type;

  final Token identifier;

  @override
  int get offset => keyword.offset;

  @override
  int get end => identifier.end;
}

final class TypeDefinition extends Declaration with _TypeDefinition {
  const TypeDefinition(
    this.keyword,
    this.name,
    this.leftParenthesis,
    this.parameters,
    this.rightParenthesis,
    this.equals,
    this.variants,
  );

  final Token keyword;

  final Token name;

  final Token? leftParenthesis;

  final SyntacticEntityList<IdentifierExpression>? parameters;

  final Token? rightParenthesis;

  final Token equals;

  final SyntacticEntityList<TypeVariantNode> variants;

  @override
  int get offset => keyword.offset;

  @override
  int get end => variants.end;
}

final class LetDeclaration extends Declaration with _LetDeclaration {
  const LetDeclaration(
    this.keyword,
    this.identifier,
    this.parameter,
    this.equals,
    this.body,
  );

  final Token keyword;

  final Token identifier;

  final StructLiteral? parameter;

  final Token equals;

  final Expression body;

  @override
  int get offset => keyword.offset;

  @override
  int get end => body.end;
}
