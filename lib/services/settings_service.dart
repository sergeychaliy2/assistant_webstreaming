import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Tradeoff between adaptive bitrate (auto-downgrades on slow networks) and
/// pinned-high quality (always requests the top simulcast layer, may stutter
/// on poor links).
enum StreamingQuality {
  /// LiveKit picks the best layer based on render size + bandwidth.
  auto,

  /// Force highest available layer at all times.
  high;

  static StreamingQuality fromName(String? n) {
    for (final v in StreamingQuality.values) {
      if (v.name == n) return v;
    }
    return StreamingQuality.high;
  }
}

class SettingsService extends ChangeNotifier {
  static const _kSandbox = 'sandbox_enabled';
  static const _kSessionSeconds = 'session_seconds';
  static const _kAssistantLanguage = 'language';
  static const _kUiLanguage = 'ui_language';
  static const _kAvatarId = 'avatar_id';
  static const _kVoiceId = 'voice_id';
  static const _kStreamingQuality = 'streaming_quality';
  static const _kSubtitles = 'subtitles_enabled';

  bool _sandbox = false;
  int _sessionSeconds = AppConfig.defaultSessionSeconds;
  String _language = 'en';
  String _uiLanguage = 'en';
  String _avatarId = AppConfig.defaultAvatarId;
  String _voiceId = AppConfig.defaultVoiceId;
  StreamingQuality _streamingQuality = StreamingQuality.high;
  bool _subtitlesEnabled = false;
  bool _loaded = false;

  bool get sandbox => _sandbox;
  int get sessionSeconds =>
      _sandbox ? AppConfig.sandboxSessionSeconds : _sessionSeconds;
  int get userSessionSeconds => _sessionSeconds;
  String get language => _language;
  String get uiLanguage => _uiLanguage;

  /// Avatar to use for the next session. When sandbox is on the underlying
  /// HeyGen service swaps in the sandbox avatar regardless of this value.
  String get avatarId => _avatarId;
  String get voiceId => _voiceId;
  StreamingQuality get streamingQuality => _streamingQuality;
  bool get subtitlesEnabled => _subtitlesEnabled;

  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sandbox = prefs.getBool(_kSandbox) ?? false;
    _sessionSeconds =
        prefs.getInt(_kSessionSeconds) ?? AppConfig.defaultSessionSeconds;
    _language = prefs.getString(_kAssistantLanguage) ?? 'en';
    _uiLanguage = prefs.getString(_kUiLanguage) ?? 'en';
    _avatarId = prefs.getString(_kAvatarId) ?? AppConfig.defaultAvatarId;
    _voiceId = prefs.getString(_kVoiceId) ?? AppConfig.defaultVoiceId;
    _streamingQuality = StreamingQuality.fromName(
      prefs.getString(_kStreamingQuality),
    );
    _subtitlesEnabled = prefs.getBool(_kSubtitles) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSubtitlesEnabled(bool v) async {
    if (_subtitlesEnabled == v) return;
    _subtitlesEnabled = v;
    await (await SharedPreferences.getInstance()).setBool(_kSubtitles, v);
    notifyListeners();
  }

  Future<void> setStreamingQuality(StreamingQuality q) async {
    if (_streamingQuality == q) return;
    _streamingQuality = q;
    await (await SharedPreferences.getInstance())
        .setString(_kStreamingQuality, q.name);
    notifyListeners();
  }

  Future<void> setSandbox(bool v) async {
    if (_sandbox == v) return;
    _sandbox = v;
    await (await SharedPreferences.getInstance()).setBool(_kSandbox, v);
    notifyListeners();
  }

  Future<void> setSessionSeconds(int seconds) async {
    final clamped = seconds.clamp(30, 1800);
    if (_sessionSeconds == clamped) return;
    _sessionSeconds = clamped;
    await (await SharedPreferences.getInstance())
        .setInt(_kSessionSeconds, _sessionSeconds);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_language == code) return;
    _language = code;
    await (await SharedPreferences.getInstance())
        .setString(_kAssistantLanguage, code);
    notifyListeners();
  }

  Future<void> setUiLanguage(String code) async {
    if (_uiLanguage == code) return;
    _uiLanguage = code;
    await (await SharedPreferences.getInstance())
        .setString(_kUiLanguage, code);
    notifyListeners();
  }

  Future<void> setAvatarId(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty || _avatarId == trimmed) return;
    _avatarId = trimmed;
    await (await SharedPreferences.getInstance())
        .setString(_kAvatarId, trimmed);
    notifyListeners();
  }

  Future<void> setVoiceId(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty || _voiceId == trimmed) return;
    _voiceId = trimmed;
    await (await SharedPreferences.getInstance())
        .setString(_kVoiceId, trimmed);
    notifyListeners();
  }
}
