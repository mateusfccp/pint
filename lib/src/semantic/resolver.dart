import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pinto/ast.dart';
import 'package:pinto/error.dart';
import 'package:pinto/lexer.dart'
    hide DoubleLiteral, IntegerLiteral, StringLiteral, SymbolLiteral;

import 'element.dart';
import 'environment.dart';
import 'package.dart';
import 'symbols_resolver.dart';
import 'type.dart';

final class Resolver extends SimpleAstNodeVisitor<Future<Element>> {
  Resolver({
    required this.program,
    required this.symbolsResolver,
    ErrorHandler? errorHandler,
  }) : _errorHandler = errorHandler;

  final List<Declaration> program;
  final SymbolsResolver symbolsResolver;
  final ErrorHandler? _errorHandler;

  Environment _environment = Environment();

  final _unresolvedParameters = <ParameterElement, Expression>{};

  Future<ProgramElement> resolve() async {
    const core = DartSdkPackage(name: 'core');
    final programElement = ProgramElement();
    final syntheticTypeDefinitions = await _resolvePackage(core);

    void defineTypeAlias(String name, Type definedType) {
      final syntheticElement = ImportedSymbolSyntheticElement(
        name: 'Unknown',
        syntheticElement: TypeDefinitionElement(name: 'Unknown')
          ..definedType = const UnknownType(),
      );

      syntheticTypeDefinitions.add(syntheticElement);

      _environment.defineSymbol(name, syntheticElement);
    }

    defineTypeAlias('Unknown', const UnknownType());
    defineTypeAlias('Never', const NeverType());

    final importsDeclarations = <ImportDeclaration>[];
    final importsElementsFuture = <Future<ImportElement>>[];

    // At this point, imports should be guaranteed to come before anything else.
    // This is guaranteed in the parser (maybe not the best place?).

    for (final importDeclaration in program.whereType<ImportDeclaration>()) {
      try {
        importsDeclarations.add(importDeclaration);
        importsElementsFuture.add(() async {
          final import = await importDeclaration.accept(this) as ImportElement;
          import.enclosingElement = programElement;
          programElement.imports.add(import);
          return import;
        }());
      } on ResolveError catch (error) {
        _errorHandler?.emit(error);
      }
    }

    final importElements = await importsElementsFuture.wait;
    for (int i = 0; i < importElements.length; i++) {
      try {
        final element = importElements[i];

        syntheticTypeDefinitions.addAll(await _resolvePackage(element.package));
      } on Exception {
        final declaration = importsDeclarations[i];
        throw ImportedPackageNotAvailableError(declaration.identifier);
      } on ResolveError catch (error) {
        _errorHandler?.emit(error);
      }
    }

    for (final definition in syntheticTypeDefinitions) {
      programElement.declarations.add(definition);
      definition.enclosingElement = programElement;
    }

    for (final declaration in program.whereNot(
      (declaration) => declaration is ImportDeclaration,
    )) {
      try {
        if (declaration is LetDeclaration) {
          final letVariableDeclaration =
              await declaration.accept(this) as DeclarationElement;
          letVariableDeclaration.enclosingElement = programElement;
          programElement.declarations.add(letVariableDeclaration);
        } else {
          final typeDefinition =
              await declaration.accept(this) as TypeDefinitionElement;
          typeDefinition.enclosingElement = programElement;
          programElement.declarations.add(typeDefinition);
        }
      } on ResolveError catch (error) {
        _errorHandler?.emit(error);
      }
    }

    for (final MapEntry(key: parameterElement, value: typeIdentifier)
        in _unresolvedParameters.entries) {
      try {
        parameterElement.type = _resolveType(typeIdentifier);
      } on _SymbolNotResolved {
        // TODO(mateusfccp): do better
        final type = typeIdentifier as IdentifierExpression;
        _errorHandler?.emit(SymbolNotInScopeError(type.identifier));
      }
    }

    return programElement;
  }

  @override
  Future<Element> visitBooleanLiteral(BooleanLiteral node) async {
    return SingletonLiteralElement(type: const BooleanType())
      ..constantValue = node.literal.type == TokenType.trueKeyword
          ? true
          : false;
  }

  @override
  Future<Element> visitDoubleLiteral(DoubleLiteral node) async {
    return SingletonLiteralElement(type: const DoubleType())
      ..constantValue = double.parse(_removeSeparators(node.literal.lexeme));
  }

