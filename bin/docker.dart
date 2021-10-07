import 'dart:io';

import 'geologger.dart' as geologger;

void main() {
  var envVars = Platform.environment;
  geologger.main(
      'run -f ${envVars['LOG_FILE'] ?? '/var/log/access.log'} -d ${envVars['DATABASE_FILE'] ?? '/app/GeoLite2-City.mmdb'} --metrics'
          .split(' '));
}
