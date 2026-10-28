import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_theme.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:character_lens/domain/dictionary/dictionary_failure.dart';
import 'package:character_lens/domain/dictionary/resolve_character.dart';
import 'package:character_lens/features/result/controllers/lookup_state.dart';
import 'package:character_lens/features/result/controllers/speech_state.dart';
import 'package:character_lens/features/result/widgets/dictionary_card.dart';
import 'package:character_lens/features/result/widgets/result_sheet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_dictionary.dart';
import '../../../support/sample_entries.dart';

const _jp = InkLanguage.japanese;
const _cn = InkLanguage.chinese;

final _dictionary = FakeDictionary([
  SampleEntries.mu,
  SampleEntries.go,
  SampleEntries.goSimplified,
  SampleEntries.gaku,
  SampleEntries.gakuTraditional,
  SampleEntries.kiJapanese,
  SampleEntries.kiSimplified,
  SampleEntries.kiTraditional,
  SampleEntries.noDefinition,
  SampleEntries.bare,
]);

Future<LookupLoaded> _loaded(String character, InkLanguage language) async {
  final entry = (await _dictionary.lookup(character))!;
  final view = await ResolveCharacter(_dictionary)(entry, language.han);
  return LookupLoaded(character: character, language: language, view: view);
}

class _Calls {
  final candidates = <String>[];
  var retries = 0;
  var closes = 0;
  final spoken = <String>[];
}

Future<_Calls> _pump(
  WidgetTester tester,
  LookupOpen state, {
  List<String> candidates = const [],
  double textScale = 1,
  Size size = const Size(400, 1400),
  SpeechState speech = const SpeechIdle(),
  double bottomInset = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: EdgeInsets.only(bottom: bottomInset),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: ResultSheetView(
            state: state,
            candidates: candidates,
            onCandidate: calls.candidates.add,
            onRetry: () => calls.retries++,
            onClose: () => calls.closes++,
            speech: speech,
            onSpeak: calls.spoken.add,
          ),
        ),
      ),
    ),
  );
  return calls;
}

Finder _glyph(String character, Locale locale) => find.byWidgetPredicate(
  (w) => w is Text && w.data == character && w.locale == locale,
);

BoxDecoration _decorationOf(WidgetTester tester, Key key) {
  final box = tester.widget<Container>(find.byKey(key));
  return box.decoration! as BoxDecoration;
}

