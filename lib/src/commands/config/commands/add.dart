import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfn/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

class ConfigAddCommand extends Command<int> {
  ConfigAddCommand({
    required this.logger,
  });

  final Logger logger;

  @override
  String get description => 'register/add a script';

  @override
  String get name => 'add';

  @override
  Future<int> run() async {
    final results = argResults;
    if (results == null) {
      throw FormatException(
        'Unexpected: results are null.',
        StackTrace.current,
      );
    }
    final args = results.arguments;
    if (args.isEmpty) {
      throw UsageException(
        'Please specify a script or path.',
        'dfn config add <script|path>',
      );
    }

    for (final arg in args) {
      final path = normalize(arg);
      final pathType = FileSystemEntity.typeSync(path);
      final (configFile, config) = await getConfig();
      if (pathType == FileSystemEntityType.file) {
        final file = File(path);
        if (!file.existsSync()) {
          throw UsageException(
            '$path does not exist.',
            'dfn config add <script|path>',
          );
        }
        if (config.standalone.contains(file.absolute.path)) {
          throw UsageException(
            '$path is already registered.',
            'dfn config add <script|path>',
          );
        }
        final newConfig = DfnConfig(
          packages: config.packages,
          standalone: [...config.standalone, file.absolute.path],
          source: configFile,
          version: DfnConfig.currentVersion,
        );
        await writeConfig(newConfig, newConfig.source);
        final scriptName =
            split(file.absolute.path).last.replaceAll('.dart', '');
        logger.success('Registered $scriptName');
        return ExitCode.success.code;
      }

      if (pathType == FileSystemEntityType.directory) {
        final directory = Directory(path);

        if (!directory.existsSync()) {
          throw UsageException(
            '$path does not exist.',
            'dfn config add <script|path>',
          );
        }

        if (config.packages.contains(directory.absolute.path)) {
          throw UsageException(
            '$path is already registered.',
            'dfn config add <script|path>',
          );
        }

        final scriptsDir = Directory(join(directory.absolute.path, 'scripts'));
        if (!scriptsDir.existsSync()) {
          throw UsageException(
            '$path does not contain "script" sub folder.',
            'dfn config add <script|path>',
          );
        }

        final newScripts = await scriptsDir
            .list()
            .where((entity) => entity is File)
            .cast<File>()
            .where((file) => file.absolute.path.endsWith('.dart'))
            .where((file) => !split(file.absolute.path).last.startsWith('_'))
            .toList();

        final newConfig = DfnConfig(
          packages: [...config.packages, directory.absolute.path],
          standalone: config.standalone,
          source: configFile,
          version: DfnConfig.currentVersion,
        );

        await writeConfig(newConfig, newConfig.source);
        final count = newScripts.length;
        final s = newScripts.length > 1 ? 's' : '';
        logger.success(
          'Registered $count new script$s from ${scriptsDir.absolute.path}',
        );

        for (final script in newScripts) {
          final path = script.absolute.path;
          final name = styleBold.wrap(split(path).last.replaceAll('.dart', ''));
          final source = link(uri: Uri.file(path), message: path);
          logger.info('  - $name -> $source');
        }

        return ExitCode.success.code;
      }
    }

    throw UsageException(
      'path(s) does not exist: ${args.join(', ')}',
      'dfn config add <script|path>',
    );
  }
}
