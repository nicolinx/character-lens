import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/ink/ink_language.dart';

sealed class InkFailure extends Equatable implements Exception {
  const InkFailure();
}

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

class NoCandidatesFailure extends InkFailure {
  const NoCandidatesFailure();

  @override
  List<Object?> get props => [];
}

class RecognitionFailure extends InkFailure {
  const RecognitionFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
