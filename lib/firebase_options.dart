// Firebase project "emplake-rm-jl" (Spark plan). The app is delivered for the
// web; run `flutterfire configure` to add other platforms.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Run `flutterfire configure` for $defaultTargetPlatform.');
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAdqygUk7nEXNrNDsfylummHcpeh7hB1e4',
    appId: '1:78981553218:web:19d03bdbb996eb508fa1db',
    messagingSenderId: '78981553218',
    projectId: 'emplake-rm-jl',
    authDomain: 'emplake-rm-jl.firebaseapp.com',
    storageBucket: 'emplake-rm-jl.firebasestorage.app',
  );
}
