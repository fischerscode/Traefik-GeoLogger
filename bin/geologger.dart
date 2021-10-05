import 'dart:io';

import 'package:geologger/geologger.dart';

void main(List<String> arguments) async {
  var code = await GeoLoggerCommandRunner().run(arguments);
  await Future.wait([stdout.close(), stderr.close()]);
  exit(code);
}
