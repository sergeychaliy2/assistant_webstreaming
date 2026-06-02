import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../utils/logger.dart';
import 'disposable.dart';

/// Wraps the `record` package with hold-to-talk ergonomics:
/// permission check, smoothed amplitude meter, cancel-without-keeping-file.
class MicRecorderService implements AsyncDisposable {
  MicRecorderService({AudioRecorder? recorder, Log? logger})
      : _recorder = recorder ?? AudioRecorder(),
        _log = logger ?? const Log('Mic');

  static const _kSampleRate = 16000;
  static const _kBitRate = 256000;
  static const _kAmpInterval = Duration(milliseconds: 80);
  static const _kSmoothing = 0.45;

  final AudioRecorder _recorder;
  final Log _log;
  StreamSubscription<Amplitude>? _ampSub;

  /// Normalised mic loudness (0..1). Listen via [ValueListenable].
  final ValueNotifier<double> level = ValueNotifier<double>(0.0);

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  Future<bool> ensurePermission() async {
    if (await _recorder.hasPermission()) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Begin recording to a temp .wav. Returns false if permission was
  /// denied or the platform recorder refused to start.
  Future<bool> start() async {
    if (_isRecording) return true;
    if (!await ensurePermission()) return false;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}rec_${DateTime.now().millisecondsSinceEpoch}.wav';
    _currentPath = path;

    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: _kSampleRate,
      numChannels: 1,
      bitRate: _kBitRate,
    );

    try {
      await _recorder.start(config, path: path);
    } catch (e, st) {
      _log.e('start failed', error: e, stack: st);
      return false;
    }

    _isRecording = true;
    level.value = 0.0;

    _ampSub?.cancel();
    _ampSub = _recorder.onAmplitudeChanged(_kAmpInterval).listen(
      _onAmplitude,
      onError: (Object e) => _log.w('amplitude error', error: e),
    );
    return true;
  }

  void _onAmplitude(Amplitude amp) {
    // amp.current is dBFS — 0 dBFS = clipping, -∞ = silence.
    // Speaking voice typically lands between -45 and -10 dBFS.
    final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
    level.value = level.value + (normalized - level.value) * _kSmoothing;
  }

  /// Finalise recording and return path to the resulting .wav, or null.
  Future<String?> stop() async {
    if (!_isRecording) return null;
    _isRecording = false;
    await _ampSub?.cancel();
    _ampSub = null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e, st) {
      _log.e('stop failed', error: e, stack: st);
    }
    level.value = 0.0;
    return path ?? _currentPath;
  }

  /// Abort recording and delete the partial file (no transcription).
  Future<void> cancel() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
    level.value = 0.0;
    final p = _currentPath;
    if (p != null) {
      try {
        await File(p).delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() async {
    await _ampSub?.cancel();
    _ampSub = null;
    if (_isRecording) {
      try {
        await _recorder.cancel();
      } catch (_) {}
      _isRecording = false;
    }
    try {
      await _recorder.dispose();
    } catch (_) {}
    level.dispose();
  }
}
