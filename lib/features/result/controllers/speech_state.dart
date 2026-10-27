import 'package:equatable/equatable.dart';

/// What the speaker button of the result sheet is doing.
sealed class SpeechState extends Equatable {
  const SpeechState();

  @override
  List<Object?> get props => [];
}

class SpeechIdle extends SpeechState {
  const SpeechIdle();
}

class SpeechSpeaking extends SpeechState {
  const SpeechSpeaking();
}

/// The device has no voice for the language.
class SpeechNoVoice extends SpeechState {
  const SpeechNoVoice();
}

class SpeechFailed extends SpeechState {
  const SpeechFailed();
}