  @override
  Future<StructMemberElement> visitFullStructMember(
    FullStructMember node,
  ) async {
    final value = await node.value.accept(this) as ExpressionElement;

    return StructMemberElement() //
      ..name = node.name.literal.lexeme.substring(1)
      ..value = value;
  }

  @override
  Future<IdentifierElement> visitIdentifierExpression(
    IdentifierExpression node,
  ) async {
    final definition = _environment.getDefinition(node.identifier.lexeme);

    if (definition == null) {
      throw SymbolNotInScopeError(node.identifier);
    }

    final Object? constantValue;

    if (definition is LetVariableDeclaration) {
      constantValue = definition.body.constantValue;
    } else if (definition case ImportedSymbolSyntheticElement(
      syntheticElement: TypeDefinitionElement typeDefinitionElement,
    )) {
      constantValue = typeDefinitionElement.definedType;
    } else {
      constantValue = null;
    }

    // TODO (mateusfccp): Deal with recursive definitions?
    return IdentifierElement(
      name: node.identifier.lexeme,
      constantValue: constantValue,
      type: definition.type,
    );
  }

  @override
  Future<Element>? visitInvocationExpression(InvocationExpression node) async {
    final identifier = await node.identifier.accept(this) as IdentifierElement;
    final argument = await node.argument.accept(this) as ExpressionElement;

    final invocationElement = InvocationElement(
      identifier: identifier,
      argument: argument,
      // TODO(mateusfccp): It will be potentially constant when we have macros
      constantValue: null,
    );

    identifier.enclosingElement = invocationElement;
    argument.enclosingElement = invocationElement;

    switch (identifier.type) {
      case final FunctionType functionType:
        // Check if the argument type matches the parameter type
        final expectedType = parameterTypeToExpectedArgumentType(
          functionType.parameterType,
        );

        if (!argument.type!.subtypeOf(expectedType)) {
          _errorHandler?.emit(
            InvalidArgumentTypeError(
              syntacticEntity: node.argument,
              expectedType: expectedType,
              argumentType: argument.type!,
            ),
          );
        }

        invocationElement.type = functionType.returnType;

        return invocationElement;
      case final TypeType type when type.reference is PolymorphicType:
        // TODO(mateusfccp): For now, we will treat types with type parameters specially.
        // In the future, type with type parameters will be regular constant functions that
        // return a type.
        invocationElement.type = type;

        return invocationElement;
      default:
        _errorHandler?.emit(
          NotAFunctionError(
            syntacticEntity: node.identifier,
            calledType: identifier.type!,
          ),
        );

        return invocationElement;
    }
  }

  @override
  Future<Element> visitImportDeclaration(ImportDeclaration node) async {
    final package = switch (node.type) {
      ImportType.dart => DartSdkPackage(
        name: node.identifier.lexeme.substring(1),
      ),
      ImportType.package => ExternalPackage(name: node.identifier.lexeme),
    };

    return ImportElement(package: package);
  }

  @override
  Future<Element> visitIntegerLiteral(IntegerLiteral node) async {
    return SingletonLiteralElement(type: const IntegerType())
      ..constantValue = int.parse(_removeSeparators(node.literal.lexeme));
  }

  @override
  Future<TypedElement> visitLetDeclaration(LetDeclaration node) async {
    if (_environment.getDefinition(node.identifier.lexeme) != null) {
      throw IdentifierAlreadyDefinedError(node.identifier);
    }

    final LetDeclarationElement declaration;
    if (node.parameter case final parameter?) {
      final parameterElement =
          await parameter.accept(this) as StructLiteralElement;

      for (int index = 0; index < parameterElement.members.length; index++) {
        final memberElement = parameterElement.members[index];
        if (memberElement.value.type is! TypeType) {
          final member = parameter.members[index];

          final syntacticEntity = switch (member) {
            NamelessStructMember() => member.value,
            FullStructMember() => member.value,
            ValuelessStructMember() => member.name,
          };

          throw InvalidParameterTypeError(
            syntacticEntity: syntacticEntity,
            parameterType: memberElement.value.type!,
          );
        }
      }

      declaration = LetFunctionDeclaration(
        name: node.identifier.lexeme,
        parameter: parameterElement,
      );

      parameterElement.enclosingElement = declaration;
    } else {
      declaration = LetVariableDeclaration(name: node.identifier.lexeme);
    }

    _environment.defineSymbol(node.identifier.lexeme, declaration);
    _environment = _environment.fork();

    // TODO(mateusfccp): We want to allow parameters to be referenced by other parameters
    if (declaration is LetFunctionDeclaration) {
      for (final member in declaration.parameter.members) {
        final syntheticDeclaration = LetVariableDeclaration(
          name: member.name,
          type: (member.value.type as TypeType).reference,
        );
        syntheticDeclaration.body = IdentifierElement(
          name: member.name,
          constantValue: null,
        );

        _environment.defineSymbol(member.name, syntheticDeclaration);
      }
    }

    final expressionElement = await node.body.accept(this) as ExpressionElement;
    expressionElement.enclosingElement = declaration;

    declaration.body = expressionElement;

    switch (declaration) {
      case LetFunctionDeclaration():
        final functionType = FunctionType(
          parameterType: declaration.parameter.type,
          returnType: expressionElement.type!,
        );

        declaration.type = functionType;
      case LetVariableDeclaration():
        declaration.type = expressionElement.type!;
    }

    _environment = _environment.enclosing!;

    return declaration;
  }

