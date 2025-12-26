import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:pinto/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'common.dart';

Builder treeBuilder(BuilderOptions options) {
  return SharedPartBuilder([TreeGenerator()], 'tree');
}

final _emitter = DartEmitter();

final class TreeGenerator extends GeneratorForAnnotation<TreeRoot> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    assert(element is ClassElement);
    final classElement = element as ClassElement;

    if (classElement.isPrivate) {
      throw InvalidGenerationSourceError(
        'The class ${classElement.name} is private. Tree nodes must be public.',
        element: classElement,
      );
    }

    final units = [
      _emitter.visitMixin(_mixinForElement(classElement)).toString(),
    ];

    classElement.descend((node) {
      assert(node is InterfaceElement);
      final element = node as InterfaceElement;

      units.add(_emitter.visitMixin(_mixinForElement(element)).toString());
    });

    return units;
  }
}

Mixin _mixinForElement(InterfaceElement element) {
  return Mixin((builder) {
    builder.base = true;
    builder.name = element.privateName;

    final elementName = element.name;

    if (elementName == null) {
      throw InvalidGenerationSourceError(
        'The element has no name.',
        element: element,
      );
    }

    // Generate fields without definitions in the main class.
    for (final field in element.fields) {
      final fieldName = field.name;

      if (fieldName == null) {
        // Skip fields without a name
        continue;
      }

      builder.methods.add(
        Method((builder) {
          builder.returns = refer(field.type.toString());
          builder.type = MethodType.getter;
          builder.name = '_$fieldName';
          builder.body = refer(
            'this',
          ).asA(refer(element.displayName)).property(fieldName).code;
        }),
      );
    }

    if (element.isVisitable) {
      if (element.isLeaf) {
        builder.methods.add(_acceptMethod(element));
      }

      if (!element.isRoot) {
        builder.methods.add(_visitChildrenMethod(element));
      }
    }

    builder.methods.add(_toStringMethod(element));
  });
}

Method _acceptMethod(InterfaceElement element) {
  return Method((builder) {
    builder.returns = refer('R?');
    builder.name = 'accept';
    builder.types.add(refer('R'));

    builder.requiredParameters.add(
      Parameter((builder) {
        builder.type = referWithR('${element.root.name}Visitor');
        builder.name = 'visitor';
      }),
    );

    final name = element.name;

    if (name == null) {
      throw InvalidGenerationSourceError(
        'The element has no name.',
        element: element,
      );
    }

    builder.lambda = true;
    builder.body =
        refer('visitor') //
            .property('visit$name')
            .call([refer('this').asA(refer(name))])
            .code;
  });
}

Method _visitChildrenMethod(InterfaceElement element) {
  return Method((builder) {
    builder.returns = refer('void');
    builder.name = 'visitChildren';
    builder.types.add(refer('R'));

    builder.requiredParameters.add(
      Parameter((builder) {
        builder.type = referWithR('${element.root.name}Visitor');
        builder.name = 'visitor';
      }),
    );

    builder.body = Block((builder) {
      for (final field in element.fields) {
        final typeSystem = field.enclosingElement.library.typeSystem;
        final isNullable = typeSystem.isNullable(field.type);

        if (field.isIterableOfVisitable) {
          final block = Block.of([
            if (isNullable) Code('if (_${field.name} case final nodes?) {'),
            Code(
              'for (final node in ${isNullable ? 'nodes' : '_${field.name}'}) {',
            ),
            if (field.isIterableOfNullable) //
              refer('node').nullSafeProperty('visitChildren').call([
                refer('visitor'),
              ]).statement
            else
              refer(
                'node',
              ).property('visitChildren').call([refer('visitor')]).statement,
            Code('}'),
            if (isNullable) Code('}'),
          ]);

          builder.statements.add(block);
        } else if (field.isVisitable) {
          final name = refer('_${field.name}');
          final nameProperty = isNullable
              ? name.nullSafeProperty
              : name.property;

          builder.statements.add(
            nameProperty('accept').call([refer('visitor')]).statement,
          );
        }
      }
    });
  });
}

Method _toStringMethod(InterfaceElement element) {
  return Method((builder) {
    builder.annotations.add(refer('override'));
    builder.returns = refer('String');
    builder.name = 'toString';

    final name = element.name;

    if (name == null) {
      throw InvalidGenerationSourceError(
        'The element has no name.',
        element: element,
      );
    }

    final string = StringBuffer(name);

    if (element.fields.isNotEmpty) {
      string.write('(');

      for (int i = 0; i < element.fields.length; i = i + 1) {
        string.write(element.fields[i].name);
        string.write(r': $_');
        string.write(element.fields[i].name);

        if (i < element.fields.length - 1) {
          string.write(', ');
        }
      }

      string.write(')');
    }

    builder.body = literalString(string.toString()).code;
  });
}
