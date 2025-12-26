import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';

/// Returns a [TypeReference] to [symbol] with type parameter `R`.
@pragma('vm:prefer-inline')
TypeReference referWithR(String symbol) {
  return TypeReference((builder) {
    builder.symbol = symbol;
    builder.types.add(refer('R'));
  });
}

extension FieldElementExtension on FieldElement {
  bool get isIterableOfNullable {
    if (type.isIterable) {
      final iterableType = type as InterfaceType;
      final typeArguments = iterableType.typeArguments;

      assert(
        typeArguments.length == 1,
        'Expected one type argument, found ${typeArguments.length}.',
      );

      return typeArguments.single.isNullable;
    }

    return false;
  }

  bool get isIterableOfVisitable {
    if (type.isIterable) {
      final iterableType = type as InterfaceType;
      final typeArguments = iterableType.typeArguments;

      assert(
        typeArguments.length == 1,
        'Expected one type argument, found ${typeArguments.length}.',
      );

      final typeArgument = typeArguments.single;

      if (typeArgument.element case InterfaceElement interfaceElement) {
        return interfaceElement.isVisitable;
      }
    }

    return false;
  }

  bool get isNullable => type.isNullable;

  bool get isVisitable {
    if (type.element case final InterfaceElement element) {
      return element.isVisitable;
    } else {
      return false;
    }
  }
}

extension InterfaceElementExtension on InterfaceElement {
  void descend(void Function(Element element) visitor) {
    visitor(this);

    for (final element in nodes) {
      element.descend(visitor);
    }
  }

  /// Whether this class is a leaf node in the AST tree.
  bool get isLeaf {
    for (final interface in library.classes) {
      if (interface.allSupertypes.any((type) => type.element == this)) {
        return false;
      }
    }

    return true;
  }

  bool get isNode {
    return nodeRootAnnotation != null || (supertype?.element.isNode ?? false);
  }

  /// Whether this class is the root of AST tree.
  bool get isRoot => root == this;

  /// Whether this class is a visitable node.
  bool get isVisitable => isNode;

  ElementAnnotation? get nodeRootAnnotation {
    return metadata.annotations.firstWhereOrNull(
      (element) => element.element?.name == 'TreeRoot',
    );
  }

  List<InterfaceElement> get nodes {
    return [
      for (final interface in library.classes)
        if (interface.isNode && interface.supertype?.element == this) interface,
    ];
  }

  InterfaceElement? get parentNode {
    if (supertype case final supertype? when supertype.element.isNode) {
      return supertype.element;
    } else {
      return null;
    }
  }

  /// Returns the private name of the class.
  String get privateName => '_$name';

  /// Returns the root of the tree.
  InterfaceElement get root {
    var current = this;

    // TODO(mateusfccp): use while patterns when available.
    while (true) {
      if (current.parentNode case final InterfaceElement parent) {
        current = parent;
      } else {
        break;
      }
    }

    return current;
  }
}

extension on DartType {
  bool get isIterable {
    // First check for `Iterable` and its subtypes from `dart:core`.
    if (isDartCoreList || isDartCoreIterable || isDartCoreSet) {
      return true;
    }

    // Now check if the type is a subtype of any of the above types.
    if (element is InterfaceType) {
      final interface = element as InterfaceType;

      for (final type in interface.allSupertypes) {
        if (type.isIterable) {
          return true;
        }
      }
    }

    return false;
  }

  bool get isNullable {
    final typeSystem = element?.library?.typeSystem;

    if (typeSystem == null) {
      return false;
    } else {
      return typeSystem.isNullable(this);
    }
  }
}
