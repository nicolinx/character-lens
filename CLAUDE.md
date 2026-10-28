# CLAUDE.md: Character Lens

Flutter app for handwriting-based Han character lookup. Personal notes live in
`CLAUDE.local.md` (gitignored, not part of this repo).

Full spec: `docs/prd.md`. If this file and the PRD disagree, the PRD
wins for product scope and this file wins for working rules.

---

## 1. Project summary

Draw a Chinese, Japanese, or Korean-Hanja character with a finger. Recognize it
on-device, then show pronunciation, meaning, cross-language readings (CN, JP,
KO), and a clearly labeled AI explanation (components, mnemonic, example
words).

It is a **portfolio piece**, not a product launch. It exists to show:

- On-device ML (ML Kit Digital Ink) and offline-first data (SQLite).
- A grounded LLM feature with evaluation (Gemini via Firebase AI Logic), where
  the LLM is an explainer, not the source of truth.
- Clean Architecture, documented decisions (ADRs), tests, CI.
- A case study and 3 LinkedIn posts derived from the docs.

So **documentation and evals are requirements, not extras**. Cut order if time
runs short: history, then the CN/JP usage note, then undo. Never cut the
validator or the evals.

- Target: finished, well-documented app in about 2 to 3 weeks part-time.
- MVP input: Chinese (Hanzi) and Japanese (Kanji), single characters.
- Out of scope for now: Arabic, Hindi, Hangul input, multi-character words,
  bookmarks, stroke-order validation, camera OCR.
- Keep planning pragmatic. Do not expand scope; a small finished milestone
  counts as progress.

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

### Grounding rules (these are the case-study story, never weaken them)

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
  transitions. Eval script is separate from unit tests.
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
| M4 | Eval script and results, tests, polish, demo video | `case-study.md`, README, `architecture.md` |

Docs layout: `docs/architecture.md`, `docs/data-flow.md`, `docs/ai-usage.md`,
`docs/adr/`, `docs/case-study.md`, plus `README.md` (pitch, demo GIF, diagram,
stack, run instructions, case-study link).

### Eval set

About 30 characters (simple, compound, CN/JP-divergent). Script checks: valid
schema, readings consistent with the dictionary, no contradicting definition.
Report real pass rate and real failure examples. **Never tune the eval to hide
failures**; the honest result is the content.

### Acceptance criteria (summary)

- 木, 水, 日, 語, 学 drawn in CN and JP appear in the top 5 candidates.
- Dictionary card works in airplane mode after models download.
- AI section never shows a reading contradicting the dictionary on the eval set.
- Every failure path shows a non-crashing, understandable state: model not
  downloaded, empty recognition, character not in dictionary, LLM timeout or
  invalid JSON, no TTS voice.
- Docs and README complete, demo video recorded, repo public, CI green.

### Open questions (resolve before the milestone that needs them)

- Shinjitai: map variants via `kSimplifiedVariant`/`kTraditionalVariant`, or
  document as a known limitation. Decide before M2.
- Verify `firebase_ai` fits the Flutter/Firebase versions at build time. Fallback:
  a small Cloudflare Worker proxy. Verify before M3.

## 3. Writing rules (docs, README, case study, LinkedIn posts)

Everything published about this project is employer- and client-facing.

- **Factual accuracy outranks polish.** Do not invent metrics, pass rates,
  latencies, or results. Eval numbers come from actual runs. If something was
  not measured, say so.
- Concrete engineering language. Lead with what was built and the real number.
- **No em dashes** in prose; use commas.
- Banned stock phrases: "results-driven," "proven track record," "passionate,"
  "leveraging," "spearheaded," "game-changing," "synergy," and similar filler.
- No hedged asks and no closing question ("Are you hiring?"). End on a plain
  statement.
- Describe limits honestly (for example: mnemonics can be plausible-sounding
  folk etymology, and the docs and UI say so).
- Unihan attribution stays in the About screen and README (Unicode license).
  Repo license: MIT.

### LinkedIn posts derived from the docs (3)

1. Demo video and the problem: "I can't type a character I can't pronounce."
2. Why the LLM is not the source of truth: grounding and validator, with the
   diagram.
3. Eval results: pass rate, what failed, what I changed.
