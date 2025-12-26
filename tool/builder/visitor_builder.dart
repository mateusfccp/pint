import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:pinto/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'common.dart';

Builder visitorBuilder(BuilderOptions options) {
  return LibraryBuilder(
    VisitorGenerator(),
    generatedExtension: '.visitors.dart',
  );
}

final _emitter = DartEmitter();

final class VisitorGenerator extends GeneratorForAnnotation<TreeRoot> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    assert(element is ClassElement);
    final classElement = element as ClassElement;

    if (classElement.isPrivate) {
      throw InvalidGenerationSourceError(
        'The class ${classElement.name} is private. Tree nodes must be public.',
        element: classElement,
      );
    }

    if (classElement.isRoot) {
      final inputLibrary = await buildStep.inputLibrary;

      // TODO(mateusfccp): Handle libraries with multiple fragments.
      final fileName = inputLibrary.firstFragment.source.shortName;

      return [
        "import '$fileName';",
        _emitter.visitClass(_visitorFromElement(element)).toString(),
        _emitter.visitClass(_simpleVisitorFromElement(element)).toString(),
        _emitter
            .visitClass(_generalizingVisitorFromElement(element))
            .toString(),
      ];
    } else {
      return [];
    }
  }
}

Class _visitorFromElement(InterfaceElement element) {
  return Class((builder) {
    builder.name = '${element.name}Visitor';
    builder.abstract = true;
    builder.modifier = ClassModifier.interface;
    builder.types.add(refer('R'));

    element.descend((child) {
      if (child is InterfaceElement && child.isLeaf && child.isVisitable) {
        final name = child.name;

        if (name == null) {
          throw InvalidGenerationSourceError(
            'The element has no name.',
            element: child,
          );
        }

        final method = Method((builder) {
          builder.returns = refer('R?');
          builder.name = 'visit$name';
          builder.requiredParameters.add(
            Parameter((builder) {
              builder.type = refer(name);
              builder.name = 'node';
            }),
          );
        });

        builder.methods.add(method);
      }
    });
  });
}

Class _simpleVisitorFromElement(InterfaceElement element) {
  return Class((builder) {
    builder.name = 'Simple${element.name}Visitor';
    builder.abstract = true;
    builder.modifier = ClassModifier.base;
    builder.types.add(refer('R'));
    builder.implements.add(referWithR('${element.name}Visitor'));

    element.descend((child) {
      if (child is InterfaceElement && child.isLeaf && child.isVisitable) {
        final name = child.name;

        if (name == null) {
          throw InvalidGenerationSourceError(
            'The element has no name.',
            element: child,
          );
        }

        final method = Method((builder) {
          builder.annotations.add(refer('override'));
          builder.returns = refer('R?');
          builder.name = 'visit$name';
          builder.requiredParameters.add(
            Parameter((builder) {
              builder.type = refer(name);
              builder.name = 'node';
            }),
          );

          builder.lambda = true;
          builder.body = literalNull.code;
        });

        builder.methods.add(method);
      }
    });
  });
}

Class _generalizingVisitorFromElement(InterfaceElement interface) {
  return Class((builder) {
    builder.name = 'Generalizing${interface.name}Visitor';
    builder.abstract = true;
    builder.modifier = ClassModifier.base;
    builder.types.add(refer('R'));
    builder.implements.add(referWithR('${interface.name}Visitor'));

    interface.descend((child) {
      if (child is InterfaceElement && child.isVisitable) {
        final method = Method((builder) {
          if (child.isLeaf) {
            builder.annotations.add(refer('override'));
          }

          final name = child.name;

          if (name == null) {
            throw InvalidGenerationSourceError(
              'The element has no name.',
              element: child,
            );
          }

          builder.returns = refer('R?');
          builder.name = 'visit$name';
          builder.requiredParameters.add(
            Parameter((builder) {
              builder.type = refer(name);
              builder.name = 'node';
            }),
          );

          if (child.parentNode case final parent?) {
            builder.lambda = true;
            builder.body = refer(
              'visit${parent.name}',
            ).call([refer('node')]).code;
          } else {
            builder.body = Block.of([
              refer(
                'node',
              ).property('visitChildren').call([refer('this')]).statement,
              refer('null').returned.statement,
            ]);
          }
        });

        builder.methods.add(method);
      }
    });
  });
}
