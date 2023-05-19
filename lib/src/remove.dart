import 'dart:async';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

Future<int> handleRemove(List<String> arguments, Logger logger) async {
  if (arguments.isEmpty) {
    logger.info(dfnConfigRemoveUsage());
    return ExitCode.usage.code;
  }

  final (configFile, config) = await getConfig(logger);
  final newStandalone = <String>[];
  final newPackages = <String>[];

  var didRemove = false;

  for (final option in arguments) {
    for (final path in config.standalone) {
      final matchesScriptName =
          option == split(path).last.replaceAll('.dart', '');
      late final matchesPath = canonicalize(option) == canonicalize(path);

      if (!matchesScriptName && !matchesPath) {
        newStandalone.add(path);
        continue;
      }
      didRemove = true;
      logger.success(
        'Removed: ${bold(path)}',
      );
    }

    for (final package in config.packages) {
      if (canonicalize(option) != canonicalize(package)) {
        newPackages.add(package);
        continue;
      }
      didRemove = true;
      logger.success('Removed: ${bold(package)}');
    }
  }

  if (didRemove) {
    await writeConfig(
      DfnConfig(
        packages: newPackages,
        standalone: newStandalone,
        version: DfnConfig.currentVersion,
        source: configFile,
      ),
      configFile,
      logger,
    );
    return ExitCode.success.code;
  }

  logger.err(
    '''
Could not remove ${arguments.join(', ')}.
${bold('dfn config remove <script|path>')}''',
  );
  return ExitCode.usage.code;
}

String dfnConfigRemoveUsage() => '''
Usage: ${green.wrap(bold('dfn config remove'))} ${italic('<script|path>')}

Possible ${italic('arguments')}:
  ${lightGreen.wrap('script'.fit)}Unregister a script you have that has been registered.
  ${lightGreen.wrap('path'.fit)}Path to directory with a ${italic('scripts')} subfolder
  ${''.fit}which holds your registered ${italic('.dart')} files.
''';
