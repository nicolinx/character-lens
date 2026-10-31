import 'package:equatable/equatable.dart';

import 'package:character_lens/domain/dictionary/character_view.dart';
import 'package:character_lens/domain/history/history_entry.dart';

/// A history entry with what the dictionary says about it now.
class HistoryItem extends Equatable {
  const HistoryItem({required this.entry, this.view});

  final HistoryEntry entry;

  /// Null when the dictionary could not be read, or no longer has the entry.
  final CharacterView? view;

  @override
  List<Object?> get props => [entry, view];
}
