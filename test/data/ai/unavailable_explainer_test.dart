import 'package:character_lens/data/ai/unavailable_explainer.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_entries.dart';

void main() {
  test('says it is not configured, for every character and language', () async {
    final explainer = UnavailableExplainer();

    for (final language in HanLanguage.values) {
      await expectLater(
        explainer.explain(SampleEntries.mu, language),
        throwsA(const ExplainerNotConfiguredFailure()),
      );
    }
  });
}
