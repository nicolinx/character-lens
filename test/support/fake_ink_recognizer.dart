import 'dart:async';

import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/repositories/ink_recognizer.dart';

/// Answers from memory, so no test touches the network or the plugin.
class FakeInkRecognizer implements InkRecognizer {
  /// Status per language. A language not listed is not downloaded.
  final statuses = <InkLanguage, ModelStatus>{};

  /// What a download ends with.
  ModelStatus downloadResult = const ModelReady();
  Object? checkError;
  Object? downloadError;

  /// When set, a download waits for it, which keeps the state Downloading.
  Completer<void>? downloadGate;

  /// When set, a status check waits for it.
  Completer<void>? checkGate;

  final checked = <InkLanguage>[];
  final downloaded = <InkLanguage>[];

  @override
  Future<ModelStatus> modelStatus(InkLanguage language) async {
    checked.add(language);
    await checkGate?.future;
    if (checkError != null) throw checkError!;
    return statuses[language] ?? const ModelNotDownloaded();
  }

  @override
  Future<ModelStatus> downloadModel(InkLanguage language) async {
    downloaded.add(language);
    await downloadGate?.future;
    if (downloadError != null) throw downloadError!;
    if (downloadResult is ModelReady) statuses[language] = downloadResult;
    return downloadResult;
  }

  @override
  Future<List<Candidate>> recognize(
    List<Stroke> strokes,
    InkLanguage language, {
    required WritingArea writingArea,
  }) async => const [Candidate(character: '木')];
}
