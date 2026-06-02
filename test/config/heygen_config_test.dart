import 'package:assistant_webstreaming/config/app_config.dart';
import 'package:assistant_webstreaming/config/heygen_config.dart';
import 'package:assistant_webstreaming/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mirrors settings into a config snapshot', () async {
    final s = SettingsService();
    await s.load();
    await s.setLanguage('ru');
    await s.setSandbox(true);
    await s.setStreamingQuality(StreamingQuality.auto);

    final config = HeyGenConfig.fromSettings(s);

    expect(config.apiKey, AppConfig.heyGenApiKey);
    expect(config.contextId, AppConfig.defaultContextId);
    expect(config.language, 'ru');
    expect(config.sandbox, isTrue);
    expect(config.highQuality, isFalse);
    expect(config.avatarId, s.avatarId);
    expect(config.voiceId, s.voiceId);
  });

  test('high quality maps from streaming quality enum', () async {
    final s = SettingsService();
    await s.load();
    await s.setStreamingQuality(StreamingQuality.high);
    expect(HeyGenConfig.fromSettings(s).highQuality, isTrue);

    await s.setStreamingQuality(StreamingQuality.auto);
    expect(HeyGenConfig.fromSettings(s).highQuality, isFalse);
  });
}
