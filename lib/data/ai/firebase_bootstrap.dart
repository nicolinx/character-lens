import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:character_lens/data/ai/firebase_config.dart';

/// Starts Firebase and App Check. Returns false, and leaves the rest of the app
/// untouched, when there are no settings or Firebase cannot start.
Future<bool> startFirebase(FirebaseConfig config) async {
  if (!config.isConfigured) return false;
  try {
    await Firebase.initializeApp(options: config.toOptions());
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(
              debugToken: config.appCheckDebugToken.isEmpty
                  ? null
                  : config.appCheckDebugToken,
            )
          : const AndroidPlayIntegrityProvider(),
    );
    return true;
  } on Exception catch (e) {
    debugPrint('Firebase did not start: $e');
    return false;
  }
}
