import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('Fit extension', () {
    test('[fit] pads the right with a width of 16', () {
      const name = 'hi';
      expect(name.fit.length, equals(16));
      expect(name.fit, startsWith('hi'));
      expect(name.fit, endsWith(' ' * 14));
    });
  });

  group('checkVerbose', () {
    late Logger logger;

    setUp(() {
      logger = MockLogger();
    });

    tearDownAll(() => reset(logger));

    group('no-op when', () {
      test('[arguments] is empty', () {
        checkVerbose([], logger);
        verifyZeroInteractions(logger);
      });

      test('first argument is not "--verbose"', () {
        checkVerbose(['this', '--verbose'], logger);
        verifyZeroInteractions(logger);
      });
    });

    test('updates logger level & removes "--verbose" options from args', () {
      final args = ['--verbose'];
      checkVerbose(args, logger);
      expect(args.contains('--verbose'), isFalse);
      // expect(logger.level, equals(Level.verbose));
      verify(() => logger.level = Level.verbose).called(1);
      verify(() => logger.detail(any())).called(2);
    });
  });
}
