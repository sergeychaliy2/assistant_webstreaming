import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../config/app_config.dart';
import '../controllers/session_controller.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../services/transcription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/atoms/glass_circle.dart';
import '../widgets/chat_panel.dart';
import '../widgets/connecting_view.dart';
import '../widgets/glass_container.dart';
import '../widgets/mic_button.dart';
import '../widgets/sending_indicator.dart';
import '../widgets/subtitle_strip.dart';
import '../widgets/timer_bar.dart';
import '../widgets/window_controls.dart';
import 'settings_screen.dart';

/// Thin presentation layer. Owns no avatar state — only the
/// [SessionController] does. Re-renders on controller notifications.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionController _controller;
  bool _chatOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = SessionController(
      settings: widget.settings,
      transcription: WhisperTranscriptionService(apiKey: AppConfig.openAiApiKey),
    );
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    // Fire-and-forget; UI is going away regardless. State.dispose must be sync.
    _controller.close();
    _controller.dispose();
    super.dispose();
  }

  // ─── intents ──────────────────────────────────────────────────────────────

  Future<void> _onMicPressStart() async {
    final result = await _controller.micPressStart();
    if (!mounted) return;
    if (result == MicStartResult.permissionDenied) {
      _showSnack(AppLocalization.of(context).microphoneDenied);
    }
  }

  void _openChat() {
    if (_chatOpen) return;
    setState(() => _chatOpen = true);
  }

  void _closeChat() {
    if (!_chatOpen) return;
    FocusScope.of(context).unfocus();
    setState(() => _chatOpen = false);
  }

  Future<void> _onChatSend(String text) async {
    _closeChat();
    await _controller.sendText(text);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(settings: widget.settings),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgMid,
        content: Text(msg, style: const TextStyle(color: AppTheme.textPrimary)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _resolveConnectingLabel(AppStrings t) {
    if (_controller.phase == SessionPhase.connecting) {
      return t.connectingToHost;
    }
    switch (_controller.idleReason) {
      case IdleReason.initial:
        return t.tapToStart;
      case IdleReason.failed:
        return t.connectionFailed(_controller.lastError);
      case IdleReason.sessionEnded:
        return t.sessionEndedTapToStart;
    }
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    final phase = _controller.phase;
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      // Avoid resizing the avatar video when the soft keyboard opens —
      // the ChatPanel handles its own bottom inset.
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          if (phase == SessionPhase.live)
            _AvatarVideo(track: _controller.remoteVideoTrack),
          if (phase != SessionPhase.live) _buildConnectingOverlay(t),
          if (phase == SessionPhase.live) _buildLiveHud(t),
          if (phase == SessionPhase.live) _buildSubtitleLayer(),
          _buildTopBar(t),
          if (phase == SessionPhase.live) _buildChatLayer(t),
        ],
      ),
    );
  }

  Widget _buildSubtitleLayer() {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        if (!widget.settings.subtitlesEnabled) {
          return const SizedBox.shrink();
        }
        // Mic position dictates caption placement:
        //  • avatarSpeaking → mic is docked in the bottom-right corner,
        //    so the caption can sit near the bottom edge between corners.
        //  • otherwise (idle/recording/sending — e.g. the auto-greeting
        //    before any user input) → mic is big and centered, so the
        //    caption goes ABOVE it.
        final speaking =
            _controller.interaction == InteractionState.avatarSpeaking;
        return AnimatedPositioned(
          duration: AppTheme.micMoveDuration,
          curve: AppTheme.micMoveCurve,
          // Horizontal insets clear the bottom-corner controls (chat
          // trigger on the start side, mic when docked on the end side).
          left: 110,
          right: 110,
          bottom: speaking ? 28 : 220,
          child: ValueListenableBuilder<String>(
            valueListenable: _controller.subtitle,
            builder: (context, text, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: text.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('cc-empty'))
                    : SubtitleStrip(
                        key: const ValueKey('cc-visible'),
                        text: text,
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChatLayer(AppStrings t) {
    return Stack(
      children: [
        // Backdrop: only present while chat is open. Catches outside taps
        // and dismisses the panel without dimming the avatar.
        if (_chatOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeChat,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _chatOpen
                ? ChatPanel(
                    key: const ValueKey('chat-panel'),
                    busy: _controller.interaction == InteractionState.sending,
                    placeholder: t.typeYourQuestion,
                    sendTooltip: t.sendQuestion,
                    closeTooltip: t.chatCloseTooltip,
                    onSend: _onChatSend,
                    onClose: _closeChat,
                  )
                : const SizedBox.shrink(key: ValueKey('chat-empty')),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingOverlay(AppStrings t) {
    final showStart = _controller.phase != SessionPhase.connecting;
    return SafeArea(
      child: ConnectingView(
        label: _resolveConnectingLabel(t),
        showPlayButton: showStart,
        onStart: _controller.start,
      ),
    );
  }

  Widget _buildTopBar(AppStrings t) {
    final showWindowControls =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final hudTopOffset = showWindowControls ? 58.0 : 4.0;

    return SafeArea(
      child: Stack(
        children: [
          if (showWindowControls)
            Positioned(
              top: 10,
              right: 12,
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: const WindowControls(),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, hudTopOffset, 14, 0),
            child: Row(
              children: [
                const Spacer(),
                if (_controller.phase == SessionPhase.live) ...[
                  TimerBar(
                    remaining: _controller.remaining,
                    total: _controller.total,
                    onStop: _controller.end,
                  ),
                  const SizedBox(width: 10),
                ],
                GlassContainer(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    tooltip: t.settingsTooltip,
                    onPressed: _openSettings,
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHud(AppStrings t) {
    return SafeArea(
      child: Stack(
        children: [
          if (_controller.interaction == InteractionState.sending)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: SendingIndicator(label: t.sendingToAssistant),
              ),
            ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _chatOpen ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: _chatOpen,
              child: _AnimatedMicSlot(
                interaction: _controller.interaction,
                level: _controller.micLevel,
                onPressStart: _onMicPressStart,
                onPressEnd: _controller.micPressEnd,
                onTapStop: _controller.stopAvatar,
              ),
            ),
          ),
          PositionedDirectional(
            start: 22,
            bottom: 22,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _chatOpen ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _chatOpen,
                child: _ChatTriggerButton(
                  tooltip: t.chatTooltip,
                  onTap: _openChat,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── private widgets ────────────────────────────────────────────────────────

class _ChatTriggerButton extends StatelessWidget {
  const _ChatTriggerButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  static const double _size = 58;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const GlassCircle(
          size: _size,
          fillOpacity: 0.10,
          strokeOpacity: 0.38,
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppTheme.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _AvatarVideo extends StatelessWidget {
  const _AvatarVideo({required this.track});
  final lk.RemoteVideoTrack? track;

  @override
  Widget build(BuildContext context) {
    if (track == null) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.04, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      // Fill the window edge-to-edge. `cover` crops the 16:9 source on
      // the long axis instead of letterboxing on aspect-mismatched
      // monitors, so no dark side bars are visible.
      child: SizedBox.expand(
        key: ValueKey(track!.sid),
        child: lk.VideoTrackRenderer(
          track!,
          fit: lk.VideoViewFit.cover,
        ),
      ),
    );
  }
}

class _AnimatedMicSlot extends StatelessWidget {
  const _AnimatedMicSlot({
    required this.interaction,
    required this.level,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onTapStop,
  });

  final InteractionState interaction;
  final ValueListenable<double> level;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onTapStop;

  static const _centerPadBottom = 56.0;
  static const _cornerPadBottom = 22.0;
  static const _cornerPadEnd = 22.0;

  bool get _isInCorner => interaction == InteractionState.avatarSpeaking;

  MicButtonMode get _mode {
    switch (interaction) {
      case InteractionState.recording:
        return MicButtonMode.recording;
      case InteractionState.avatarSpeaking:
        return MicButtonMode.stop;
      case InteractionState.idle:
      case InteractionState.sending:
        return MicButtonMode.idle;
    }
  }

  bool get _disabled => interaction == InteractionState.sending;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final size = _isInCorner
            ? AppTheme.micButtonSmallSize
            : AppTheme.micButtonBigSize;
        final startInset = _isInCorner
            ? w - size - _cornerPadEnd
            : (w - size) / 2;
        final bottom = _isInCorner ? _cornerPadBottom : _centerPadBottom;

        return Stack(
          children: [
            AnimatedPositionedDirectional(
              duration: AppTheme.micMoveDuration,
              curve: AppTheme.micMoveCurve,
              start: startInset,
              bottom: bottom,
              width: size,
              height: size,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _disabled ? 0.45 : 1.0,
                child: MicButton(
                  mode: _mode,
                  level: level,
                  size: size,
                  enabled: !_disabled,
                  onPressStart: onPressStart,
                  onPressEnd: onPressEnd,
                  onTapStop: onTapStop,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
