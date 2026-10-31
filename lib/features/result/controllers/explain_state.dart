import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:character_lens/domain/explainer/validated_explanation.dart';

/// Separate from LookupState: the dictionary card never waits for this.
sealed class ExplainState extends Equatable {
  const ExplainState();

  @override
  List<Object?> get props => [];
}

class ExplainIdle extends ExplainState {
  const ExplainIdle();
}

class ExplainLoading extends ExplainState {
  const ExplainLoading();
}

class ExplainReady extends ExplainState {
  const ExplainReady(this.result);

  final ValidatedExplanation result;

  @override
  List<Object?> get props => [result];
}

class ExplainUnavailable extends ExplainState {
  const ExplainUnavailable(this.failure);

  final ExplanationFailure failure;

  @override
  List<Object?> get props => [failure];
}
