import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase 프로젝트: kkook-fd367
///
/// 실제 키는 Firebase Console 또는 `flutterfire configure`로 생성한 값으로
/// 교체해야 합니다. 아래 값은 플레이스홀더입니다.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions: Linux는 아직 설정되지 않았습니다.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions: 지원하지 않는 플랫폼입니다.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJH9ZgJjL7-ZnqCCo7jP7yX4yCFoOAXO4',
    appId: '1:366143800773:web:35e2c7a9f185a2b53877ac',
    messagingSenderId: '366143800773',
    projectId: 'kkook-fd367',
    authDomain: 'kkook-fd367.firebaseapp.com',
    storageBucket: 'kkook-fd367.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJH9ZgJjL7-ZnqCCo7jP7yX4yCFoOAXO4',
    appId: '1:366143800773:android:35e2c7a9f185a2b53877ac',
    messagingSenderId: '366143800773',
    projectId: 'kkook-fd367',
    storageBucket: 'kkook-fd367.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAs_DummyKeyForSetup_PleaseCheckConsole',
    appId: '1:1234567890:ios:dummyappid12345',
    messagingSenderId: '1234567890',
    projectId: 'kkook-fd367',
    storageBucket: 'kkook-fd367.firebasestorage.app',
    iosBundleId: 'com.example.kkookTest1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAs_DummyKeyForSetup_PleaseCheckConsole',
    appId: '1:1234567890:ios:dummyappid12345',
    messagingSenderId: '1234567890',
    projectId: 'kkook-fd367',
    storageBucket: 'kkook-fd367.firebasestorage.app',
    iosBundleId: 'com.example.kkookTest1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAs_DummyKeyForSetup_PleaseCheckConsole',
    appId: '1:1234567890:web:dummyappid12345',
    messagingSenderId: '1234567890',
    projectId: 'kkook-fd367',
    authDomain: 'kkook-fd367.firebaseapp.com',
    storageBucket: 'kkook-fd367.firebasestorage.app',
  );
}
