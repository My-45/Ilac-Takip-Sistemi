// import işlemleri web için vs
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// uygulamanın hangi platformda çalıştıgına dair paltform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
  // web için gereksinimler
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '"AIzaSyDOlJfVsKnEfKHcYCNabuTP2cOT2uwnBkg"',
    appId: '1:316215060536:web:ee331eb539cd8b68ae5ecd',
    messagingSenderId: '316215060536',
    projectId: 'ilac-takip-sistemi-38c3d',
    authDomain: 'ilac-takip-sistemi-38c3d.firebaseapp.com',
    databaseURL: 'https://ilac-takip-sistemi-38c3d-default-rtdb.firebaseio.com',
    storageBucket: 'ilac-takip-sistemi-38c3d.firebasestorage.app',
    measurementId: 'G-XPMDJ6CVPJ',
  );
  // android için gereksinimler 
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeBFpKF8_ok2C1jA_UYQco1ZfSuhLe9Po',
    appId: '1:316215060536:android:85ced8996ee66852ae5ecd',
    messagingSenderId: '316215060536',
    projectId: 'ilac-takip-sistemi-38c3d',
    databaseURL: 'https://ilac-takip-sistemi-38c3d-default-rtdb.firebaseio.com',
    storageBucket: 'ilac-takip-sistemi-38c3d.firebasestorage.app',
  );
}