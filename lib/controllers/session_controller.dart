import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../config/heygen_config.dart';
import '../services/disposable.dart';
import '../services/heygen_service.dart';
import '../services/mic_recorder_service.dart';
import '../services/settings_service.dart';
import '../services/transcription_service.dart';
import '../utils/logger.dart';

/// Top-level lifecycle of an avatar session.
enum SessionPhase { idle, connecting, live, ended }

/// User-driven sub-state when [SessionPhase] is `live`.
enum InteractionState { idle, recording, sending, avatarSpeaking }

/// Reason for being in [SessionPhase.idle] — drives the connecting label
/// in the UI without leaking translations into the controller.
enum IdleReason { initial, failed, sessionEnded }

/// Owns the avatar session state machine — connection lifecycle, recording
/// flow, timer, error surface. The UI listens via [ChangeNotifier] and
/// reacts; it must not own any of these resources directly.
class SessionController extends ChangeNotifier implements AsyncDisposable {
  SessionController({
    required this.settings,
    required TranscriptionService transcription,
    MicRecorderService? mic,
    HeyGenService Function(HeyGenConfig)? serviceFactory,
  })  : _transcription = transcription,
        _mic = mic ?? MicRecorderService(),
        _serviceFactory = serviceFactory ?? HeyGenService.new;

  final SettingsService settings;
  final TranscriptionService _transcription;
  final MicRecorderService _mic;
  final HeyGenService Function(HeyGenConfig) _serviceFactory;

  static const _log = Log('Session');
  static const _tickInterval = Duration(milliseconds: 250);

  HeyGenService? _heyGen;
  Timer? _ticker;

  /// Stable, controller-owned caption stream. We forward updates from the
  /// current [HeyGenService] so the UI can bind once and survive
  /// session restarts (new service instance → same notifier).
  final ValueNotifier<String> _subtitle = ValueNotifier<String>('');

  SessionPhase _phase = SessionPhase.idle;
  InteractionState _interaction = InteractionState.idle;
  IdleReason _idleReason = IdleReason.initial;
  String? _lastError;
  Duration _remaining = Duration.zero;
  Duration _total = Duration.zero;

  // ─── exposed read-only state ───────────────────────────────────────────────

  SessionPhase get phase => _phase;
  InteractionState get interaction => _interaction;
  IdleReason get idleReason => _idleReason;
  String? get lastError => _lastError;
  Duration get remaining => _remaining;
  Duration get total => _total;
  lk.RemoteVideoTrack? get remoteVideoTrack => _heyGen?.remoteVideoTrack;
  ValueListenable<double> get micLevel => _mic.level;
  ValueListenable<String> get subtitle => _subtitle;

  // ─── lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_phase == SessionPhase.connecting) return;
    _phase = SessionPhase.connecting;
    notifyListeners();

    final previous = _heyGen;
    if (previous != null) {
      previous.removeListener(_onServiceChanged);
      previous.subtitle.removeListener(_onSubtitleChanged);
      previous.avatarTalking.removeListener(_onAvatarTalkingChanged);
      try {
        await previous.close();
      } catch (e) {
        _log.w('previous session close failed', error: e);
      }
      previous.dispose();
    }
    _subtitle.value = '';

    final svc = _serviceFactory(HeyGenConfig.fromSettings(settings));
    svc.addListener(_onServiceChanged);
    svc.subtitle.addListener(_onSubtitleChanged);
    svc.avatarTalking.addListener(_onAvatarTalkingChanged);
    _heyGen = svc;

    final ok = await svc.connect();
    if (!ok) {
      _phase = SessionPhase.idle;
      _idleReason = IdleReason.failed;
      _lastError = _short(svc.errorMessage);
      notifyListeners();
      return;
    }

