import 'package:character_lens/domain/dictionary/dictionary_failure.dart';
import 'package:character_lens/domain/dictionary/han_language.dart';
import 'package:character_lens/domain/dictionary/resolve_character.dart';
import 'package:character_lens/domain/history/history_entry.dart';
import 'package:character_lens/domain/history/list_history.dart';
import 'package:character_lens/domain/history/lookup_history_failure.dart';
import 'package:character_lens/domain/ink/ink_language.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dictionary.dart';
import '../../support/fake_lookup_history.dart';
import '../../support/sample_entries.dart';

HistoryEntry _entry(String character, InkLanguage language, int minute) =>
    HistoryEntry(
      character: character,
      language: language,
      openedAt: DateTime.utc(2026, 10, 31, 12, minute),
    );

void main() {
  late FakeDictionary dictionary;
  late FakeLookupHistory history;
  late ListHistory list;

  setUp(() {
    dictionary = FakeDictionary([
      SampleEntries.mu,
      SampleEntries.go,
      SampleEntries.goSimplified,
    ]);
    history = FakeLookupHistory();
    list = ListHistory(
      history: history,
      dictionary: dictionary,
      resolve: ResolveCharacter(dictionary),
    );
  });

  test('is empty when nothing was looked up', () async {
    expect(await list(), isEmpty);
  });

  test('lists the entries in the order the history gives them', () async {
    history.entries.addAll([
      _entry('語', InkLanguage.chinese, 5),
      _entry('木', InkLanguage.japanese, 3),
    ]);

    final items = await list();

    expect(items.map((i) => i.entry.character), ['語', '木']);
  });

  test('gives each entry its view in the language it was drawn in', () async {
    history.entries.addAll([
      _entry('語', InkLanguage.chinese, 5),
      _entry('語', InkLanguage.japanese, 4),
    ]);

    final items = await list();

    expect(items[0].view!.selected, HanLanguage.chinese);
    expect(items[0].view!.form, '语');
    expect(items[1].view!.selected, HanLanguage.japanese);
    expect(items[1].view!.form, '語');
  });

  test('still lists a character the dictionary does not have', () async {
    history.entries.add(_entry('水', InkLanguage.chinese, 1));

    final items = await list();

    expect(items.single.entry.character, '水');
    expect(items.single.view, isNull);
  });

  test('still lists an entry when the dictionary cannot be read', () async {
    history.entries.addAll([
      _entry('語', InkLanguage.chinese, 2),
      _entry('木', InkLanguage.chinese, 1),
    ]);
    dictionary.lookupErrors['語'] = const DictionaryUnavailableFailure();

    final items = await list();

    expect(items.map((i) => i.entry.character), ['語', '木']);
    expect(items[0].view, isNull);
    expect(items[1].view, isNotNull);
  });

  test('a history that cannot be read is a failure', () async {
    history.recentError = const LookupHistoryUnavailableFailure();

    await expectLater(list(), throwsA(const LookupHistoryUnavailableFailure()));
  });
}
