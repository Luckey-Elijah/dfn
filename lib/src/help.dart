import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';

int handleHelp(Logger logger) {
  logger.info(dfnUsage());
  return ExitCode.success.code;
}

String dfnUsage() => '''
${italic('Use Dart as your scripting language; register scripts from anywhere.')}

Usage: ${green.wrap(bold('dfn'))} ${italic('<command> [arguments]')}

Available commands:
  ${lightGreen.wrap('config'.fit)}Add, remove, and manage scripts.
  ${lightGreen.wrap('list, ls'.fit)}Show all registered/added scripts.

Options (${italic('must be first argument provided')}):
  ${'--help, -h'.fit}Print this usage information.
  ${'--verbose, -v'.fit}Enable verbose logging.
''';