import 'dart:convert';
import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

Future<int> handleConfig(List<String> arguments, Logger logger) async {
  if (arguments.isEmpty) {
    logger.info(dfnConfigUsage());
    return ExitCode.usage.code;
  }

  if (arguments.first == 'add') {
    return handleAdd(arguments.rest, logger);
  }

  if (arguments.first == 'remove' || arguments.first == 'rm') {
    return handleRemove(arguments.rest, logger);
  }

  logger.info(dfnConfigUsage());
  return ExitCode.usage.code;
}

String dfnConfigUsage() => '''
Usage: ${green.wrap(bold('dfn config'))} ${italic('<command> [arguments]')}

Available commands:
  ${lightGreen.wrap('add'.fit)}Add register/add scripts.
  ${lightGreen.wrap('remove (rm)'.fit)}Remove/un-register scripts.
  ${lightGreen.wrap('list (ls)'.fit)}show all registered/added scripts.
''';
String? home =
    Platform.environment[Platform.isWindows ? 'UserProfile' : 'HOME'];

Future<(File, DfnConfig)> getConfig(Logger logger) async {
  logger.detail('Checking for if home path exists: $home.');

  if (!Directory(normalize('$home')).existsSync()) {
    throw FileSystemException('User home path does not exist.', '$home');
  }

  logger.detail('Home path exists ✓.');
  final path = canonicalize(join('$home', '.dfn'));
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
    ..detail('Wrote to ${canonicalize(source.absolute.path)}: ')
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

  for (final MapEntry(:key, :value) in json.entries) {
    buffer
      ..write(bold('$key'))
      ..writeln(value is Map ? jsonPretty(value) : value);
  }

  return '$buffer';
}
