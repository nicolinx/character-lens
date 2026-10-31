import 'package:character_lens/core/theme/app_theme.dart';
import 'package:character_lens/domain/explainer/explanation.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';
import 'package:character_lens/features/result/controllers/explain_state.dart';
import 'package:character_lens/features/result/widgets/explain_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _cn = Locale('zh', 'Hans');
const _jp = Locale('ja');

const _tree = ExplanationExample(word: '木头', reading: 'mùtou', meaning: 'wood');
const _forest = ExplanationExample(
  word: '树林',
  reading: 'shùlín',
  meaning: 'woods',
);

ExplainReady _ready({
  List<ExplanationComponent> components = const [
    ExplanationComponent(part: '木', role: 'a tree with roots and branches'),
  ],
  String mnemonic = 'A tree with a trunk, branches and roots.',
  List<ExplanationExample> examples = const [_tree, _forest],
  List<ReadingCheck>? checks,
  String? usageNote,
}) => ExplainReady(
  ValidatedExplanation(
    explanation: Explanation(
      components: components,
      mnemonic: mnemonic,
      examples: examples,
      usageNote: usageNote,
    ),
    checks: checks ?? [for (final _ in examples) ReadingCheck.verified],
  ),
);

Future<void> _pump(
  WidgetTester tester,
  ExplainState state, {
  Locale locale = _cn,
  double textScale = 1,
  Size size = const Size(400, 1400),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ExplainCard(state: state, locale: locale),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('always', () {
    for (final (name, state) in <(String, ExplainState)>[
      ('idle', const ExplainIdle()),
      ('loading', const ExplainLoading()),
      ('ready', _ready()),
      ('unavailable', const ExplainUnavailable(ExplainerTimeoutFailure())),
    ]) {
      testWidgets('is labeled as AI-generated when $name', (tester) async {
        await _pump(tester, state);

        expect(find.text('Explain it'), findsOneWidget);
        expect(find.text('AI-generated'), findsOneWidget);
      });
    }
  });

  group('while it is on its way', () {
    testWidgets('shows a skeleton that a screen reader can announce', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const ExplainLoading());

      expect(find.bySemanticsLabel('Generating explanation'), findsOneWidget);
      expect(find.text('Memory hook'), findsNothing);
      handle.dispose();
    });

    testWidgets('idle shows the skeleton too, not an empty card', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const ExplainIdle());

      expect(find.bySemanticsLabel('Generating explanation'), findsOneWidget);
      expect(find.text('Memory hook'), findsNothing);
      handle.dispose();
    });
  });

  group('when ready', () {
    testWidgets('shows the components, the mnemonic and the examples', (
      tester,
    ) async {
      await _pump(tester, _ready());

      expect(find.text('Components'), findsOneWidget);
      expect(find.text('a tree with roots and branches'), findsOneWidget);
      expect(find.text('Memory hook'), findsOneWidget);
      expect(
        find.text('A tree with a trunk, branches and roots.'),
        findsOneWidget,
      );
      expect(find.text('Example words'), findsOneWidget);
      for (final example in [_tree, _forest]) {
        expect(find.text(example.word), findsOneWidget);
        expect(find.text(example.reading), findsOneWidget);
        expect(find.text(example.meaning), findsOneWidget);
      }
    });

    testWidgets('says that memory hooks can be folk etymology', (tester) async {
      await _pump(tester, _ready());

      expect(find.textContaining('folk etymology'), findsOneWidget);
      expect(find.textContaining('come from the dictionary'), findsOneWidget);
    });

    testWidgets('leaves out components when there are none', (tester) async {
      await _pump(tester, _ready(components: const []));

      expect(find.text('Components'), findsNothing);
      expect(find.text('Memory hook'), findsOneWidget);
    });

    testWidgets('leaves out the examples block when there are none', (
      tester,
    ) async {
      await _pump(tester, _ready(examples: const []));

      expect(find.text('Example words'), findsNothing);
    });

    testWidgets('shows the usage note only when there is one', (tester) async {
      await _pump(tester, _ready());
      expect(find.text('CN vs JP'), findsNothing);

      await _pump(tester, _ready(usageNote: 'Used the same in both.'));
      expect(find.text('CN vs JP'), findsOneWidget);
      expect(find.text('Used the same in both.'), findsOneWidget);
    });

    testWidgets('the section headings are marked as headings', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _ready());

      expect(
        tester.getSemantics(find.text('Memory hook')),
        matchesSemantics(label: 'Memory hook', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('writes the characters in the language of the sheet', (
      tester,
    ) async {
      await _pump(tester, _ready(), locale: _jp);

      final word = tester.widget<Text>(find.text('木头'));
      final part = tester.widget<Text>(find.text('木'));
      expect(word.locale, _jp);
      expect(part.locale, _jp);
    });
  });

  group('the reading flag', () {
    testWidgets('is on an example the dictionary did not confirm', (
      tester,
    ) async {
      await _pump(
        tester,
        _ready(checks: [ReadingCheck.verified, ReadingCheck.unverified]),
      );

      expect(find.text('Unverified reading'), findsOneWidget);
    });

    testWidgets('is on the right example', (tester) async {
      await _pump(
        tester,
        _ready(checks: [ReadingCheck.verified, ReadingCheck.unverified]),
      );

      final flag = tester.getTopLeft(find.text('Unverified reading')).dy;
      final first = tester.getTopLeft(find.text('mùtou')).dy;
      final second = tester.getTopLeft(find.text('shùlín')).dy;
      expect(flag, greaterThan(second));
      expect(flag, greaterThan(first));
    });

    testWidgets('is not shown when every reading is verified', (tester) async {
      await _pump(tester, _ready());

      expect(find.text('Unverified reading'), findsNothing);
    });

    testWidgets('is shown for every unverified example', (tester) async {
      await _pump(
        tester,
        _ready(checks: [ReadingCheck.unverified, ReadingCheck.unverified]),
      );

      expect(find.text('Unverified reading'), findsNWidgets(2));
    });

    testWidgets('does not hide or change the reading it flags', (tester) async {
      await _pump(
        tester,
        _ready(checks: [ReadingCheck.unverified, ReadingCheck.verified]),
      );

      expect(find.text('mùtou'), findsOneWidget);
    });
  });

  group('when there is no explanation', () {
    for (final (failure, text) in <(ExplanationFailure, String)>[
      (
        const ExplainerNotConfiguredFailure(),
        'AI explanation is not set up in this build.',
      ),
      (
        const ExplainerOfflineFailure(),
        'No connection, so there is no AI explanation. Open it again to retry.',
      ),
      (
        const ExplainerTimeoutFailure(),
        'The AI explanation took too long. Open it again to retry.',
      ),
      (
        const ExplainerInvalidOutputFailure(),
        'The AI explanation could not be used.',
      ),
      (const ExplainerRejectedFailure(), 'The AI service refused the request.'),
      (
        const ExplainerFailure(),
        'AI explanation is unavailable right now. Open it again to retry.',
      ),
    ]) {
      testWidgets('says so quietly for ${failure.runtimeType}', (tester) async {
        await _pump(tester, ExplainUnavailable(failure));

        expect(find.text(text), findsOneWidget);
        expect(find.text('Memory hook'), findsNothing);
        expect(find.text('Unverified reading'), findsNothing);
      });
    }

    testWidgets('does not show the folk etymology note', (tester) async {
      await _pump(tester, const ExplainUnavailable(ExplainerOfflineFailure()));

      expect(find.textContaining('folk etymology'), findsNothing);
    });
  });

  group('text scale', () {
    testWidgets('a full explanation fits at 1.5x on a narrow screen', (
      tester,
    ) async {
      await _pump(
        tester,
        _ready(
          components: const [
            ExplanationComponent(
              part: '言',
              role: 'speech, what a person says out loud to someone else',
            ),
            ExplanationComponent(part: '吾', role: 'provides the sound'),
          ],
          mnemonic: 'Think of speech that expresses "I" or "my", which is your language.',
          examples: const [
            ExplanationExample(
              word: '日本語',
              reading: 'にほんご',
              meaning: 'Japanese language',
            ),
            ExplanationExample(
              word: '物語',
              reading: 'ものがたり',
              meaning: 'tale or story told long ago',
            ),
          ],
          checks: [ReadingCheck.verified, ReadingCheck.unverified],
          usageNote:
              'The same word is used in both languages, with another reading.',
        ),
        locale: _jp,
        textScale: 1.5,
        size: const Size(320, 1400),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the skeleton and the quiet message fit too', (tester) async {
      await _pump(
        tester,
        const ExplainLoading(),
        textScale: 1.5,
        size: const Size(320, 1400),
      );
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        const ExplainUnavailable(ExplainerOfflineFailure()),
        textScale: 1.5,
        size: const Size(320, 1400),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
