import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/entities/ink_language.dart';

sealed class InkFailure extends Equatable implements Exception {
  const InkFailure();
}

/// Recognition was requested before the language model was on the device.
class ModelNotDownloadedFailure extends InkFailure {
  const ModelNotDownloadedFailure(this.language);

  final InkLanguage language;

  @override
  List<Object?> get props => [language];
}

class ModelDownloadFailure extends InkFailure {
  const ModelDownloadFailure(this.language, {this.cause});

  final InkLanguage language;
  final Object? cause;

  @override
  List<Object?> get props => [language, cause];
}

/// The recognizer ran but produced no candidates.
class NoCandidatesFailure extends InkFailure {
  const NoCandidatesFailure();

  @override
  List<Object?> get props => [];
}

/// The recognizer itself failed, for any reason not covered above.
class RecognitionFailure extends InkFailure {
  const RecognitionFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
