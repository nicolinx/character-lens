# ADR 002: Readings and meanings come from a bundled dictionary built from Unihan

Status: Accepted
Date: 2026-10-28

## Context

After a character is recognized, the app shows how to read it and what it means, in Chinese, Japanese and Korean (Hanja). A wrong reading is worse than no reading, so the rule for this project is that readings and definitions come from a data source, never from a language model. The AI explanation planned for M3 is built on top of this data and does not replace it.

Requirements that shaped the choice:

- The result must work offline, after the recognition model is downloaded.
- A lookup should take under 50 ms. This is a target, and it has not been measured yet.
- One source should cover Chinese, Japanese and Korean, and link simplified, traditional and Japanese forms.
- No server and no API key.
- The license must allow bundling the data in an app.

## Decision

Build a SQLite file from the Unicode Han Database (Unihan) 18.0.0, dated 2026-07-31, bundle it as an asset, and read it with `sqflite` behind the domain interface `Dictionary`.

- `tool/build_dictionary.dart` reads the extracted Unihan files and writes `assets/db/dictionary.db`. Parsing is in `tool/unihan_parser.dart` as pure functions with tests. The command is `dart run tool/build_dictionary.dart <unihan folder> [output path]`. The Unihan files are not in the repo. The one run on the real data took about 3 seconds.
- The file is committed, so a fresh clone and CI need no download. It is 3,379,200 bytes (3.22 MB, 1.59 MB gzipped) with 60,183 rows. A `meta` table stores the Unihan version, its date and the build time.
- `SqliteDictionary` copies the asset to the databases folder on first use, and again whenever the installed bytes differ from the bundled ones, so an app update that ships a new dictionary replaces the old one. The copy goes to a temporary file first and is renamed when complete. The database is opened read-only. Every failure to open or read it is a `DictionaryUnavailableFailure`. A character that is not in the file is `null`, not a failure.
- The license is the Unicode License v3. The text is in `assets/db/UNICODE-LICENSE.txt`, next to the data, and the README repeats the notice.

### What is read from Unihan

| Column | Unihan field | Format as stored |
| --- | --- | --- |
| `mandarin` | `kMandarin` | Pinyin with tone marks (`mù`, `shuǐ`), several readings possible |
| `ja_on`, `ja_kun` | `kJapaneseOn`, `kJapaneseKun` | Uppercase romaji, space separated (`BOKU MOKU`, `KI`) |
| `ja_kana` | `kJapanese` | Kana. Stored but not used by the app |
| `hangul` | `kHangul` | Hangul. The source code after the colon (`목:0E`) is dropped |
| `definition` | `kDefinition` | One English string, kept whole |
| `simplified`, `traditional` | `kSimplifiedVariant`, `kTraditionalVariant` | Characters, in the order Unihan lists them. A source suffix such as `<kMatthews` is dropped |
| `strokes` | `kTotalStrokes` | An integer, read from `Unihan_IRGSources.txt` |

A character is kept only if it has at least one reading or a definition. Lists are stored as space-separated text, or NULL when empty.

### Choices made while reading the data

