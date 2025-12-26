// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// VisitorGenerator
// **************************************************************************

import 'ast.dart';

abstract interface class AstNodeVisitor<R> {
  R? visitNamelessStructMember(NamelessStructMember node);
  R? visitValuelessStructMember(ValuelessStructMember node);
  R? visitFullStructMember(FullStructMember node);
  R? visitTypeVariantNode(TypeVariantNode node);
  R? visitIdentifierExpression(IdentifierExpression node);
  R? visitInvocationExpression(InvocationExpression node);
  R? visitBooleanLiteral(BooleanLiteral node);
  R? visitStringLiteral(StringLiteral node);
  R? visitIntegerLiteral(IntegerLiteral node);
  R? visitDoubleLiteral(DoubleLiteral node);
  R? visitStructLiteral(StructLiteral node);
  R? visitSymbolLiteral(SymbolLiteral node);
  R? visitImportDeclaration(ImportDeclaration node);
  R? visitTypeDefinition(TypeDefinition node);
  R? visitLetDeclaration(LetDeclaration node);
}

abstract base class SimpleAstNodeVisitor<R> implements AstNodeVisitor<R> {
  @override
  R? visitNamelessStructMember(NamelessStructMember node) => null;

  @override
  R? visitValuelessStructMember(ValuelessStructMember node) => null;

  @override
  R? visitFullStructMember(FullStructMember node) => null;

  @override
  R? visitTypeVariantNode(TypeVariantNode node) => null;

  @override
  R? visitIdentifierExpression(IdentifierExpression node) => null;

  @override
  R? visitInvocationExpression(InvocationExpression node) => null;

  @override
  R? visitBooleanLiteral(BooleanLiteral node) => null;

  @override
  R? visitStringLiteral(StringLiteral node) => null;

  @override
  R? visitIntegerLiteral(IntegerLiteral node) => null;

  @override
  R? visitDoubleLiteral(DoubleLiteral node) => null;

  @override
  R? visitStructLiteral(StructLiteral node) => null;

  @override
  R? visitSymbolLiteral(SymbolLiteral node) => null;

  @override
  R? visitImportDeclaration(ImportDeclaration node) => null;

  @override
  R? visitTypeDefinition(TypeDefinition node) => null;

  @override
  R? visitLetDeclaration(LetDeclaration node) => null;
}

abstract base class GeneralizingAstNodeVisitor<R> implements AstNodeVisitor<R> {
  R? visitAstNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  R? visitNode(Node node) => visitAstNode(node);

  R? visitStructMember(StructMember node) => visitNode(node);

  @override
  R? visitNamelessStructMember(NamelessStructMember node) =>
      visitStructMember(node);

  @override
  R? visitValuelessStructMember(ValuelessStructMember node) =>
      visitStructMember(node);

  @override
  R? visitFullStructMember(FullStructMember node) => visitStructMember(node);

  @override
  R? visitTypeVariantNode(TypeVariantNode node) => visitNode(node);

  R? visitExpression(Expression node) => visitAstNode(node);

  @override
  R? visitIdentifierExpression(IdentifierExpression node) =>
      visitExpression(node);

  @override
  R? visitInvocationExpression(InvocationExpression node) =>
      visitExpression(node);

  R? visitLiteral(Literal node) => visitExpression(node);

  @override
  R? visitBooleanLiteral(BooleanLiteral node) => visitLiteral(node);

  @override
  R? visitStringLiteral(StringLiteral node) => visitLiteral(node);

  @override
  R? visitIntegerLiteral(IntegerLiteral node) => visitLiteral(node);

  @override
  R? visitDoubleLiteral(DoubleLiteral node) => visitLiteral(node);

  @override
  R? visitStructLiteral(StructLiteral node) => visitLiteral(node);

  @override
  R? visitSymbolLiteral(SymbolLiteral node) => visitLiteral(node);

  R? visitDeclaration(Declaration node) => visitAstNode(node);

  @override
  R? visitImportDeclaration(ImportDeclaration node) => visitDeclaration(node);

  @override
  R? visitTypeDefinition(TypeDefinition node) => visitDeclaration(node);

  @override
  R? visitLetDeclaration(LetDeclaration node) => visitDeclaration(node);
}
