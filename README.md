# Character Lens

Draw a Chinese or Japanese character with your finger and look it up: the app recognizes the strokes on the device, then shows the pronunciation, the meaning, and how the same character is written and read in Chinese, Japanese and Korean (Hanja).

This is a portfolio project, still in progress. The product spec is in [docs/prd.md](docs/prd.md) and the decisions made so far are in [docs/adr](docs/adr).

## Status

Working today:

- A drawing canvas with undo and clear, and recognition after a short pause or on demand.
- On-device recognition with Google ML Kit Digital Ink, Chinese and Japanese, with a model download state.
- Up to five candidates, filtered to characters that exist in the dictionary.
- A result sheet with the reading and meaning from the dictionary, the same character across Chinese, Japanese and Korean, and a "Not it?" list to switch candidate.
- Pronunciation with the text-to-speech voices installed on the device.

Not built yet: the AI explanation, history, evaluation, and the demo. iOS has not been built or run. The Android checks so far were on an emulator.

## Run it

```
flutter pub get
flutter run
```

The first time you draw in a language, the app downloads that language's recognition model from Google. This needs a network connection that can reach Google's servers. After that, recognition and the dictionary work offline.

```
flutter analyze
flutter test
```

## Data and attribution

Readings, meanings and variant forms come only from a SQLite dictionary bundled in the app (`assets/db/dictionary.db`, 60,183 characters). It is built from the Unicode Han Database (Unihan) 18.0.0, dated 2026-07-31:

- Mandarin, Japanese on and kun, and Korean (Hangul) readings
- English definitions
- simplified and traditional variants

The builder is `tool/build_dictionary.dart`. The Unihan files are not in the repo. To rebuild, download and unzip `Unihan.zip` from unicode.org, then run:

```
dart run tool/build_dictionary.dart <unihan folder> [output path]
```

Unihan data is Copyright (c) 1991-2026 Unicode, Inc. and is used under the Unicode License v3. The license text is in [assets/db/UNICODE-LICENSE.txt](assets/db/UNICODE-LICENSE.txt). The dictionary keeps selected fields and reorganizes them, so it is not the official Unicode data, and Unicode does not endorse this app.

## Known limits

- Pronunciation is spoken by the device's voice engine. It reads the character in its own way, which can differ from the reading shown in the dictionary card. Korean engines often cannot read Hanja.
- Unihan does not link every pair of simplified, traditional and Japanese forms. For some characters a reading is borrowed from one linked variant, and the card says so. Other pairs stay unlinked.
- Recognition quality comes from ML Kit. The decision record has the measurements taken so far, which are small.

## Fonts

Instrument Sans and Newsreader are bundled under the SIL Open Font License 1.1. The license texts are in `assets/fonts`.

## License

The code is MIT, see [LICENSE](LICENSE). The bundled data and fonts keep their own licenses, listed above.
