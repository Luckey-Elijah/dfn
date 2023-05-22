/// dfn
/// Use Dart as your scripting language, and register scripts from anywhere.
///
/// ```sh
/// # activate dfn
/// dart pub global activate dfn
///
/// # see usage
/// dfn --help
/// ```
library dfn;

export 'src/check_for_update.dart';
export 'src/command/add.dart';
export 'src/command/config.dart';
export 'src/command/help.dart';
export 'src/command/list.dart';
export 'src/command/remove.dart';
export 'src/command/target.dart';
export 'src/extensions.dart';
export 'src/run.dart';