void main() {
  group('loaded', () {
    testWidgets('shows the character large, in the language of the drawing', (
      tester,
    ) async {
      await _pump(tester, await _loaded('学', _jp));

      expect(_glyph('学', const Locale('ja')), findsWidgets);
      final big = tester.widget<Text>(_glyph('学', const Locale('ja')).first);
      expect(big.style!.fontSize, 104);
    });

    testWidgets('tags the language it was drawn in', (tester) async {
      await _pump(tester, await _loaded('学', _jp));

      expect(find.text('Japanese'), findsOneWidget);
    });

    testWidgets('tags a form that differs, like "Traditional 學"', (
      tester,
    ) async {
      await _pump(tester, await _loaded('学', _jp));

      expect(find.text('Traditional 學'), findsOneWidget);
    });

    testWidgets('has no variant tag when the forms are the same', (
      tester,
    ) async {
      await _pump(tester, await _loaded('木', _cn));

      expect(find.textContaining('Traditional'), findsNothing);
      expect(find.textContaining('Simplified'), findsNothing);
    });

    testWidgets('shows the definition', (tester) async {
      await _pump(tester, await _loaded('木', _cn));

      // Once in the header and once in the Dictionary card.
      expect(find.text('tree; wood, lumber; wooden'), findsNWidgets(2));
    });

    testWidgets('shows a quiet note when there is no definition', (
      tester,
    ) async {
      await _pump(tester, await _loaded('丂', _cn));

      expect(find.text('No definition in Unihan'), findsOneWidget);
    });

    testWidgets('the Dictionary card is badged as verified', (tester) async {
      await _pump(tester, await _loaded('木', _cn));

      expect(find.text('Dictionary'), findsOneWidget);
      expect(find.text('Verified · Unihan'), findsOneWidget);
    });

    testWidgets('the reading row is named for the language and shows it', (
      tester,
    ) async {
      await _pump(tester, await _loaded('学', _jp));

      expect(find.text('On · Kun'), findsOneWidget);
      // Also in the Across languages item for JP.
      expect(find.text('GAKU · MANABU'), findsNWidgets(2));
    });

    testWidgets('Across languages lists CN, JP and KO with form and reading', (
      tester,
    ) async {
      await _pump(tester, await _loaded('学', _jp));

      expect(find.text('Across languages'), findsOneWidget);
      for (final code in ['CN', 'JP', 'KO']) {
        expect(find.text(code), findsOneWidget);
      }
      expect(_glyph('学', const Locale('zh', 'Hans')), findsOneWidget);
      expect(_glyph('學', const Locale('ko')), findsOneWidget);
      expect(find.text('xué'), findsNWidgets(1));
      expect(find.text('학'), findsOneWidget);
    });

    testWidgets('highlights the language it was drawn in', (tester) async {
      await _pump(tester, await _loaded('学', _jp));

      final current = _decorationOf(tester, const Key('across-JP'));
      final other = _decorationOf(tester, const Key('across-CN'));
      expect((current.border! as Border).top.color, AppColors.seal);
      expect(current.color, AppColors.sealSoft);
      expect((other.border! as Border).top.color, AppColors.line);
    });

    testWidgets('labels a reading borrowed from a variant', (tester) async {
      // 气 has no Korean reading of its own; it comes from 氣.
      await _pump(tester, await _loaded('气', _cn));

      expect(find.text('from 氣'), findsOneWidget);
    });

    testWidgets('labels a borrowed reading in the Dictionary card too', (
      tester,
    ) async {
      // 语 has no Japanese reading of its own; it comes from 語.
      await _pump(tester, await _loaded('语', _jp));

      expect(
        find.descendant(
          of: find.byType(DictionaryCard),
          matching: find.text('from 語'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not label a character own reading as borrowed', (
      tester,
    ) async {
      await _pump(tester, await _loaded('木', _cn));

      expect(find.textContaining('from '), findsNothing);
    });

    testWidgets('says so quietly when a language has no reading', (
      tester,
    ) async {
      await _pump(tester, await _loaded('〇', _cn));

      expect(find.text('No reading'), findsNWidgets(3));
      expect(find.text('No reading in Unihan'), findsOneWidget);
    });

    testWidgets('ends with the data and privacy line', (tester) async {
      await _pump(tester, await _loaded('木', _cn));

      expect(
        find.text('Data: Unicode Unihan · Handwriting stays on your device'),
        findsOneWidget,
      );
    });

    testWidgets('has no AI section', (tester) async {
      await _pump(tester, await _loaded('木', _cn));

      expect(find.textContaining('AI'), findsNothing);
    });
  });

  group('Not it? chips', () {
    testWidgets('show the other candidates, the current one highlighted', (
      tester,
    ) async {
      await _pump(tester, await _loaded('学', _jp), candidates: ['学', '字', '労']);

      expect(find.text('Not it?'), findsOneWidget);
      final on = _decorationOf(tester, const Key('switch-学'));
      final off = _decorationOf(tester, const Key('switch-字'));
      expect(on.color, AppColors.sealSoft);
      expect(off.color, AppColors.card);
    });

    testWidgets('tapping one asks for that character', (tester) async {
      final calls = await _pump(
        tester,
        await _loaded('学', _jp),
        candidates: ['学', '字'],
      );

      await tester.tap(find.byKey(const Key('switch-字')));

      expect(calls.candidates, ['字']);
    });

    testWidgets('are hidden when there is only one candidate', (tester) async {
      await _pump(tester, await _loaded('学', _jp), candidates: ['学']);

      expect(find.text('Not it?'), findsNothing);
    });

    testWidgets('are at least 48 dp', (tester) async {
      await _pump(tester, await _loaded('学', _jp), candidates: ['学', '字']);

      final size = tester.getSize(find.byKey(const Key('switch-字')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('loading', () {
    testWidgets('shows the character and a placeholder, not the cards', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, const LookupLoading(character: '木', language: _cn));

      expect(_glyph('木', const Locale('zh', 'Hans')), findsOneWidget);
      expect(find.text('Dictionary'), findsNothing);
      expect(find.bySemanticsLabel('Looking up 木'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('not found', () {
    testWidgets('says the character is not in the dictionary', (tester) async {
      await _pump(
        tester,
        const LookupNotFound(character: '水', language: _cn),
        candidates: ['水', '木'],
      );

      expect(find.text('Not in the dictionary'), findsOneWidget);
      expect(find.textContaining('水'), findsWidgets);
    });

    testWidgets('still lets the user pick another match', (tester) async {
      final calls = await _pump(
        tester,
        const LookupNotFound(character: '水', language: _cn),
        candidates: ['水', '木'],
      );

      await tester.tap(find.byKey(const Key('switch-木')));

      expect(calls.candidates, ['木']);
    });
  });

  group('failed', () {
    testWidgets('says the dictionary could not be read, with a retry', (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        const LookupFailed(
          character: '木',
          language: _cn,
          failure: DictionaryUnavailableFailure(),
        ),
      );

      expect(find.text('The dictionary could not be opened'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(calls.retries, 1);
    });

    testWidgets('the retry button is at least 48 dp', (tester) async {
      await _pump(
        tester,
        const LookupFailed(
          character: '木',
          language: _cn,
          failure: DictionaryUnavailableFailure(),
        ),
      );

      final size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('close', () {
    testWidgets('the close button calls onClose', (tester) async {
      final calls = await _pump(tester, await _loaded('木', _cn));

      await tester.tap(find.byTooltip('Close'));

      expect(calls.closes, 1);
    });

    testWidgets('the close button is at least 48 dp', (tester) async {
      await _pump(tester, await _loaded('木', _cn));

      final size = tester.getSize(find.byTooltip('Close'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('text scale', () {
    for (final state in ['木', '学', '丂']) {
      testWidgets('$state fits at 1.5x on a narrow screen', (tester) async {
        await _pump(
          tester,
          await _loaded(state, _jp),
          candidates: ['木', '学', '丂', '语', '氣'],
          textScale: 1.5,
          size: const Size(320, 800),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the failed state fits at 1.5x', (tester) async {
      await _pump(
        tester,
        const LookupFailed(
          character: '木',
          language: _cn,
          failure: DictionaryUnavailableFailure(),
        ),
        candidates: ['木', '本'],
        textScale: 1.5,
        size: const Size(320, 800),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('speaker button', () {
    testWidgets('is there once the entry is loaded', (tester) async {
      await _pump(tester, await _loaded('語', _jp));

      expect(find.byTooltip('Play pronunciation'), findsOneWidget);
    });

    testWidgets('is not there while loading, not found or failed', (
      tester,
    ) async {
      await _pump(tester, const LookupLoading(character: '語', language: _jp));
      expect(find.byTooltip('Play pronunciation'), findsNothing);

      await _pump(tester, const LookupNotFound(character: '語', language: _jp));
      expect(find.byTooltip('Play pronunciation'), findsNothing);

      await _pump(
        tester,
        const LookupFailed(
          character: '語',
          language: _jp,
          failure: DictionaryUnavailableFailure(),
        ),
      );
      expect(find.byTooltip('Play pronunciation'), findsNothing);
    });

    testWidgets('asks to speak the written form, not the drawn one', (
      tester,
    ) async {
      // Drawn as 学 in Japanese, shown as 学; drawn as 語 in Chinese, shown 语.
      final calls = await _pump(tester, await _loaded('語', _cn));

      await tester.tap(find.byTooltip('Play pronunciation'));

      expect(calls.spoken, ['语']);
    });

    testWidgets('is a stop button while speaking', (tester) async {
      await _pump(
        tester,
        await _loaded('語', _jp),
        speech: const SpeechSpeaking(),
      );

      expect(find.byTooltip('Stop pronunciation'), findsOneWidget);
      expect(find.byTooltip('Play pronunciation'), findsNothing);
    });

    testWidgets('is at least 48 dp and fits at 1.5x on a narrow screen', (
      tester,
    ) async {
      await _pump(
        tester,
        await _loaded('語', _jp),
        textScale: 1.5,
        size: const Size(320, 1400),
      );

      final size = tester.getSize(find.byTooltip('Play pronunciation'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('says when no voice is installed', (tester) async {
      await _pump(
        tester,
        await _loaded('語', _jp),
        speech: const SpeechNoVoice(),
      );

      expect(find.text('No voice installed for this language'), findsOneWidget);
    });

    testWidgets('says when the sound could not be played', (tester) async {
      await _pump(
        tester,
        await _loaded('語', _jp),
        speech: const SpeechFailed(),
      );

      expect(find.text('Could not play the sound'), findsOneWidget);
    });

    testWidgets('says nothing when idle or speaking', (tester) async {
      await _pump(tester, await _loaded('語', _jp));
      expect(find.textContaining('voice'), findsNothing);
      expect(find.textContaining('Could not'), findsNothing);

      await _pump(
        tester,
        await _loaded('語', _jp),
        speech: const SpeechSpeaking(),
      );
      expect(find.textContaining('voice'), findsNothing);
    });
  });

  group('system navigation bar', () {
    testWidgets('keeps the footer clear of it', (tester) async {
      await _pump(tester, await _loaded('木', _jp), bottomInset: 48);

      final scroll = tester.getRect(find.byType(SingleChildScrollView));
      final footer = tester.getRect(
        find.textContaining('Data: Unicode Unihan'),
      );
      expect(scroll.bottom - footer.bottom, greaterThanOrEqualTo(48));
    });
  });
}
