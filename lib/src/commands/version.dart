import 'package:args/command_runner.dart';
import 'package:version/version.dart';

class VersionCommand extends Command<int> {
  @override
  final name = 'version';
  @override
  final description = 'Print version.';

  static final Version version = Version(1, 3, 1);

  @override
  Future<int> run() async {
    print('GeoLogger $version');
    return 0;
  }
}
