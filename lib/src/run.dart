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

  await _checkForUpdate(logger);

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
  final configuration = getConfig(logger);

  return handleTarget(
    target: arguments.first,
    config: configuration,
    args: arguments.sublist(1),
    logger: logger,
  );
}

Future<void> _checkForUpdate(Logger logger) async {
  // read dfn config
  // if updateLastChecked is null || updateLastChecked > 48h ago
  // - fetch version info
  // - if available, notify user
  // - write to dfn -> DateTime.now....utc?

  throw UnimplementedError('_checkForUpdate');
}
