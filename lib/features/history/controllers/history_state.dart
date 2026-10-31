import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/history/history_item.dart';
import 'package:character_lens/domain/history/lookup_history_failure.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

/// Newest first.
class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.items);

  final List<HistoryItem> items;

  @override
  List<Object?> get props => [items];
}

class HistoryUnavailable extends HistoryState {
  const HistoryUnavailable(this.failure);

  final LookupHistoryFailure failure;

  @override
  List<Object?> get props => [failure];
}
