import 'package:pinto/annotations.dart';

import 'package.dart';
import 'type.dart';
import 'element.visitors.dart';

part 'element.g.dart';

@TreeRoot()
sealed class Element with _Element {
  const Element();

  Element? get enclosingElement;

  R? accept<R>(ElementVisitor<R> visitor);

  void visitChildren<R>(ElementVisitor<R> visitor);
}

abstract final class TypedElement extends Element {
  Type? get type;
}

abstract final class TypeDefiningElement extends Element {
  Type get definedType;
}

final class TypeParameterElement extends Element
    with _TypeParameterElement
    implements TypedElement, TypeDefiningElement {
  TypeParameterElement({required this.name});

  final String name;

  @override
  late TypeDefinitionElement enclosingElement;

  @override
  Type? get type => TypeType(definedType);

  @override
  late Type definedType;
}

final class StructMemberElement extends Element with _StructMemberElement {
  late final String name;

  late final ExpressionElement value;

  @override
  late LiteralElement enclosingElement;
}

final class ParameterElement extends Element
    with _ParameterElement
    implements TypedElement {
  ParameterElement({required this.name, this.type});

  final String name;

  @override
  Type? type;

  @override
  late Element enclosingElement;
}

sealed class ExpressionElement extends Element
    with _ExpressionElement
    implements TypedElement {
  @override
  late Element enclosingElement;

  bool get constant => constantValue != null;

  Object? get constantValue;
}

final class InvocationElement extends ExpressionElement
    with _InvocationElement {
  InvocationElement({
    this.type,
    required this.identifier,
    required this.argument,
    required this.constantValue,
  });

  @override
  Type? type;

  final IdentifierElement identifier;

  final ExpressionElement argument;

  @override
  final Object? constantValue;
}

final class IdentifierElement extends ExpressionElement
    with _IdentifierElement {
  IdentifierElement({
    required this.name,
    this.type,
    required this.constantValue,
  });

  final String name;

  @override
  Type? type;

  @override
  final Object? constantValue;
}

sealed class LiteralElement extends ExpressionElement with _LiteralElement {}

final class SingletonLiteralElement extends LiteralElement
    with _SingletonLiteralElement {
  SingletonLiteralElement({this.type});

  @override
  Type? type;

  @override
  late final Object? constantValue;
}

final class StructLiteralElement extends LiteralElement
    with _StructLiteralElement {
  @override
  late final StructType type;

  final List<StructMemberElement> members = [];

  @override
  late final Object? constantValue;
}

final class TypeVariantElement extends Element with _TypeVariantElement {
  TypeVariantElement({required this.name});

  final String name;

  final parameters = <ParameterElement>[];

  @override
  late TypeDefinitionElement enclosingElement;
}

sealed class DeclarationElement extends Element with _DeclarationElement {
  @override
  late ProgramElement enclosingElement;
}

final class ImportElement extends DeclarationElement with _ImportElement {
  ImportElement({required this.package});

  final Package package;
}

sealed class LetDeclarationElement extends DeclarationElement
    with _LetDeclarationElement
    implements TypedElement {
  LetDeclarationElement({required this.name});

  final String name;

  late final ExpressionElement body;

  @override
  void visitChildren<R>(ElementVisitor<R> visitor) {
    body.accept(visitor);
  }
}

final class LetFunctionDeclaration extends LetDeclarationElement
    with _LetFunctionDeclaration {
  LetFunctionDeclaration({required super.name, required this.parameter});

  final StructLiteralElement parameter;

  @override
  late FunctionType type;
}

final class LetVariableDeclaration extends LetDeclarationElement
    with _LetVariableDeclaration {
  LetVariableDeclaration({required super.name, this.type});

  @override
  Type? type;
}

final class ImportedSymbolSyntheticElement extends DeclarationElement
    with _ImportedSymbolSyntheticElement
    implements TypedElement {
  ImportedSymbolSyntheticElement({
    required this.name,
    required this.syntheticElement,
  });

  final String name;

  final TypedElement syntheticElement;

  @override
  Type get type => syntheticElement.type!;
}

final class TypeDefinitionElement extends DeclarationElement
    with _TypeDefinitionElement
    implements TypedElement, TypeDefiningElement {
  TypeDefinitionElement({required this.name});

  final String name;

  final parameters = <TypeParameterElement>[];

  final variants = <TypeVariantElement>[];

  @override
  Type? get type => TypeType(definedType);

  @override
  late Type definedType;
}

final class ProgramElement extends Element with _ProgramElement {
  final imports = <ImportElement>[];

  final declarations = <DeclarationElement>[];

  @override
  late final Null enclosingElement = null;
}