    _total = Duration(seconds: settings.sessionSeconds);
    _remaining = _total;
    _phase = SessionPhase.live;
    notifyListeners();
    _startTicker();
  }

  Future<void> end() async {
    _ticker?.cancel();
    _ticker = null;

    if (_interaction == InteractionState.recording) {
      await _mic.cancel();
    }
    try {
      await _heyGen?.stop();
    } catch (e) {
      _log.w('end stop failed', error: e);
    }

    _phase = SessionPhase.ended;
    _interaction = InteractionState.idle;
    _idleReason = IdleReason.sessionEnded;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) {
      final next = _remaining - _tickInterval;
      if (next.inMilliseconds <= 0) {
        end();
        return;
      }
      _remaining = next;
      notifyListeners();
    });
  }

  void _onServiceChanged() => notifyListeners();

  void _onSubtitleChanged() {
    final svc = _heyGen;
    if (svc == null) return;
    _subtitle.value = svc.subtitle.value;
  }

  /// When HeyGen tells us the avatar finished its response, drop the
  /// interaction back to idle so the mic slides from the corner back to
  /// centre — but only if we were in the user-driven avatarSpeaking
  /// state (the auto-greeting plays with interaction == idle and should
  /// stay that way).
  void _onAvatarTalkingChanged() {
    final svc = _heyGen;
    if (svc == null) return;
    if (!svc.avatarTalking.value &&
        _interaction == InteractionState.avatarSpeaking) {
      _interaction = InteractionState.idle;
      notifyListeners();
    }
  }

  // ─── mic interactions ──────────────────────────────────────────────────────

  /// Result codes for the press-start so the UI can show a snack on denial
  /// without having to inspect controller state.
  Future<MicStartResult> micPressStart() async {
    if (_interaction != InteractionState.idle) return MicStartResult.ignored;
    final ok = await _mic.start();
    if (!ok) return MicStartResult.permissionDenied;
    _interaction = InteractionState.recording;
    notifyListeners();
    return MicStartResult.started;
  }

  Future<void> micPressEnd() async {
    if (_interaction != InteractionState.recording) return;
    _interaction = InteractionState.sending;
    notifyListeners();

    final path = await _mic.stop();
    if (path == null) {
      _resetInteraction();
      return;
    }

    final text = await _transcription.transcribe(path);
    if (text == null || text.trim().isEmpty) {
      _resetInteraction();
      return;
    }

    await _heyGen?.sendToBrain(text);
    _interaction = InteractionState.avatarSpeaking;
    notifyListeners();
  }

  Future<void> stopAvatar() async {
    if (_interaction != InteractionState.avatarSpeaking) return;
    await _heyGen?.interruptResponse();
    _resetInteraction();
  }

  /// Send a typed question. Mirrors the post-transcription half of
  /// [micPressEnd]. If the avatar is currently speaking, its response is
  /// interrupted before the new question is sent.
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (_interaction == InteractionState.sending ||
        _interaction == InteractionState.recording) {
      return;
    }

    if (_interaction == InteractionState.avatarSpeaking) {
      await _heyGen?.interruptResponse();
    }

    _interaction = InteractionState.sending;
    notifyListeners();

    await _heyGen?.sendToBrain(trimmed);
    _interaction = InteractionState.avatarSpeaking;
    notifyListeners();
  }

  void _resetInteraction() {
    _interaction = InteractionState.idle;
    notifyListeners();
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  static String? _short(String? s) {
    if (s == null) return null;
    final clean = s.replaceAll('\n', ' ').trim();
    return clean.length > 70 ? '${clean.substring(0, 70)}...' : clean;
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    _ticker = null;
    final svc = _heyGen;
    if (svc != null) {
      svc.removeListener(_onServiceChanged);
      svc.subtitle.removeListener(_onSubtitleChanged);
      svc.avatarTalking.removeListener(_onAvatarTalkingChanged);
      try {
        await svc.close();
      } catch (_) {}
      svc.dispose();
      _heyGen = null;
    }
    _subtitle.value = '';
    await _mic.close();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _heyGen?.removeListener(_onServiceChanged);
    _heyGen?.subtitle.removeListener(_onSubtitleChanged);
    _heyGen?.avatarTalking.removeListener(_onAvatarTalkingChanged);
    _heyGen?.dispose();
    _subtitle.dispose();
    // Mic close is async-only; controller's caller should `await close()`
    // before dispose for a clean teardown.
    super.dispose();
  }
}

enum MicStartResult { started, permissionDenied, ignored }
