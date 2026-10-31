import 'dart:async';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import 'package:character_lens/domain/explainer/explanation_failure.dart';

/// Turns what the Firebase plugin and the network throw into one of our
/// failures, so nothing from the plugin leaves `data/`.
ExplanationFailure explanationFailureFor(Object error) {
  return switch (error) {
    ExplanationFailure() => error,
    TimeoutException() => const ExplainerTimeoutFailure(),
    SocketException() ||
    http.ClientException() => const ExplainerOfflineFailure(),
    // App Check could not get or verify a token.
    FirebaseException(plugin: 'firebase_app_check') => ExplainerRejectedFailure(
      cause: error,
    ),
    InvalidApiKey() ||
    UnsupportedUserLocation() ||
    ServiceApiNotEnabled() ||
    QuotaExceeded() => ExplainerRejectedFailure(cause: error),
    ServerException() => ExplainerFailure(cause: error),
    // What is left of FirebaseAIException is an answer that was blocked.
    FirebaseAIException() => ExplainerRejectedFailure(cause: error),
    _ => ExplainerFailure(cause: error),
  };
}
