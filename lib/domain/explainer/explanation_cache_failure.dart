import 'package:equatable/equatable.dart';

sealed class ExplanationCacheFailure extends Equatable implements Exception {
  const ExplanationCacheFailure();
}

/// The cache could not be opened or read. An entry that is merely missing or
/// damaged is not a failure: `ExplanationCache.get` returns null for it.
class ExplanationCacheUnavailableFailure extends ExplanationCacheFailure {
  const ExplanationCacheUnavailableFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
