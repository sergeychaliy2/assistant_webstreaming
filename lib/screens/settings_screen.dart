import 'package:flutter/material.dart';

import '../data/presets.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../services/settings_service.dart'
    show SettingsService, StreamingQuality;
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/picker_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.settings.userSessionSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListenableBuilder(
                listenable: widget.settings,
                builder: (context, _) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UiLanguageSection(settings: widget.settings),
                      const SizedBox(height: 18),
                      _AssistantSection(settings: widget.settings),
                      const SizedBox(height: 18),
                      _SessionDurationSection(
                        settings: widget.settings,
                        seconds: _seconds,
                        onLiveChange: (v) => setState(() => _seconds = v),
                      ),
                      const SizedBox(height: 18),
                      _AssistantLanguageSection(settings: widget.settings),
                      const SizedBox(height: 18),
                      _StreamingQualitySection(settings: widget.settings),
                      const SizedBox(height: 18),
                      _SubtitlesSection(settings: widget.settings),
                      const SizedBox(height: 18),
                      _AvatarSection(settings: widget.settings),
                      const SizedBox(height: 18),
                      _VoiceSection(settings: widget.settings),
                      const SizedBox(height: 24),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                          ),
                          child: Text(t.done),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── section: UI language ────────────────────────────────────────────────────

class _UiLanguageSection extends StatelessWidget {
  const _UiLanguageSection({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    return _Section(
      title: t.sectionInterfaceLanguage,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: UiLocale.values.map((l) {
          final selected = settings.uiLanguage == l.code;
          return _LanguageChipUi(
            label: l.nativeName,
            code: l.code,
            selected: selected,
            onTap: () => settings.setUiLanguage(l.code),
          );
        }).toList(),
      ),
    );
  }
}

class _LanguageChipUi extends StatelessWidget {
  const _LanguageChipUi({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LangChip(
      label: label,
      code: code,
      selected: selected,
      onTap: onTap,
    );
  }
}

// ─── section: assistant (sandbox) ────────────────────────────────────────────

class _AssistantSection extends StatelessWidget {
  const _AssistantSection({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    return _Section(
      title: t.sectionAssistantMode,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          t.sandboxToggle,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          t.sandboxDescription,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        activeThumbColor: AppTheme.accentOrange,
        value: settings.sandbox,
        onChanged: (v) => settings.setSandbox(v),
      ),
    );
  }
}

// ─── section: session duration ───────────────────────────────────────────────

class _SessionDurationSection extends StatelessWidget {
  const _SessionDurationSection({
    required this.settings,
    required this.seconds,
    required this.onLiveChange,
  });

