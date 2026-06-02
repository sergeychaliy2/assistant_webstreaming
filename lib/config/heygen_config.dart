import '../services/settings_service.dart';
import 'app_config.dart';

/// Immutable bundle of every value needed to spin up a HeyGen LiveAvatar
/// session. Built from [SettingsService] at session-start time so the
/// service layer has no dependency on settings or app-wide constants.
class HeyGenConfig {
  const HeyGenConfig({
    required this.apiKey,
    required this.avatarId,
    required this.voiceId,
    required this.contextId,
    required this.sandbox,
    required this.language,
    required this.highQuality,
  });

  factory HeyGenConfig.fromSettings(SettingsService settings) {
    return HeyGenConfig(
      apiKey: AppConfig.heyGenApiKey,
      avatarId: settings.avatarId,
      voiceId: settings.voiceId,
      contextId: AppConfig.defaultContextId,
      sandbox: settings.sandbox,
      language: settings.language,
      highQuality: settings.streamingQuality == StreamingQuality.high,
    );
  }

  final String apiKey;
  final String avatarId;
  final String voiceId;
  final String contextId;
  final bool sandbox;
  final String language;

  /// When true: LiveKit adaptive stream is disabled and the top simulcast
  /// layer is pinned.
  final bool highQuality;
}
