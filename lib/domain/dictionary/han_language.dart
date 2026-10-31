import 'package:character_lens/domain/ink/ink_language.dart';

/// Input is Chinese or Japanese ([InkLanguage]); Korean (Hanja) only appears in
/// the output.
enum HanLanguage { chinese, japanese, korean }

extension InkLanguageHan on InkLanguage {
  HanLanguage get han => switch (this) {
    InkLanguage.chinese => HanLanguage.chinese,
    InkLanguage.japanese => HanLanguage.japanese,
  };
}
