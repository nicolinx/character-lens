# ADR 001: Recognize handwriting on-device with ML Kit Digital Ink

Status: Accepted
Date: 2026-10-26

## Context

The app turns a finger-drawn character into text, so the user can look up a character they cannot type or pronounce. The input is one Han character, drawn as a list of strokes, in Chinese or Japanese. The recognizer has to return a ranked list, because a hand-drawn character is often ambiguous and the user picks the right one.

Constraints that shaped the choice:

- Strokes are personal input. The project rule is that strokes never leave the device.
- The app should work offline after setup.
- There is no backend and no API key in the app bundle.
- This is a portfolio project, so cost per call and operations work should be near zero.

## Decision

Use Google ML Kit Digital Ink Recognition, through the Flutter plugin `google_mlkit_digital_ink_recognition` 0.16.1 (community plugin from flutter-ml.dev, MIT license, built on `google_mlkit_commons` 0.13.0).

- Models are `zh-Hani` for Chinese and `ja` for Japanese. Each is downloaded once, then recognition runs on the device.
- The plugin sits behind a domain interface, `InkRecognizer`. The app depends on the interface, and `main.dart` is the only place that names `MlKitInkRecognizer`. Swapping the engine means writing another implementation and changing that one override.
- The recognizer is created lazily per language and closed on dispose. No pre-context is passed. The real canvas size is passed as the writing area.
- The top 5 candidates are kept. The cap is applied in our code (`maxCandidates = 5`).

## Alternatives considered

None of these were built or benchmarked. The reasons below are from their design, not from measurements.

1. **Server-side OCR or an LLM with vision.** The strokes, or an image of them, would go to a server. That breaks the rule that strokes stay on the device, needs a network for every lookup, and adds a per-call cost and a backend or key to manage.
2. **A custom TensorFlow Lite model.** This would give full control, but I would need training data for Chinese and Japanese handwriting, a training pipeline, and an evaluation of my own. That is a project of its own, and it is not what this portfolio piece is meant to show.
3. **Stroke-matching libraries for Han lookup.** There are open-source libraries that match strokes against a character dataset. I did not evaluate their Japanese coverage, their ranking quality, or whether they are maintained. I did not test them, so this is not a claim that they are worse.

## Evidence

Two sets of measurements, both small.

**Spike (2026-10-23).** Android emulator `Medium_Phone` (API 37, arm64), strokes drawn with a mouse, one attempt per character, 木 水 日 語 学 in both languages. The spike created a new recognizer on every press, so each time includes loading the model.

- 10 of 10 had the intended character at rank 1.
- `zh-Hani` took 252 to 632 ms, and one call (632 ms) was over the 500 ms target. `ja` took 65 to 85 ms. I did not investigate the cause of the difference.

**Acceptance pass (Step 9).** A physical Android device (model not recorded), strokes drawn with a finger, one attempt per cell, the same 10 cells, using the real app. The timer wrapped only the `recognize` call.

- 10 of 10 had the intended character at rank 1.
- 34 to 144 ms, median about 55 ms. The slowest was 語 in Chinese with 15 strokes (144 ms).
- Not recorded: the build mode (debug, profile or release), which call was first after launch, and any repeats. These figures are not end-to-end times: they leave out the 600 ms pause before recognition starts.

Both runs are one attempt per cell. They show that the engine works on these characters. They are not an accuracy rate.

Other things I read or saw:

- Platform minimums come from the plugin source, not from a build: iOS 15.5 (`GoogleMLKit/DigitalInkRecognition ~> 9.0.0`) and Android minSdk 21 (`com.google.mlkit:digital-ink-recognition:19.0.0`). I have not built or run the app on iOS.
- The plugin gives no download progress. The UI shows a single "downloading" state.
- On the office wifi, the Japanese model download failed with `UnknownHostException: Unable to resolve host "dl.google.com"`. The same download worked on a phone hotspot. The app showed its failed state with a Retry button and did not crash. I did not find out which network setting blocked the host.

## Consequences

- Strokes stay on the device, there is no per-call cost, and no key is needed. After the models are downloaded, recognition needs no network.
- **The first use of each language needs a network that can reach `dl.google.com`.** Some networks cannot. The size of the models was not measured.
- **Candidates are noisy.** Even with the right answer at rank 1, the top 5 contain multi-character strings (`十木`, `言語`, `、学`, `学学`), non-Han symbols (`ホ`, `ㄖ`, `1`, `+`, `t`) and, for Chinese, a simplified form (语 at rank 3 for 語). The lookup step in M2 needs a rule for these: filter to a single Han character, keep but skip lookup, or show as is. This is not decided yet.
- I do not know whether ML Kit returns more than 5 candidates, because both the spike and the app apply the cap of 5 before printing.
- The plugin is a community package that wraps Google's SDK. If it falls behind, the interface lets another implementation replace it, but I have not tried that.
- The writing area is reported to the engine, and a change in size clears the strokes. I did not test how much the writing area size changes accuracy.
- Only Chinese (`zh-Hani`) and Japanese (`ja`) are wired up. Korean Hanja input is out of scope for the MVP.
