// Stub used on web, where local file-system access via dart:io is unavailable.
import 'dart:typed_data';

Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('Loading a local file path is not supported on web.');
}
