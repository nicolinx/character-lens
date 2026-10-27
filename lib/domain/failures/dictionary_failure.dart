import 'package:equatable/equatable.dart';

sealed class DictionaryFailure extends Equatable implements Exception {
  const DictionaryFailure();
}

/// The dictionary could not be opened or read: the asset is missing, corrupt
/// or could not be copied. A character that is simply not in it is not a
/// failure; [Dictionary.lookup] returns null for that.
class DictionaryUnavailableFailure extends DictionaryFailure {
  const DictionaryUnavailableFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
