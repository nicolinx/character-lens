import 'dart:async';
import 'dart:io';

import 'package:character_lens/data/ai/firebase_failure_mapper.dart';
import 'package:character_lens/domain/explainer/explanation_failure.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  Matcher rejected() => isA<ExplainerRejectedFailure>();
  Matcher other() => isA<ExplainerFailure>();

  group('the network', () {
    test('a socket error is offline', () {
      expect(
        explanationFailureFor(const SocketException('Failed host lookup')),
        const ExplainerOfflineFailure(),
      );
    });

    test('an http client error is offline', () {
      expect(
        explanationFailureFor(http.ClientException('connection closed')),
        const ExplainerOfflineFailure(),
      );
    });

    test('a timeout is a timeout', () {
      expect(
        explanationFailureFor(TimeoutException('slow')),
        const ExplainerTimeoutFailure(),
      );
    });
  });

  group('the service refuses', () {
    test('App Check failing, as seen with an unregistered debug token', () {
      final error = FirebaseException(
        plugin: 'firebase_app_check',
        code: 'unknown',
        message:
            'Error returned from API. code: 403 body: App attestation failed.',
      );

      expect(explanationFailureFor(error), rejected());
    });

    test('a rejected API key, a missing API or an unsupported location', () {
      expect(explanationFailureFor(InvalidApiKey('bad key')), rejected());
      expect(
        explanationFailureFor(ServiceApiNotEnabled('projects/p')),
        rejected(),
      );
      expect(explanationFailureFor(UnsupportedUserLocation()), rejected());
    });

    test('a quota that is used up', () {
      expect(explanationFailureFor(QuotaExceeded('too many')), rejected());
    });

    test('an answer that was blocked', () {
      expect(
        explanationFailureFor(FirebaseAIException('Response was blocked')),
        rejected(),
      );
    });

    test('keeps the original error as the cause', () {
      final error = QuotaExceeded('too many');

      expect(
        explanationFailureFor(error),
        ExplainerRejectedFailure(cause: error),
      );
    });
  });

  group('anything else', () {
    test('a server error is a general failure', () {
      expect(explanationFailureFor(ServerException('500')), other());
    });

    test('an SDK error is a general failure', () {
      expect(
        explanationFailureFor(FirebaseAISdkException('new format')),
        other(),
      );
    });

    test('a Firebase error from another plugin is a general failure', () {
      final error = FirebaseException(plugin: 'firebase_core', code: 'x');

      expect(explanationFailureFor(error), other());
    });

    test('an unknown exception is a general failure with its cause', () {
      final error = Exception('boom');

      expect(explanationFailureFor(error), ExplainerFailure(cause: error));
    });

    test('a failure of ours is passed on as it is', () {
      expect(
        explanationFailureFor(const ExplainerTimeoutFailure()),
        const ExplainerTimeoutFailure(),
      );
    });
  });
}
