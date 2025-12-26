import 'package:pinto/semantic.dart';
import 'package:test/test.dart';

void main() {
  const top = UnknownType();
  const bottom = NeverType();
  const unit = StructType.unit;
  const type = TypeType.self();
  final singleton = StructType.singleton;
  const num = NumberType();
  const int = IntegerType();
  const double = DoubleType();
  const string = StringType();

  test('The top type is only the subtype of itself', () {
    final top = const UnknownType();
    expect(top < top, isTrue);
    expect(top < singleton(top), isTrue);
    expect(top < bottom, isFalse);
    expect(top < type, isFalse);
    expect(top < unit, isFalse);
  });

  test('The bottom type is the subtype of all types', () {
    expect(bottom < top, isTrue);
    expect(bottom < bottom, isTrue);
    expect(bottom < singleton(bottom), isTrue);
    expect(bottom < type, isTrue);
    expect(bottom < unit, isTrue);
  });

  test('A singleton struct is the subtype of its member type', () {
    expect(singleton(top) < top, isTrue);
    expect(singleton(unit) < unit, isTrue);
    expect(singleton(type) < type, isTrue);
    expect(singleton(bottom) < bottom, isTrue);
  });

  test('A type is subtype of their counterpart singleton struct', () {
    expect(top < singleton(top), isTrue);
    expect(unit < singleton(unit), isTrue);
    expect(type < singleton(type), isTrue);
    expect(bottom < singleton(bottom), isTrue);
  });

  test('A type is subtype of itself', () {
    expect(top < top, isTrue);
    expect(unit < unit, isTrue);
    expect(type < type, isTrue);
    expect(bottom < bottom, isTrue);
    expect(num < num, isTrue);
    expect(int < int, isTrue);
    expect(double < double, isTrue);
    expect(string < string, isTrue);
  });

  test('A type is subtype of their declared supertypes', () {
    expect(int < num, isTrue);
    expect(double < num, isTrue);
  });

  test('A type is not subtype of their declared subtypes', () {
    expect(num < int, isFalse);
    expect(num < double, isFalse);
  });

  test(
    'A struct is a subtype of another struct with the same shape when the fields are subtypes',
    () {
      const singleFieldStruct = StructType(members: {'name': string});
      const singleFieldStruct2 = StructType(members: {'age': num});
      const singleFieldStruct3 = StructType(members: {'age': int});
      const multiFieldStruct = StructType(
        members: {'name': string, 'age': num},
      );
      const multiFieldStruct2 = StructType(
        members: {'name': string, 'age': int},
      );

      expect(singleFieldStruct < singleFieldStruct, isTrue);
      expect(singleFieldStruct3 < singleFieldStruct2, isTrue);
      expect(multiFieldStruct2 < multiFieldStruct, isTrue);
    },
  );

  test(
    'A struct is not a subtype of another struct with a different shape',
    () {
      const singleFieldStruct = StructType(members: {'name': string});
      const singleFieldStruct2 = StructType(members: {'age': num});
      const singleFieldStruct3 = StructType(members: {'age': int});
      const multiFieldStruct = StructType(
        members: {'name': string, 'age': num},
      );
      const multiFieldStruct2 = StructType(
        members: {'name': string, 'age': int},
      );

      expect(singleFieldStruct < singleFieldStruct2, isFalse);
      expect(singleFieldStruct < singleFieldStruct3, isFalse);
      expect(singleFieldStruct < multiFieldStruct, isFalse);
      expect(singleFieldStruct < multiFieldStruct2, isFalse);
      expect(multiFieldStruct < multiFieldStruct2, isFalse);
    },
  );
}
