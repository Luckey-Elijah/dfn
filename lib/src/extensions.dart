import 'dart:async';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template style}
/// Helper for decorating strings as
/// {@endtemplate}
/// bold.
final bold = styleBold.wrap;

/// {@macro style}
/// italic.
final italic = styleItalic.wrap;

/// {@template fit}
/// Helper to fit command usage string.
/// {@endtemplate}
extension Fit on String {
  /// {@macro fit}
  String get fit => padRight(16);
}

/// Function for handling commands and options.
typedef Handler = FutureOr<int> Function(
  List<String> arguments,
  Logger logger,
  DfnConfig config,
);

/// Check if `--verbose` is the first argument and then sets
/// the logger to verbose mode.
void checkVerbose(List<String> arguments, Logger logger) {
  if (arguments.isNotEmpty && arguments.first == '--verbose') {
    logger
      ..level = Level.verbose
      ..detail('[checkVerbose] Enabling verbose mode.')
      ..detail('[checkVerbose] Removing "--verbose" argument.');
    arguments.remove('--verbose');
  }
}
