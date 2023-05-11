import 'package:args/command_runner.dart';
import 'package:dfn/src/commands/config/commands/add.dart';
import 'package:dfn/src/commands/config/commands/remove.dart';
import 'package:mason_logger/mason_logger.dart';

class ConfigCommand extends Command<int> {
  ConfigCommand({
    required this.logger,
  }) {
    addSubcommand(ConfigAddCommand(logger: logger));
    addSubcommand(ConfigRemoveCommand(logger: logger));
  }

  final Logger logger;

  @override
  String get description => 'add, remove, and manage scripts';

  @override
  String get name => 'config';
}
