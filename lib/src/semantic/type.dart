import 'package:meta/meta.dart';
import 'package:quiver/collection.dart';

import 'element.dart';

final _supertypesCache = Expando<List<Type>>('Supertypes cache');

/// A type in the pint° language.
sealed class Type {
  const Type();

  /// The element that defines this type, if any.
  TypeDefiningElement? get element;

  /// The supertypes that this type explicitly declares.
  List<Type> get declaredSupertypes => const [];

  /// The proper supertypes of this type.
  ///
  /// The proper supertypes of a type are the supertypes that are not the type
  /// itself.
  List<Type> get properSupertypes {
    final List<Type> types;

    if (_supertypesCache[this] case final cache?) {
      types = cache;
    } else {
      types = {
        const UnknownType(),
        for (final supertype in declaredSupertypes) ...{
          supertype,
          ...supertype.properSupertypes,
        },
      }.toList();
      _supertypesCache[this] = types;
    }

    return types;
  }

  /// Whether [this] is a subtype of [other].
  ///
  /// Singleton structs types are considered the same as their member type.
  @nonVirtual
  bool subtypeOf(Type other) {
    Type flattened(Type type) {
      if (type is StructType && type.members.length == 1) {
        return flattened(type.members.values.single);
      } else {
        return type;
      }
    }

    final self = flattened(this);
    other = flattened(other);

    switch ((self, other)) {
      case (NeverType(), _) || (_, UnknownType()):
        return true;
      case (StructType self, StructType other):
        if (self.members.length != other.members.length) {
          return false;
        } else {
          for (final MapEntry(:key, value: type) in self.members.entries) {
            if (other.members[key] case final otherType?
                when type < otherType) {
              continue;
            } else {
              return false;
            }
          }
          return true;
        }
      default:
        return self == other || self.properSupertypes.contains(other);
    }
  }

  /// Whether [this] is a subtype of [other].
  ///
  /// This is the same as [subtypeOf].
  bool operator <(Type other) => subtypeOf(other);
}

/// A type that represents a boolean value.
final class BooleanType extends Type {
  /// Creates the boolean type.
  const BooleanType();

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is BooleanType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'bool';
}

/// A type that represents the bottom type.
///
/// When compiled to Dart, the bottom type is represented by `Never`.
final class NeverType extends Type {
  /// Creates the bottom type.
  const NeverType();

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is NeverType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Never';
}

/// A type that represents a double value.
///
/// When compiled to Dart, the double type is represented by `double`.
final class DoubleType extends Type {
  /// Creates the double type.
  const DoubleType();

  @override
  Null get element => null;

  @override
  List<Type> get declaredSupertypes => const [NumberType()];

  @override
  bool operator ==(Object other) => other is DoubleType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'double';
}

/// A type that represents a function.
///
/// It is composed of a parameter type and a return type, represented by the
/// symbol `→`.
///
/// For instance, the function type `(:a int, :b int) → int` represents a
/// function that takes a struct with two members, `a` and `b`, both of type
/// `int`, and returns an `int`.
final class FunctionType extends Type {
  /// Creates a function type.
  FunctionType({required this.returnType, required this.parameterType});

  /// The struct type that represents the parameter of the function.
  final StructType parameterType;

  /// The return type of the function.
  final Type returnType;

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is NeverType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$parameterType → $returnType';
}

/// A type that represents an integer value.
///
/// When compiled to Dart, the integer type is represented by `int`.
final class IntegerType extends Type {
  const IntegerType();

  @override
  Null get element => null;

  @override
  List<Type> get declaredSupertypes => const [NumberType()];

  @override
  bool operator ==(Object other) => other is IntegerType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'integer';
}

/// A type that represents an integer value.
///
/// When compiled to Dart, the integer type is represented by `int`.
final class NumberType extends Type {
  const NumberType();

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is NumberType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'number';
}

/// A type that is possibly parameterized by other types.
///
/// For instance, the type `Option(int)` is a polymorphic type with the name
/// `Option` and the argument `int`.
//
// In the future, this will be able to be parameterized by other constants,
// creating a kind of refinement type system.
final class PolymorphicType extends Type {
  /// Creates a polymorphic type with the provided [name] and [arguments].
  ///
  /// The [element] is the element that defines this type, if any, and it is
  /// optional.
  PolymorphicType({
    required this.name,
    required this.arguments,
    this.element,
    this.declaredSupertypes = const [],
  });

  /// The name of the polymorphic type.
  final String name;

  /// The arguments of the polymorphic type.
  final List<Type> arguments;

  @override
  final List<Type> declaredSupertypes;

  /// Whether this type is the `Option` type.
  // TODO(mateusfccp): We have to find a way to check if the type comes from
  // the standard library. Maybe we can use the element.
  bool get isOption {
    return name == 'Option';
  }

