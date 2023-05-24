import 'dart:async';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

/// Override a given option or command with the handler.
/// This will always be used if non-null.
@visibleForTesting
({
  Handler? handler,
  void Function(List<String> arguments, Logger logger)? checkVerbose,
  DfnConfig Function(Logger logger)? getConfig,
  Future<DfnConfig> Function(DfnConfig config, Logger logger)? checkForUpdate,
  Future<int> Function({
    required String target,
    required DfnConfig config,
    required List<String> args,
    required Logger logger,
  })? handleTarget,
})? testOverrides;

/// Entry point for `dfn` command.
Future<int> run(
  List<String> arguments,
  Logger logger,
) async {
  (testOverrides?.checkVerbose ?? checkVerbose)(arguments, logger);

  final config = await (testOverrides?.checkForUpdate ?? checkForUpdate).call(
    (testOverrides?.getConfig ?? getConfig).call(logger),
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

  final handler = testOverrides?.handler ?? handlers[arguments.first];
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
  return (testOverrides?.handleTarget ?? handleTarget)(
    target: arguments.first,
    config: configuration,
    args: arguments.sublist(1),
    logger: logger,
  );
}
