import 'package:flutter/widgets.dart';

/// All user-visible strings in the app. Add a key here, then implement it
/// in [EnStrings], [RuStrings], [ArStrings].
abstract class AppStrings {
  // app
  String get appTitle;
  String get brandTagline;

  // connecting screen
  String get tapToStart;
  String get connectingToHost;
  String get sessionEndedTapToStart;
  String connectionFailed(String? error);

  // live HUD
  String get holdMicHint;
  String get sendingToAssistant;
  String get timerLabel;
  String get microphoneDenied;

  // chat panel
  String get chatTooltip;
  String get typeYourQuestion;
  String get sendQuestion;
  String get chatCloseTooltip;

  // top bar
  String get settingsTooltip;

  // settings screen
  String get settingsTitle;
  String get sectionAssistantMode;
  String get sandboxToggle;
  String get sandboxDescription;
  String get sectionSessionDuration;
  String get sandboxDurationFixed;
  String get sectionInterfaceLanguage;
  String get sectionAssistantLanguage;
  String get sectionAvatar;
  String get sectionVoice;
  String get done;
  String get cancel;
  String get save;
  String get customAvatarTitle;
  String get customAvatarHintAdd;
  String get customAvatarHintReplace;
  String get customVoiceTitle;
  String get customVoiceHintAdd;
  String get customVoiceHintReplace;
  String get pasteHeyGenId;
  String get sandboxTag;

  // streaming quality
  String get sectionStreamingQuality;
  String get qualityHigh;
  String get qualityHighDescription;
  String get qualityAuto;
  String get qualityAutoDescription;

  // subtitles
  String get sectionSubtitles;
  String get subtitlesToggle;
  String get subtitlesDescription;

  // exit dialog
  String get exitTitle;
  String get exitMessage;
  String get exitConfirm;
  String get exitCancel;
}

/// English strings (default fallback).
class EnStrings implements AppStrings {
  const EnStrings();

  @override String get appTitle => 'Assistant Webstreaming';
  @override String get brandTagline => 'WEBSTREAMING ASSISTANT';

  @override String get tapToStart => 'Tap to start';
  @override String get connectingToHost => 'Connecting to host';
  @override String get sessionEndedTapToStart =>
      'Session ended. Tap to start again';
  @override String connectionFailed(String? error) {
    if (error == null) return 'Connection failed. Tap to retry';
    return 'Failed: $error · Tap to retry';
  }

  @override String get holdMicHint => 'Hold the mic to ask a question';
  @override String get sendingToAssistant => 'Sending to assistant...';
  @override String get timerLabel => 'TIME';
  @override String get microphoneDenied => 'Microphone permission denied';

  @override String get chatTooltip => 'Type a question';
  @override String get typeYourQuestion => 'Type your question...';
  @override String get sendQuestion => 'Send';
  @override String get chatCloseTooltip => 'Close';

  @override String get settingsTooltip => 'Settings';

  @override String get settingsTitle => 'Settings';
  @override String get sectionAssistantMode => 'Assistant mode';
  @override String get sandboxToggle => 'Test assistant (Sandbox)';
  @override String get sandboxDescription =>
      'Use the HeyGen sandbox avatar — no minutes charged (session capped at 58 sec)';
  @override String get sectionSessionDuration => 'Session duration';
  @override String get sandboxDurationFixed =>
      'In sandbox mode the duration is fixed at 58 sec';
  @override String get sectionInterfaceLanguage => 'Interface language';
  @override String get sectionAssistantLanguage => 'Assistant language';
  @override String get sectionAvatar => 'Assistant (Avatar)';
  @override String get sectionVoice => 'Voice';
  @override String get done => 'Done';
  @override String get cancel => 'Cancel';
  @override String get save => 'Save';
  @override String get customAvatarTitle => 'Custom avatar';
  @override String get customAvatarHintAdd => 'Add custom avatar...';
  @override String get customAvatarHintReplace =>
      'Paste your own HeyGen avatar ID';
  @override String get customVoiceTitle => 'Custom voice';
  @override String get customVoiceHintAdd => 'Add custom voice...';
  @override String get customVoiceHintReplace =>
      'Paste your own HeyGen voice ID';
  @override String get pasteHeyGenId => 'paste HeyGen ID';
  @override String get sandboxTag => 'SANDBOX';

  @override String get sectionStreamingQuality => 'Streaming quality';
  @override String get qualityHigh => 'High';
  @override String get qualityHighDescription =>
      'Always request the top simulcast layer — best picture, more bandwidth';
  @override String get qualityAuto => 'Auto';
  @override String get qualityAutoDescription =>
      'Adaptive — LiveKit picks the layer that fits your bandwidth and screen';

