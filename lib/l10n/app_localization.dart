import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Inherited bridge that exposes [AppStrings] to descendant widgets.
///
/// Usage:
///   final t = AppLocalization.of(context);
///   Text(t.connectingToHost)
class AppLocalization extends InheritedWidget {
  const AppLocalization({
    super.key,
    required this.strings,
    required this.locale,
    required super.child,
  });

  final AppStrings strings;
  final UiLocale locale;

  static AppStrings of(BuildContext context) {
    final w = context
        .dependOnInheritedWidgetOfExactType<AppLocalization>();
    assert(w != null, 'AppLocalization not found in widget tree');
    return w!.strings;
  }

  static UiLocale localeOf(BuildContext context) {
    final w = context
        .dependOnInheritedWidgetOfExactType<AppLocalization>();
    assert(w != null, 'AppLocalization not found in widget tree');
    return w!.locale;
  }

  @override
  bool updateShouldNotify(AppLocalization oldWidget) =>
      oldWidget.locale.code != locale.code;
}
