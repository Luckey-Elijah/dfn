import 'dart:convert';
import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Handler for `dfn config` command.
Future<int> handleConfig(List<String> arguments, Logger logger) async {
  if (arguments.isEmpty) {
    logger.info(dfnConfigUsage);
    return ExitCode.usage.code;
  }
  checkVerbose(arguments, logger);
  final handlers = <String, Handler>{
    'add': handleAdd,
    'list': handleList,
    'ls': handleList,
    'remove': handleRemove,
    'rm': handleRemove
  };

  final handler = handlers[arguments.first] ?? _defaultHandler;
  return handler(arguments.sublist(1), logger);
}

int _defaultHandler(List<String> arguments, Logger logger) {
  logger
    ..warn('could not handle: dfn config ${arguments.join(' ')}')
    ..info(dfnConfigUsage);
  return ExitCode.usage.code;
}

/// Usage for `dfn config` command:
/// ```text
/// Usage: dfn config <command> [arguments]
///
/// Available commands:
///   add             Add register/add scripts.
///   remove (rm)     Remove/un-register scripts.
///   list (ls)       show all registered/added scripts.
/// ```
final dfnConfigUsage = '''
Usage: ${green.wrap(bold('dfn config'))} ${italic('<command> [arguments]')}

Available commands:
  ${lightGreen.wrap('add'.fit)}Add register/add scripts.
  ${lightGreen.wrap('remove (rm)'.fit)}Remove/un-register scripts.
  ${lightGreen.wrap('list (ls)'.fit)}show all registered/added scripts.
''';

/// Path to the user's "home" directory.
final home = Platform.environment[Platform.isWindows ? 'UserProfile' : 'HOME'];

/// Retrieve the `dfn` configuration.
/// Will create the configuration if it does not exist.
Future<(File, DfnConfig)> getConfig(Logger logger) async {
  logger.detail('Checking for if home path exists: $home.');

  if (!Directory(p.normalize('$home')).existsSync()) {
    throw FileSystemException('User home path does not exist.', '$home');
  }

  logger.detail('Home path exists ✓.');
  final path = p.canonicalize(p.join('$home', '.dfn'));
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
  final config = DfnConfig.fromJsonAndFile(
    jsonDecode(contents) as Map<String, dynamic>,
    configFile,
  );
  return (configFile, config);
}

/// Write to the `dfn` configuration file.
/// Will create the configuration if it does not exist.
Future<(File, DfnConfig)> writeConfig(
  DfnConfig config,
  File source,
  Logger logger,
) async {
  await source.create();
  final data = config.toMap();
  await source.writeAsString(jsonEncode(data));
  logger
    ..detail('Wrote to ${p.canonicalize(source.absolute.path)}: ')
    ..detail(const JsonEncoder.withIndent('  ').convert(data));
  return (source, config);
}

/// {@template dfn_config}
/// Dart representation of the `.dfn` file.
/// {@endtemplate}
class DfnConfig {
  /// {@macro dfn_config}
  const DfnConfig({
    required this.packages,
    required this.standalone,
    required this.version,
    required this.source,
  });

  /// An "empty" representation of the file.
  /// {@macro dfn_config}
  DfnConfig.empty(File source)
      : this(
          packages: [],
          standalone: [],
          version: currentVersion,
          source: source,
        );

  /// Create a [DfnConfig] from JSON String.
  /// {@macro dfn_config}
  factory DfnConfig.fromJsonAndFile(
    Map<String, dynamic> map,
    File source,
  ) =>
      DfnConfig(
        source: source,
        packages: List<String>.from(map['packages'] as List<dynamic>? ?? []),
        standalone:
            List<String>.from(map['standalone'] as List<dynamic>? ?? []),
        version: int.tryParse(map['version'].toString()) ?? currentVersion,
      );

  /// Most recent version of the schema.
  static const currentVersion = 1;

  /// Paths to package directories that are registered.
  final List<String> packages;

  /// Paths to scripts that are registered.
  final List<String> standalone;

  /// Version of this schema.
  final int version;

  /// Location of this config.
  final File source;

  /// Whether any package or standalone scripts exist.
  bool get hasScripts => packages.isNotEmpty || standalone.isNotEmpty;

  /// Converts this config into JSON-like map.
  Map<String, dynamic> toMap() => {
        'packages': packages,
        'standalone': standalone,
        'version': version,
      };
}
