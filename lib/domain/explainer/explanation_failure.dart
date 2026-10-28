import 'package:equatable/equatable.dart';

sealed class ExplanationFailure extends Equatable implements Exception {
  const ExplanationFailure();
}

/// The app was built without Firebase settings, so there is no explainer.
class ExplainerNotConfiguredFailure extends ExplanationFailure {
  const ExplainerNotConfiguredFailure();

  @override
  List<Object?> get props => [];
}

class ExplainerOfflineFailure extends ExplanationFailure {
  const ExplainerOfflineFailure();

  @override
  List<Object?> get props => [];
}

class ExplainerTimeoutFailure extends ExplanationFailure {
  const ExplainerTimeoutFailure();

  @override
  List<Object?> get props => [];
}

/// The answer did not match the schema, also after the one retry.
class ExplainerInvalidOutputFailure extends ExplanationFailure {
  const ExplainerInvalidOutputFailure({this.detail});

  final String? detail;

  @override
  List<Object?> get props => [detail];
}

/// The service refused the request: App Check, quota or a blocked prompt.
class ExplainerRejectedFailure extends ExplanationFailure {
  const ExplainerRejectedFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}

/// Anything else that went wrong while explaining.
class ExplainerFailure extends ExplanationFailure {
  const ExplainerFailure({this.cause});

  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
