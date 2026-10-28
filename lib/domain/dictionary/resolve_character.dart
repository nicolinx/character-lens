import 'package:character_lens/domain/dictionary/character_entry.dart';
import 'package:character_lens/domain/dictionary/character_view.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/dictionary/dictionary.dart';

/// Variants are followed one hop only, and only to fill a gap: a language gets
/// readings from a variant only when the drawn character has none for it.
/// Unihan does not link every pair of forms (for example 気 has no link to 氣),
/// so some characters stay unlinked.
class ResolveCharacter {
  ResolveCharacter(this._dictionary);

  final Dictionary _dictionary;

  Future<CharacterView> call(CharacterEntry entry, HanLanguage selected) async {
    final variants = _variantsOf(entry);
    final found = <String, CharacterEntry?>{};

    Future<CharacterEntry?> lookup(String character) async {
      if (!found.containsKey(character)) {
        found[character] = await _dictionary.lookup(character);
      }
      return found[character];
    }

    final readings = <HanLanguage, LanguageReading>{};
    for (final language in HanLanguage.values) {
      final own = _readingsOf(entry, language);
      if (!own.isEmpty) {
        readings[language] = own;
        continue;
      }
      var borrowed = const LanguageReading();
      for (final variant in variants) {
        final variantEntry = await lookup(variant);
        if (variantEntry == null) continue;
        final candidate = _readingsOf(variantEntry, language);
        if (candidate.isEmpty) continue;
        borrowed = LanguageReading(
          readings: candidate.readings,
          kun: candidate.kun,
          borrowedFrom: variant,
        );
        break;
      }
      readings[language] = borrowed;
    }

    final forms = {
      HanLanguage.chinese:
          _firstOther(entry.simplified, entry) ?? entry.character,
      // Japan writes what its own readings are attached to.
      HanLanguage.japanese:
          readings[HanLanguage.japanese]!.borrowedFrom ?? entry.character,
      HanLanguage.korean:
          _firstOther(entry.traditional, entry) ?? entry.character,
    };

    return CharacterView(
      entry: entry,
      selected: selected,
      forms: forms,
      readings: readings,
      variantNote: _variantNote(forms, selected),
    );
  }

  /// Traditional forms first, then simplified, without the character itself.
  List<String> _variantsOf(CharacterEntry entry) {
    final all = [...entry.traditional, ...entry.simplified];
    return {
      for (final v in all)
        if (v != entry.character) v,
    }.toList();
  }

  String? _firstOther(List<String> variants, CharacterEntry entry) {
    for (final v in variants) {
      if (v != entry.character) return v;
    }
    return null;
  }

  LanguageReading _readingsOf(CharacterEntry entry, HanLanguage language) =>
      switch (language) {
        HanLanguage.chinese => LanguageReading(readings: entry.mandarin),
        HanLanguage.japanese => LanguageReading(
          readings: entry.japaneseOn,
          kun: entry.japaneseKun,
        ),
        HanLanguage.korean => LanguageReading(readings: entry.hangul),
      };

  /// "Traditional X" when the selected form differs from the Korean (Hanja)
  /// form, else "Simplified X" when it differs from the Chinese form.
  FormVariant? _variantNote(
    Map<HanLanguage, String> forms,
    HanLanguage selected,
  ) {
    final form = forms[selected]!;
    final traditional = forms[HanLanguage.korean]!;
    final simplified = forms[HanLanguage.chinese]!;
    if (form != traditional) {
      return FormVariant(VariantKind.traditional, traditional);
    }
    if (form != simplified) {
      return FormVariant(VariantKind.simplified, simplified);
    }
    return null;
  }
}
