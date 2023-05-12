import 'dart:io';

import 'package:dfn/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

Future<void> main(List<String> args) async {
  final commandRunner = DfnCommandRunner(logger: Logger());
  return _flushThenExit(await commandRunner.run(args));
}

Future<void> _flushThenExit(int status) => [
      stdout.close(),
      stderr.close(),
    ].wait.then<void>((_) => exit(status));