  @override
  Future<StructMemberElement> visitNamelessStructMember(
    NamelessStructMember node,
  ) async {
    final value = await node.value.accept(this) as ExpressionElement;
    return StructMemberElement()..value = value;
  }

  @override
  Future<Element> visitStringLiteral(StringLiteral node) async {
    // TODO(mateusfccp): Once we have string literals with interpolation, we should only consider them const if all the internal expressions are const
    return SingletonLiteralElement(type: const StringType())
      ..constantValue = node.literal.lexeme.substring(
        1,
        node.literal.lexeme.length - 1,
      );
  }

  @override
  Future<StructLiteralElement> visitStructLiteral(StructLiteral node) async {
    final element = StructLiteralElement();

    Map<String, Object?>? constantValue = {};

    final typeMembers = <String, Type>{};

    if (node.members case final members) {
      int positional = 0;

      for (final member in members) {
        final memberElement = await member.accept(this) as StructMemberElement;
        element.members.add(memberElement);
        memberElement.enclosingElement = element;

        try {
          memberElement.name = '\$$positional';
          positional++;
        } on Error catch (error) {
          // TODO(mateusfccp): It's not recommended to catch errors, and using the runtimeType to see if this is the error we wanted is even worse, but we don't have much better alterantives
          // This may be changed if we ever have something like https://github.com/dart-lang/language/issues/3680
          if (error.runtimeType.toString() != 'LateError') {
            rethrow;
          }
        }

        if (typeMembers.containsKey(memberElement.name)) {
          // TODO(mateusfccp): Make a proper error or should we shadow it?
          // Maybe shadowing is better if we have struct spreads
          throw 'Duplicated member name';
        }

        typeMembers[memberElement.name] = memberElement.value.type!;

        if (constantValue != null) {
          if (memberElement.value.constant) {
            constantValue[memberElement.name] =
                memberElement.value.constantValue;
          } else {
            constantValue = null;
          }
        }
      }
    }

    element.constantValue = constantValue;
    element.type = StructType(members: typeMembers);

    return element;
  }

  @override
  Future<LiteralElement> visitSymbolLiteral(SymbolLiteral node) async {
    return SingletonLiteralElement(type: SymbolType())
      ..constantValue = node.literal.lexeme.substring(1);
  }

  @override
  Future<Element> visitTypeDefinition(TypeDefinition node) async {
    if (_environment.getDefinition(node.name.lexeme) != null) {
      throw IdentifierAlreadyDefinedError(node.name);
    }

    final definition = TypeDefinitionElement(name: node.name.lexeme);

    final definedType = PolymorphicType(
      name: node.name.lexeme,
      arguments: [
        if (node.parameters case final parameters?)
          for (final parameter in parameters)
            TypeParameterType(name: parameter.identifier.lexeme),
      ],
      element: definition,
    );

    definition.definedType = definedType;

    _environment.defineSymbol(node.name.lexeme, definition);

    _environment = _environment.fork();

    if (node.parameters case final parameters?) {
      for (final parameter in parameters) {
        final definedType = _environment.getDefinition(
          parameter.identifier.lexeme,
        );

        if (definedType is TypeParameterType) {
          _errorHandler?.emit(
            TypeParameterAlreadyDefinedError(parameter.identifier),
          );
        } else if (definedType == null) {
          final element = TypeParameterElement(
            name: parameter.identifier.lexeme,
          );
          final type = TypeParameterType(name: parameter.identifier.lexeme);

          type.element = element;
          element.definedType = type;

          _environment.defineSymbol(parameter.identifier.lexeme, element);

          definition.parameters.add(element);
        }
      }
    }

    for (final statementVariant in node.variants) {
      final variant = await statementVariant.accept(this) as TypeVariantElement;
      variant.enclosingElement = definition;
      definition.variants.add(variant);
    }

    _environment = _environment.enclosing!;

    return definition;
  }

