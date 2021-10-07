import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;

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
      )
      ..addFlag(
        'metrics',
        defaultsTo: false,
        negatable: true,
      )
      ..addOption(
        'metrics-port',
        abbr: 'p',
        defaultsTo: '8080',
      );
  }

  @override
  Future<int> run() async {
    late Logger logger;
    final logfile = File(argResults!['accessFile']);
    final enableMetrics = argResults!['metrics'];
    final metricsPort = int.parse(argResults!['metrics-port']);
    if (argResults!['memory']) {
      logger = await Logger.memory(
        database: File(argResults!['dataBaseFile']).readAsBytesSync(),
        logfile: logfile,
        enableMetrics: enableMetrics,
        metricsPort: metricsPort,
      );
    } else {
      logger = await Logger.file(
        database: File(argResults!['dataBaseFile']),
        logfile: logfile,
        enableMetrics: enableMetrics,
        metricsPort: metricsPort,
      );
    }

    if (enableMetrics) {
      runtime_metrics.register();
    }

    while (!await logger.logfile.exists()) {
      stderr.writeln('${logger.logfile.path} does not exist! Sleep 200ms...');
      await Future.delayed(Duration(milliseconds: 200));
    }

    await logger.start();
    return 1;
  }
}
