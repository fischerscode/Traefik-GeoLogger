import 'dart:io';

import 'package:args/command_runner.dart';

import '../logger.dart';

class RunCommand extends Command<int> {
  @override
  final name = 'run';
  @override
  final description = 'Run the log manipulator.';

  RunCommand() {
    argParser
      ..addOption(
        'accessFile',
        abbr: 'f',
        defaultsTo: '/var/log/access.log',
      )
      ..addOption(
        'dataBaseFile',
        abbr: 'd',
        defaultsTo: 'GeoLite2-City.mmdb',
      )
      ..addFlag(
        'memory',
        abbr: 'm',
        defaultsTo: false,
        negatable: true,
      );
  }

  @override
  Future<int> run() async {
    late Logger logger;
    if (argResults!['memory']) {
      logger = await Logger.memory(
          database: File(argResults!['dataBaseFile']).readAsBytesSync(),
          logfile: File(argResults!['accessFile']));
    } else {
      logger = await Logger.file(
          database: File(argResults!['dataBaseFile']),
          logfile: File(argResults!['accessFile']));
    }

    await logger.start();
    return 1;
  }
}
