import 'dart:collection';

import 'package:code_builder/code_builder.dart' hide ClassBuilder, FunctionType;
import 'package:dart_style/dart_style.dart';
import 'package:pinto/semantic.dart';

import 'class_builder.dart';

final class Compiler implements ElementVisitor<List<Spec>> {
  Compiler(this.programElement);

  final ProgramElement programElement;

  /// Writes the compiled program to the [sink].
  void write(StringSink sink) {
    final emmiter = DartEmitter(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final [library] = programElement.accept(this) as List<Library>;

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestShortStyleLanguageVersion,
    );

    final buffer = StringBuffer(library.accept(emmiter));
    final formattedSource = formatter.format(buffer.toString());

    sink.write(formattedSource);
  }

  @override
  List<Expression> visitIdentifierElement(IdentifierElement node) {
    if (node.type case TypeType type) {
      return [refer(_buildTypeName(type.reference))];
    } else {
      return [refer(node.name)];
    }
  }

  @override
  List<Expression> visitInvocationElement(InvocationElement node) {
    final argument = node.argument;
    final identifier = refer(node.identifier.name);

    final Expression expression;

    switch (argument) {
      case SingletonLiteralElement():
        expression = identifier.call([literal(argument.constantValue)]);
      case StructLiteralElement(:final members):
        final namedArguments = {
          for (final member in members) //
            member.name: member.value.accept(this)?.single as Expression,
        };

        expression = identifier.call([], namedArguments);
      case InvocationElement():
        final invocation = argument.accept(this) as List<Expression>;
        expression = identifier.call(invocation);
      case IdentifierElement():
        expression = identifier.call([refer(argument.name)]);
    }

    return [expression];
  }

  @override
  Null visitImportedSymbolSyntheticElement(
    ImportedSymbolSyntheticElement node,
  ) {}

  @override
  List<Directive> visitImportElement(ImportElement importElement) {
    final String url;

    switch (importElement.package) {
      case DartSdkPackage(:final name):
        url = 'dart:$name';
      case ExternalPackage(:final name):
        final parts = name.split('/');

        if (parts case [final root]) {
          url = 'package:$root/$root.dart';
        } else {
          url = 'package:$name.dart';
        }
      case CurrentPackage():
        throw 'Nope'; // TODO(mateusfccp): CurrentPackage shouldn't exist
    }

    return [Directive.import(url)];
  }

  @override
  List<Method> visitLetFunctionDeclaration(LetFunctionDeclaration node) {
    final method = Method((builder) {
      builder.returns = _typeReferenceFromType(
        node.type.returnType,
        position: _ParameterPosition.contravariant,
      );

      builder.name = node.name;

      for (final member in node.parameter.members) {
        builder.optionalParameters.add(
          Parameter((builder) {
            builder.named = true;

            // This shouldn't break because the resolver should have already validated the type
            final identifier = member.value as IdentifierElement;
            final type = identifier.constantValue as Type;

            if (type case PolymorphicType(isOption: true)) {
              builder.required = false;
            } else {
              builder.required = true;
            }

            final typeCode = member.value.accept(this);

            builder.type = typeCode?.single as Reference;
            builder.name = member.name;
          }),
        );
      }

      builder.lambda = true;

      final [expression] = node.body.accept(this) as List<Expression>;
      builder.body = expression.code;
    });

    return [method];
  }

  @override
  List<Field>? visitLetVariableDeclaration(LetVariableDeclaration node) {
    if (node.type case StructType(isUnit: true)) {
      return null;
    } else {
      final [expression] = node.body.accept(this) as List<Expression>;

      final field = Field((builder) {
        if (node.body.constant) {
          builder.modifier = FieldModifier.constant;
        } else {
          builder.modifier = FieldModifier.final$;
        }
        builder.name = node.name;
        builder.assignment = expression.code;
      });

      return [field];
    }
  }

  @override
  List<Library> visitProgramElement(ProgramElement programElement) {
    final library = Library((builder) {
      for (final import in programElement.imports) {
        final [element] = import.accept(this) as List<Directive>;
        builder.directives.add(element);
      }

      for (final declaration in programElement.declarations) {
        final elements = declaration.accept(this);
        if (elements != null) {
          builder.body.addAll(elements);
        }
      }
    });

    return [library];
  }

  @override
  Null visitParameterElement(ParameterElement node) {
    // We still don't have a way to compile it to a single element, as for classes we have to both add constructor parameters and fields
  }

  @override
  List<Expression> visitSingletonLiteralElement(SingletonLiteralElement node) {
    return [literal(node.constantValue)];
  }

  @override
  List<Expression> visitStructLiteralElement(StructLiteralElement node) {
    if (node.members.isEmpty) {
      return [];
    }

    final recordLiteral = literalRecord([], {});
    final positionalArguments = SplayTreeMap<int, Expression>();

    for (final StructMemberElement(:name, :value) in node.members) {
      final valueExpression = (value.accept(this) as List<Expression>).single;

      if (int.tryParse(name.substring(1)) case final index?
          when name[0] == r'$') {
        positionalArguments[index] = valueExpression;
      } else {
        recordLiteral.namedFieldValues[name] = valueExpression;
      }
    }

    // TODO(mateusfccp):
    // Currently, we simply spread the positioned arguments even if there are
    // gaps in the numbers. We may want to rethink if this is the desired
    // behavior.
    recordLiteral.positionalFieldValues.addAll(positionalArguments.values);

    return [recordLiteral];
  }

