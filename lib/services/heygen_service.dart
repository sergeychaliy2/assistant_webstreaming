import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart' as lk;

import '../config/app_config.dart';
import '../config/heygen_config.dart';
import '../utils/logger.dart';
import 'disposable.dart';

enum HeyGenStatus {
  idle,
  connecting,
  ready,
  failed,
  closed,
}

/// Drives a HeyGen LiveAvatar session: REST handshake (token + start),
/// LiveKit room subscription, data-channel control. Knows nothing about
/// STT, recording or UI.
class HeyGenService extends ChangeNotifier implements AsyncDisposable {
  HeyGenService(this.config);

  final HeyGenConfig config;

  static const _log = Log('HeyGen');

  HeyGenStatus _status = HeyGenStatus.idle;
  HeyGenStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _sessionId;
  String? _sessionToken;

  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  lk.RemoteVideoTrack? _remoteVideoTrack;
  lk.RemoteVideoTrack? get remoteVideoTrack => _remoteVideoTrack;


  /// All currently subscribed remote audio tracks. We hold references so we
  /// can explicitly stop+dispose them on teardown — otherwise on Windows
  /// the flutter_webrtc renderer can keep playing audio from a previous
  /// session while a new room connects, producing two overlapping voices.
  final List<lk.RemoteAudioTrack> _audioTracks = [];

  /// Live caption for the avatar's current spoken response. Updated as
  /// HeyGen streams partials over the data channel; empty when no
  /// caption is active. The UI may treat empty as "hide".
  final ValueNotifier<String> _subtitle = ValueNotifier<String>('');
  ValueListenable<String> get subtitle => _subtitle;
  String _subtitleAccumulator = '';

  /// True while the avatar is actively producing a response. Goes false
  /// when we receive an explicit stop event or the stale timer fires.
  /// Lets the controller move the mic back to center when the avatar
  /// genuinely finishes speaking, even with subtitles disabled.
  final ValueNotifier<bool> _avatarTalking = ValueNotifier<bool>(false);
  ValueListenable<bool> get avatarTalking => _avatarTalking;

  /// Auto-fade timer for the caption. Restarted on every text update so
  /// the caption stays visible while the avatar is actively talking, then
  /// clears itself after a brief grace window of silence — even if we
  /// never receive an explicit `avatar_stop_talking` event.
  Timer? _subtitleClearTimer;

  /// Tracks the most recent moment we believed the avatar was producing
  /// audio — either because [Participant.audioLevel] crossed
  /// [_audioLoudThreshold] OR because a text partial arrived (a fallback
  /// for HeyGen LiveKit deployments that don't ship per-speaker levels,
  /// where audioLevel reads 0). [_pollAudio] fires
  /// [_onAvatarFinished] once this stale window exceeds
  /// [_silenceFinishAfter].
  Timer? _audioPollTimer;
  DateTime? _lastLoudAt;
  static const _audioPollInterval = Duration(milliseconds: 250);
  static const _silenceFinishAfter = Duration(seconds: 2);

  /// Local audio-frame visualizer attached to the avatar's audio track.
  /// HeyGen's LiveKit room doesn't publish per-speaker audio levels, so
  /// [Participant.audioLevel] sits at 0 forever. The visualizer reads
  /// the actual decoded samples client-side and emits band magnitudes —
  /// any bar above [_visualizerThreshold] means the avatar is producing
  /// sound right now.
  lk.AudioVisualizer? _visualizer;
  lk.EventsListener<lk.AudioVisualizerEvent>? _visualizerListener;
  static const _visualizerThreshold = 0.05;

  /// Grace once we receive an explicit `avatar_stop_talking` event —
  /// gives the user a beat to read the trailing words before the
  /// caption clears and the mic slides back to centre.
  static const _subtitleStopGrace = Duration(milliseconds: 1500);

  /// After we interrupt the avatar, HeyGen may still deliver a few
  /// buffered partials for the response that was being torn down. We
  /// discard those until the next `avatar_start_talking` so the
  /// just-cleared caption doesn't pop back up.
  bool _suppressSubtitleUntilNextStart = false;

  Timer? _keepAliveTimer;
  bool _disposed = false;
  bool _teardownInFlight = false;

  String get _effectiveAvatarId =>
      config.sandbox ? AppConfig.sandboxAvatarId : config.avatarId;

