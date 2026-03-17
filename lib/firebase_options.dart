import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web; 

    switch (defaultTargetPlatform) {
      case TargetPlatform.android: 
        return android; // Nyní už odkazuje na existující proměnnou níže
      case TargetPlatform.windows: 
        return windows;
      default: 
        throw UnsupportedError('Platforma není podporována');
    }
  }

  // --- ÚDAJE PRO ANDROID ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArDFFYxygQaedguSm0mVIPiOSNE4bB4J0',
    appId: '1:556461457278:android:4d51c855fe9455b9a67d2f',
    messagingSenderId: '556461457278',
    projectId: 'aplikace-auto',
    storageBucket: 'aplikace-auto.firebasestorage.app',
  );

  // --- ÚDAJE PRO WEB ---
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyArDFFYxygQaedguSm0mVIPiOSNE4bB4J0',
    appId: '1:556461457278:android:4d51c855fe9455b9a67d2f',
    messagingSenderId: '556461457278',
    projectId: 'aplikace-auto',
    storageBucket: 'aplikace-auto.firebasestorage.app',
  );

  static const FirebaseOptions windows = web;
}