  final SettingsService settings;
  final int seconds;
  final ValueChanged<int> onLiveChange;

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    return _Section(
      title: t.sectionSessionDuration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: seconds.toDouble(),
                  min: 60,
                  max: 1200,
                  divisions: 19,
                  activeColor: AppTheme.accentOrange,
                  inactiveColor: AppTheme.glassStroke,
                  label: _fmt(seconds),
                  onChanged: settings.sandbox
                      ? null
                      : (v) => onLiveChange(v.toInt()),
                  onChangeEnd: (v) => settings.setSessionSeconds(v.toInt()),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  _fmt(seconds),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (settings.sandbox)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.sandboxDurationFixed,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── section: assistant language ─────────────────────────────────────────────

class _AssistantLanguageSection extends StatelessWidget {
  const _AssistantLanguageSection({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    return _Section(
      title: t.sectionAssistantLanguage,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: Presets.languages.map((lang) {
          final selected = settings.language == lang.code;
          return _LangChip(
            label: lang.nativeName,
            code: lang.code,
            selected: selected,
            onTap: () => settings.setLanguage(lang.code),
          );
        }).toList(),
      ),
    );
  }
}

// ─── shared: language chip ───────────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.accentOrange.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: GlassContainer(
        borderRadius: 14,
        strong: selected,
        borderColor: selected
            ? AppTheme.accentOrange.withValues(alpha: 0.55)
            : null,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  code.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.star_rounded,
                    color: AppTheme.accentOrange,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── section: avatar ─────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    final currentId = settings.avatarId;
    final knownIds = Presets.avatars.map((a) => a.id).toSet();
    final isCustom = !knownIds.contains(currentId);

    return _Section(
      title: t.sectionAvatar,
      child: Column(
        children: [
          ...Presets.avatars.map((a) => PickerCard(
                title: a.name,
                subtitle: a.description ?? a.id,
                selected: currentId == a.id,
                tagLabel: a.isSandbox ? t.sandboxTag : null,
                onTap: () => settings.setAvatarId(a.id),
              )),
          PickerCard(
            title: isCustom ? t.customAvatarTitle : t.customAvatarHintAdd,
            subtitle: isCustom ? currentId : t.customAvatarHintReplace,
            selected: isCustom,
            leading: const Icon(
              Icons.tune_rounded,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _promptCustomId(context, settings, _Kind.avatar),
          ),
        ],
      ),
    );
  }
}

// ─── section: subtitles ──────────────────────────────────────────────────────

class _SubtitlesSection extends StatelessWidget {
  const _SubtitlesSection({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    return _Section(
      title: t.sectionSubtitles,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          t.subtitlesToggle,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          t.subtitlesDescription,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        activeThumbColor: AppTheme.accentOrange,
        value: settings.subtitlesEnabled,
        onChanged: (v) => settings.setSubtitlesEnabled(v),
      ),
    );
  }
}

// ─── section: streaming quality ──────────────────────────────────────────────

class _StreamingQualitySection extends StatelessWidget {
  const _StreamingQualitySection({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    return _Section(
      title: t.sectionStreamingQuality,
      child: Column(
        children: [
          PickerCard(
            title: t.qualityHigh,
            subtitle: t.qualityHighDescription,
            selected: settings.streamingQuality == StreamingQuality.high,
            leading: const Icon(
              Icons.high_quality_rounded,
              color: AppTheme.textSecondary,
            ),
            onTap: () => settings.setStreamingQuality(StreamingQuality.high),
          ),
          PickerCard(
            title: t.qualityAuto,
            subtitle: t.qualityAutoDescription,
            selected: settings.streamingQuality == StreamingQuality.auto,
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.textSecondary,
            ),
            onTap: () => settings.setStreamingQuality(StreamingQuality.auto),
          ),
        ],
      ),
    );
  }
}

// ─── section: voice ──────────────────────────────────────────────────────────

class _VoiceSection extends StatelessWidget {
  const _VoiceSection({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    final currentId = settings.voiceId;
    final knownIds = Presets.voices.map((v) => v.id).toSet();
    final isCustom = !knownIds.contains(currentId);

    return _Section(
      title: t.sectionVoice,
      child: Column(
        children: [
          ...Presets.voices.map((v) => PickerCard(
                title: v.name,
                subtitle: v.description ?? v.id,
                selected: currentId == v.id,
                onTap: () => settings.setVoiceId(v.id),
              )),
          PickerCard(
            title: isCustom ? t.customVoiceTitle : t.customVoiceHintAdd,
            subtitle: isCustom ? currentId : t.customVoiceHintReplace,
            selected: isCustom,
            leading: const Icon(
              Icons.graphic_eq_rounded,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _promptCustomId(context, settings, _Kind.voice),
          ),
        ],
      ),
    );
  }
}

enum _Kind { avatar, voice }

Future<void> _promptCustomId(
  BuildContext context,
  SettingsService settings,
  _Kind kind,
) async {
  final t = AppLocalization.of(context);
  final current = kind == _Kind.avatar ? settings.avatarId : settings.voiceId;
  final controller = TextEditingController(text: current);
  final id = await showDialog<String?>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppTheme.bgMid,
        title: Text(
          kind == _Kind.avatar ? t.customAvatarTitle : t.customVoiceTitle,
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: t.pasteHeyGenId,
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t.cancel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(t.save),
          ),
        ],
      );
    },
  );
  if (id == null || id.isEmpty) return;
  if (kind == _Kind.avatar) {
    await settings.setAvatarId(id);
  } else {
    await settings.setVoiceId(id);
  }
}

// ─── shared section frame ────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      strong: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
