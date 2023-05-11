import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfn/src/commands/commands.dart';
import 'package:dfn/src/commands/config/config.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

const executableName = 'dfn';
const packageName = 'dfn';
const description = 'Use Dart as your scripting language, '
    'and register scripts from anywhere.';

class DfnCommandRunner extends CommandRunner<int> {
  /// {@macro dfn_command_runner}
  DfnCommandRunner({
    required this.logger,
  }) : super(executableName, description) {
    addCommand(ConfigCommand(logger: logger));
    addCommand(ListCommand(logger: logger));
  }

  @override
  void printUsage() => logger.info(usage);

  final Logger logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      final possibleScriptName = topLevelResults.arguments.firstOrNull;

      if (topLevelResults.command == null &&
          possibleScriptName != null &&
          !possibleScriptName.startsWith('-') &&
          !possibleScriptName.startsWith('_')) {
        final (_, config) = await getConfig();

        return tryHandleScript(
          scriptName: possibleScriptName,
          config: config,
          args: topLevelResults.rest,
          logger: logger,
        );
      }
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    } catch (e, stackTrace) {
      logger
        ..err('$e')
        ..err('$stackTrace')
        ..info('');
      return ExitCode.software.code;
    }
  }
}

Future<int> tryHandleScript({
  required String scriptName,
  required DfnConfig config,
  required List<String> args,
  required Logger logger,
}) async {
  if (!config.hasScripts) {
    logger.err('No registered scripts.');
    return 127;
  }

  Future<int> runScript(File file) async {
    final results = await Process.start(
      'dart',
      [file.absolute.path, ...args],
      mode: ProcessStartMode.inheritStdio,
    );
    return results.exitCode;
  }

  for (final path in config.standalone) {
    final file = File(path);
    final fileName = split(file.absolute.path).last;
    if (fileName == scriptName ||
        fileName.replaceAll('.dart', '') == scriptName) {
      // has match!
      return runScript(file);
    }
  }

  for (final path in config.packages) {
    final directory = Directory(join(path, 'dfn'));
    await for (final file in directory
        .list()
        .where((e) => e is File)
        .cast<File>()
        .where((file) => file.absolute.path.endsWith('.dart'))
        .where((file) => !split(file.absolute.path).last.startsWith('_'))) {
      final fileName = split(file.absolute.path).last;
      if (fileName == scriptName ||
          fileName.replaceAll('.dart', '') == scriptName) {
        return runScript(file);
      }
    }
  }

  logger.err('${styleBold.wrap(scriptName)} not found in registered scripts.');
  return 127;
}

Future<(File, DfnConfig)> getConfig() async {
  final home = Platform.environment['HOME'];
  final configFile = File('$home/.dfn');
  if (!configFile.existsSync()) {
    // initialize the default config
    final empty = DfnConfig.empty(configFile);
    final config = (await writeConfig(empty, configFile)).$2;
    return (configFile, config);
  }
  final contents = await configFile.readAsString();
  final config = DfnConfig.fromJson(contents, configFile);
  return (configFile, config);
}

Future<(File, DfnConfig)> writeConfig(DfnConfig config, File source) async {
  await source.create();
  await source.writeAsString(jsonEncode(config.toMap()));
  return (source, config);
}

class DfnConfig {
  const DfnConfig({
    required this.packages,
    required this.standalone,
    required this.version,
    required this.source,
  });

  DfnConfig.empty(File source)
      : this(
          packages: [],
          standalone: [],
          version: currentVersion,
          source: source,
        );

  factory DfnConfig.fromMap(Map<String, dynamic> map, File source) {
    return DfnConfig(
      source: source,
      packages: List<String>.from(map['packages'] as List<dynamic>? ?? []),
      standalone: List<String>.from(map['standalone'] as List<dynamic>? ?? []),
      version: int.tryParse(map['version'].toString()) ?? currentVersion,
    );
  }

  factory DfnConfig.fromJson(String contents, File source) => DfnConfig.fromMap(
        json.decode(contents) as Map<String, dynamic>,
        source,
      );
  static const currentVersion = 1;

  final List<String> packages;
  final List<String> standalone;
  final int version;
  final File source;

  bool get hasScripts => packages.isNotEmpty || standalone.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'packages': packages,
        'standalone': standalone,
        'version': version,
      };
}
