import 'dart:convert';
import 'dart:io';

import 'package:assistant_webstreaming/services/transcription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File audio;
  setUp(() async {
    audio = await File('${Directory.systemTemp.path}/test_whisper.wav').create();
    await audio.writeAsBytes([0x52, 0x49, 0x46, 0x46]); // RIFF stub
  });
  tearDown(() async {
    if (await audio.exists()) await audio.delete();
  });

  test('returns parsed text on 200 OK', () async {
    final client = MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.headers['Authorization'], 'Bearer test-key');
      return http.Response(jsonEncode({'text': 'Hello world'}), 200);
    });

    final svc = WhisperTranscriptionService(apiKey: 'test-key', httpClient: client);
    final text = await svc.transcribe(audio.path);
    expect(text, 'Hello world');
  });

  test('returns null on non-200 response', () async {
    final client = MockClient(
        (req) async => http.Response('rate limit', 429));
    final svc = WhisperTranscriptionService(apiKey: 'k', httpClient: client);
    expect(await svc.transcribe(audio.path), isNull);
  });

  test('returns null on empty transcription text', () async {
    final client = MockClient(
        (req) async => http.Response(jsonEncode({'text': '   '}), 200));
    final svc = WhisperTranscriptionService(apiKey: 'k', httpClient: client);
    expect(await svc.transcribe(audio.path), isNull);
  });

  test('returns null on missing text field', () async {
    final client =
        MockClient((req) async => http.Response('{"other":"x"}', 200));
    final svc = WhisperTranscriptionService(apiKey: 'k', httpClient: client);
    expect(await svc.transcribe(audio.path), isNull);
  });

  test('returns null when underlying http throws', () async {
    final client = MockClient((req) async => throw const SocketException('x'));
    final svc = WhisperTranscriptionService(apiKey: 'k', httpClient: client);
    expect(await svc.transcribe(audio.path), isNull);
  });
}
