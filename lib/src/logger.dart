import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_geohash/dart_geohash.dart';
import 'package:dcli/dcli.dart';
import 'package:maxminddb/maxminddb.dart';
import 'package:extendedip/extendedip.dart';
import 'package:prometheus_client/format.dart' as format;
import 'package:prometheus_client/prometheus_client.dart' as prometheus;

class Logger {
  final MaxMindDatabase database;
  final File logfile;
  final int bufferSize;
  final int? maxSize;
  late final prometheus.Counter? _accessCounter;
  final int? traefikPid;
  final String? traefikProcessName;
  final bool logAccess;

  /// Listen the [logfile] and add geo location for 'ClientHost' using the [database].
  /// The file is read with a [bufferSize] bytes large buffer
  /// and rotated when exscinding [maxSize] MB.
  /// Setting [enableMetrics] to true enables the metrics server listening on [metricsPort].
  /// [metricsPort] defaults to 8080.
  Logger({
    required this.database,
    required this.logfile,
    this.bufferSize = 2048,
    this.maxSize,
    required bool enableMetrics,
    int? metricsPort,
    this.traefikPid,
    this.traefikProcessName,
    bool? logAccess,
  }) : logAccess = logAccess ?? true {
    if (enableMetrics) {
      _accessCounter = prometheus.Counter(
          name: 'traefik_geo_access_log_total',
          help: '',
          labelNames: [
            'request_host',
            'request_method',
            'request_port',
            'request_protocol',
            'request_scheme',
            'router_name',
            'entry_point_name',
            'geohash',
            'latitude',
            'longitude',
            'private_client_address',
            'country_iso_code',
            'continent_iso_code',
          ])
        ..register();
      HttpServer.bind(InternetAddress.anyIPv6, metricsPort ?? 8080)
          .then((server) {
        server.listen((request) {
          request.response.headers
              .add(HttpHeaders.contentTypeHeader, format.contentType);
          format.write004(
              request.response,
              prometheus.CollectorRegistry.defaultRegistry
                  .collectMetricFamilySamples());
          request.response.close();
        });
      });
    }
  }

  static Future<Logger> file({
    required File database,
    required File logfile,
    bool? enableMetrics,
    int? metricsPort,
    int? maxSize,
    int? traefikPid,
    String? traefikProcessName,
    bool? logAccess,
  }) async {
    return Logger(
      database: await MaxMindDatabase.file(database),
      logfile: logfile,
      enableMetrics: enableMetrics ?? false,
      metricsPort: metricsPort,
      maxSize: maxSize,
      traefikPid: traefikPid,
      traefikProcessName: traefikProcessName,
      logAccess: logAccess,
    );
  }

  static Future<Logger> memory({
    required Uint8List database,
    required File logfile,
    bool? enableMetrics,
    int? metricsPort,
    int? maxSize,
    int? traefikPid,
    String? traefikProcessName,
    bool? logAccess,
  }) async {
    return Logger(
      database: await MaxMindDatabase.memory(database),
      logfile: logfile,
      enableMetrics: enableMetrics ?? false,
      metricsPort: metricsPort,
      maxSize: maxSize,
      traefikPid: traefikPid,
      traefikProcessName: traefikProcessName,
      logAccess: logAccess,
    );
  }

  Future<void> start() async {
    print('''Starting Logger with:
    bufferSize: $bufferSize
    maxSize: $maxSize
    traefikPid: $traefikPid
    traefikProcessName: $traefikProcessName
    logAccess: $logAccess''');
    return _read()
        .map(Utf8Decoder().convert)
        .transform(LineSplitter())
        .asyncMap(jsonDecode)
        .asyncMap((access) async {
      final address = InternetAddress(access['ClientHost']);
      (access as Map<String, dynamic>)['geolocation'] =
          (await database.searchAddress(address)) ?? {};

      access['privateClientAddress'] = address.isInPrivate;

      return access;
    }).map((access) {
      final double? latitude = access['geolocation']['location']?['latitude'];
      final double? longitude = access['geolocation']['location']?['longitude'];

      if (latitude != null && longitude != null) {
        final geoHasher = GeoHasher();
        access['geolocation']['location']['geohash'] =
            geoHasher.encode(longitude, latitude);
      }
      return access;
    }).handleError((error) {
      stderr.write(error);
    }).forEach((data) {
      // Only if metrics is enabled, a.k.a. _accessCounter is not null.
      _accessCounter?.labels([
        data['RequestHost'] ?? '',
        data['RequestMethod'] ?? '',
        data['RequestPort'] ?? '',
        data['RequestProtocol'] ?? '',
        data['RequestScheme'] ?? '',
        data['RouterName'] ?? '',
        data['entryPointName'] ?? '',
        data['geolocation']?['location']?['geohash'] ?? '',
        data['geolocation']?['location']?['latitude']?.toString() ?? '',
        data['geolocation']?['location']?['longitude']?.toString() ?? '',
        data['privateClientAddress']?.toString() ?? '',
        data['geolocation']?['country']?['iso_code'] ?? '',
        data['geolocation']?['continent']?['iso_code'] ?? '',
      ]).inc();
      if (logAccess) {
        print(jsonEncode(data));
      }
    });
  }

  Stream<List<int>> _read() async* {
    final fileAccess = await logfile.open(mode: FileMode.read);
    var position = 0;
    var buffer = Uint8List(bufferSize);

    Stream<Uint8List> _read() async* {
      var length = await (fileAccess.length());
      while (position < length) {
        final bytesRead = await fileAccess.readInto(buffer);
        position += bytesRead;

        yield buffer.sublist(0, bytesRead);
      }

      // print('position: $length / ${(maxSize ?? 1) * 1048576}');
      if (maxSize != null && length > maxSize! * 1048576) {
        await logfile.writeAsBytes([], mode: FileMode.writeOnly, flush: true);
        final pids;
        if (traefikPid != null) {
          pids = [traefikPid];
        } else if (traefikProcessName != null) {
          pids = ProcessHelper()
              .getProcessesByName(traefikProcessName!)
              .map((e) => e.pid);
        } else {
          pids = [];
        }
        for (var pid in pids) {
          Process.killPid(pid, ProcessSignal.sigusr1);
        }
        fileAccess.setPositionSync(0);
        position = 0;
      }
    }

    while (await logfile.exists()) {
      yield* _read();

      await for (final event in logfile.watch(events: FileSystemEvent.modify)) {
        if (event is FileSystemModifyEvent && event.contentChanged) {
          yield* _read();
        }
      }
    }
  }
}
