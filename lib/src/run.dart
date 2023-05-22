import 'dart:async';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';

/// Entry point for `dfn` command.
Future<int> run(List<String> arguments, Logger logger) async {
  checkVerbose(arguments, logger);

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
  if (handler == null) return _handleTarget(arguments, logger);
  return handler(arguments.sublist(1), logger);
}

Future<int> _handleTarget(List<String> arguments, Logger logger) async {
  final (_, configuration) = await getConfig(logger);

  return handleTarget(
    target: arguments.first,
    config: configuration,
    args: arguments.sublist(1),
    logger: logger,
  );
}
