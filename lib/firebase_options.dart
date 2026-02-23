// Archivo generado normalmente por: dart run flutterfire_cli:flutterfire configure
// Si usas Firebase en producción, ejecuta ese comando y reemplaza los valores.

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDpyLbmAz5Og1ophNmwGyoBRjd8R4qYsao',
    appId: '1:706676694047:web:8661f176b1d0d95862092a',
    messagingSenderId: '706676694047',
    projectId: 'govconnect-8fb26',
    authDomain: 'govconnect-8fb26.firebaseapp.com',
    storageBucket: 'govconnect-8fb26.firebasestorage.app',
    measurementId: 'G-V8N7SBG30R',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDun4FgUccfdhlyYn_sagJBrCL0gUfCv5U',
    appId: '1:706676694047:android:e6411fb477b4269d62092a',
    messagingSenderId: '706676694047',
    projectId: 'govconnect-8fb26',
    storageBucket: 'govconnect-8fb26.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAzYV-yUurRuhQBZuZ8tHErfe2UYCxsWqU',
    appId: '1:706676694047:ios:9b20ca9387908c5d62092a',
    messagingSenderId: '706676694047',
    projectId: 'govconnect-8fb26',
    storageBucket: 'govconnect-8fb26.firebasestorage.app',
    iosClientId: '706676694047-2j2fsieom1i591h63dfh7u80ip4thpco.apps.googleusercontent.com',
    iosBundleId: 'com.example.govconnect',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAzYV-yUurRuhQBZuZ8tHErfe2UYCxsWqU',
    appId: '1:706676694047:ios:9b20ca9387908c5d62092a',
    messagingSenderId: '706676694047',
    projectId: 'govconnect-8fb26',
    storageBucket: 'govconnect-8fb26.firebasestorage.app',
    iosClientId: '706676694047-2j2fsieom1i591h63dfh7u80ip4thpco.apps.googleusercontent.com',
    iosBundleId: 'com.example.govconnect',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDpyLbmAz5Og1ophNmwGyoBRjd8R4qYsao',
    appId: '1:706676694047:web:caae50789c2c64be62092a',
    messagingSenderId: '706676694047',
    projectId: 'govconnect-8fb26',
    authDomain: 'govconnect-8fb26.firebaseapp.com',
    storageBucket: 'govconnect-8fb26.firebasestorage.app',
    measurementId: 'G-VW8QLVHVL1',
  );

}