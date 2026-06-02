import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/logger.dart';

/// Speech-to-text contract. Anything that can convert a recorded audio file
/// path into a text transcript implements this — keeps the avatar layer
/// free from STT-vendor specifics so we can swap Whisper for Deepgram /
/// Yandex / on-device later without touching the streaming code.
abstract interface class TranscriptionService {
  /// Returns the transcribed text, or `null` on empty/failed transcription.
  Future<String?> transcribe(String audioFilePath);
}

/// OpenAI Whisper (`whisper-1`) implementation.
class WhisperTranscriptionService implements TranscriptionService {
  WhisperTranscriptionService({
    required this.apiKey,
    http.Client? httpClient,
    Log? logger,
  })  : _http = httpClient ?? http.Client(),
        _log = logger ?? const Log('Whisper');

  final String apiKey;
  final http.Client _http;
  final Log _log;

  @override
  Future<String?> transcribe(String audioFilePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(AppConfig.whisperUrl))
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = 'whisper-1'
        ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      final streamed = await _http.send(request);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        _log.w('transcribe http ${res.statusCode}: ${res.body}');
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (body['text'] as String?)?.trim();
      return (text == null || text.isEmpty) ? null : text;
    } catch (e, st) {
      _log.e('transcribe threw', error: e, stack: st);
      return null;
    }
  }
}
