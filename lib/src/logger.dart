import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_geohash/dart_geohash.dart';
import 'package:maxminddb/maxminddb.dart';

class Logger {
  final MaxMindDatabase database;
  final File logfile;
  final int bufferSize;
  final int maxLength;

  /// Listen the [logfile] and add geo location for 'ClientHost' using the [database].
  /// The file is read with a [bufferSize] bytes large buffer
  /// and rotated when exscinding [maxSize] MB.
  Logger({
    required this.database,
    required this.logfile,
    this.bufferSize = 2048,
    int maxSize = 10,
  }) : maxLength = maxSize * 1048576;

  static Future<Logger> file({
    required File database,
    required File logfile,
  }) async {
    return Logger(
      database: await MaxMindDatabase.file(database),
      logfile: logfile,
    );
  }

  static Future<Logger> memory({
    required Uint8List database,
    required File logfile,
  }) async {
    return Logger(
      database: await MaxMindDatabase.memory(database),
      logfile: logfile,
    );
  }

  Future<void> start() async {
    return _read()
        .map(Utf8Decoder().convert)
        .transform(LineSplitter())
        .asyncMap(jsonDecode)
        .asyncMap((access) async {
          (access as Map<String, dynamic>)['geolocation'] =
              (await database.search((access)['ClientHost'])) ?? {};
          return access;
        })
        .map((access) {
          final double? latitude =
              access['geolocation']['location']?['latitude'];
          final double? longitude =
              access['geolocation']['location']?['longitude'];

          if (latitude != null && longitude != null) {
            final geoHasher = GeoHasher();
            access['geolocation']['location']['geohash'] =
                geoHasher.encode(longitude, latitude);
          }
          return access;
        })
        .map(jsonEncode)
        .handleError((error) {
          stderr.write(error);
        })
        .forEach(print);
  }

  Stream<List<int>> _read() async* {
    var fileAccess = await logfile.open(mode: FileMode.read);
    var position = 0;
    var length = await fileAccess.length();
    var buffer = Uint8List(bufferSize);

    Stream<Uint8List> _read() async* {
      while (position < length) {
        final bytesRead = await fileAccess.readInto(buffer);
        position += bytesRead;

        yield buffer.sublist(0, bytesRead);
      }

      if (position > maxLength) {
        var oldFile = await logfile.rename('${logfile.path}.old');
        fileAccess = await (await logfile.create()).open(mode: FileMode.read);
        position = 0;
        await oldFile.delete();
      }
    }

    while (await logfile.exists()) {
      yield* _read();

      await for (final event in logfile.watch(events: FileSystemEvent.modify)) {
        if (event is FileSystemModifyEvent && event.contentChanged) {
          length = await (fileAccess.length());
          yield* _read();
        }
      }
    }
  }
}
