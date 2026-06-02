import 'package:assistant_webstreaming/widgets/mic_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget mount(MicButton btn) => MaterialApp(home: Scaffold(body: Center(child: btn)));

  testWidgets('idle mode shows mic icon', (tester) async {
    await tester.pumpWidget(mount(MicButton(
      mode: MicButtonMode.idle,
      level: ValueNotifier(0),
      size: 100,
      onPressStart: () {},
      onPressEnd: () {},
      onTapStop: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);
  });

  testWidgets('stop mode shows stop icon', (tester) async {
    await tester.pumpWidget(mount(MicButton(
      mode: MicButtonMode.stop,
      level: ValueNotifier(0),
      size: 100,
      onPressStart: () {},
      onPressEnd: () {},
      onTapStop: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsNothing);
  });

  testWidgets('press in idle invokes start then end', (tester) async {
    var started = 0;
    var ended = 0;
    await tester.pumpWidget(mount(MicButton(
      mode: MicButtonMode.idle,
      level: ValueNotifier(0),
      size: 100,
      onPressStart: () => started++,
      onPressEnd: () => ended++,
      onTapStop: () {},
    )));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.mic_rounded)),
    );
    await tester.pump();
    expect(started, 1);
    expect(ended, 0);

    await gesture.up();
    await tester.pump();
    expect(ended, 1);
  });

  testWidgets('tap in stop mode invokes onTapStop, not press handlers',
      (tester) async {
    var stopTapped = 0;
    var started = 0;
    await tester.pumpWidget(mount(MicButton(
      mode: MicButtonMode.stop,
      level: ValueNotifier(0),
      size: 100,
      onPressStart: () => started++,
      onPressEnd: () {},
      onTapStop: () => stopTapped++,
    )));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byIcon(Icons.stop_rounded)));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(stopTapped, 1);
    expect(started, 0);
  });
}