  @override String get sectionSubtitles => 'Subtitles';
  @override String get subtitlesToggle => 'Show subtitles';
  @override String get subtitlesDescription =>
      'Display the assistant’s spoken response as live captions';

  @override String get exitTitle => 'Exit?';
  @override String get exitMessage => 'Close Assistant Webstreaming?';
  @override String get exitConfirm => 'Exit';
  @override String get exitCancel => 'Stay';
}

/// Русский.
class RuStrings implements AppStrings {
  const RuStrings();

  @override String get appTitle => 'Ассистент Вебстриминг';
  @override String get brandTagline => 'ВЕБСТРИМИНГ АССИСТЕНТ';

  @override String get tapToStart => 'Нажмите, чтобы начать';
  @override String get connectingToHost => 'Подключение...';
  @override String get sessionEndedTapToStart =>
      'Сессия завершена. Нажмите, чтобы начать снова';
  @override String connectionFailed(String? error) {
    if (error == null) return 'Не удалось подключиться. Нажмите для повтора';
    return 'Ошибка: $error · Нажмите для повтора';
  }

  @override String get holdMicHint =>
      'Удерживайте микрофон, чтобы задать вопрос';
  @override String get sendingToAssistant => 'Отправляю ассистенту...';
  @override String get timerLabel => 'ВРЕМЯ';
  @override String get microphoneDenied => 'Нет доступа к микрофону';

  @override String get chatTooltip => 'Написать вопрос';
  @override String get typeYourQuestion => 'Введите вопрос...';
  @override String get sendQuestion => 'Отправить';
  @override String get chatCloseTooltip => 'Закрыть';

  @override String get settingsTooltip => 'Настройки';

  @override String get settingsTitle => 'Настройки';
  @override String get sectionAssistantMode => 'Режим ассистента';
  @override String get sandboxToggle => 'Тестовый ассистент (Sandbox)';
  @override String get sandboxDescription =>
      'Использовать тестового аватара HeyGen без списания минут (сессия 58 сек)';
  @override String get sectionSessionDuration => 'Длительность сессии';
  @override String get sandboxDurationFixed =>
      'В sandbox-режиме длительность фиксирована: 58 сек';
  @override String get sectionInterfaceLanguage => 'Язык интерфейса';
  @override String get sectionAssistantLanguage => 'Язык ассистента';
  @override String get sectionAvatar => 'Ассистент (Аватар)';
  @override String get sectionVoice => 'Голос';
  @override String get done => 'Готово';
  @override String get cancel => 'Отмена';
  @override String get save => 'Сохранить';
  @override String get customAvatarTitle => 'Свой аватар';
  @override String get customAvatarHintAdd => 'Добавить свой аватар...';
  @override String get customAvatarHintReplace =>
      'Вставьте свой ID аватара HeyGen';
  @override String get customVoiceTitle => 'Свой голос';
  @override String get customVoiceHintAdd => 'Добавить свой голос...';
  @override String get customVoiceHintReplace =>
      'Вставьте свой ID голоса HeyGen';
  @override String get pasteHeyGenId => 'вставьте ID HeyGen';
  @override String get sandboxTag => 'ТЕСТ';

  @override String get sectionStreamingQuality => 'Качество стриминга';
  @override String get qualityHigh => 'Максимум';
  @override String get qualityHighDescription =>
      'Всегда запрашивать верхний simulcast-слой — максимум картинки, больше трафика';
  @override String get qualityAuto => 'Авто';
  @override String get qualityAutoDescription =>
      'Адаптивное — LiveKit подстраивается под канал и размер окна';

  @override String get sectionSubtitles => 'Субтитры';
  @override String get subtitlesToggle => 'Показывать субтитры';
  @override String get subtitlesDescription =>
      'Отображать ответ ассистента текстом по мере озвучивания';

  @override String get exitTitle => 'Выйти?';
  @override String get exitMessage => 'Закрыть Ассистент Вебстриминг?';
  @override String get exitConfirm => 'Выйти';
  @override String get exitCancel => 'Остаться';
}

/// العربية (Arabic — RTL).
class ArStrings implements AppStrings {
  const ArStrings();

  @override String get appTitle => 'مساعد البث';
  @override String get brandTagline => 'مساعد البث المباشر';