  void _setStatus(HeyGenStatus s, {String? error}) {
    if (_disposed) return;
    _status = s;
    _errorMessage = error;
    notifyListeners();
  }

  // ─── session lifecycle ─────────────────────────────────────────────────────

  Future<bool> connect() async {
    if (_status == HeyGenStatus.connecting || _status == HeyGenStatus.ready) {
      return _status == HeyGenStatus.ready;
    }
    _setStatus(HeyGenStatus.connecting);
    try {
      final tokenRes = await _requestSessionToken();
      _sessionId = tokenRes['session_id'] as String;
      _sessionToken = tokenRes['session_token'] as String;

      final startRes = await _startSession(_sessionToken!);
      final livekitUrl = startRes['livekit_url'] as String;
      final livekitToken = startRes['livekit_client_token'] as String;

      await _connectLiveKit(livekitUrl, livekitToken);

      _startKeepAlive();
      _setStatus(HeyGenStatus.ready);
      return true;
    } catch (e, st) {
      _log.e('connect failed', error: e, stack: st);
      _setStatus(HeyGenStatus.failed, error: e.toString());
      await _teardown();
      return false;
    }
  }

  Future<Map<String, dynamic>> _requestSessionToken() async {
    final body = jsonEncode({
      'mode': 'FULL',
      'is_sandbox': config.sandbox,
      'avatar_id': _effectiveAvatarId,
      // Reference the stored Voice Agent (its context/knowledge base + voice +
      // LLM config) instead of the deprecated inline `avatar_persona`. The
      // legacy path only applied persona/voice and did NOT load the agent's
      // knowledge base, so live sessions answered "I don't have that
      // information" while the dashboard playground (which uses voice_agent)
      // worked. The two fields are mutually exclusive.
      'voice_agent': {
        'id': AppConfig.voiceAgentId,
      },
      'interactivity_type': 'CONVERSATIONAL',
    });
    final res = await http.post(
      Uri.parse('${AppConfig.heyGenApiBase}/v1/sessions/token'),
      headers: {
        'X-API-KEY': config.apiKey,
        'Content-Type': 'application/json',
      },
      body: body,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HeyGenApiException('token', res.statusCode, res.body);
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null || data['session_token'] == null) {
      throw HeyGenApiException('token-shape', res.statusCode, res.body);
    }
    return data;
  }

  Future<Map<String, dynamic>> _startSession(String sessionToken) async {
    final res = await http.post(
      Uri.parse('${AppConfig.heyGenApiBase}/v1/sessions/start'),
      headers: {
        'Authorization': 'Bearer $sessionToken',
        'Content-Type': 'application/json',
      },
      body: '{}',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HeyGenApiException('start', res.statusCode, res.body);
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null || data['livekit_url'] == null) {
      throw HeyGenApiException('start-shape', res.statusCode, res.body);
    }
    return data;
  }

  Future<void> _connectLiveKit(String url, String token) async {
    final room = lk.Room(
      roomOptions: lk.RoomOptions(
        adaptiveStream: !config.highQuality,
        dynacast: !config.highQuality,
      ),
    );
    final listener = room.createListener();

    listener.on<lk.TrackSubscribedEvent>((event) async {
      final track = event.track;
      if (track is lk.RemoteVideoTrack) {
        _remoteVideoTrack = track;
        notifyListeners();
        await _maybePinHighQuality(event.publication);
        return;
      }
      if (track is lk.RemoteAudioTrack) {
        _log.d('audio track subscribed sid=${track.sid}');
        _audioTracks.add(track);
        // Attach a fresh AudioVisualizer to the newest avatar audio
        // track so the silence detector sees real samples, not the
        // server-side audioLevel HeyGen never publishes.
        unawaited(_attachVisualizer(track));
        // SDK already auto-starts the audio renderer on subscribe; calling
        // start() ourselves spawns a duplicate renderer on Windows.
      }
    });
    listener.on<lk.TrackUnsubscribedEvent>((event) {
      final track = event.track;
      if (track == _remoteVideoTrack) {
        _remoteVideoTrack = null;
        notifyListeners();
      }
      if (track is lk.RemoteAudioTrack) {
        _audioTracks.remove(track);
      }
    });
    listener.on<lk.AudioPlaybackStatusChanged>((event) {
      _log.d('audio playback isPlaying=${event.isPlaying}');
    });
    listener.on<lk.DataReceivedEvent>(_handleData);
    listener.on<lk.RoomDisconnectedEvent>((_) {
      _setStatus(HeyGenStatus.closed);
    });

    _room = room;
    _listener = listener;

    await room.connect(url, token);
    await _ensureAudioOutput();
    try {
      await room.startAudio();
    } catch (e) {
      _log.w('room.startAudio() failed', error: e);
    }
    _startAudioPolling();
  }

