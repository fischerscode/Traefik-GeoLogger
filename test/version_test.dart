import 'dart:io';

import 'package:geologger/src/commands/version.dart';
import 'package:yamltools/yamltools.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('Test version', () async {
    var pubspec = await File('pubspec.yaml').readAsString();
    var version = loadYamlNode(pubspec).getMapValue('version')?.asString();
    expect(VersionCommand.version.toString(), version);
  });
}
