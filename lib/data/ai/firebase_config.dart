import 'package:firebase_core/firebase_core.dart';

/// Firebase settings, read from `--dart-define-from-file=firebase.local.json`
/// at build time. The file is not in the repo, so a build without it simply has
/// no AI section.
class FirebaseConfig {
  const FirebaseConfig({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.senderId,
    this.appCheckDebugToken = '',
  });

  factory FirebaseConfig.fromEnvironment() => const FirebaseConfig(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    senderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    appCheckDebugToken: String.fromEnvironment('FIREBASE_APPCHECK_DEBUG_TOKEN'),
  );

  final String apiKey;
  final String appId;
  final String projectId;
  final String senderId;

  /// A token registered in the console, used only by debug builds.
  final String appCheckDebugToken;

  bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      projectId.isNotEmpty &&
      senderId.isNotEmpty;

  FirebaseOptions toOptions() => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
  );
}
