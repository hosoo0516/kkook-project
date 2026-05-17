import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAs_DummyKeyForSetup_PleaseCheckConsole',
    authDomain: 'kkook-fd367.firebaseapp.com',
    projectId: 'kkook-fd367',
    storageBucket: 'kkook-fd367.firebasestorage.app',
    messagingSenderId: '1234567890',
    appId: '1:1234567890:web:dummyappid12345',
  );
}