  @override
  Future<Element> visitTypeVariantNode(TypeVariantNode node) async {
    final typeVariantElement = TypeVariantElement(name: node.name.lexeme);

    for (final parameter in node.parameters?.members ?? <StructMember>[]) {
      if (parameter is! FullStructMember) {
        _errorHandler?.emit(
          InvalidTypeParameterError(syntacticEntity: parameter),
        );
        continue;
      }

      final value = parameter.value;

      // TODO(mateusfccp): Maybe reintroduce a common supertype for `IdentifierExpression` and `InvocationExpression`?
      if (value is! IdentifierExpression && value is! InvocationExpression) {
        _errorHandler?.emit(
          InvalidTypeParameterError(syntacticEntity: parameter),
        );
        continue;
      }

      late final ParameterElement element;

      try {
        final type = _resolveType(value);
        element = ParameterElement(name: node.name.lexeme)..type = type;
      } on _SymbolNotResolved {
        element = ParameterElement(name: node.name.lexeme);
        _unresolvedParameters[element] = value;
      }

      element.enclosingElement = typeVariantElement;
      typeVariantElement.parameters.add(element);
    }

    return typeVariantElement;
  }

  @override
  Future<StructMemberElement> visitValuelessStructMember(
    ValuelessStructMember node,
  ) async {
    // TODO(mateusfccp): Should we have a proper synthetic element here?
    final syntheticElement = IdentifierExpression(
      Token(
        type: TokenType.identifier,
        lexeme: node.name.literal.lexeme.substring(1),
        offset: node.name.offset + 1,
      ),
    );

    final value = await syntheticElement.accept(this) as IdentifierElement;

    return StructMemberElement() //
      ..name = node.name.literal.lexeme.substring(1)
      ..value = value;
  }

  Type _resolveType(Expression expression) {
    switch (expression) {
      case IdentifierExpression():
        final definition = _environment.getDefinition(
          expression.identifier.lexeme,
        );

        if (definition == null) {
          throw _SymbolNotResolved();
        } else if (definition
            case TypeDefiningElement(:final definedType) ||
                ImportedSymbolSyntheticElement(
                  syntheticElement: TypeDefiningElement(:final definedType),
                )) {
          return definedType;
        } else {
          // TODO(mateusfccp): Make a proper ResolveError and throw it
          throw StateError(
            '${expression.identifier.lexeme} has type ${definition.runtimeType}.',
          );
        }

      case InvocationExpression(:final identifier):
        final baseType = _resolveType(identifier);

        if (baseType is PolymorphicType) {
          final passedArguments = <Type>[];

          if (expression case InvocationExpression(:final argument)) {
            if (argument is StructLiteral) {
              final members = argument.members;
              for (final member in members) {
                if (member case NamelessStructMember(:final value)) {
                  passedArguments.add(_resolveType(value));
                }
              }
            } else {
              passedArguments.add(_resolveType(argument));
            }
          }

          if (passedArguments.length != baseType.arguments.length) {
            throw WrongNumberOfArgumentsError(
              syntacticEntity: expression,
              argumentsCount: passedArguments.length,
              expectedArgumentsCount: baseType.arguments.length,
            );
          }

          return PolymorphicType(
            name: expression.identifier.identifier.lexeme,
            arguments: passedArguments,
          );
        } else {
          // TODO(mateusfccp): Make a proper ResolveError and throw it
          throw StateError(
            "Symbol $baseType is non-polymorphic, which shouldn't happen.",
          );
        }
      case Expression():
        // TODO(mateusfccp): Make a proper ResolveError and throw it
        throw StateError(
          'The expression $expression does not evaluate to a type.',
        );
    }
  }

  Future<List<ImportedSymbolSyntheticElement>> _resolvePackage(
    Package package,
  ) async {
    final symbols = await symbolsResolver.getSymbolsForPackage(
      package: package,
    );

    for (final symbol in symbols) {
      _environment.defineSymbol(symbol.name, symbol);
    }

    return symbols;
  }
}

final class _SymbolNotResolved implements Exception {}

// TODO(mateusfccp): Remove this method after Dart 3.6 when separators will be supported
String _removeSeparators(String literal) => literal.replaceAll('_', '');
