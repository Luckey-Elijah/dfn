import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('run', () {
    late Logger logger;
    setUp(() => logger = MockLogger());
    tearDownAll(() {
      return testOverrides = null;
    });
  });
}