  @override String get tapToStart => 'اضغط للبدء';
  @override String get connectingToHost => 'جارٍ الاتصال بالمضيف';
  @override String get sessionEndedTapToStart =>
      'انتهت الجلسة. اضغط للبدء من جديد';
  @override String connectionFailed(String? error) {
    if (error == null) return 'فشل الاتصال. اضغط لإعادة المحاولة';
    return 'خطأ: $error · اضغط لإعادة المحاولة';
  }

  @override String get holdMicHint =>
      'اضغط مع الاستمرار على الميكروفون لطرح سؤال';
  @override String get sendingToAssistant => 'يتم الإرسال إلى المساعد...';
  @override String get timerLabel => 'الوقت';
  @override String get microphoneDenied => 'تم رفض إذن الميكروفون';

  @override String get chatTooltip => 'اكتب سؤالاً';
  @override String get typeYourQuestion => 'اكتب سؤالك...';
  @override String get sendQuestion => 'إرسال';
  @override String get chatCloseTooltip => 'إغلاق';

  @override String get settingsTooltip => 'الإعدادات';

  @override String get settingsTitle => 'الإعدادات';
  @override String get sectionAssistantMode => 'وضع المساعد';
  @override String get sandboxToggle => 'مساعد تجريبي (Sandbox)';
  @override String get sandboxDescription =>
      'استخدم الصورة الرمزية التجريبية من HeyGen دون احتساب دقائق (الجلسة محددة بـ 58 ثانية)';
  @override String get sectionSessionDuration => 'مدة الجلسة';
  @override String get sandboxDurationFixed =>
      'في الوضع التجريبي تكون المدة ثابتة: 58 ثانية';
  @override String get sectionInterfaceLanguage => 'لغة الواجهة';
  @override String get sectionAssistantLanguage => 'لغة المساعد';
  @override String get sectionAvatar => 'المساعد (الصورة الرمزية)';
  @override String get sectionVoice => 'الصوت';
  @override String get done => 'تم';
  @override String get cancel => 'إلغاء';
  @override String get save => 'حفظ';
  @override String get customAvatarTitle => 'صورة رمزية مخصصة';
  @override String get customAvatarHintAdd => 'إضافة صورة رمزية مخصصة...';
  @override String get customAvatarHintReplace =>
      'الصق معرف الصورة الرمزية من HeyGen';
  @override String get customVoiceTitle => 'صوت مخصص';
  @override String get customVoiceHintAdd => 'إضافة صوت مخصص...';
  @override String get customVoiceHintReplace =>
      'الصق معرف الصوت من HeyGen';
  @override String get pasteHeyGenId => 'الصق معرف HeyGen';
  @override String get sandboxTag => 'تجريبي';

  @override String get sectionStreamingQuality => 'جودة البث';
  @override String get qualityHigh => 'الأعلى';
  @override String get qualityHighDescription =>
      'طلب أعلى طبقة دائمًا — أفضل صورة، استهلاك أعلى للنطاق الترددي';
  @override String get qualityAuto => 'تلقائي';
  @override String get qualityAutoDescription =>
      'تكيفي — يختار LiveKit الجودة المناسبة للشبكة وحجم العرض';

  @override String get sectionSubtitles => 'الترجمة النصية';
  @override String get subtitlesToggle => 'عرض الترجمة النصية';
  @override String get subtitlesDescription =>
      'إظهار رد المساعد كنص أثناء التحدث';

  @override String get exitTitle => 'الخروج؟';
  @override String get exitMessage => 'إغلاق مساعد البث؟';
  @override String get exitConfirm => 'خروج';
  @override String get exitCancel => 'البقاء';
}

/// Available UI languages and their factory.
class UiLocale {
  const UiLocale({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.textDirection,
    required this.factory,
  });

  final String code;
  final String nativeName;
  final String englishName;
  final TextDirection textDirection;
  final AppStrings Function() factory;

  Locale get locale => Locale(code);

  static const en = UiLocale(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    textDirection: TextDirection.ltr,
    factory: EnStrings.new,
  );

  static const ru = UiLocale(
    code: 'ru',
    nativeName: 'Русский',
    englishName: 'Russian',
    textDirection: TextDirection.ltr,
    factory: RuStrings.new,
  );

  static const ar = UiLocale(
    code: 'ar',
    nativeName: 'العربية',
    englishName: 'Arabic',
    textDirection: TextDirection.rtl,
    factory: ArStrings.new,
  );

  static const List<UiLocale> values = [en, ru, ar];

  static UiLocale forCode(String code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return en;
  }
}
