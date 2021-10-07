import 'dart:io';

import 'geologger.dart' as geologger;

void main() {
  geologger.main([
    'run',
    '-f',
    '${String.fromEnvironment('LOG_FILE', defaultValue: '/var/log/access.log')}',
    '-d',
    '${String.fromEnvironment('DATABASE_FILE', defaultValue: '/app/GeoLite2-City.mmdb')}',
    '--${(bool.fromEnvironment('ENABLE_METRICS', defaultValue: false) ? '' : 'no-')}metrics',
    '-p',
    '${String.fromEnvironment('METRICS_PORT', defaultValue: '8080')}',
  ]);
}
