import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// macOS-style three-button cluster: close / minimise / fullscreen-toggle.
///
/// We draw our own controls because the native title bar is hidden (the
/// app runs in borderless fullscreen). Hover reveals the standard glyph
/// inside each pill — same affordance as macOS.
class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _groupHover = false;
  bool _isFullScreen = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncFullScreen();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncFullScreen() async {
    final v = await windowManager.isFullScreen();
    if (!mounted) return;
    if (v != _isFullScreen) setState(() => _isFullScreen = v);
  }

  @override
  void onWindowEnterFullScreen() => _syncFullScreen();
  @override
  void onWindowLeaveFullScreen() => _syncFullScreen();
  @override
  void onWindowMaximize() => _syncFullScreen();
  @override
  void onWindowUnmaximize() => _syncFullScreen();

  Future<void> _close() async {
    // Goes through our setPreventClose(true) handler → shows exit dialog.
    await windowManager.close();
  }

  Future<void> _minimize() async {
    // Borderless fullscreen on Windows can swallow the minimize. Briefly
    // dropping fullscreen makes the taskbar reliably accept the request;
    // we re-enter fullscreen via the WindowListener when the user restores
    // the window.
    final wasFullScreen = _isFullScreen;
    if (wasFullScreen) {
      await windowManager.setFullScreen(false);
    }
    await windowManager.minimize();
    if (wasFullScreen) {
      _restoreFullScreenOnNextActivate = true;
    }
  }

  bool _restoreFullScreenOnNextActivate = false;

  @override
  void onWindowRestore() async {
    if (_restoreFullScreenOnNextActivate) {
      _restoreFullScreenOnNextActivate = false;
      await windowManager.setFullScreen(true);
      await _syncFullScreen();
    }
  }

  @override
  void onWindowFocus() async {
    if (_restoreFullScreenOnNextActivate) {
      _restoreFullScreenOnNextActivate = false;
      await windowManager.setFullScreen(true);
      await _syncFullScreen();
    }
  }

  Future<void> _toggleFullScreen() async {
    final next = !_isFullScreen;
    await windowManager.setFullScreen(next);
    if (!next) {
      // Restore to a sensible windowed size on exit-fullscreen.
      await windowManager.setSize(const Size(1280, 800));
      await windowManager.center();
    }
    await _syncFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _groupHover = true),
      onExit: (_) => setState(() => _groupHover = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DotButton(
            color: const Color(0xFFFEBC2E),
            hoverIcon: Icons.remove_rounded,
            tooltip: 'Minimize',
            showIcon: _groupHover,
            onTap: _minimize,
          ),
          const SizedBox(width: 8),
          _DotButton(
            color: const Color(0xFF28C840),
            hoverIcon: _isFullScreen
                ? Icons.close_fullscreen_rounded
                : Icons.open_in_full_rounded,
            tooltip: _isFullScreen ? 'Exit full screen' : 'Enter full screen',
            showIcon: _groupHover,
            onTap: _toggleFullScreen,
          ),
          const SizedBox(width: 8),
          _DotButton(
            color: const Color(0xFFFF5F57),
            hoverIcon: Icons.close_rounded,
            tooltip: 'Close',
            showIcon: _groupHover,
            onTap: _close,
          ),
        ],
      ),
    );
  }
}

class _DotButton extends StatefulWidget {
  const _DotButton({
    required this.color,
    required this.hoverIcon,
    required this.tooltip,
    required this.showIcon,
    required this.onTap,
  });

  final Color color;
  final IconData hoverIcon;
  final String tooltip;
  final bool showIcon;
  final VoidCallback onTap;

  @override
  State<_DotButton> createState() => _DotButtonState();
}

class _DotButtonState extends State<_DotButton> {
  static const double _size = 14;

  @override
  Widget build(BuildContext context) {
    final dot = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.20),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.45),
            blurRadius: widget.showIcon ? 10 : 6,
            spreadRadius: widget.showIcon ? 0.8 : 0,
          ),
        ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: widget.showIcon ? 1.0 : 0.0,
        child: Center(
          child: Icon(
            widget.hoverIcon,
            size: _size * 0.7,
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),
      ),
    );

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: dot,
          ),
        ),
      ),
    );
  }
}
