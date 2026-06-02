// Шаблон конфигурации. Скопируйте этот файл в `app_config.dart`
// (рядом, в той же папке) и подставьте свои ключи и ID.
//
//   cp lib/config/app_config.example.dart lib/config/app_config.dart   (bash)
//   Copy-Item lib/config/app_config.example.dart lib/config/app_config.dart   (PowerShell)
//
// `app_config.dart` намеренно в .gitignore — секреты не должны попадать в репозиторий.
// Для боевого окружения лучше проксировать запросы к OpenAI/HeyGen через свой бэкенд,
// чтобы ключи не лежали в клиентском приложении.
class AppConfig {
  // ── Секреты ──────────────────────────────────────────────────────────────
  static const String heyGenApiKey = 'YOUR_HEYGEN_API_KEY';
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';

  // ── Идентификаторы аватара/голоса (из вашего аккаунта HeyGen) ─────────────
  static const String defaultAvatarId = 'YOUR_DEFAULT_AVATAR_ID';
  static const String sandboxAvatarId = 'YOUR_SANDBOX_AVATAR_ID';
  static const String defaultVoiceId = 'YOUR_DEFAULT_VOICE_ID';
  static const String defaultContextId = 'YOUR_DEFAULT_CONTEXT_ID';

  // ── Эндпоинты и тайминги (не секретны) ────────────────────────────────────
  static const String heyGenApiBase = 'https://api.liveavatar.com';
  static const String whisperUrl =
      'https://api.openai.com/v1/audio/transcriptions';

  static const int defaultSessionSeconds = 300;
  static const int sandboxSessionSeconds = 58;

  static const int keepAliveIntervalSec = 20;
  static const String agentControlTopic = 'agent-control';
}
