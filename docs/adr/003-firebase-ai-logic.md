# ADR 003: Gemini through Firebase AI Logic, with App Check and no API key in the app

Status: Accepted
Date: 2026-10-31

## Context

The app shows an AI explanation (components, a memory hook, example words) under the dictionary card. The call has to leave the device, because there is no on-device model for this. Requirements that shaped the choice:

- No API key in the app or the repo.
- The dictionary card never waits for it, and the app works without it.
- No server to run or pay for.
- Usable on a free tier, so a visitor who clones the repo can try it at no cost.
- The Flutter and Firebase package versions have to fit. This was an open question in the PRD and is resolved below.

## Decision

Call Gemini through **Firebase AI Logic** with the `firebase_ai` package, using the Gemini Developer API (`FirebaseAI.googleAI()`), and protect the project with **Firebase App Check**.

- **Versions:** `firebase_ai` 5.1.0, `firebase_core` 5.1.0, `firebase_app_check` 0.5.1. They resolved together with the Flutter version of this repo (3.47.7), so the Cloudflare Worker proxy named as the fallback in the PRD was not needed and is not built.
- **Model:** `gemini-3.1-flash-lite`. It was chosen from the Firebase AI Logic models page on 2026-10-27 because it was stable, had no shutdown announced before 2027-05-07, and did not need a paid plan. It is a name in one constant (`geminiModelName`), so changing it is one line. The prompt version is part of the cache key (see [ADR 005](005-grounded-llm.md)), so bump it with the model when old answers should not be reused.
- **Output:** the request asks for `application/json` with a JSON schema (`responseJsonSchema`). The model accepted the schema in every call of the spike.
- **No key in the app:** the app talks to Firebase, and the Gemini key lives on the Firebase side. The Firebase settings (project id, app id, API key of the Firebase app) are passed at build time from a gitignored `firebase.local.json` with `--dart-define-from-file`. Setup is in [firebase-setup.md](../firebase-setup.md). Firebase documents the API key of an app as an identifier, not a secret, but it is still kept out of the repo, so a clone does not point at my project.
- **App Check:** in debug builds the app uses the App Check debug provider with a token registered in the console. In release builds it uses Play Integrity on Android. iOS was never built, so no iOS provider is set up.
- **Not configured is a normal state:** without `firebase.local.json` Firebase is not started and the app uses `UnavailableExplainer`. The AI card says "AI explanation is not set up in this build." CI builds and tests without any Firebase setting.
- **A thin seam:** the Gemini call is the only code that knows `firebase_ai` (`FirebaseExplanationModel`, behind `ExplanationModel`). `LlmExplainer` builds the prompt, retries and parses, and works with any `ExplanationModel`. The PRD calls the explainer `GeminiExplainer`. It is `LlmExplainer` here because nothing in that class is specific to Gemini.
- **Failures** from the plugin and the network are mapped to our own types in one place (`firebase_failure_mapper.dart`), so nothing from the plugin leaves `data/`. See the table in [ai-usage.md](../ai-usage.md).

## What was measured

A spike on 2026-10-28, on the Medium_Phone Android emulator, with the real prompt and schema. The characters were 木 水 日 語 学, each in Chinese and Japanese.

| Run | Calls | Median | Min | Max | Under 4 s |
| --- | --- | --- | --- | --- | --- |
| Debug build, App Check debug provider | 10 | 3.9 s | 3.1 s | 5.3 s | 6 of 10 |
| Release build, Play Integrity | 10 | 3.2 s | 3.0 s | 8.7 s | 9 of 10 |

- The very first two calls ever (木, debug) took 8.2 s and 5.6 s. The first call also pays for the App Check token exchange. This was not separated out.
- Tokens per call: 279 to 302 in, 102 to 239 out, 386 to 528 in total. At the paid list price on the pricing page (dated 2026-10-27, $0.25 in and $1.50 out per 1M tokens) that is about $0.0002 to $0.0004 a call. This is derived from the price list, not billed, and the free tier costs nothing.
- All 20 answers were bare JSON that parsed. No call failed.
- In the app, one call on the History flow took about 8 to 10 s, observed once.
- A second run on 2026-10-31 (debug build, the same emulator, the same five characters drawn by hand in both languages) was slower: 11 calls for 10 characters, median 6.2 s, min 3.2 s, max 24.2 s, 2 of 11 under 4 s. The slow calls came in a block (calls 4 to 7), then it recovered. A ping from the emulator to the Firebase host lost 2 of 3 packets at the time, but ICMP on an emulator is unreliable and the cause was not established. Tokens were in the same range (279 to 302 in, 107 to 231 out). One call went past the 15 s timeout and the card showed "The AI explanation took too long", then the character was explained on the next try.
- The release build with Firebase starts with no extra R8 keep rules for the three Firebase packages (ML Kit needed them in M2). The APK went from 69.8 MB to 72.3 MB.

The PRD target is "under 4 s typical, with a skeleton". The spike medians were under it and the second run's was not. Latency varies a lot, with a tail past the 15 s timeout, and both samples are small and from an emulator. A physical device was not measured, so the target is not shown to be met.

## Consequences

- The card shows a skeleton first, and the explanation fills in. Some calls take 10 s or more and a few may end in the timeout card.
- **Free tier data use.** On the free tier, the pricing page (2026-10-27) says the content sent is used to improve Google products. What is sent is the recognized character and its dictionary entry, never the strokes, so a visitor's drawing does not leave the device. This is also in the README.
- **App Check is not proven for Play Integrity yet.** In the release spike the calls succeeded, but enforcement was off for AI Logic, so that does not show the token was valid. Auto-enforcement for Firebase AI Logic starts on 2026-11-02. The App Check metrics page in the console would show it. This is checked in the M3 acceptance pass.
- The debug token and the Firebase settings are per developer. A visitor who wants the AI card has to set up their own Firebase project.
- Each cached character costs one call ever (see [ADR 005](005-grounded-llm.md)), which keeps usage far below any free-tier limit for a personal app. The rate limits themselves were not tested.

## Alternatives considered

- **A small proxy (Cloudflare Worker) holding a Gemini key.** This was the fallback if `firebase_ai` did not fit. It does fit, so the extra service, its key and its deploy were not built.
- **A Gemini key in the app.** Rejected: a key in a bundle can be extracted.
- **An on-device language model.** Not evaluated.
