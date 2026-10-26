import 'dart:async';

import 'package:character_lens/app.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/failures/ink_failure.dart';
import 'package:character_lens/features/canvas/ink_recognizer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ink_recognizer.dart';

Future<void> _pump(WidgetTester tester, FakeInkRecognizer recognizer) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inkRecognizerProvider.overrideWithValue(recognizer)],
      child: const CharacterLensApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('a missing model locks drawing and offers a download', (
    tester,
  ) async {
    await _pump(tester, FakeInkRecognizer());

    expect(find.text('Chinese model · not downloaded'), findsOneWidget);
    expect(find.text('Download the model to start'), findsOneWidget);
    expect(find.text('Write one character'), findsNothing);
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('downloading shows progress, then unlocks drawing', (
    tester,
  ) async {
    final recognizer = FakeInkRecognizer()..downloadGate = Completer<void>();
    await _pump(tester, recognizer);

    await tester.tap(find.text('Download'));
    await tester.pump();

    expect(find.text('Downloading Chinese model…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Download'), findsNothing);

    recognizer.downloadGate!.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text('Chinese model ready · on-device'), findsOneWidget);
    expect(find.text('Write one character'), findsOneWidget);
    expect(find.text('Download the model to start'), findsNothing);
  });

  testWidgets('a failed download shows Retry, which recovers', (tester) async {
    final recognizer = FakeInkRecognizer()
      ..downloadResult = const ModelFailed(
        ModelDownloadFailure(InkLanguage.chinese),
      );
    await _pump(tester, recognizer);

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Download failed. Check your connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Download the model to start'), findsOneWidget);

    recognizer.downloadResult = const ModelReady();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Write one character'), findsOneWidget);
  });

  testWidgets("switching language shows that language's own model state", (
    tester,
  ) async {
    final recognizer = FakeInkRecognizer()
      ..statuses[InkLanguage.chinese] = const ModelReady();
    await _pump(tester, recognizer);
    expect(find.text('Write one character'), findsOneWidget);

    await tester.tap(find.text('JAPANESE'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Japanese model · not downloaded'), findsOneWidget);
    expect(find.text('Download the model to start'), findsOneWidget);
  });

  testWidgets('the action button has a 48 dp tap target', (tester) async {
    await _pump(tester, FakeInkRecognizer());

    final size = tester.getSize(
      find.ancestor(of: find.text('Download'), matching: find.byType(InkWell)),
    );

    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });
}
