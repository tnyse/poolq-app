import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCU2asf-nn87qKzce35EuIR232s5CvaVhE",
    authDomain: "nflgamesapp.firebaseapp.com",
    projectId: "nflgamesapp",
    storageBucket: "nflgamesapp.appspot.com",
    messagingSenderId: "849141363382",
    appId: "1:849141363382:web:120b57263ede3d58a5ac17",
    measurementId: "G-C1W9FCRVR4",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "nflgamesapp",
    storageBucket: "dummy",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "nflgamesapp",
    storageBucket: "dummy",
    iosClientId: "dummy",
    iosBundleId: "dummy",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "nflgamesapp",
    storageBucket: "dummy",
    iosClientId: "dummy",
    iosBundleId: "dummy",
  );
}