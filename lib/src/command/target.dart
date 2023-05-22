import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

/// Handler for `dfn <target|script>`.
/// Execute a script/command file from in this order:
/// - a config standalone script
/// - a config package script
/// - forward everything the `dart run`
Future<int> handleTarget({
  required String target,
  required DfnConfig config,
  required List<String> args,
  required Logger logger,
}) async {
  Future<int> dartRun(String target, List<String> args) async {
    final process = Process.start(
      'dart',
      ['run', target, ...args],
      mode: ProcessStartMode.inheritStdio,
    );
    return (await process).exitCode;
  }

  Future<int> runScript(File file) async {
    return dartRun(canonicalize(file.absolute.path), args);
  }

  for (final path in config.standalone) {
    final file = File(path);
    final fileName = split(canonicalize(file.absolute.path)).last;
    if (fileName == target || fileName.replaceAll('.dart', '') == target) {
      return runScript(file);
    }
  }

  for (final path in config.packages) {
    final directory = Directory(join(path, 'scripts'));
    await for (final file in directory
        .list()
        .where((e) => e is File)
        .cast<File>()
        .where((file) => canonicalize(file.absolute.path).endsWith('.dart'))
        .where(
          (file) =>
              !split(canonicalize(file.absolute.path)).last.startsWith('_'),
        )) {
      final fileName = split(canonicalize(file.absolute.path)).last;
      if (fileName == target || fileName.replaceAll('.dart', '') == target) {
        return runScript(file);
      }
    }
  }

  return dartRun(target, args);
}
