# ADR 004: Riverpod with sealed states for the canvas feature

Status: Accepted
Date: 2026-10-26

## Context

The canvas screen has a small state machine: the user draws, recognition runs after a pause, and the result is a list of candidates or an error. Input must be ignored while recognition runs, and a failed or empty recognition must show a readable state, not a crash. Separately, each language has a model that can be missing, downloading, ready or failed, and drawing is allowed only when the selected language's model is ready.

Requirements that shaped the choice:

- State transitions must be easy to unit test, including the 600 ms pause.
- The recognition engine must be replaceable in tests without a plugin or a network.
- Drawing updates state on every touch move, so the UI must not rebuild more than it has to.

## Decision

Use Riverpod 3.4.3 (`flutter_riverpod`) with sealed state classes and `Equatable`.

- **Sealed `CanvasState`:** `CanvasIdle`, `CanvasRecognizing`, `CanvasResult` (candidates and selected index) and `CanvasError` (a typed `InkFailure`). The PRD also lists a LookingUp state. In M2 it became its own sealed `LookupState` (`LookupClosed`, `LookupLoading`, `LookupLoaded`, `LookupNotFound`, `LookupFailed`) with a separate `LookupController`, not a fifth `CanvasState`. The result sheet opens, switches candidate and closes on its own, and the strokes and candidates must be as they were when it closes. The controller drops an answer for a character the user has already left, or that arrives after the sheet was closed.
- **Strokes and language are part of every state,** so a result can never be shown for different strokes than the ones it was recognized from. The cost is that each transition passes them along.
- **`CanvasController` is a `Notifier<CanvasState>`.** It owns the stroke list, the 600 ms debounce timer, and the rules (input is locked while recognizing, switching language clears strokes, a changed writing area clears strokes). State is never modified in place: every change builds a new list, which also lets the stroke painter compare by identity.
- **`ModelStatusController` is a `Notifier<Map<InkLanguage, ModelStatus>>`.** A missing key means "not checked yet".
- **Derived values are plain `Provider`s:** `selectedModelStatusProvider` and `drawingEnabledProvider`. They only expose a value, so widgets can watch exactly one thing.
- **Dependency injection through the provider graph.** `inkRecognizerProvider` is declared in the feature and overridden in `main.dart` with the ML Kit implementation. Tests override it with a hand-written `FakeInkRecognizer`.
- **Widgets watch narrowly,** with `ref.watch(provider.select(...))`. The layer that draws strokes watches only `strokes`.

Layers: presentation (`features/`) depends on domain, `data/` implements the domain interface, and `domain/` has no Flutter imports.

## Alternatives considered

1. **BLoC or Cubit.** This is the stack I have shipped apps with, so it would have been the faster path. A `Cubit<CanvasState>` with the same sealed states would work equally well here. I did not build the canvas in BLoC, so I cannot report a measured difference. Riverpod with sealed states was set in the PRD before any code existed. After building the feature, these are the properties I relied on: providers give dependency injection and derived state without a separate injection package, and `select` and derived providers make the rebuild scope explicit. **Riverpod is new to me in a shipped project.** This is my first project using it, so I kept the notifiers small and added tests for each transition.
2. **`ChangeNotifier` with `Provider` or `ListenableBuilder`.** It needs the least code. State would be mutable fields plus `notifyListeners()`, so impossible combinations (for example a result with no strokes) are easier to represent, and every listener is notified on any change unless I add narrowing code. I did not try it.

## Evidence

- `flutter test` runs 122 tests at the time of writing, and `flutter analyze` is clean. The state tests use `ProviderContainer` with overrides and `fakeAsync` for the debounce. Covered transitions include Idle to Recognizing to Result, Idle to Recognizing to Error, undo and clear, a new stroke during the pause cancelling it, input locked while recognizing, and an empty result.
- I checked that some tests can fail by breaking the code on purpose: removing the one-finger guard, removing the claim that stops the page from scrolling during a stroke, and removing the "not while recognizing" lock on Undo, Clear and Analyze each made a test fail.
- Drawing was checked by eye on an Android emulator. **No frame timing was measured,** so I make no claim about frame rate.

## Consequences

- Sealed states give an exhaustive `switch` in the UI, so a new state is a compile error wherever it is not handled.
- Because every state carries strokes and language, transitions are verbose. The upside is that no state can hold a mismatched result.
- **Rebuild scope is my responsibility.** Watching the whole `canvasControllerProvider` in a parent widget would rebuild that widget on every touch move. I avoid it with `select` and small widgets, and I keep the drawing layers separate. This is a rule to follow and review, not something the framework enforces.
- State changes need a new list each time. Changing a list in place would break the identity check in `StrokePainter.shouldRepaint` and the screen would stop updating.
- Two mistakes I made while building this, kept here because they are Riverpod-specific: reading `state` inside `build()` of a `Notifier` crashed at startup (fixed by deferring the first check with a microtask guarded by `ref.mounted`), and `on Exception` does not catch an `Error` such as `StateError`. A test of mine showed that when the recognizer throws one, it escapes and the state stays `CanvasRecognizing`, which locks the canvas. The plugin errors we know of are mapped to `Exception`, so I have not hit this on a device, but I have not decided whether to catch `Error` too.
- The controllers depend on the `InkRecognizer` interface, not on ML Kit, so the data layer can change without touching the state code (see ADR 001).
