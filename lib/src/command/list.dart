import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

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
  checkVerbose(arguments, logger);

  final progress = logger.progress('Reading register scripts');

  final (_, config) = getConfig(logger);

  final results = await lsScriptFiles(
    config: config,
    onInvalidPath: (path) => logger.alert(
      'Failed finding script(s) at $path',
    ),
    logger: logger,
  ).toList();

  if (results.isEmpty) {
    logger.warn(
      '''
There are no registered scripts; use:
  ${green.wrap(bold('dfn config add <script|path>'))}
''',
      tag: '',
    );
    return ExitCode.usage.code;
  }

  final s = results.length > 1 ? 's' : '';
  progress.complete('${results.length} script$s available:');

  for (final result in results) {
    if (result.type == RegisterSource.path) {
      final path = p.canonicalize(result.file.absolute.parent.path);
      final name = bold(
        p.split(result.file.absolute.path).last.replaceAll('.dart', ''),
      );
      final pathLabel = link(uri: Uri.file(path), message: path);
      logger.info('  - $name -> $pathLabel');
    } else {
      final path = p.canonicalize(result.file.absolute.path);
      final name = bold(p.split(path).last.replaceAll('.dart', ''));
      final pathLabel = link(uri: Uri.file(path), message: path);
      logger.info('  - $name -> $pathLabel');
    }
  }

  return ExitCode.success.code;
}

/// Emits all registered scripts in [config].
Stream<({File file, RegisterSource type})> lsScriptFiles({
  required DfnConfig config,
  required void Function(String) onInvalidPath,
  required Logger logger,
}) async* {
  logger.detail('Checking for standalone scripts');
  for (final path in config.standalone) {
    final file = File(path);

    if (!file.existsSync()) {
      onInvalidPath(path);
      continue;
    }
    logger.detail('found standalone script: ${file.absolute.path}');

    yield (file: file, type: RegisterSource.script);
  }

  logger.detail('Checking for package scripts');
  for (final package in config.packages) {
    final packageDirectory = Directory(package);

    if (!packageDirectory.existsSync()) {
      onInvalidPath(packageDirectory.path);
      continue;
    }

    final scriptsDirectory =
        Directory(p.canonicalize(p.join(packageDirectory.path, 'scripts')));

    if (!scriptsDirectory.existsSync()) {
      onInvalidPath(scriptsDirectory.path);
      continue;
    }

    logger.detail('found scripts directory: ${scriptsDirectory.absolute.path}');

    await for (final file in scriptsDirectory
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => file.absolute.path.toLowerCase().endsWith('.dart'))
        .where((file) => !p.split(file.absolute.path).last.startsWith('_'))) {
      logger.detail(
        'found script registered in "script" path: ${file.absolute.path}',
      );
      yield (file: file, type: RegisterSource.path);
    }
  }
}
