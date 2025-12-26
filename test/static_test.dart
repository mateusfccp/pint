@Tags(['static'])
library;

import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

import '../tool/expectation_tester.dart';

void main() async {
  final directory = Directory('test/static');

  await for (final file in directory.list()) {
    if (file is File && extension(file.path) == '.pinto') {
      _testFile(file.path);
    }
  }
}

void _testFile(String path) {
  test(basename(path), () async {
    final tester = StaticTester(path);

    final expectations = SplayTreeSet.of(await tester.expectations.toList());

    final errors = SplayTreeSet.of(await tester.errors.toList());

    expect(errors, emittedJustLikeTheExpected(expectations));
  });
}
