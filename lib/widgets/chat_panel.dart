import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// iMessage-style glass input bar: multiline text field on the left,
/// circular gradient send button on the right. The parent is responsible
/// for mounting / unmounting and animating slide-in / slide-out.
class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.busy,
    required this.onSend,
    required this.onClose,
    required this.placeholder,
    required this.sendTooltip,
    required this.closeTooltip,
  });

  final bool busy;
  final ValueChanged<String> onSend;
  final VoidCallback onClose;
  final String placeholder;
  final String sendTooltip;
  final String closeTooltip;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  late final TextEditingController _ctl;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController()..addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final next = _ctl.text.trim().isNotEmpty;
    if (next != _canSend) setState(() => _canSend = next);
  }

  @override
  void dispose() {
    _ctl.removeListener(_onTextChanged);
    _ctl.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _ctl.text.trim();
    if (text.isEmpty || widget.busy) return;
    widget.onSend(text);
    _ctl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: (bottomInset > 0 ? bottomInset : safeBottom) + 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassContainer(
            borderRadius: 26,
            strong: true,
            padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 6, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: widget.closeTooltip,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: widget.onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: _ctl,
                      autofocus: true,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      enabled: !widget.busy,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        height: 1.3,
                      ),
                      cursorColor: AppTheme.accentOrange,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                        hintText: widget.placeholder,
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _SendButton(
                  enabled: _canSend && !widget.busy,
                  tooltip: widget.sendTooltip,
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.tooltip,
    required this.onPressed,
  });

  final bool enabled;
  final String tooltip;
  final VoidCallback onPressed;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: enabled ? AppTheme.orangeGradient : null,
          color: enabled ? null : AppTheme.glassFillStrong,
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x66E0681F),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Icon(
              Icons.arrow_upward_rounded,
              size: 22,
              color: enabled ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
