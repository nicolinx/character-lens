import 'package:equatable/equatable.dart';

sealed class LookupHistoryFailure extends Equatable implements Exception {
  const LookupHistoryFailure();
}

class LookupHistoryUnavailableFailure extends LookupHistoryFailure {
  const LookupHistoryUnavailableFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
