import 'dart:async';

import 'package:mason_logger/mason_logger.dart';

/// {@template style}
/// Helper for decorating strings as
/// {@endtemplate}
/// bold.
final bold = styleBold.wrap;

/// {@macro style}
/// italic.
final italic = styleItalic.wrap;

/// {@template rest}
/// Retrieve all but the "first" of a list of arguments.
/// {@endtemplate}
extension Rest on List<String> {
  /// {@macro rest}
  List<String> get rest => sublist(1);
}

/// {@template fit}
/// Helper to fit command usage string.
/// {@endtemplate}
extension Fit on String {
  /// {@macro fit}
  String get fit => padRight(16);
}

/// Function for handling commands.
typedef Handler = FutureOr<int> Function(List<String> arguments, Logger logger);
