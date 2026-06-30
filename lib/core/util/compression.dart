import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Payload ko JSON me encode karke gzip compress karta hai.
///
/// Ye pure CPU kaam hai — multi-hour (24h tak) sessions me payload kai MB ka
/// ho sakta hai, aur main thread pe karne se UI freeze hoti hai. Isliye
/// [gzipPayloadInIsolate] ise ek alag background isolate me chalata hai.
({Uint8List gzipBytes, int jsonLength}) gzipPayloadSync(
    Map<String, dynamic> payload) {
  final jsonBytes = utf8.encode(jsonEncode(payload));
  final gzipBytes = gzip.encode(jsonBytes);
  return (
    gzipBytes: Uint8List.fromList(gzipBytes),
    jsonLength: jsonBytes.length,
  );
}

/// [gzipPayloadSync] ko background isolate me chalata hai — main thread (UI)
/// block nahi hoti, chahe payload kitna bhi bada ho.
Future<({Uint8List gzipBytes, int jsonLength})> gzipPayloadInIsolate(
        Map<String, dynamic> payload) =>
    Isolate.run(() => gzipPayloadSync(payload));
