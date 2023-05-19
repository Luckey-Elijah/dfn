import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';

/// Handler for the `dfn -help` or `dfn -h` option.
int handleHelp(List<String> arguments, Logger logger) {
  checkVerbose(arguments, logger);
  logger.info(dfnUsage);
  return ExitCode.success.code;
}

/// `dfn -h` or `dfn --help` output:
/// ```text
/// Use Dart as your scripting language; register scripts from anywhere.
///
/// Usage: dfn <command> [arguments]
///
/// Available commands:
///   config          Add, remove, and manage scripts.
///   list, ls        Show all registered/added scripts.
///
/// Options (must be first argument provided):
///   --help, -h      Print this usage information.
///   --verbose, -v   Enable verbose logging.
/// ```
final dfnUsage = '''
${italic('Use Dart as your scripting language; register scripts from anywhere.')}

Usage: ${green.wrap(bold('dfn'))} ${italic('<command> [arguments]')}

Available commands:
  ${lightGreen.wrap('config'.fit)}Add, remove, and manage scripts.
  ${lightGreen.wrap('list, ls'.fit)}Show all registered/added scripts.

Options (${italic('must be first argument provided')}):
  ${'--help, -h'.fit}Print this usage information.
  ${'--verbose, -v'.fit}Enable verbose logging.
''';
