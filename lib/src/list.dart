import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

/// {@template register_source}
/// The type of register script.
/// {@endtemplate}
enum RegisterSource {
  /// Registered as path to a script.
  /// {@macro register_source}
  script,

  /// Registered as path to a directory.
  /// {@macro register_source}
  path;
}

/// Handler for `dfn ls`, `dfn list` command.
Future<int> handleList(List<String> arguments, Logger logger) async {
  final progress = logger.progress('Reading register scripts');

  final (_, config) = await getConfig(logger);

  final files = await lsScriptFiles(
    config: config,
    onInvalidPath: (path) => logger.alert(
      'Failed finding script(s) at $path',
    ),
    logger: logger,
  ).toList();

  if (files.isEmpty) {
    logger.warn(
      '''
There are no registered scripts; use:
  ${green.wrap(bold('dfn config add <script|path>'))}
''',
      tag: '',
    );
    return ExitCode.usage.code;
  }

  final s = files.length > 1 ? 's' : '';
  progress.complete('${files.length} script$s available:');

  for (final file in files) {
    if (file.$2 == RegisterSource.path) {
      final p = canonicalize(file.$1.absolute.parent.path);
      final name = bold(
        split(file.$1.absolute.path).last.replaceAll('.dart', ''),
      );
      final path = link(uri: Uri.file(p), message: p);
      logger.info('  - $name -> $path');
    } else {
      final p = canonicalize(file.$1.absolute.path);
      final name = bold(split(p).last.replaceAll('.dart', ''));
      final path = link(uri: Uri.file(p), message: p);
      logger.info('  - $name -> $path');
    }
  }

  return ExitCode.success.code;
}

/// Emits all registered scripts in [config].
Stream<(File, RegisterSource)> lsScriptFiles({
  required DfnConfig config,
  required void Function(String) onInvalidPath,
  required Logger logger,
}) async* {
  logger.detail('Checking for standalone scripts');
  for (final path in config.standalone) {
    final file = File(canonicalize(path));

    if (!file.existsSync()) {
      onInvalidPath(path);
      continue;
    }
    logger.detail('found standalone script: ${file.absolute.path}');

    yield (file, RegisterSource.script);
  }

  logger.detail('Checking for package scripts');
  for (final package in config.packages) {
    final packageDirectory = Directory(package);

    if (!packageDirectory.existsSync()) {
      onInvalidPath(packageDirectory.path);
      continue;
    }

    final scriptsDirectory =
        Directory(canonicalize(join(packageDirectory.path, 'scripts')));

    if (!scriptsDirectory.existsSync()) {
      onInvalidPath(scriptsDirectory.path);
      continue;
    }

    logger.detail('found scripts directory: ${scriptsDirectory.absolute.path}');

    await for (final file in scriptsDirectory
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => file.absolute.path.endsWith('.dart'))
        .where((file) => !split(file.absolute.path).last.startsWith('_'))) {
      logger.detail(
        'found script registered in "script" path: ${file.absolute.path}',
      );
      yield (file, RegisterSource.path);
    }
  }
}
