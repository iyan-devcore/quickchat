// File generated manually based on user's firebaseConfig.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDTHKXGmleoU4b5A38HoCPX0uHjnfkM7mw',
    appId: '1:706864127326:web:9ac840eb5f9360957a43cf',
    messagingSenderId: '706864127326',
    projectId: 'quickchat-edf04',
    authDomain: 'quickchat-edf04.firebaseapp.com',
    storageBucket: 'quickchat-edf04.firebasestorage.app',
    measurementId: 'G-19SQR26M7E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTHKXGmleoU4b5A38HoCPX0uHjnfkM7mw',
    appId: '1:706864127326:android:replaceme', // Note: Only web config provided
    messagingSenderId: '706864127326',
    projectId: 'quickchat-edf04',
    storageBucket: 'quickchat-edf04.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTHKXGmleoU4b5A38HoCPX0uHjnfkM7mw',
    appId: '1:706864127326:ios:replaceme', // Note: Only web config provided
    messagingSenderId: '706864127326',
    projectId: 'quickchat-edf04',
    storageBucket: 'quickchat-edf04.firebasestorage.app',
    iosBundleId: 'com.example.quickchat',
  );
}
