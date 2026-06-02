import '../config/app_config.dart';

/// Lightweight catalog of avatars/voices/languages exposed in the UI.
///
/// HeyGen does not expose a public list endpoint in the LiveAvatar API used
/// here, so we curate a small set of known good options and allow the user
/// to plug in a custom ID for anything not on the list.

class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.name,
    this.description,
    this.isSandbox = false,
  });

  final String id;
  final String name;
  final String? description;
  final bool isSandbox;
}

class VoicePreset {
  const VoicePreset({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
}

class LanguagePreset {
  const LanguagePreset({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  final String code;
  final String nativeName;
  final String englishName;
}

class Presets {
  Presets._();

  static const List<AvatarPreset> avatars = [
    AvatarPreset(
      id: AppConfig.defaultAvatarId,
      name: 'Default Assistant',
      description: 'Production avatar configured for the client',
    ),
    AvatarPreset(
      id: AppConfig.sandboxAvatarId,
      name: 'HeyGen Sandbox',
      description: 'Free test avatar (capped at 58 sec)',
      isSandbox: true,
    ),
  ];

  static const List<VoicePreset> voices = [
    VoicePreset(
      id: AppConfig.defaultVoiceId,
      name: 'Default Voice',
      description: 'Original assistant voice',
    ),
  ];

  static const List<LanguagePreset> languages = [
    LanguagePreset(code: 'en', nativeName: 'English', englishName: 'English'),
    LanguagePreset(code: 'ru', nativeName: 'Русский', englishName: 'Russian'),
    LanguagePreset(
        code: 'es', nativeName: 'Español', englishName: 'Spanish'),
    LanguagePreset(code: 'fr', nativeName: 'Français', englishName: 'French'),
    LanguagePreset(code: 'de', nativeName: 'Deutsch', englishName: 'German'),
    LanguagePreset(
        code: 'it', nativeName: 'Italiano', englishName: 'Italian'),
    LanguagePreset(
        code: 'pt', nativeName: 'Português', englishName: 'Portuguese'),
    LanguagePreset(code: 'zh', nativeName: '中文', englishName: 'Chinese'),
    LanguagePreset(code: 'ja', nativeName: '日本語', englishName: 'Japanese'),
    LanguagePreset(code: 'ko', nativeName: '한국어', englishName: 'Korean'),
    LanguagePreset(code: 'uk', nativeName: 'Українська',
        englishName: 'Ukrainian'),
    LanguagePreset(code: 'tr', nativeName: 'Türkçe', englishName: 'Turkish'),
  ];

  static AvatarPreset? findAvatar(String id) {
    for (final a in avatars) {
      if (a.id == id) return a;
    }
    return null;
  }

  static VoicePreset? findVoice(String id) {
    for (final v in voices) {
      if (v.id == id) return v;
    }
    return null;
  }

  static LanguagePreset findLanguage(String code) {
    for (final l in languages) {
      if (l.code == code) return l;
    }
    return languages.first;
  }
}
