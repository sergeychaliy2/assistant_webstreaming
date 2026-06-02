import 'package:assistant_webstreaming/config/app_config.dart';
import 'package:assistant_webstreaming/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService.load defaults', () {
    test('falls back to expected defaults when nothing persisted', () async {
      final s = SettingsService();
      await s.load();

      expect(s.loaded, isTrue);
      expect(s.sandbox, isFalse);
      expect(s.userSessionSeconds, AppConfig.defaultSessionSeconds);
      expect(s.sessionSeconds, AppConfig.defaultSessionSeconds);
      expect(s.language, 'en');
      expect(s.uiLanguage, 'en');
      expect(s.avatarId, AppConfig.defaultAvatarId);
      expect(s.voiceId, AppConfig.defaultVoiceId);
      expect(s.streamingQuality, StreamingQuality.high);
    });
  });

  group('SettingsService writers', () {
    test('sandbox toggle is persisted and overrides session seconds', () async {
      final s = SettingsService();
      await s.load();

      await s.setSessionSeconds(420);
      expect(s.userSessionSeconds, 420);
      expect(s.sessionSeconds, 420);

      await s.setSandbox(true);
      expect(s.sessionSeconds, AppConfig.sandboxSessionSeconds);
      expect(s.userSessionSeconds, 420); // still kept

      // reload to verify persistence
      final reloaded = SettingsService();
      await reloaded.load();
      expect(reloaded.sandbox, isTrue);
      expect(reloaded.userSessionSeconds, 420);
    });

    test('setLanguage and setUiLanguage are independent', () async {
      final s = SettingsService();
      await s.load();

      await s.setLanguage('ru');
      await s.setUiLanguage('ar');
      expect(s.language, 'ru');
      expect(s.uiLanguage, 'ar');
    });

    test('streaming quality round-trips through prefs', () async {
      final s = SettingsService();
      await s.load();

      await s.setStreamingQuality(StreamingQuality.auto);
      final reloaded = SettingsService();
      await reloaded.load();
      expect(reloaded.streamingQuality, StreamingQuality.auto);
    });

    test('empty avatar/voice ID writes are ignored', () async {
      final s = SettingsService();
      await s.load();
      final original = s.avatarId;

      await s.setAvatarId('   ');
      expect(s.avatarId, original);

      await s.setAvatarId('custom-123');
      expect(s.avatarId, 'custom-123');
    });
  });
}