  @override
  TypeDefiningElement? element;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolymorphicType && //
        other.name == name &&
        listsEqual(other.arguments, arguments);
  }

  @override
  int get hashCode => Object.hash(name, arguments);

  @override
  String toString() {
    final buffer = StringBuffer(name);

    if (arguments.isNotEmpty) {
      buffer.write('(');
      for (final argument in arguments) {
        buffer.write(argument.toString());

        if (argument != arguments[arguments.length - 1]) {
          buffer.write(', ');
        }
      }
      buffer.write(')');
    }

    return buffer.toString();
  }
}

/// A type that represents a string value.
///
/// When compiled to Dart, the string type is represented by `String`.
final class StringType extends Type {
  const StringType();

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is StringType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'String';
}

/// A type that represents a struct.
///
/// A struct is a type that has named members. For instance, the type
/// `(:name String, :age int)` represents a struct with two members, `name` and
/// `age`, of types `String` and `int`, respectively.
///
/// Different from Dart records, structs are always named. Positional members
/// can be emulated by using a single member with a name that represents the
/// position, prefixed by `$`. For instance, the type `(:$0 int, :$1 int)` will
/// be compiled to a Dart record with shape `(int, int)`.
///
/// A struct with a single member is considered a singleton struct, and it is
/// considered a subtype of its member type, and vice-versa.
///
/// The unit struct is represented by the symbol `()`. It is a struct with no
/// members, and it is used where no information is needed. It is equivalent to
/// the Dart `void` type when used in a covariant position.
final class StructType extends Type {
  /// Creates a struct with the provided [members].
  const StructType({required this.members});

  /// Creates a singleton struct with [member] as its single member, named `$0`.
  StructType.singleton(Type member) : members = {r'$0': member};

  /// The unit struct.
  static const unit = StructType(members: {});

  @override
  Null get element => null;

  final Map<String, Type> members;

  /// Whether this struct is the unit struct.
  ///
  /// The unit struct is a struct with no members.
  bool get isUnit => members.isEmpty;

  /// Whether this struct is a singleton struct.
  ///
  /// A singleton struct is a struct with a single member.
  bool get isSingleton => members.length == 1;

  @override
  bool operator ==(Object other) {
    if (other is! StructType) return false;
    return mapsEqual(other.members, members);
  }

  @override
  int get hashCode => Object.hashAll(members.entries);

  @override
  String toString() {
    final buffer = StringBuffer('(');
    final entries = [...members.entries];

    for (int i = 0; i < entries.length; i++) {
      buffer.write(':${entries[i].key} ${entries[i].value}');

      if (i < entries.length - 1) {
        buffer.write(', ');
      }
    }

    buffer.write(')');
    return buffer.toString();
  }
}

/// A type that represents a symbol.
///
/// A symbol is a type that represents an identifier.
final class SymbolType extends Type {
  /// Creates the symbol type.
  const SymbolType();

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is SymbolType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Symbol';
}

/// The `Unknown` type.
///
/// It is the top type in the type hierarchy, but it uses the "unknown" name to
/// promote a higher degree of built-in type safety when dealing with the
/// universal type.
///
/// When compiled to Dart, the top type is represented by `Object?`.
final class UnknownType extends Type {
  const UnknownType();

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is UnknownType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Top';
}

final class TypeParameterType extends Type {
  TypeParameterType({required this.name});

  final String name;

  @override
  TypeDefiningElement? element;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypeParameterType && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// A type that represents the type of a type.
///
/// It is represented by the symbol `★`.
final class TypeType extends Type {
  /// Creates a type that represents the [reference]d type.
  const TypeType(Type reference) : _reference = reference;

  /// Creates a type that represents the type of a type.
  const TypeType.self() : _reference = null;

  /// The type that this type represents.
  ///
  /// This is `null` if this type represents the type of a type (★).
  Type get reference => _reference ?? this;

  final Type? _reference;

  /// Whether this type represents the type of a type (★).
  bool get isSelf => _reference == null;

  @override
  Null get element => null;

  @override
  bool operator ==(Object other) => other is TypeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Type${isSelf ? '' : ' of $_reference'}';
}

/// Maps a parameter type to the expected argument type.
///
/// For instance, consider this function:
///
/// ```
/// let printMessage (:message String) = message
/// ```
///
/// `printMessage` parameter has a type (:message ★), but whe calling it, we
/// must pass a type (:message String).
StructType parameterTypeToExpectedArgumentType(Type parameterType) {
  final normalizedParameterType = parameterType is StructType
      ? parameterType
      : StructType.singleton(parameterType);

  assert(
    normalizedParameterType.members.values.every(
      (element) => element is TypeType,
    ),
    'All members of a parameter must be a type. Got ${normalizedParameterType.members.values} instead.',
  );

  final castedMembers = normalizedParameterType.members
      .cast<String, TypeType>();

  return StructType(
    members: {
      for (final entry in castedMembers.entries)
        entry.key: entry.value.reference,
    },
  );
}
