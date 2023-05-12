import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
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
      callback: (verbose) {
        if (!verbose) return;
        logger
          ..level = Level.verbose
          ..detail('Verbose logging enabled.');
      },
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
        logger.detail(
          'Tried calling `dfn` from dfn which is results in recursive builds.',
        );
        throw UsageException('Do not call "dfn" with "dfn".', 'dfn <script>');
      }

      argParser.options.keys.any(topLevelResults.wasParsed);

      if (hasCommand ||
          argParser.options.keys.any(
            topLevelResults.wasParsed,
          )) {
        logger.detail(
          'A built in was called: ${prettyArgResultsPrint(topLevelResults)}',
        );
        return await runCommand(topLevelResults) ?? ExitCode.success.code;
      }

      if (hasTargetName) {
        logger.detail('Trying to call a target: $targetName');
        final (_, config) = await getConfig(logger);

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

Future<(File, DfnConfig)> getConfig(Logger logger) async {
  logger.detail('Checking for if home path exists: $home.');

  if (!Directory(normalize('$home')).existsSync()) {
    throw FileSystemException('User home path does not exist.', '$home');
  }

  logger.detail('Home path exists ✓.');
  final path = join('$home', '.dfn');
  final configFile = File(path);
  logger.detail('Checking for if dfn config exists: $path.');

  if (!configFile.existsSync()) {
    logger.detail('No dfn config found. Creating empty dfn config at $path.');
    // initialize the default config
    final empty = DfnConfig.empty(configFile);
    final config = (await writeConfig(empty, configFile, logger)).$2;
    return (configFile, config);
  }
  logger.detail('✓ dfn config exists.');
  final contents = await configFile.readAsString();
  final config = DfnConfig.fromJson(contents, configFile);
  return (configFile, config);
}

Future<(File, DfnConfig)> writeConfig(
  DfnConfig config,
  File source,
  Logger logger,
) async {
  await source.create();
  final data = config.toMap();
  await source.writeAsString(jsonEncode(data));
  logger
    ..detail('Wrote to ${source.absolute.path}: ')
    ..detail(jsonPretty(data));
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

String jsonPretty(Map<Object?, Object?> json) {
  final buffer = StringBuffer();
  final bold = styleBold.wrap;

  for (final MapEntry(:key, :value) in json.entries) {
    buffer
      ..write('${bold('$key')}: ')
      ..writeln(value is Map ? jsonPretty(value) : value);
  }

  return '$buffer';
}

String prettyArgResultsPrint(ArgResults results) {
  final hasCommand = results.command != null;
  final commandLabel =
      hasCommand ? prettyArgResultsPrint(results.command!) : results.command;
  final buffer = StringBuffer()
    ..writeln('{')
    ..writeln('  name: ${results.name}')
    ..writeln('  rest: ${results.rest}')
    ..writeln('  arguments: ${results.arguments}')
    ..writeln('  command: $commandLabel')
    ..writeln('}');
  return '$buffer';
}
