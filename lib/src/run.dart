import 'dart:async';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';

/// Entry point for `dfn` command.
Future<int> run(List<String> arguments, Logger logger) async {
  checkVerbose(arguments, logger);

  final config = await checkForUpdate(
    getConfig(logger),
    logger,
  );

  if (arguments.isEmpty) {
    logger.info(dfnUsage);
    return ExitCode.usage.code;
  }

  final handlers = <String, Handler>{
    '--help': handleHelp,
    '-h': handleHelp,
    'list': handleList,
    'ls': handleList,
    'config': handleConfig,
  };

  final handler = handlers[arguments.first];
  if (handler == null) return _handleTarget(arguments, logger, config);
  logger.detail(
    '[run] Using built-in "dfn" option/command: ${arguments.first}',
  );
  return handler(arguments.sublist(1), logger, config);
}

Future<int> _handleTarget(
  List<String> arguments,
  Logger logger,
  DfnConfig configuration,
) {
  return handleTarget(
    target: arguments.first,
    config: configuration,
    args: arguments.sublist(1),
    logger: logger,
  );
}
