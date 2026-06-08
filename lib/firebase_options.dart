import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

// All values must be passed via --dart-define at build time.
// Example:
//   flutter build apk \
//     --dart-define=FIREBASE_API_KEY=xxx \
//     --dart-define=FIREBASE_APP_ID=xxx \
//     --dart-define=FIREBASE_MESSAGING_SENDER_ID=xxx \
//     --dart-define=FIREBASE_PROJECT_ID=xxx \
//     --dart-define=LICENSE_HASH=xxx \
//     --dart-define=LICENSE_SALT=xxx

const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.windows:
        return _windows;
      default:
        return _android;
    }
  }

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions _windows = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );
}
