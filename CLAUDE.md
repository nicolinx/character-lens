# CLAUDE.md: Character Lens

Flutter app for handwriting-based Han character lookup.

Full spec: `docs/prd.md`. If this file and the PRD disagree, the PRD
wins for product scope and this file wins for working rules.

---

## 1. Project summary

Draw a Chinese, Japanese, or Korean-Hanja character with a finger. Recognize it
on-device, then show pronunciation, meaning, cross-language readings (CN, JP,
KO), and a clearly labeled AI explanation (components, mnemonic, example
words).

What it shows:

- On-device ML (ML Kit Digital Ink) and offline-first data (SQLite).
- A grounded LLM feature (Gemini via Firebase AI Logic), where the LLM is an
  explainer, not the source of truth. No formal eval was run, see Evaluation.
- Clean Architecture, documented decisions (ADRs), tests, CI.

Documentation is part of the work: each milestone ships its doc.

- MVP input: Chinese (Hanzi) and Japanese (Kanji), single characters.
- Out of scope for now: Arabic, Hindi, Hangul input, multi-character words,
  bookmarks, stroke-order validation, camera OCR.
- Keep scope small. Do not expand it.

### Locked decisions (each gets an ADR in `docs/adr/`)

| Area | Choice |
|---|---|
| Recognition | Google ML Kit Digital Ink, on-device |
| Source of truth | Bundled SQLite dictionary built from Unicode Unihan (kMandarin, kJapaneseOn/Kun, kKorean, kDefinition, variants) |
| LLM | Gemini via Firebase AI Logic (`firebase_ai`) with App Check, no API key in app |
| LLM role | Explainer only, grounded on the dictionary entry, JSON-schema output |
| State | Riverpod with sealed states (Idle, Recognizing, LookingUp, Result, Error) |
| Storage | sqflite: read-only dictionary asset, separate cache/history DB |
| Abstractions | `InkRecognizer`, `Dictionary`, `Explainer` interfaces |

### Architecture

```
lib/
  features/   canvas/ result/ history/     (presentation)
  domain/     ink/ dictionary/ explainer/ tts/  (entities, failures, interfaces, use cases)
  data/       ink/ dictionary/ ai/ cache/ tts/
```

Feature-first, three layers. Presentation depends on domain, data implements
domain interfaces. No Flutter imports in `domain/`.

### UI

The approved prototype is `docs/design/index.html` (Ink & Paper: warm paper,
serif type, vermilion seal, light mode only). Match it when building screens.

## 2. Working rules for Claude Code

### Grounding rules (never weaken them)

1. Readings and definitions shown to the user come **only** from the dictionary,
   never from the LLM.
2. The LLM prompt includes the dictionary entry. Output is schema-constrained
   JSON (`components`, `mnemonic`, `examples`, `usage_note`). Invalid output is
   retried once, then dropped.
3. A validator flags any reading in `examples` that does not match the
   dictionary as unverified.
4. AI content is always labeled "AI-generated" and visually separate from the
   dictionary card. The dictionary card renders first and never waits on the
   LLM.
5. Cache AI results per character and language, so one call per character ever.
6. Prompt and schema are versioned in the repo (`prompt_v1`).

### Privacy and security

- No secrets in the repo or app bundle. Firebase config files stay out of git
  where they contain keys; document setup instead.
- Strokes never leave the device. Only the recognized character and its
  dictionary entry go to the LLM.
- No account, no analytics in MVP.

### Code conventions

- Dart/Flutter, Riverpod, sealed state classes, immutable models (Freezed only
  if it earns its keep; the PRD says no codegen for storage).
- Match the surrounding code's style, comment density, and naming.
- Tests required for: stroke mapper, dictionary lookup, validator, state
  transitions.
- `flutter analyze` and `flutter test` must pass before any commit. CI runs both.
- Non-functional targets: recognition under 500 ms, dictionary lookup under
  50 ms, AI explanation under 4 s typical with a skeleton, 48 dp tap targets,
  text scaling.

### Docs are built progressively

Each milestone ships its doc, not at the end.

| Milestone | Deliverable | Doc |
|---|---|---|
| M1 | Canvas, strokes, ML Kit recognition, candidate chips, model download state | ADR 001, 004 |
| M2 | Unihan SQLite builder script, lookup, result sheet, TTS | ADR 002, `data-flow.md` |
| M3 | Firebase AI Logic explainer, schema, validator, cache, history | ADR 003, 005, `ai-usage.md` |
| M4 | Tests, polish, demo GIF (no eval, see Evaluation) | `case-study.md`, README, `architecture.md` |

Docs layout: `docs/architecture.md`, `docs/data-flow.md`, `docs/ai-usage.md`,
`docs/adr/`, `docs/case-study.md`, plus `README.md` (pitch, demo GIF, diagram,
stack, run instructions, case-study link).

### Evaluation

No formal eval was run (decision 2026-10-31, scope and effort). Docs and posts
say so, and report only what was measured: the spike, the emulator pass and the
validator tests. Never call those an eval, a pass rate or a validation set.

### Acceptance criteria (summary)

- 木, 水, 日, 語, 学 drawn in CN and JP appear in the top 5 candidates.
- Dictionary card works in airplane mode after models download.
- AI example readings the dictionary does not confirm are marked unverified
  (validator tests, and checks on the emulator).
- Every failure path shows a non-crashing, understandable state: model not
  downloaded, empty recognition, character not in dictionary, LLM timeout or
  invalid JSON, no TTS voice.
- Docs and README complete, demo GIF in the README, CI green.

## 3. Writing rules (docs and README)

- **Factual accuracy outranks polish.** Do not invent metrics, pass rates,
  latencies, or results. Numbers come from actual runs. If something was not
  measured, say so.
- Concrete engineering language. Lead with what was built and the real number.
- No em dashes in prose; use commas.
- No stock filler phrases.
- Describe limits honestly (for example: mnemonics can be plausible-sounding
  folk etymology, and the docs and UI say so).
- Unihan attribution stays in the About screen and README (Unicode license).
  Repo license: MIT.