  @override
  Null visitStructMemberElement(StructMemberElement node) {
    // We still don't have a way to compile it to a single element, as for classes we have to both add constructor parameters and fields
  }

  @override
  List<Class> visitTypeDefinitionElement(
    TypeDefinitionElement typeDefinitionElement,
  ) {
    final classes = <Class>[];

    if (typeDefinitionElement.variants case [final variant]) {
      final [class_] = variant.accept(this) as List<Class>;
      classes.add(class_);
    } else {
      final topClass = ClassBuilder(name: typeDefinitionElement.name);

      topClass.sealed = true;

      for (final parameter in typeDefinitionElement.parameters) {
        final [reference] = parameter.accept(this) as List<Reference>;
        topClass.addParameter(reference);
      }

      classes.add(topClass.asCodeBuilderClass());

      for (final variant in typeDefinitionElement.variants) {
        final [class_] = variant.accept(this) as List<Class>;
        classes.add(class_);
      }
    }

    return classes;
  }

  @override
  List<Reference> visitTypeParameterElement(TypeParameterElement node) {
    return [_typeReferenceFromType(node.definedType)];
  }

  @override
  List<Class> visitTypeVariantElement(TypeVariantElement node) {
    final typeDefinitionElement = node.enclosingElement;

    final variantClass = ClassBuilder(name: node.name, withEquality: true)
      ..final$ = true;

    for (final parameter in node.parameters) {
      for (final type in _typeParametersFromType(parameter.type!)) {
        variantClass.addParameter(_typeReferenceFromType(type));
      }

      variantClass.addField(_typeReferenceFromType(parameter.type!), parameter);
    }

    if (typeDefinitionElement.variants.length > 1) {
      variantClass.defineSupertypeName(typeDefinitionElement.name);

      final currentVariantTypes = [
        for (final parameter in node.parameters) parameter.type!,
      ];

      final typeParameters = _typeParametersFromTypeList(currentVariantTypes);

      for (final typeParameter in typeDefinitionElement.parameters) {
        final argument =
            typeParameters.contains(typeParameter.type) //
            ? typeParameter.type!
            : const NeverType();

        final parameter = _typeReferenceFromType(argument);
        variantClass.addParameterToSupertype(parameter);
      }
    }

    return [variantClass.asCodeBuilderClass()];
  }
}

enum _ParameterPosition { covariant, contravariant }

@pragma('vm:prefer-inline')
String _buildTypeName(
  Type type, {
  _ParameterPosition position = _ParameterPosition.covariant,
}) {
  return switch (type) {
    BooleanType() => 'bool',
    NeverType() => 'Never',
    DoubleType() => 'double',
    FunctionType() =>
      '${_buildTypeName(type.returnType, position: _ParameterPosition.contravariant)} Function(${_buildTypeName(type.parameterType)})',
    IntegerType() => 'int',
    NumberType() => 'num',
    PolymorphicType(:final name) || TypeParameterType(:final name) => name,
    StringType() => 'String',
    StructType(isUnit: true) => switch (position) {
      _ParameterPosition.covariant => '',
      _ParameterPosition.contravariant => 'void',
    },
    StructType() => _buildStructTypeName(type),
    SymbolType() => 'Symbol',
    UnknownType() => 'Object?',
    TypeType() => 'Type',
  };
}

String _buildStructTypeName(StructType type) {
  final recordLiteral = literalRecord([], {});

  for (final MapEntry(key: name, value: type) in type.members.entries) {
    final valueType = _buildTypeName(type);

    if (int.tryParse(name.substring(1)) case final index?
        when name[0] == r'$') {
      recordLiteral.positionalFieldValues[index] = Code(valueType);
    } else {
      recordLiteral.namedFieldValues[name] = Code(valueType);
    }
  }

  return DartEmitter().visitLiteralRecordExpression(recordLiteral).toString();
}

TypeReference _typeReferenceFromType(
  Type type, {
  _ParameterPosition position = _ParameterPosition.covariant,
}) {
  if (type case PolymorphicType(name: '?')) {
    final innerType = _typeReferenceFromType(type.arguments[0]);

    return innerType.rebuild((builder) {
      builder.isNullable = true;
    });
  } else {
    return TypeReference((builder) {
      if (type case PolymorphicType(name: '?')) {
        builder.symbol = _buildTypeName(type.arguments[0], position: position);
        builder.isNullable = true;
      } else {
        builder.symbol = _buildTypeName(type, position: position);
      }

      if (type is PolymorphicType) {
        for (final type in type.arguments) {
          builder.types.add(_typeReferenceFromType(type, position: position));
        }
      }
    });
  }
}

List<TypeParameterType> _typeParametersFromType(Type type) {
  return switch (type) {
    PolymorphicType(:final arguments) => _typeParametersFromTypeList(arguments),
    TypeParameterType() => [type],
    BooleanType() || //
    NeverType() ||
    DoubleType() ||
    FunctionType() ||
    IntegerType() ||
    NumberType() ||
    StringType() ||
    StructType() ||
    SymbolType() ||
    UnknownType() ||
    TypeType() => const [],
  };
}

List<TypeParameterType> _typeParametersFromTypeList(List<Type> list) {
  final parameters = {
    for (final type in list) ..._typeParametersFromType(type),
  };

  return [...parameters];
}
