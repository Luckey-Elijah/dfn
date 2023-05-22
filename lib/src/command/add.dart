import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Handler for `dfn config add` command.
Future<int> handleAdd(List<String> arguments, Logger logger) async {
  if (arguments.isEmpty) {
    logger.info(dfnConfigAddUsage);
    return ExitCode.usage.code;
  }

  checkVerbose(arguments, logger);

  final (configFile, configuration) = await getConfig(logger);

  for (final argument in arguments) {
    final path = p.canonicalize(p.normalize(argument));
    final pathType = FileSystemEntity.typeSync(path);

    if (pathType == FileSystemEntityType.file) {
      final file = File(path);
      if (!file.existsSync()) {
        logger.err(
          '$path does not exist.\n'
          'dfn config add <script|path>',
        );
      }
      if (configuration.standalone.contains(file.absolute.path)) {
        logger.err(
          '$path is already registered.\n'
          'dfn config add <script|path>',
        );
      }
      final newConfig = DfnConfig(
        packages: configuration.packages,
        standalone: [...configuration.standalone, file.absolute.path],
        source: configFile,
        version: DfnConfig.currentVersion,
      );
      await writeConfig(newConfig, newConfig.source, logger);
      final scriptName =
          p.split(file.absolute.path).last.replaceAll('.dart', '');
      logger.success('Registered $scriptName');
      return ExitCode.success.code;
    }

    if (pathType == FileSystemEntityType.directory) {
      final directory = Directory(path);

      if (!directory.existsSync()) {
        logger.err(
          '$path does not exist.\n'
          'dfn config add <script|path>',
        );
      }

      if (configuration.packages.contains(directory.absolute.path)) {
        logger.warn(
          '$path is already registered.\n'
          'dfn config add <script|path>',
        );
      }

      final scriptsDir = Directory(p.join(directory.absolute.path, 'scripts'));
      if (!scriptsDir.existsSync()) {
        logger.warn(
          '${directory.absolute.path} does not contain "script" sub-folder.',
        );
      }

      final newScripts = await scriptsDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .where((file) => file.absolute.path.endsWith('.dart'))
          .where((file) => !p.split(file.absolute.path).last.startsWith('_'))
          .toList();

      final newConfig = DfnConfig(
        packages: [...configuration.packages, directory.absolute.path],
        standalone: configuration.standalone,
        source: configFile,
        version: DfnConfig.currentVersion,
      );

      await writeConfig(newConfig, newConfig.source, logger);
      final count = newScripts.length;
      final s = newScripts.length > 1 ? 's' : '';
      logger.success(
        'Registered $count new script$s from ${scriptsDir.absolute.path}',
      );

      for (final script in newScripts) {
        final path = script.absolute.path;
        final name = styleBold.wrap(p.split(path).last.replaceAll('.dart', ''));
        final source = link(uri: Uri.file(path), message: path);
        logger.info('  - $name -> $source');
      }

      return ExitCode.success.code;
    }
  }
  logger.info(dfnConfigAddUsage);
  return ExitCode.usage.code;
}

/// Usage information of `dfn config add` command:
/// ```text
/// Usage: dfn config add <script|path>
///
/// Possible arguments:
///   script          .dart file with a top-level `main` function.
///   path            Path to directory with a scripts subfolder
///                   which holds .dart files. Dart files should meet
///                   requirement of scripts. Files that start with _
///                   (underscore) are excluded.
/// ```
final dfnConfigAddUsage = '''
Usage: ${green.wrap(bold('dfn config add'))} ${italic('<script|path>')}

Possible ${italic('arguments')}:
  ${lightGreen.wrap('script'.fit)}${italic('.dart')} file with a top-level `main` function.
  ${lightGreen.wrap('path'.fit)}Path to directory with a ${italic('scripts')} subfolder
  ${''.fit}which holds ${italic('.dart')} files. Dart files should meet
  ${''.fit}requirement of ${italic('scripts')}. Files that start with ${italic('_')}
  ${''.fit}(underscore) are excluded.
''';
