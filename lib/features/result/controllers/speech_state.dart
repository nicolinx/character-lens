import 'package:equatable/equatable.dart';

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

class SpeechNoVoice extends SpeechState {
  const SpeechNoVoice();
}

class SpeechFailed extends SpeechState {
  const SpeechFailed();
}