  Future<void> _maybePinHighQuality(lk.TrackPublication pub) async {
    if (!config.highQuality) return;
    if (pub is! lk.RemoteTrackPublication) return;
    try {
      await pub.setVideoQuality(lk.VideoQuality.HIGH);
      _log.d('VideoQuality.HIGH requested for ${pub.sid}');
    } catch (e) {
      _log.w('setVideoQuality failed', error: e);
    }
  }

  Future<void> _ensureAudioOutput() async {
    try {
      final outputs = await lk.Hardware.instance.audioOutputs();
      _log.d('audio outputs: ${outputs.map((d) => d.label).join(", ")}');
      if (outputs.isNotEmpty) {
        await lk.Hardware.instance.selectAudioOutput(outputs.first);
      }
    } catch (e) {
      _log.w('audio output select failed', error: e);
    }
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(
      const Duration(seconds: AppConfig.keepAliveIntervalSec),
      (_) async {
        final sid = _sessionId;
        if (sid == null) return;
        try {
          await http.post(
            Uri.parse('${AppConfig.heyGenApiBase}/v1/sessions/keep_alive'),
            headers: {
              'X-API-KEY': config.apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'session_id': sid}),
          );
        } catch (e) {
          _log.w('keep_alive failed', error: e);
        }
      },
    );
  }

  // ─── conversation ──────────────────────────────────────────────────────────

  Future<void> sendToBrain(String text) async {
    final sid = _sessionId;
    final lp = _room?.localParticipant;
    if (sid == null || lp == null || text.trim().isEmpty) return;
    final payload = jsonEncode({
      'event_type': 'avatar.speak_response',
      'session_id': sid,
      'text': text,
    });
    _resetSubtitle();
    await _publish(lp, payload, label: 'sendToBrain');
  }

  Future<void> interruptResponse() async {
    final sid = _sessionId;
    final lp = _room?.localParticipant;
    if (sid == null || lp == null) return;
    final payload = jsonEncode({
      'event_type': 'avatar.interrupt',
      'session_id': sid,
    });
    _resetSubtitle();
    // Discard any in-flight partials for the response we just killed.
    _suppressSubtitleUntilNextStart = true;
    // Caller (user-tapped Stop) considers the avatar no longer speaking.
    _avatarTalking.value = false;
    await _publish(lp, payload, label: 'interrupt');
  }

  // ─── subtitle stream ───────────────────────────────────────────────────────

  /// HeyGen sends conversation events over the LiveKit data channel as JSON.
  /// We surface the avatar-spoken text as a live subtitle. The exact event
  /// shape varies by protocol version, so we accept several aliases and fall
  /// back to any text-like field.
  void _handleData(lk.DataReceivedEvent event) {
    String raw;
    try {
      raw = utf8.decode(event.data);
    } catch (_) {
      return;
    }
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) json = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }
    if (json == null) return;

    final type = (json['type'] ?? json['event_type'])?.toString() ?? '';
    final msg = (json['message'] ?? json['text'] ?? json['content'])
        ?.toString();
    // Truncated raw for protocol debugging — the only way to know the
    // exact HeyGen event names is to see them on the wire.
    final preview = raw.length > 220 ? '${raw.substring(0, 220)}…' : raw;
    _log.d('data type=$type len=${raw.length} :: $preview');

    // User-side echoes (their STT etc.) must never reach the agent caption.
    if (type.startsWith('user_') || type.startsWith('user.')) return;

    if (type.contains('avatar_start_talking') ||
        type.contains('avatar.start_talking') ||
        type.contains('agent_start')) {
      _suppressSubtitleUntilNextStart = false;
      _resetSubtitle();
      _markTalking();
      return;
    }
    // Treat any "the avatar/agent finished" signal as a stop — HeyGen
    // protocol uses several names across versions.
    if (type.contains('avatar_stop_talking') ||
        type.contains('avatar.stop_talking') ||
        type.contains('avatar_end_talking') ||
        type.contains('agent_response_end') ||
        type.endsWith('_complete') ||
        type.endsWith('.complete')) {
      if (_suppressSubtitleUntilNextStart) return;
      _scheduleAvatarFinish(_subtitleStopGrace);
      return;
    }
    if (msg == null || msg.isEmpty) return;
    // Drop stale partials that belong to a response we just interrupted.
    if (_suppressSubtitleUntilNextStart) return;

    // Agent-side partials → accumulate ([_appendChunk] handles both
    // delta and snapshot semantics).
    if (type.contains('agent_talking_message') ||
        type.contains('agent.talking_message') ||
        type.contains('agent_response_partial') ||
        type.contains('partial_message') ||
        type.contains('agent_message_partial')) {
      _markTalking();
      _subtitleAccumulator = _appendChunk(_subtitleAccumulator, msg);
      _subtitle.value = _subtitleAccumulator;
      return;
    }
    // Final / full canonical text → snapshot.
    if (type.contains('agent_end_message') ||
        type.contains('agent.end_message') ||
        type == 'agent_response' ||
        type == 'agent_message') {
      _markTalking();
      _subtitleAccumulator = msg;
      _subtitle.value = msg;
      return;
    }
    // Unknown shape but carries text — accumulate (NOT replace) so a
    // stream of unrecognised partial events doesn't degenerate to the
    // last word. A later canonical end-event can still overwrite cleanly.
    _markTalking();
    _subtitleAccumulator = _appendChunk(_subtitleAccumulator, msg);
    _subtitle.value = _subtitleAccumulator;
  }

  /// Mark the avatar as talking AND refresh the silence anchor. Each
  /// text event therefore counts as "activity" for the audio-poller
  /// silence detector, so we still get a proper finish even when
  /// LiveKit's per-speaker levels never arrive.
  void _markTalking() {
    if (!_avatarTalking.value) _avatarTalking.value = true;
    _lastLoudAt = DateTime.now();
  }

  /// Schedule the "avatar finished" transition. Clears the caption AND
  /// drops `avatarTalking` to false so the controller can move the mic
  /// back to centre. Called either from an explicit stop event (with the
  /// short stop-grace) or from the stale-timer fallback (with the
  /// reading-time estimate).
  void _scheduleAvatarFinish(Duration after) {
    _subtitleClearTimer?.cancel();
    _subtitleClearTimer = Timer(after, _onAvatarFinished);
  }

  void _onAvatarFinished() {
    _resetSubtitle();
    _lastLoudAt = null;
    _avatarTalking.value = false;
  }

  /// Bind an `AudioVisualizer` to the given remote audio track. The
  /// visualizer reads decoded PCM samples client-side and emits band
  /// magnitudes — works regardless of whether the server publishes
  /// per-speaker levels.
  Future<void> _attachVisualizer(lk.RemoteAudioTrack track) async {
    await _disposeVisualizer();
    if (_disposed) return;
    try {
      final viz = lk.createVisualizer(
        track,
        options: const lk.AudioVisualizerOptions(
          barCount: 5,
          smoothTransition: true,
        ),
      );
      final listener = viz.createListener()
        ..on<lk.AudioVisualizerEvent>(_handleVisualizerEvent);
      _visualizer = viz;
      _visualizerListener = listener;
      await viz.start();
    } catch (e, st) {
      _log.w('visualizer start failed', error: e, stack: st);
    }
  }

  Future<void> _disposeVisualizer() async {
    final viz = _visualizer;
    final listener = _visualizerListener;
    _visualizer = null;
    _visualizerListener = null;
    if (listener != null) {
      try {
        await listener.dispose();
      } catch (_) {}
    }
    if (viz != null) {
      try {
        await viz.stop();
      } catch (_) {}
      try {
        viz.dispose();
      } catch (_) {}
    }
  }

  void _handleVisualizerEvent(lk.AudioVisualizerEvent ev) {
    double maxBar = 0;
    for (final v in ev.event) {
      if (v is num) {
        final d = v.toDouble().abs();
        if (d > maxBar) maxBar = d;
      }
    }
    if (maxBar > _visualizerThreshold) {
      _lastLoudAt = DateTime.now();
      if (!_avatarTalking.value) _avatarTalking.value = true;
    }
  }

  /// Periodic silence checker. The visualizer pushes "loud" events that
  /// refresh `_lastLoudAt`; this timer simply notices when too much
  /// time has passed since the last refresh and fires the finish.
  void _startAudioPolling() {
    _audioPollTimer?.cancel();
    _lastLoudAt = null;
    _audioPollTimer = Timer.periodic(_audioPollInterval, (_) => _pollAudio());
  }

  void _pollAudio() {
    if (!_avatarTalking.value) return;
    final last = _lastLoudAt;
    if (last == null) return;
    if (DateTime.now().difference(last) >= _silenceFinishAfter) {
      _onAvatarFinished();
    }
  }

  void _resetSubtitle() {
    _subtitleClearTimer?.cancel();
    _subtitleClearTimer = null;
    _subtitleAccumulator = '';
    _subtitle.value = '';
  }

  /// Merge a streamed chunk into the running caption. Handles two HeyGen
  /// quirks: chunks may already include a leading space (delta semantics),
  /// or may carry the full text-so-far (snapshot semantics).
  static String _appendChunk(String acc, String chunk) {
    if (acc.isEmpty) return chunk;
    if (chunk.length >= acc.length && chunk.startsWith(acc)) return chunk;
    if (chunk.startsWith(' ') ||
        acc.endsWith(' ') ||
        acc.endsWith('\n')) {
      return acc + chunk;
    }
    return '$acc $chunk';
  }

  Future<void> _publish(
    lk.LocalParticipant lp,
    String payload, {
    required String label,
  }) async {
    try {
      await lp.publishData(
        Uint8List.fromList(utf8.encode(payload)),
        reliable: true,
        topic: AppConfig.agentControlTopic,
      );
    } catch (e) {
      _log.w('$label publishData failed', error: e);
    }
  }

  // ─── teardown ──────────────────────────────────────────────────────────────

  /// Best-effort: tell HeyGen to release the session via REST WITHOUT the
  /// local LiveKit teardown. Used on app exit, where the process is about to
  /// die anyway — we only need to free the session server-side and must not
  /// block on the (slow on Windows) WebRTC teardown.
  Future<void> stopRemote() async {
    final sid = _sessionId;
    if (sid == null) return;
    try {
      await http.post(
        Uri.parse('${AppConfig.heyGenApiBase}/v1/sessions/stop'),
        headers: {
          'X-API-KEY': config.apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'session_id': sid}),
      );
    } catch (e) {
      _log.w('stopRemote failed', error: e);
    }
  }

  /// Full stop: tear down LiveKit and notify HeyGen via REST. Idempotent.
  Future<void> stop() async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    final sid = _sessionId;
    _sessionId = null;
    _sessionToken = null;

    await _teardown();

    if (sid != null) {
      try {
        await http.post(
          Uri.parse('${AppConfig.heyGenApiBase}/v1/sessions/stop'),
          headers: {
            'X-API-KEY': config.apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'session_id': sid}),
        );
      } catch (e) {
        _log.w('stop request failed', error: e);
      }
    }
    _setStatus(HeyGenStatus.closed);
  }

  /// Tear down LiveKit + audio without sending stop REST. Use when the
  /// caller is about to replace this service instance.
  @override
  Future<void> close() => _teardown();

  Future<void> _teardown() async {
    if (_teardownInFlight) return;
    _teardownInFlight = true;
    _audioPollTimer?.cancel();
    _audioPollTimer = null;
    await _disposeVisualizer();
    try {
      for (final t in List.of(_audioTracks)) {
        try {
          await t.stop();
        } catch (_) {}
        try {
          await t.dispose();
        } catch (_) {}
      }
      _audioTracks.clear();

      try {
        await _listener?.dispose();
      } catch (_) {}
      _listener = null;

      try {
        await _room?.disconnect();
      } catch (_) {}
      try {
        await _room?.dispose();
      } catch (_) {}
      _room = null;
      _remoteVideoTrack = null;
    } finally {
      _teardownInFlight = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _keepAliveTimer?.cancel();
    _subtitleClearTimer?.cancel();
    _audioPollTimer?.cancel();
    // Fire-and-forget. Callers that need guaranteed teardown await
    // [close] before calling dispose().
    _teardown();
    _subtitle.dispose();
    _avatarTalking.dispose();
    super.dispose();
  }
}

/// Strongly-typed HeyGen REST failure for nicer logs and pattern matching.
class HeyGenApiException implements Exception {
  HeyGenApiException(this.stage, this.statusCode, this.body);
  final String stage;
  final int statusCode;
  final String body;

  @override
  String toString() => 'HeyGenApiException($stage, $statusCode): $body';
}
