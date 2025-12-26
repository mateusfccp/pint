// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// VisitorGenerator
// **************************************************************************

import 'element.dart';

abstract interface class ElementVisitor<R> {
  R? visitTypeParameterElement(TypeParameterElement node);
  R? visitStructMemberElement(StructMemberElement node);
  R? visitParameterElement(ParameterElement node);
  R? visitInvocationElement(InvocationElement node);
  R? visitIdentifierElement(IdentifierElement node);
  R? visitSingletonLiteralElement(SingletonLiteralElement node);
  R? visitStructLiteralElement(StructLiteralElement node);
  R? visitTypeVariantElement(TypeVariantElement node);
  R? visitImportElement(ImportElement node);
  R? visitLetFunctionDeclaration(LetFunctionDeclaration node);
  R? visitLetVariableDeclaration(LetVariableDeclaration node);
  R? visitImportedSymbolSyntheticElement(ImportedSymbolSyntheticElement node);
  R? visitTypeDefinitionElement(TypeDefinitionElement node);
  R? visitProgramElement(ProgramElement node);
}

abstract base class SimpleElementVisitor<R> implements ElementVisitor<R> {
  @override
  R? visitTypeParameterElement(TypeParameterElement node) => null;

  @override
  R? visitStructMemberElement(StructMemberElement node) => null;

  @override
  R? visitParameterElement(ParameterElement node) => null;

  @override
  R? visitInvocationElement(InvocationElement node) => null;

  @override
  R? visitIdentifierElement(IdentifierElement node) => null;

  @override
  R? visitSingletonLiteralElement(SingletonLiteralElement node) => null;

  @override
  R? visitStructLiteralElement(StructLiteralElement node) => null;

  @override
  R? visitTypeVariantElement(TypeVariantElement node) => null;

  @override
  R? visitImportElement(ImportElement node) => null;

  @override
  R? visitLetFunctionDeclaration(LetFunctionDeclaration node) => null;

  @override
  R? visitLetVariableDeclaration(LetVariableDeclaration node) => null;

  @override
  R? visitImportedSymbolSyntheticElement(ImportedSymbolSyntheticElement node) =>
      null;

  @override
  R? visitTypeDefinitionElement(TypeDefinitionElement node) => null;

  @override
  R? visitProgramElement(ProgramElement node) => null;
}

abstract base class GeneralizingElementVisitor<R> implements ElementVisitor<R> {
  R? visitElement(Element node) {
    node.visitChildren(this);
    return null;
  }

  R? visitTypedElement(TypedElement node) => visitElement(node);

  R? visitTypeDefiningElement(TypeDefiningElement node) => visitElement(node);

  @override
  R? visitTypeParameterElement(TypeParameterElement node) => visitElement(node);

  @override
  R? visitStructMemberElement(StructMemberElement node) => visitElement(node);

  @override
  R? visitParameterElement(ParameterElement node) => visitElement(node);

  R? visitExpressionElement(ExpressionElement node) => visitElement(node);

  @override
  R? visitInvocationElement(InvocationElement node) =>
      visitExpressionElement(node);

  @override
  R? visitIdentifierElement(IdentifierElement node) =>
      visitExpressionElement(node);

  R? visitLiteralElement(LiteralElement node) => visitExpressionElement(node);

  @override
  R? visitSingletonLiteralElement(SingletonLiteralElement node) =>
      visitLiteralElement(node);

  @override
  R? visitStructLiteralElement(StructLiteralElement node) =>
      visitLiteralElement(node);

  @override
  R? visitTypeVariantElement(TypeVariantElement node) => visitElement(node);

  R? visitDeclarationElement(DeclarationElement node) => visitElement(node);

  @override
  R? visitImportElement(ImportElement node) => visitDeclarationElement(node);

  R? visitLetDeclarationElement(LetDeclarationElement node) =>
      visitDeclarationElement(node);

  @override
  R? visitLetFunctionDeclaration(LetFunctionDeclaration node) =>
      visitLetDeclarationElement(node);

  @override
  R? visitLetVariableDeclaration(LetVariableDeclaration node) =>
      visitLetDeclarationElement(node);

  @override
  R? visitImportedSymbolSyntheticElement(ImportedSymbolSyntheticElement node) =>
      visitDeclarationElement(node);

  @override
  R? visitTypeDefinitionElement(TypeDefinitionElement node) =>
      visitDeclarationElement(node);

  @override
  R? visitProgramElement(ProgramElement node) => visitElement(node);
}
