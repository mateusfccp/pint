// ignore_for_file: implementation_imports

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart' hide Package;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:pinto/lexer.dart';
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

  Future<List<ImportedSymbolSyntheticElement>> getSymbolsForPackage({required Package package}) async {
    final uri = getUriFromPackage(package);

    if (uri == null) {
      throw _SymbolResolvingException(package);
    }

    // TODO(mateusfccp): Improve this
    if (uri == '.') {
      return [];
    }

    final library = await analysisContextCollection.contexts.first.currentSession.getResolvedLibrary(uri);

    if (library is ResolvedLibraryResult) {
      return [
        for (var element in library.element.exportNamespace.definedNames.values) //
          if (_dartElementToPintoElement(element) case final element?) element,
      ];
    } else {
      throw _SymbolResolvingException(package);
    }
  }

  ImportedSymbolSyntheticElement? _dartElementToPintoElement(dart.Element element) {
    final TypedElement syntheticElement;

    switch (element) {
      case dart.FunctionTypedElement():
        syntheticElement = LetFunctionDeclaration(
          name: element.name!,
          parameter: Token(
            type: TokenType.unitLiteral,
            offset: 0,
            lexeme: '()',
          ), // TODO(mateusfccp): Map to proper parameter. As it's synthetic, it shouldn't have an associated token anyway
          type: FunctionType(
            returnType: _dartTypeToPintoType(element.returnType),
          ),
          body: LiteralElement(
            constant: true,
            constantValue: null,
          ),
        );
      case dart.InstanceElement():
        final typeDefinition = TypeDefinitionElement(name: element.name!);

        final variant = TypeVariantElement(name: element.name!);
        variant.enclosingElement = typeDefinition;

        for (final typeParameter in element.typeParameters) {
          final typeParameterElement = TypeParameterElement(name: typeParameter.name);
          typeParameterElement.enclosingElement = typeDefinition;
          typeDefinition.parameters.add(typeParameterElement);
          typeParameterElement.definedType = TypeParameterType(name: typeParameterElement.name);

          final parameterElement = ParameterElement(name: typeParameter.name);
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
        syntheticElement = LetVariableDeclaration(
          name: element.name,
          type: _dartTypeToPintoType(element.type),
          body: LiteralElement(
            constant: true,
            constantValue: null,
          ),
        );
      case dart.TypeAliasElement(:final aliasedElement?) when element.aliasedType is! dart.FunctionType:
        syntheticElement = LetVariableDeclaration(
          name: element.name,
          body: IdentifierElement(
            name: aliasedElement.name!,
            type: _dartTypeToPintoType(element.aliasedType),
            constant: false,
          ),
        );
      default:
        // throw UnimplementedError('No conversion implemented from ${element.runtimeType} to a pint° element.');
        return null;
    }

    return ImportedSymbolSyntheticElement(
      name: element.name!,
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

Type _dartTypeToPintoType(dart.DartType type, {bool contravariant = false}) {
  // TODO(mateusfccp): Implement Object → Some(NonSome)
  // TODO(mateusfccp): Implement T? → Option(T)
  // TODO(mateusfccp): Implement T <: Object → Some(T <: NonSome)
  switch (type) {
    case dart.VoidType() when !contravariant:
      return const UnitType();
    case dart.VoidType():
    case dart.DynamicType():
    case dart.DartType(isDartCoreObject: true, nullabilitySuffix: NullabilitySuffix.question):
      return const TopType();
    case dart.NeverType():
      return const BottomType();
    case dart.TypeParameterType():
      return TypeParameterType(
        name: type.element.declaration.name,
      );
    case dart.FunctionType():
      return FunctionType(
        returnType: _dartTypeToPintoType(type.returnType),
      );
    case dart.ParameterizedType():
      if (type.isDartCoreBool) {
        return const BooleanType();
      } else if (type.isDartCoreString) {
        return const StringType();
      } else if (type.isDartCoreNull) {
        return const UnitType();
      } else if (type.isDartCoreType) {
        return const TypeType();
      } else if (type.element case final dart.InterfaceElement element) {
        final Package source;

        if (element.library.isInSdk) {
          source = DartSdkPackage(name: element.library.name); // TODO(mateusfccp): Check if we should remove `dart.` or not
        } else {
          source = ExternalPackage(name: element.library.name);
        }

        return PolymorphicType(
          name: element.name,
          source: source,
          arguments: [
            for (final typeParameter in element.typeParameters) //
              TypeParameterType(name: typeParameter.name),
          ],
        );
      } else {
        throw UnimplementedError("We still don't support importing the type ${type.getDisplayString()} to pint°");
      }
    default:
      throw UnimplementedError("We still don't support importing the type ${type.getDisplayString()} to pint°");
  }
}

final class _SymbolResolvingException implements Exception {
  _SymbolResolvingException(this.package);

  final Package package;

  @override
  String toString() {
    return "Couldn't resolve symbols for package $package.";
  }
}
