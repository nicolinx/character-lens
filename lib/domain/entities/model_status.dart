import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/failures/ink_failure.dart';

sealed class ModelStatus extends Equatable {
  const ModelStatus();
}

class ModelNotDownloaded extends ModelStatus {
  const ModelNotDownloaded();

  @override
  List<Object?> get props => [];
}

class ModelDownloading extends ModelStatus {
  const ModelDownloading();

  @override
  List<Object?> get props => [];
}

class ModelReady extends ModelStatus {
  const ModelReady();

  @override
  List<Object?> get props => [];
}

class ModelFailed extends ModelStatus {
  const ModelFailed(this.failure);

  final InkFailure failure;

  @override
  List<Object?> get props => [failure];
}
