import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:dfn/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

class ConfigRemoveCommand extends Command<int> {
  ConfigRemoveCommand({
    required this.logger,
  });

  final Logger logger;

  @override
  String get description => 'un-register/remove a script';

  @override
  String get name => 'remove';

  @override
  Future<int> run() async {
    final results = argResults;
    if (results == null) {
      logger.err('Unexpected: results are null');
      return ExitCode.software.code;
    }

    final args = results.arguments;
    if (args.isEmpty) {
      final example = styleBold.wrap('dfn config remove <script>');
      logger.err('Please specify a path: $example');
      return ExitCode.usage.code;
    }
    final (configFile, config) = await getConfig();
    final newStandalone = <String>[];
    final newPackages = <String>[];

    for (final option in args) {
      for (final path in config.standalone) {
        final scriptName = split(path).last.replaceAll('.dart', '');
        if (option != scriptName) {
          newStandalone.add(path);
          continue;
        }

        logger.success(
          'Removed: ${styleBold.wrap(scriptName)} $path',
        );
      }

      for (final package in config.packages) {
        if (option != package) {
          newPackages.add(package);
          continue;
        }
        logger.success(
          'Removed: ${styleBold.wrap(package)}',
        );
      }
    }

    await writeConfig(
      DfnConfig(
        packages: newPackages,
        standalone: newStandalone,
        version: DfnConfig.currentVersion,
        source: configFile,
      ),
      configFile,
    );

    return ExitCode.usage.code;
  }
}
