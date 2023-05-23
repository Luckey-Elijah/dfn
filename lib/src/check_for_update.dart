import 'dart:convert';

import 'package:dfn/dfn.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

/// Current version of `dfn`.
const version = '0.2.2';

/// Checks if a new update is available notifies via [logger] message.
/// Return [DfnConfig] to be use in rest of application.
Future<DfnConfig> checkForUpdate(DfnConfig config, Logger logger) async {
  final now = DateTime.now();
  logger.detail(
    '[checkForUpdate] Checking config for "updateLastChecked" is longer than '
    '48 hours.',
  );
  try {
    final updateLastChecked = config.updateLastChecked;
    if (updateLastChecked == null ||
        updateLastChecked.difference(now) > const Duration(hours: 48)) {
      final url = Uri.parse('https://pub.dev/api/packages/dfn');
      logger
        ..detail('[checkForUpdate] "updateLastChecked": $updateLastChecked')
        ..detail('[checkForUpdate] Checking $url for an update.');

      final result = await http.get(url);
      final body = jsonDecode(result.body);

      if (result.statusCode != 200) {
        throw Exception('Non-200 status code: ${result.statusCode}');
      }

      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected result body: $body');
      }

      final thisVersion = Version.parse(version);
      final latestVersion = Version.parse(
        (body['latest'] as Map<String, dynamic>)['version'] as String,
      );

      logger.detail(
        '[checkForUpdate] Checking if $thisVersion is lower '
        'than $latestVersion',
      );

      if (thisVersion < latestVersion) {
        logger.info(
          '''
A newer version of dfn is available: ${bold(green.wrap('$latestVersion'))}
Update with ${bold(green.wrap('dart pub global activate dfn'))}.
''',
        );
      } else {
        logger.detail('[checkForUpdate] No newer version available.');
      }

      final dt = now.toIso8601String();

      logger.detail(
        '[checkForUpdate] Writing "updateLastChecked": "$dt" to config.',
      );

      final newConfig = DfnConfig(
        packages: config.packages,
        standalone: config.standalone,
        version: DfnConfig.currentVersion,
        source: config.source,
        updateLastChecked: now,
      );

      return writeConfig(newConfig, logger);
    }
    logger.detail('[checkForUpdate] No update to get for now.');
  } catch (e, st) {
    logger
      ..err('Unsuccessfully checked for updates.')
      ..detail('[checkForUpdate] $e')
      ..detail('[checkForUpdate] $st');
  }
  return config;
}
