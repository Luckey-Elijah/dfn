import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfn/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

class ListCommand extends Command<int> {
  ListCommand({required this.logger});

  final Logger logger;

  @override
  String get description => 'show all registered/added scripts';

  @override
  String get name => 'list';

  @override
  List<String> get aliases => ['ls'];

  @override
  Future<int> run() async {
    final progress = logger.progress('Reading register scripts');

    final (_, config) = await getConfig();

    final files = await lsScriptFiles(
      config: config,
      onInvalidPath: (path) => logger.err('Failed finding script(s) at $path'),
    ).toList();

    if (files.isEmpty) {
      throw UsageException(
        'No scripts are registered.',
        'dfn config add <script|path>',
      );
    }

    final s = files.length > 1 ? 's' : '';
    progress.complete('${files.length} script$s available:');

    for (final file in files) {
      final name = styleBold.wrap(
        split(file.absolute.path).last.replaceAll('.dart', ''),
      );
      final path = link(
        uri: Uri.file(file.absolute.path),
        message: file.absolute.path,
      );
      logger.info('  - $name -> $path');
    }

    return ExitCode.success.code;
  }
}

Stream<File> lsScriptFiles({
  required DfnConfig config,
  required void Function(String) onInvalidPath,
}) async* {
  for (final path in config.standalone) {
    final file = File(path);

    if (!file.existsSync()) {
      onInvalidPath(path);
      continue;
    }

    yield file;
  }

  for (final package in config.packages) {
    final packageDirectory = Directory(package);

    if (!packageDirectory.existsSync()) {
      onInvalidPath(packageDirectory.path);
      continue;
    }

    final scriptsDirectory = Directory(join(packageDirectory.path, 'scripts'));

    if (!scriptsDirectory.existsSync()) {
      onInvalidPath(scriptsDirectory.path);
      continue;
    }

    yield* scriptsDirectory
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => file.absolute.path.endsWith('.dart'))
        .where((file) => !split(file.absolute.path).last.startsWith('_'));
  }
}
