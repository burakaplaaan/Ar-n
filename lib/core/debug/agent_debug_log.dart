// #region agent log
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug mode: NDJSON to ingest + debugPrint (session dbd864).
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, dynamic>? data,
  String runId = 'pre',
}) {
  final payload = <String, dynamic>{
    'sessionId': 'dbd864',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data ?? {},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = jsonEncode(payload);
  debugPrint('[AGENT_LOG]$line');
  if (kIsWeb) return;
  Future<void>(() async {
    final uris = [
      Uri.parse(
          'http://127.0.0.1:7299/ingest/fce147f5-e6b0-4176-ba3d-cf1f86d10c8c'),
      Uri.parse(
          'http://10.0.2.2:7299/ingest/fce147f5-e6b0-4176-ba3d-cf1f86d10c8c'),
    ];
    for (final uri in uris) {
      HttpClient? client;
      try {
        client = HttpClient();
        client.connectionTimeout = const Duration(milliseconds: 600);
        final req = await client.postUrl(uri);
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        req.headers.set('X-Debug-Session-Id', 'dbd864');
        req.write(line);
        await req.close().timeout(const Duration(milliseconds: 600));
        break;
      } catch (_) {
        // try next host
      } finally {
        client?.close(force: true);
      }
    }
  });
}
// #endregion
