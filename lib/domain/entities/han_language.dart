import 'ink_language.dart';

/// The three languages a Han character is read in. Input is Chinese or
/// Japanese ([InkLanguage]); Korean (Hanja) only appears in the output.
enum HanLanguage { chinese, japanese, korean }

extension InkLanguageHan on InkLanguage {
  HanLanguage get han => switch (this) {
    InkLanguage.chinese => HanLanguage.chinese,
    InkLanguage.japanese => HanLanguage.japanese,
  };
}
