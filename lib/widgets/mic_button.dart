import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'atoms/circle_press_target.dart';
import 'atoms/glass_circle.dart';
import 'atoms/pulse_halo.dart';

enum MicButtonMode { idle, recording, stop }

/// Composable glass mic / stop button.
///
/// Behavior:
/// - hold-to-talk in [MicButtonMode.idle] (press → onPressStart, release → onPressEnd)
/// - tap in [MicButtonMode.stop] triggers [onTapStop] to interrupt the avatar
///
/// Visual state:
/// - idle:      neutral glass + white mic icon
/// - recording: glass + outer pulse halo + mic icon fills green from bottom
///              up based on the live mic level
/// - stop:      glass + stop icon + tiny red indicator dot
class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.mode,
    required this.level,
    required this.size,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onTapStop,
    this.enabled = true,
  });

  final MicButtonMode mode;
  final ValueListenable<double> level;
  final double size;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onTapStop;
  final bool enabled;

  /// Minimum green fill so a faint signal is still visible while talking.
  static const double _minVisibleFill = 0.18;

  /// Bright green used for the inner mic-icon level fill.
  static const Color _levelGreen = Color(0xFF3DDC84);

  bool get _isStop => mode == MicButtonMode.stop;
  bool get _isRecording => mode == MicButtonMode.recording;

  @override
  Widget build(BuildContext context) {
    return CirclePressTarget(
      diameter: size,
      enabled: enabled,
      onPressStart: _isStop ? null : onPressStart,
      onPressEnd: _isStop ? null : onPressEnd,
      onTap: _isStop ? onTapStop : null,
      child: ValueListenableBuilder<double>(
        valueListenable: level,
        builder: (context, value, _) {
          final fillLevel = _isRecording
              ? (_minVisibleFill + (1 - _minVisibleFill) * value).clamp(0.0, 1.0)
              : 0.0;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_isRecording)
                PulseHalo(
                  active: true,
                  diameter: size,
                  color: Colors.white,
                ),
              GlassCircle(
                size: size,
                glowColor: _isRecording
                    ? _levelGreen
                    : _isStop
                        ? const Color(0xFFFF6B5C)
                        : null,
                glowStrength: _isRecording
                    ? (0.18 + 0.35 * value)
                    : _isStop
                        ? 0.30
                        : 0.0,
                child: _MicGlyph(
                  mode: mode,
                  iconSize: size * 0.4,
                  fillLevel: fillLevel,
                  fillColor: _levelGreen,
                ),
              ),
              if (_isStop)
                Positioned(
                  top: size * 0.16,
                  right: size * 0.16,
                  child: const _StatusDot(color: Color(0xFFFF6B5C)),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Mic glyph that fills with [fillColor] from the bottom up based on
/// [fillLevel] (0..1). When [fillLevel] == 0 the glyph is rendered plain
/// white. Implemented by layering a coloured copy of the icon under a
/// [ShaderMask] that exposes only the bottom portion.
class _MicGlyph extends StatelessWidget {
  const _MicGlyph({
    required this.mode,
    required this.iconSize,
    required this.fillLevel,
    required this.fillColor,
  });

  final MicButtonMode mode;
  final double iconSize;
  final double fillLevel;
  final Color fillColor;

  static const _shadows = [
    Shadow(
      color: Color(0x88000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  IconData get _icon => mode == MicButtonMode.stop
      ? Icons.stop_rounded
      : Icons.mic_rounded;

  @override
  Widget build(BuildContext context) {
    final base = Icon(
      _icon,
      size: iconSize,
      color: AppTheme.textPrimary,
      shadows: _shadows,
    );

    if (fillLevel <= 0 || mode != MicButtonMode.recording) {
      return base;
    }

    final clamped = fillLevel.clamp(0.001, 0.999);
    return Stack(
      alignment: Alignment.center,
      children: [
        base,
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [0, clamped, clamped],
            colors: [
              fillColor,
              fillColor,
              const Color(0x00000000),
            ],
          ).createShader(rect),
          child: Icon(
            _icon,
            size: iconSize,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}
