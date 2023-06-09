import 'dart:convert';
import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Handler for `dfn config` command.
Future<int> handleConfig(
  List<String> arguments,
  Logger logger,
  DfnConfig config,
) async {
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

  final handler = handlers[arguments.first];
  if (handler == null) return _defaultHandler(arguments, logger, config);
  logger.detail(
    '[handleConfig] Using built-in "dfn config" option/command: ${arguments.first}',
  );
  return handler(arguments.sublist(1), logger, config);
}

int _defaultHandler(List<String> arguments, Logger logger, DfnConfig _) {
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
DfnConfig getConfig(Logger logger) {
  logger.detail('[getConfig] Checking for if home path exists: $home.');

  if (!Directory(p.normalize('$home')).existsSync()) {
    throw FileSystemException('User home path does not exist.', '$home');
  }

  logger.detail('[getConfig] Home path exists: $home.');
  final path = p.canonicalize(p.join('$home', '.dfn'));
  final configFile = File(path);
  logger.detail('[getConfig] Checking for if dfn config exists: $path.');

  if (!configFile.existsSync()) {
    logger.detail(
      '[getConfig] No dfn config found. Creating empty dfn config at $path.',
    );
    // initialize the default config
    final empty = DfnConfig.empty(configFile);
    final config = writeConfig(empty, logger);
    return config;
  } else {
    logger.detail('[getConfig] dfn config exists at: $path');
  }
  final contents = configFile.readAsStringSync();
  final config = DfnConfig.fromJsonAndFile(
    jsonDecode(contents) as Map<String, dynamic>,
    configFile,
  );
  return config;
}

/// Write to the `dfn` configuration file.
/// Will create the configuration if it does not exist.
DfnConfig writeConfig(
  DfnConfig config,
  Logger logger,
) {
  config.source.createSync();
  final data = config.toJson();
  config.source.writeAsStringSync(jsonEncode(data));
  logger
    ..detail(
      '[writeConfig] Wrote to ${p.canonicalize(config.source.absolute.path)}: ',
    )
    ..detail(const JsonEncoder.withIndent('  ').convert(data));
  return config;
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
    this.updateLastChecked,
  });

  /// An "empty" representation of the file.
  /// {@macro dfn_config}
  DfnConfig.empty(File source)
      : this(
          packages: [],
          standalone: [],
          version: currentVersion,
          source: source,
          updateLastChecked: null,
        );

  /// Create a [DfnConfig] from JSON String.
  /// {@macro dfn_config}
  factory DfnConfig.fromJsonAndFile(
    Map<String, dynamic> map,
    File source,
  ) {
    final updateLastCheckedSrc = map['updateLastChecked'] as String?;
    return DfnConfig(
      updateLastChecked: updateLastCheckedSrc != null
          ? DateTime.tryParse(updateLastCheckedSrc)
          : null,
      source: source,
      packages: List<String>.from(map['packages'] as List<dynamic>? ?? []),
      standalone: List<String>.from(map['standalone'] as List<dynamic>? ?? []),
      version: int.tryParse(map['version'].toString()) ?? currentVersion,
    );
  }

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

  /// That last time an update for `dfn` was checked.
  final DateTime? updateLastChecked;

  /// Whether any package or standalone scripts exist.
  bool get hasScripts => packages.isNotEmpty || standalone.isNotEmpty;

  /// Convert config into JSON object.
  Map<String, dynamic> toJson() => {
        'packages': packages,
        'standalone': standalone,
        'version': version,
        'updateLastChecked': updateLastChecked?.toIso8601String(),
      };
}
