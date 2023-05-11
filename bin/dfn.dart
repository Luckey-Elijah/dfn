import 'dart:io';

import 'package:dfn/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

Future<void> main(List<String> args) async => _flushThenExit(
      await DfnCommandRunner(logger: Logger(level: Level.verbose)).run(args),
    );

Future<void> _flushThenExit(int status) => [
      stdout.close(),
      stderr.close(),
    ].wait.then<void>((_) => exit(status));
