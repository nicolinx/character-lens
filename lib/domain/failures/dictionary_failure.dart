import 'package:equatable/equatable.dart';

sealed class DictionaryFailure extends Equatable implements Exception {
  const DictionaryFailure();
}

/// A character that is simply not in the dictionary is not a failure:
/// [Dictionary.lookup] returns null for that.
class DictionaryUnavailableFailure extends DictionaryFailure {
  const DictionaryUnavailableFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
