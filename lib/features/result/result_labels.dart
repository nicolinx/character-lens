import 'package:flutter/widgets.dart';

import 'package:character_lens/domain/dictionary/character_view.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';

extension HanLanguageLabels on HanLanguage {
  String get code => switch (this) {
    HanLanguage.chinese => 'CN',
    HanLanguage.japanese => 'JP',
    HanLanguage.korean => 'KO',
  };

  String get name => switch (this) {
    HanLanguage.chinese => 'Chinese',
    HanLanguage.japanese => 'Japanese',
    HanLanguage.korean => 'Korean (Hanja)',
  };

  String get readingLabel => switch (this) {
    HanLanguage.chinese => 'Pinyin',
    HanLanguage.japanese => 'On · Kun',
    HanLanguage.korean => 'Hangul',
  };

  Locale get locale => switch (this) {
    HanLanguage.chinese => const Locale('zh', 'Hans'),
    HanLanguage.japanese => const Locale('ja'),
    HanLanguage.korean => const Locale('ko'),
  };
}

String readingText(LanguageReading reading) => [
  reading.readings.join(', '),
  reading.kun.join(', '),
].where((part) => part.isNotEmpty).join(' · ');

String variantText(FormVariant variant) => switch (variant.kind) {
  VariantKind.traditional => 'Traditional ${variant.character}',
  VariantKind.simplified => 'Simplified ${variant.character}',
};

String explainUnavailableMessage(ExplanationFailure failure) =>
    switch (failure) {
      ExplainerNotConfiguredFailure() =>
        'AI explanation is not set up in this build.',
      ExplainerOfflineFailure() =>
        'No connection, so there is no AI explanation. Open it again to retry.',
      ExplainerTimeoutFailure() =>
        'The AI explanation took too long. Open it again to retry.',
      ExplainerInvalidOutputFailure() =>
        'The AI explanation could not be used.',
      ExplainerRejectedFailure() => 'The AI service refused the request.',
      ExplainerFailure() =>
        'AI explanation is unavailable right now. Open it again to retry.',
    };
