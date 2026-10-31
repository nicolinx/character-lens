import 'package:character_lens/domain/explainer/kana_romanizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('romanizes the way Unihan spells Japanese readings', () {
    test('plain hiragana', () {
      expect(romanizeKana('もく'), 'MOKU');
      expect(romanizeKana('ぼく'), 'BOKU');
    });

    test('every row of the syllabary', () {
      const rows = {
        'あいうえお': 'AIUEO',
        'かきくけこ': 'KAKIKUKEKO',
        'さしすせそ': 'SASHISUSESO',
        'たちつてと': 'TACHITSUTETO',
        'なにぬねの': 'NANINUNENO',
        'はひふへほ': 'HAHIFUHEHO',
        'まみむめも': 'MAMIMUMEMO',
        'やゆよ': 'YAYUYO',
        'らりるれろ': 'RARIRURERO',
        'わをん': 'WAON',
        'がぎぐげご': 'GAGIGUGEGO',
        'ざじずぜぞ': 'ZAJIZUZEZO',
        'だぢづでど': 'DAJIZUDEDO',
        'ばびぶべぼ': 'BABIBUBEBO',
        'ぱぴぷぺぽ': 'PAPIPUPEPO',
      };
      for (final MapEntry(key: kana, value: romaji) in rows.entries) {
        expect(romanizeKana(kana), romaji, reason: kana);
      }
    });

    test('every small ya, yu and yo syllable', () {
      const rows = {
        'きゃきゅきょ': 'KYAKYUKYO',
        'しゃしゅしょ': 'SHASHUSHO',
        'ちゃちゅちょ': 'CHACHUCHO',
        'にゃにゅにょ': 'NYANYUNYO',
        'ひゃひゅひょ': 'HYAHYUHYO',
        'みゃみゅみょ': 'MYAMYUMYO',
        'りゃりゅりょ': 'RYARYURYO',
        'ぎゃぎゅぎょ': 'GYAGYUGYO',
        'じゃじゅじょ': 'JAJUJO',
        'びゃびゅびょ': 'BYABYUBYO',
        'ぴゃぴゅぴょ': 'PYAPYUPYO',
      };
      for (final MapEntry(key: kana, value: romaji) in rows.entries) {
        expect(romanizeKana(kana), romaji, reason: kana);
      }
    });

    test('Hepburn spellings: shi, chi, tsu, fu, ji', () {
      expect(romanizeKana('し'), 'SHI');
      expect(romanizeKana('ち'), 'CHI');
      expect(romanizeKana('つ'), 'TSU');
      expect(romanizeKana('ふ'), 'FU');
      expect(romanizeKana('じ'), 'JI');
      expect(romanizeKana('ぢ'), 'JI');
      expect(romanizeKana('づ'), 'ZU');
    });

    test('long vowels stay as two vowels, as in JUU and SHOU', () {
      expect(romanizeKana('じゅう'), 'JUU');
      expect(romanizeKana('しょう'), 'SHOU');
      expect(romanizeKana('こう'), 'KOU');
    });

    test('small ya, yu and yo make one syllable', () {
      expect(romanizeKana('きょう'), 'KYOU');
      expect(romanizeKana('しゃ'), 'SHA');
      expect(romanizeKana('じゃ'), 'JA');
      expect(romanizeKana('りゅう'), 'RYUU');
      expect(romanizeKana('ぴょ'), 'PYO');
    });

    test('ん is N', () {
      expect(romanizeKana('じん'), 'JIN');
      expect(romanizeKana('にん'), 'NIN');
    });

    test('を is O', () {
      expect(romanizeKana('を'), 'O');
    });

    test('っ doubles the next consonant', () {
      expect(romanizeKana('がっこう'), 'GAKKOU');
      expect(romanizeKana('いっち'), 'ITCHI');
    });

    test('katakana is read like hiragana', () {
      expect(romanizeKana('モクヨウビ'), 'MOKUYOUBI');
    });

    test('the long vowel mark repeats the last vowel', () {
      expect(romanizeKana('コーヒー'), 'KOOHII');
    });

    test('spaces and a middle dot between syllables are ignored', () {
      expect(romanizeKana('もく よう び'), 'MOKUYOUBI');
      expect(romanizeKana('もく・よう'), 'MOKUYOU');
    });
  });

  group('gives up instead of guessing', () {
    test('romaji is not kana', () {
      expect(romanizeKana('mokuyoubi'), isNull);
    });

    test('a Han character is not kana', () {
      expect(romanizeKana('木'), isNull);
    });

    test('an empty reading has nothing to romanize', () {
      expect(romanizeKana(''), isNull);
      expect(romanizeKana('  '), isNull);
    });

    test('a small kana that does not follow a consonant is not handled', () {
      expect(romanizeKana('ぁ'), isNull);
    });

    test('っ at the end has nothing to double', () {
      expect(romanizeKana('あっ'), isNull);
    });
  });
}