- **Korean uses `kHangul`, not `kKorean`.** `kKorean` is Yale romanization (`MOK`, `SWU`), not Revised Romanization, and the design prototype's "수 (su)" is mock data. `kHangul` gives Hangul directly.
- **`kDefinition` is not split into senses.** Both `;` and `,` separate senses, but both also appear inside one sense, so it cannot be split reliably. The sheet shows it as one string.
- **`kJapanese` is stored but unused.** It covers 51,583 characters against 13,177 with an on reading, so its coverage is much wider, and it may include uses that are not Japanese. I did not read its definition in the Unicode specification (UAX #38), so I did not rely on it.
- **Variants follow a one-hop rule.** This answers the open question in `CLAUDE.md` about shinjitai. See below.

### The one-hop variant rule

`ResolveCharacter` turns an entry into what the sheet shows for each language.

1. Use the readings on the drawn character.
2. If it has none for a language, borrow from one linked variant: traditional forms first, then simplified, never the character itself. The first variant that has readings for that language wins, and the row says where it came from ("from 氣").
3. Never follow a second hop.

Display forms: Chinese shows the first simplified variant that differs from the character, Korean (Hanja) shows the first traditional variant that differs, and Japanese shows the character whose readings were used.

Examples from the data, each with a test in `test/domain/usecases/resolve_character_test.dart`:

- 語 has the simplified variant 语. 语 has no Japanese or Korean readings, so its Japanese and Korean rows are borrowed from 語.
- 气 lists two traditional variants, `气 氣`. The rule skips 气 itself and takes 氣, so the Korean form is 氣 and the Korean reading 기 is borrowed from it.
- 学 has the traditional variant 學 and its own readings in all three languages, so nothing is borrowed.

## Alternatives considered

None of these were built or compared with measurements. The reasons are from their design.

1. **Ask a language model for readings and meanings.** This is simpler to build and covers any character, but it can state a wrong reading with confidence. It also needs a network and a key or proxy. It breaks the project's grounding rule, so it is the explainer's job at most, never the source.
2. **Other open dictionaries such as CC-CEDICT or KANJIDIC2.** I did not look at their data or licenses, so this is not a claim that they are worse. Unihan was chosen because I had read its files and it links forms across all three languages in one place.
3. **Read the Unihan text files at runtime.** This avoids the build step, but the device would parse text files and have no index. A database file gives lookup by character.

## Evidence

All counts are from `assets/db/dictionary.db`, queried on 2026-10-28.

- 60,183 rows. Columns with a value: definition 23,310; mandarin 44,355; ja_on 13,177; ja_kun 11,296; ja_kana 51,583; hangul 8,525; simplified 6,755; traditional 5,966; strokes 60,183.
- 44,702 characters have at least one of Mandarin, Japanese on or kun, or Hangul. 7,540 of them have Mandarin, Japanese on and Hangul together. Most characters have readings in fewer than three languages.
- 22,186 characters have a Mandarin reading and no definition. The sheet shows "No definition in Unihan" for them.
- 木, 水, 日, 語 and 学 have readings in all three languages on the character itself. 语 has Mandarin only.

## Consequences

- Readings and definitions are what Unihan says. If Unihan is wrong or silent, the app is too. The AI section in M3 may add context, but the dictionary card is the only place that states a reading.
- **Half the characters with a reading have no definition.** Of 44,355 with a Mandarin reading, 22,186 have no `kDefinition`. This is common, not an edge case.
- **Unihan does not link every pair of forms.** The Japanese form 気 has no variant links, and neither do 広 or 沢. They carry their own readings, so they display correctly, but nothing connects 気 to 氣 or 气. 気 has no Hangul reading, and its Korean row is empty ("No reading") instead of borrowed. 広 is similar: it links to nothing, so its Chinese and Korean forms show 広 itself.
- **Drawn traditional forms keep a traditional Japanese form.** Unihan gives 學 its own Japanese readings, so the app shows 學 as the Japanese form. The data used has no field that says which form is current in Japan, so the app cannot show 学 there. This is a known limit, with a test.
- **Borrowing can mislead for some characters.** 广 is listed as a simplified variant of 廣, but its Japanese readings (GEN, IE) and Korean reading (엄) belong to a different sense than those of 廣 and 広 (KOU, 광). Borrowing happens only when a character has no reading of its own, so 广 is not affected. A character with no Japanese reading whose only variant is 广 would be shown GEN. I did not search the data for such a case. The "from X" label is how a user can see this happened.
- **The data version is fixed at build time.** A new Unihan release means rebuilding the file and committing it. The app copies the new file over the old one on the next start.
- **The bundle grows by 3.22 MB.**
- **Lookup time was measured once, on an emulator.** Android emulator Medium_Phone, release build, one lookup per cell for 木 水 日 学 語 in Chinese and Japanese: 0 to 17 ms, median 2 ms, so all ten were under the 50 ms target. The timer covered `Dictionary.lookup` and the resolve step only, in whole milliseconds, from a temporary log that was removed afterwards. It does not cover drawing, recognition or rendering. These five characters have their own readings in every language, so the variant-borrowing path (a second lookup) was not timed. The time of the first copy on a fresh install was not captured either, because recognition had already opened the database before the first lookup. An emulator on a Mac CPU is not a phone.
- Unihan has more fields that are not used (`kSemanticVariant`, `kZVariant`, `kKorean`). Adding one means changing the builder, the schema and the entry, and rebuilding.
