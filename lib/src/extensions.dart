import 'package:mason_logger/mason_logger.dart';

final bold = styleBold.wrap;
final italic = styleItalic.wrap;

extension Rest on List<String> {
  List<String> get rest {
    if (isEmpty) return this;
    if (length == 1) return [];
    return [for (var i = 1; i < length; i++) this[i]];
  }
}

extension Fit on String {
  String get fit => padRight(16);
}
