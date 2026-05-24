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
    apiKey: 'AIzaSyBf8Pc1wdqhPbfEXSX7PIdjPxLHeAM3OW0',
    appId: '1:440899815896:web:60da2429638ff853360aad',
    messagingSenderId: '440899815896',
    projectId: 'flutter3-82336',
    authDomain: 'flutter3-82336.firebaseapp.com',
    storageBucket: 'flutter3-82336.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDoD6ZXOMdn1n_9z65U3NDYffqZ87pST38',
    appId: '1:440899815896:android:7ce920eace62e6fb360aad',
    messagingSenderId: '440899815896',
    projectId: 'flutter3-82336',
    storageBucket: 'flutter3-82336.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzAvTEoDwfofznPzSyK0LuSggoQWop1v8',
    appId: '1:440899815896:ios:0489e95bb986a5e5360aad',
    messagingSenderId: '440899815896',
    projectId: 'flutter3-82336',
    storageBucket: 'flutter3-82336.firebasestorage.app',
    androidClientId: '440899815896-3li9ri1386edg4vs8n1s4gc7fs3d5ohi.apps.googleusercontent.com',
    iosClientId: '440899815896-t4trveucdjoo5p4cv147mrd88c4qsfr4.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutter93',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCzAvTEoDwfofznPzSyK0LuSggoQWop1v8',
    appId: '1:440899815896:ios:0489e95bb986a5e5360aad',
    messagingSenderId: '440899815896',
    projectId: 'flutter3-82336',
    storageBucket: 'flutter3-82336.firebasestorage.app',
    androidClientId: '440899815896-3li9ri1386edg4vs8n1s4gc7fs3d5ohi.apps.googleusercontent.com',
    iosClientId: '440899815896-t4trveucdjoo5p4cv147mrd88c4qsfr4.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutter93',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBf8Pc1wdqhPbfEXSX7PIdjPxLHeAM3OW0',
    appId: '1:440899815896:web:e033a145f0aad140360aad',
    messagingSenderId: '440899815896',
    projectId: 'flutter3-82336',
    authDomain: 'flutter3-82336.firebaseapp.com',
    storageBucket: 'flutter3-82336.firebasestorage.app',
  );
}
