// ignore_for_file: implementation_imports

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart' hide Package;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:pinto/semantic.dart';

final class SymbolsResolver {
  SymbolsResolver({
    required this.resourceProvider,
    required this.analysisContextCollection,
    required this.sdk,
  }) {
    _packages = findPackagesFrom(
      resourceProvider,
      analysisContextCollection.contexts.first.contextRoot.root,
    );
  }

  final ResourceProvider resourceProvider;
  final AnalysisContextCollection analysisContextCollection;
  final AbstractDartSdk sdk;
  late Packages _packages;

  Future<List<ImportedSymbolSyntheticElement>> getSymbolsForPackage({
    required Package package,
  }) async {
    final uri = getUriFromPackage(package);

    if (uri == null) {
      throw _SymbolResolvingException(package);
    }

    // TODO(mateusfccp): Improve this
    if (uri == '.') {
      return [];
    }

    final library = await analysisContextCollection
        .contexts
        .first
        .currentSession
        .getResolvedLibrary(uri);

    if (library is ResolvedLibraryResult) {
      return [
        for (var element
            in library.element.exportNamespace.definedNames2.values)
          ?_dartElementToPintoElement(element),
      ];
    } else {
      throw _SymbolResolvingException(package);
    }
  }

  ImportedSymbolSyntheticElement? _dartElementToPintoElement(
    dart.Element element,
  ) {
    final TypedElement syntheticElement;

    switch (element) {
      case dart.FunctionTypedElement():
        final functionType = _dartFunctionTypeToPintoFunctionType(element.type);

        final body = SingletonLiteralElement()..constantValue = null;

        syntheticElement =
            LetFunctionDeclaration(
                name: element.displayName,
                parameter: StructLiteralElement()
                  ..constantValue = null
                  ..type = functionType.parameterType,
              )
              ..type = functionType
              ..body = body;
      case dart.InstanceElement():
        final typeDefinition = TypeDefinitionElement(name: element.displayName);

        final variant = TypeVariantElement(name: element.displayName);
        variant.enclosingElement = typeDefinition;

        for (final typeParameter in element.typeParameters) {
          final typeParameterElement = TypeParameterElement(
            name: typeParameter.displayName,
          );
          typeParameterElement.enclosingElement = typeDefinition;
          typeDefinition.parameters.add(typeParameterElement);
          typeParameterElement.definedType = TypeParameterType(
            name: typeParameterElement.name,
          );

          final parameterElement = ParameterElement(
            name: typeParameter.displayName,
          );
          parameterElement.enclosingElement = typeDefinition;
          variant.parameters.add(parameterElement);
        }

        try {
          typeDefinition.definedType = _dartTypeToPintoType(element.thisType);
        } catch (exception) {
          return null;
        }

        syntheticElement = typeDefinition;
      case dart.TopLevelVariableElement():
        final body = SingletonLiteralElement()..constantValue = null;

        syntheticElement = LetVariableDeclaration(
          name: element.displayName,
          type: _dartTypeToPintoType(element.type),
        )..body = body;
      case dart.TypeAliasElement()
          when element.aliasedType is! dart.FunctionType:
        final name = element.name;

        if (name == null) {
          return null;
        }

        final body = IdentifierElement(
          name: name,
          type: _dartTypeToPintoType(element.aliasedType),
          constantValue: null,
        );

        syntheticElement = LetVariableDeclaration(name: element.displayName)
          ..body = body;
      default:
        // throw UnimplementedError('No conversion implemented from ${element.runtimeType} to a pint° element.');
        return null;
    }

    return ImportedSymbolSyntheticElement(
      name: element.displayName,
      syntheticElement: syntheticElement,
    );
  }

  String? getUriFromPackage(Package package) {
    switch (package) {
      case DartSdkPackage(:final name):
        return sdk.mapDartUri('dart:$name')?.fullName;
      case ExternalPackage(:final name):
        final parts = name.split('/');
        final package = parts.first;

        final String file;

        if (parts.length == 1) {
          file = '$package.dart';
        } else {
          file = '${parts.skip(1).join('/')}.dart';
        }

        final folder = _packages[package]?.libFolder;

        return folder == null ? null : '$folder/$file';
      case CurrentPackage():
        return '.';
    }
  }
}

Type _dartTypeToPintoType(
  dart.DartType type, {
  TypePosition position = TypePosition.covariant,
}) {
  // TODO(mateusfccp): Implement Object → Some(NonSome)
  // TODO(mateusfccp): Implement T? → Option(T)
  // TODO(mateusfccp): Implement T <: Object → Some(T <: NonSome)
  switch (type) {
    case dart.VoidType() when position == TypePosition.covariant:
      return StructType.unit;
    case dart.VoidType():
    case dart.DynamicType():
    case dart.DartType(
      isDartCoreObject: true,
      nullabilitySuffix: NullabilitySuffix.question,
    ):
      return const UnknownType();
    case dart.NeverType():
      return const NeverType();
    case dart.TypeParameterType():
      return TypeParameterType(name: type.element.displayName);
    case dart.FunctionType():
      return _dartFunctionTypeToPintoFunctionType(type);
    case dart.ParameterizedType():
      if (type.isDartCoreBool) {
        return const BooleanType();
      } else if (type.isDartCoreDouble) {
        return const DoubleType();
      } else if (type.isDartCoreInt) {
        return const IntegerType();
      } else if (type.isDartCoreNum) {
        return const NumberType();
      } else if (type.isDartCoreNull) {
        return StructType.unit;
      } else if (type.isDartCoreString) {
        return const StringType();
      } else if (type.isDartCoreType) {
        return const TypeType.self();
      } else if (type.element case final dart.InterfaceElement element) {
        return PolymorphicType(
          name: element.displayName,
          arguments: [
            for (final typeParameter in element.typeParameters) //
              TypeParameterType(name: typeParameter.displayName),
          ],
          declaredSupertypes: [
            for (final supertype in element.allSupertypes)
              _dartTypeToPintoType(
                supertype,
                position: TypePosition.contravariant,
              ),
          ],
        );
      } else {
        throw UnimplementedError(
          "We still don't support importing the type ${type.getDisplayString()} to pint°",
        );
      }
    default:
      throw UnimplementedError(
        "We still don't support importing the type ${type.getDisplayString()} to pint°",
      );
  }
}

FunctionType _dartFunctionTypeToPintoFunctionType(dart.FunctionType type) {
  final typeMembers = <String, TypeType>{};

  int index = 0;
  for (final parameter in type.formalParameters) {
    final type = _dartTypeToPintoType(parameter.type);

    if (parameter.isPositional) {
      typeMembers['\$${index++}'] = TypeType(type);
    } else if (parameter.name case final name? when parameter.isNamed) {
      typeMembers[name] = TypeType(type);
    }
  }

  return FunctionType(
    parameterType: StructType(members: typeMembers),
    returnType: _dartTypeToPintoType(type.returnType),
  );
}

final class _SymbolResolvingException implements Exception {
  _SymbolResolvingException(this.package);

  final Package package;

  @override
  String toString() {
    return "Couldn't resolve symbols for package $package.";
  }
}

/// The position where a type is used.
///
/// This is used to determine how the type should be treated when it is
/// transpiled to a Dart type or imported from a Dart type.
enum TypePosition {
  /// The type is in a position where it is covariant.
  ///
  /// This is the case for the return type of a function or the type of a field.
  covariant,

  /// The type is in a position where it is contravariant.
  ///
  /// This is the case for the type of a parameter in a function.
  contravariant,
}
