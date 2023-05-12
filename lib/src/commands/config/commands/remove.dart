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
  List<String> get aliases => ['rm'];

  @override
  Future<int> run() async {
    final results = argResults;
    if (results == null) {
      logger.err('Unexpected: results are null');
      return ExitCode.software.code;
    }

    final args = results.arguments;
    if (args.isEmpty) {
      throw UsageException(
        'Please specify a script or path.',
        'dfn config remove <script|path>',
      );
    }

    final (configFile, config) = await getConfig(logger);
    final newStandalone = <String>[];
    final newPackages = <String>[];

    var didRemove = false;

    for (final option in args) {
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
          'Removed: ${styleBold.wrap(path)}',
        );
      }

      for (final package in config.packages) {
        if (canonicalize(option) != canonicalize(package)) {
          newPackages.add(package);
          continue;
        }
        didRemove = true;
        logger.success(
          'Removed: ${styleBold.wrap(package)}',
        );
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

    throw UsageException(
      'Could not remove ${args.join(', ')}.',
      'dfn config remove <script|path>',
    );
  }
}
