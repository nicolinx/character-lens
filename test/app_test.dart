import 'package:character_lens/app.dart';
import 'package:character_lens/features/canvas/ink_recognizer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ink_recognizer.dart';

void main() {
  testWidgets('app launches to the canvas screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inkRecognizerProvider.overrideWithValue(FakeInkRecognizer()),
        ],
        child: const CharacterLensApp(),
      ),
    );

    expect(find.text('Character Lens'), findsOneWidget);
  });
}
