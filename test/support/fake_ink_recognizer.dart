import 'dart:async';

import 'package:character_lens/domain/entities/candidate.dart';
import 'package:character_lens/domain/entities/ink_language.dart';
import 'package:character_lens/domain/entities/model_status.dart';
import 'package:character_lens/domain/entities/stroke.dart';
import 'package:character_lens/domain/entities/writing_area.dart';
import 'package:character_lens/domain/repositories/ink_recognizer.dart';

class FakeInkRecognizer implements InkRecognizer {
  final statuses = <InkLanguage, ModelStatus>{};

  ModelStatus downloadResult = const ModelReady();
  Object? checkError;
  Object? downloadError;

  /// When set, a download waits for it, which keeps the state Downloading.
  Completer<void>? downloadGate;

  /// When set, a status check waits for it.
  Completer<void>? checkGate;

  final checked = <InkLanguage>[];
  final downloaded = <InkLanguage>[];

  List<Candidate> candidates = const [Candidate(character: '木')];
  Object? recognizeError;

  /// When set, recognition waits for it, which keeps the state Recognizing.
  Completer<void>? recognizeGate;

  final areas = <WritingArea>[];

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
  }) async {
    areas.add(writingArea);
    await recognizeGate?.future;
    if (recognizeError != null) throw recognizeError!;
    return candidates;
  }
}
