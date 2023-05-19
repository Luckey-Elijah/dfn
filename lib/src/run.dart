import 'dart:async';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';

Future<int> run(List<String> arguments, Logger logger) async {
  if (arguments.isEmpty) {
    logger.info(dfnUsage());
    return ExitCode.usage.code;
  }

  if (arguments.first == '--verbose') {
    logger.level = Level.verbose;
    arguments.remove('--verbose');
  }

  if (arguments.isEmpty) {
    logger.info(dfnUsage());
    return ExitCode.usage.code;
  }

  int help() => handleHelp(logger);
  Future<int> list() => handleList(arguments.rest, logger);
  Future<int> config() => handleConfig(arguments.rest, logger);
  final handler = <String, FutureOr<int> Function()>{
    '--help': help,
    '-h': help,
    'list': list,
    'ls': list,
    'config': config,
  }[arguments.first];

  if (handler != null) return handler();

  final (_, configuration) = await getConfig(logger);
  return handleTarget(
    target: arguments.first,
    config: configuration,
    args: arguments.rest,
    logger: logger,
  );
}
