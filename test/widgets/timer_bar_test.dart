import 'package:assistant_webstreaming/l10n/app_localization.dart';
import 'package:assistant_webstreaming/l10n/app_strings.dart';
import 'package:assistant_webstreaming/widgets/timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: AppLocalization(
        locale: UiLocale.en,
        strings: const EnStrings(),
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('formats m:ss with leading zeros', (tester) async {
    await tester.pumpWidget(_wrap(
      TimerBar(
        remaining: const Duration(seconds: 7),
        total: const Duration(seconds: 60),
      ),
    ));
    expect(find.text('TIME 00:07'), findsOneWidget);
  });

  testWidgets('shows total minutes correctly', (tester) async {
    await tester.pumpWidget(_wrap(
      TimerBar(
        remaining: const Duration(minutes: 2, seconds: 35),
        total: const Duration(minutes: 5),
      ),
    ));
    expect(find.text('TIME 02:35'), findsOneWidget);
  });

  testWidgets('uses localized timer label for Russian', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AppLocalization(
        locale: UiLocale.ru,
        strings: const RuStrings(),
        child: Scaffold(
          body: TimerBar(
            remaining: const Duration(seconds: 5),
            total: const Duration(seconds: 60),
          ),
        ),
      ),
    ));
    expect(find.text('ВРЕМЯ 00:05'), findsOneWidget);
  });

  testWidgets('stop button fires onStop callback', (tester) async {
    var stopped = 0;
    await tester.pumpWidget(_wrap(
      TimerBar(
        remaining: const Duration(seconds: 10),
        total: const Duration(seconds: 60),
        onStop: () => stopped++,
      ),
    ));
    await tester.tap(find.byIcon(Icons.stop_rounded));
    expect(stopped, 1);
  });
}
