import 'dart:io' show Platform, exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/session_controller.dart';
import 'l10n/app_localization.dart';
import 'l10n/app_strings.dart';
import 'screens/session_screen.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

/// True on platforms that host their own OS-level window (and therefore
/// benefit from window_manager and our custom title-bar controls).
bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  if (_isDesktop) {
    await _initDesktopWindow();
  }

  final settings = SettingsService();
  await settings.load();

  runApp(AssistantWebstreamingApp(settings: settings));
}

Future<void> _initDesktopWindow() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1600, 950),
    minimumSize: Size(900, 600),
    title: 'Ассистент Вебстриминг',
    backgroundColor: AppTheme.bgDeep,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });
}

class AssistantWebstreamingApp extends StatefulWidget {
  const AssistantWebstreamingApp({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<AssistantWebstreamingApp> createState() =>
      _AssistantWebstreamingAppState();
}

class _AssistantWebstreamingAppState extends State<AssistantWebstreamingApp>
    with WindowListener {
  bool _splashDone = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
    }
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void onWindowClose() async {
    if (!_isDesktop) return;
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) {
      await _hardExit();
      return;
    }
    final shouldExit = await _showExitDialog(ctx);
    if (shouldExit == true) await _hardExit();
  }

  /// Terminate immediately. A normal `windowManager.destroy()` is slow here:
  /// the Flutter engine shutdown tears down the native WebRTC/LiveKit stack on
  /// the platform thread, which can take seconds. We skip it — best-effort
  /// release the HeyGen session (bounded so it can never hang the exit), then
  /// exit the process outright. The OS reclaims everything else instantly.
  Future<void> _hardExit() async {
    try {
      await SessionController.active
          ?.shutdownForExit()
          .timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
    exit(0);
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    final t = AppLocalization.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        title: Text(
          t.exitTitle,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          t.exitMessage,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: Text(t.exitCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.exitConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = UiLocale.forCode(widget.settings.uiLanguage);
    final strings = uiLocale.factory();
    // Material's GlobalWidgetsLocalizations.delegate handles
    // TextDirection automatically from the selected Locale — no need to
    // wrap the subtree in a manual Directionality.
    return AppLocalization(
      locale: uiLocale,
      strings: strings,
      child: MaterialApp(
        title: strings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: _navigatorKey,
        locale: uiLocale.locale,
        supportedLocales:
            UiLocale.values.map((l) => l.locale).toList(growable: false),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: _splashDone
              ? SessionScreen(
                  key: const ValueKey('session'),
                  settings: widget.settings,
                )
              : SplashScreen(
                  key: const ValueKey('splash'),
                  onDone: () => setState(() => _splashDone = true),
                ),
        ),
      ),
    );
  }
}
