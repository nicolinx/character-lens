# ADR 005: The model explains, the dictionary decides

Status: Accepted
Date: 2026-10-31

## Context

A language model can write a good memory hook for a character, and it can also state a wrong reading with full confidence. A wrong reading is worse than no reading (see [ADR 002](002-unihan-dictionary.md)). So the model is allowed to explain, and it is not allowed to be the source of any reading or definition the app shows as fact.

## Decision

Four rules, each with code and tests behind it.

1. **Readings and definitions come only from the dictionary.** The dictionary card renders from `Dictionary` and never waits for the model. The AI section is a separate card with an "AI-generated" badge.
2. **The model is grounded on the entry.** The prompt (`prompt_v1`) contains the dictionary entry: definition, Mandarin, Japanese on and kun, Hangul, other written forms. The system instruction tells the model that the entry is the source of truth, not to add other readings, and that the mnemonic is a memory aid and not etymology. Only the character and its entry are sent. `ExplanationPromptBuilder` reads a `CharacterEntry` and nothing else, so strokes cannot reach the request.
3. **The output is constrained and checked.** The request asks for JSON that follows a schema. The parser then checks the shape itself and does not trust the constraint.
4. **A validator flags example readings the dictionary does not confirm.** A flagged example is shown with an "Unverified reading" mark. It is not removed and it is not corrected.

## The schema (`prompt_v1`)

```
{
  components: [{ part, role }],      // empty for an indivisible shape
  mnemonic:   string,                // one or two sentences
  examples:   [{ word, reading, meaning }],   // exactly two common words
  usage_note: string                 // optional, only when CN and JP differ
}
```

Required: `components`, `mnemonic`, `examples`. The schema is `explanationSchemaV1` in `lib/data/ai/explanation_schema.dart`. A test builds a value from the schema and parses it, so the schema and the parser cannot drift apart. The example reading format is set per language in the user message: pinyin with tone marks for Chinese, hiragana only for Japanese, Hangul for Korean.

## Parser rules (`parseExplanation`)

- The text must be one JSON object. Anything else is `ExplainerInvalidOutputFailure`.
- Every text field must be non-empty after trimming. Lists may be empty. Unknown fields are ignored.
- A problem names the field (`examples[1].reading is missing or empty`), never the model's text.

## Retry once, then drop

`LlmExplainer` makes up to two attempts. Only an **invalid answer** is asked for again. A timeout (15 s per attempt), no connection, or a rejected request is not retried, because asking again would not change the cause. After a second invalid answer the AI card says "The AI explanation could not be used." and nothing is cached. The dictionary card is unaffected. The worst case is two slow attempts, which is up to 30 s. The 15 s value comes from the spike (median 3.2 to 3.9 s, slowest 8.7 s in 20 calls) and was not tuned further. A later emulator run had one call at 24 s and the timeout card showed, so some calls on a poor network will hit it.

## The validator

`ExplanationValidator` checks only the **reading of each example word**, and returns `verified` or `unverified` per example. An example is verified when its reading contains one of the dictionary readings of the character. It never returns verified when it cannot decide.

| Language | How the reading is compared |
| --- | --- |
| Chinese | Pinyin with tone marks, lowercase, spaces and apostrophes removed, against `kMandarin` |
| Japanese | The kana reading is turned into romaji (`romanizeKana`), then compared with the on and kun readings in Unihan's uppercase romaji style |
| Korean | The Hangul reading against the Hangul syllables |

### Known limits

- **It is a "contains" test.** A reading that is wrong in the rest of the word still passes when it contains a dictionary reading of the character. For 木 (mù), a made-up reading like mùxyz is verified. The check does not look at the other characters of the word. It cannot prove a word's reading is right, only that the dictionary does not contradict the part it knows.
- **Sound changes are unverified.** 学校 is がっこう (GAKKOU), which does not contain GAKU. The reading is right and is flagged.
- **Readings the dictionary lacks are unverified.** 日本 is にほん, and Unihan has no `NI` among the on readings of 日.
- **Rendaku and similar changes** (物語 is ものがたり, 語 is read がたり) are unverified.
- **Japanese must be kana.** Romaji or anything else is unverified. The prompt asks for hiragana only.
- **Tone marks must be precomposed letters,** as in the dictionary. Combining marks are not handled.
- **A one-letter reading** only matches a one-letter word reading.
- **It checks readings, not meanings, components or the mnemonic.** Nothing checks those. They are labeled AI-generated, and the card carries a note that memory hooks can be plausible-sounding folk etymology.

Apart from the first limit, they make the check stricter: a correct reading gets flagged, which costs usefulness but does not show a wrong fact as verified. The first limit is the one that goes the other way, and it is why the validator is a flag for disagreement, not proof.

### What the spike found

On 20 distinct examples (5 characters, Chinese and Japanese), 17 were verified and 3 were unverified. All 3 were correct readings caught by the limits above (日本 にほん, 物語 ものがたり, 学校 がっこう). No wrong reading was found, and no false "verified" was seen, but 20 examples cannot show there is none.

The validator cannot see everything. For 学 the model listed 宀, 爻 and 子 as components and wrote a usage note saying the traditional form 學 is often still used in formal contexts or names in Japan. Both look doubtful and were not checked against a reference. This is why the mnemonic is labeled as a memory aid. No larger check was run: see "What was checked, and what was not" in [ai-usage.md](../ai-usage.md).

## The cache

An answer is stored per **character, language and prompt version** (`ExplanationKey`), so each character costs one model call, once, per language.

- `SqliteExplanationCache` is its own SQLite file (`explanation_cache.db`). The explanation is stored as JSON text in the same shape the model returns, so the parser that reads the model's answer also reads the cache.
- A new prompt version is a different key, so an old answer is never served for a new prompt.
- The **validator runs on every read, cached or not**. Flags are not stored, so a better validator later applies to answers that are already cached.
- A failed explanation is **not** cached. A character that failed offline is explained when it is opened again online.
- A cache that cannot be read is a miss. One that cannot be written keeps the answer for this view. A damaged entry is removed. A damaged file is deleted and created again once. None of these can break the dictionary card.

## Consequences

- A visitor never sees a model reading presented as dictionary fact. Readings in the explanation are labeled and checked, and the ones the check cannot confirm are marked.
- The check is loose and says so. Do not read "verified" as "correct". It means "the dictionary does not disagree".
- Mnemonics and components can be wrong, and the app only labels them.
- Changing the prompt or the schema means a new version string and a new cache key, which costs one call per character again.

## Alternatives considered

- **Let the model give readings and show them.** Rejected: this is the rule the project is built around.
- **Drop an example whose reading is unverified.** Rejected: most flags are correct readings, so it would hide good content. The mark shows the doubt and keeps the example.
- **A strict check with word segmentation.** Not built. It needs a word dictionary that Unihan does not provide.
- **Retry on every failure.** Rejected: timeouts and offline would double the wait without changing the outcome.
