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
    argParser.addFlag(
      'verbose',
      callback: (verbose) => verbose ? logger.level = Level.verbose : null,
      help: 'Enable verbose logging.',
      negatable: false,
    );
  }

  @override
  void printUsage() => logger.info(usage);

  final Logger logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      final targetName = topLevelResults.arguments.firstOrNull;

      final hasCommand = topLevelResults.command != null;
      final hasTargetName = targetName != null;

      // handle recursion
      if (targetName == 'dfn' ||
          targetName == ':dfn' ||
          targetName == 'dfn:dfn') {
        throw UsageException('Do not call "dfn" with "dfn".', 'dfn <script>');
      }

      if (hasCommand || topLevelResults.wasParsed('help')) {
        return await runCommand(topLevelResults) ?? ExitCode.success.code;
      }

      if (hasTargetName) {
        final (_, config) = await getConfig();

        return handleTarget(
          target: targetName,
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
        ..err('$stackTrace');
      return ExitCode.software.code;
    }
  }
}

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
    return dartRun(file.absolute.path, args);
  }

  for (final path in config.standalone) {
    final file = File(path);
    final fileName = split(file.absolute.path).last;
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
        .where((file) => file.absolute.path.endsWith('.dart'))
        .where((file) => !split(file.absolute.path).last.startsWith('_'))) {
      final fileName = split(file.absolute.path).last;
      if (fileName == target || fileName.replaceAll('.dart', '') == target) {
        return runScript(file);
      }
    }
  }

  return dartRun(target, args);
}

String? home =
    Platform.environment[Platform.isWindows ? 'UserProfile' : 'HOME'];

Future<(File, DfnConfig)> getConfig() async {
  if (!Directory(normalize('$home')).existsSync()) {
    throw FileSystemException('User home path does not exist.', '$home');
  }

  final configFile = File(join('$home', '.dfn'));
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
