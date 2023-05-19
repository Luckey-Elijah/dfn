import 'dart:async';
import 'dart:io';

import 'package:dfn/dfn.dart';
import 'package:mason_logger/mason_logger.dart';

Future<void> main(List<String> args) async {
  final logger = Logger();
  return _flushThenExit(await run(args, logger));
}

Future<void> _flushThenExit(int status) async {
  await [stdout.close(), stderr.close()].wait;
  exit(status);
}
