import 'package:character_lens/app.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/ink/model_status.dart';
import 'package:character_lens/features/canvas/controllers/ink_recognizer_provider.dart';
import 'package:character_lens/features/dictionary_provider.dart';
import 'package:character_lens/features/history/controllers/lookup_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dictionary.dart';
import '../../support/fake_ink_recognizer.dart';
import '../../support/fake_lookup_history.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(400, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inkRecognizerProvider.overrideWithValue(
          FakeInkRecognizer()
            ..statuses[InkLanguage.chinese] = const ModelReady(),
        ),
        dictionaryProvider.overrideWithValue(FakeDictionary.bare('木')),
        lookupHistoryProvider.overrideWithValue(FakeLookupHistory()),
      ],
      child: const CharacterLensApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _openAbout(WidgetTester tester) async {
  await tester.tap(find.byTooltip('About'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the About button is a 48 dp tap target', (tester) async {
    await _pump(tester);

    final size = tester.getSize(find.byTooltip('About'));

    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('opens the Unihan credit and license', (tester) async {
    await _pump(tester);

    await _openAbout(tester);

    expect(find.text('About'), findsOneWidget);
    expect(
      find.textContaining('Unicode Han Database (Unihan) 18.0.0'),
      findsOne,
    );
    expect(find.textContaining('Unicode License v3'), findsOneWidget);
    expect(find.textContaining('does not endorse this app'), findsOneWidget);
  });

  testWidgets('says what leaves the device', (tester) async {
    await _pump(tester);

    await _openAbout(tester);

    expect(
      find.textContaining('Your strokes never leave the device'),
      findsOne,
    );
  });

  testWidgets('closes with the close button', (tester) async {
    await _pump(tester);
    await _openAbout(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unicode License v3'), findsNothing);
  });

  testWidgets('fits a narrow screen at 1.5x text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await _pump(tester, size: const Size(320, 640));

    await _openAbout(tester);

    expect(find.textContaining('Unicode License v3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the last line clears the system navigation bar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    await _pump(tester, size: const Size(400, 900));

    await _openAbout(tester);
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    final bottom = tester.getBottomLeft(find.textContaining('MIT licensed')).dy;
    expect(bottom, lessThanOrEqualTo(900 - 48));
  });
}
