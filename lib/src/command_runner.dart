import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/run.dart';
import 'commands/version.dart';

class GeoLoggerCommandRunner extends CommandRunner<int> {
  GeoLoggerCommandRunner()
      : super(
          'geologger',
          'Add geo locations to the Traefic access log.',
        ) {
    addCommand(RunCommand());
    addCommand(VersionCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      return await super.run(args) ?? 0;
    } on UsageException catch (e) {
      stderr.writeln(e);
      return 1;
    }
  }
}
