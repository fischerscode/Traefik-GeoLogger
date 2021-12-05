import 'dart:io';

import 'geologger.dart' as geologger;

void main() {
  var envVars = Platform.environment;
  final traefikPid = envVars['TRAEFIK_PID'];
  final traefikProcessName = envVars['TRAEFIK_PROCESS_NAME'];
  final maxLogSize = envVars['MAX_LOG_SIZE'];
  geologger.main('''
    run -f ${envVars['LOG_FILE'] ?? '/var/log/access.log'}
        -d ${envVars['DATABASE_FILE'] ?? '/app/GeoLite2-City.mmdb'}
        --${envVars['ENABLE_METRICS']?.toLowerCase() == 'true' ? '' : 'no-'}metrics
        -p ${envVars['METRICS_PORT'] ?? '8080'}
        ${traefikPid != null ? '--traefik-pid $traefikPid' : ''}
        ${traefikProcessName != null ? '--traefik-process-name $traefikProcessName' : ''}
        ${maxLogSize != null ? '--max-log-size $maxLogSize' : ''}
    '''
      .replaceAll('\n', ' ')
      .split(' ')
      .where((element) => element.isNotEmpty)
      .toList());
}
