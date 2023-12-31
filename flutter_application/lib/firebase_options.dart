// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCkDTkClvcvZrpQv3OtPjUUOH7vw_8ZMu8',
    appId: '1:823124571438:web:4af5d5627750ca9625f6bf',
    messagingSenderId: '823124571438',
    projectId: 'flutter-project-383010',
    authDomain: 'flutter-project-383010.firebaseapp.com',
    storageBucket: 'flutter-project-383010.appspot.com',
    measurementId: 'G-TNDGC7TKB1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAySEaSkdQk-rQC81rffsqtlWxMWNoNw6U',
    appId: '1:823124571438:android:4e4b09cee2a8ac6b25f6bf',
    messagingSenderId: '823124571438',
    projectId: 'flutter-project-383010',
    storageBucket: 'flutter-project-383010.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB1e7y5_flVdPpiclo_53p7lZAqRxZr7T4',
    appId: '1:823124571438:ios:26f8738f975854f325f6bf',
    messagingSenderId: '823124571438',
    projectId: 'flutter-project-383010',
    storageBucket: 'flutter-project-383010.appspot.com',
    iosClientId:
        '823124571438-2od282ji3ndd49172k205m7t3cnuo93i.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB1e7y5_flVdPpiclo_53p7lZAqRxZr7T4',
    appId: '1:823124571438:ios:e63e601e4cfe80e225f6bf',
    messagingSenderId: '823124571438',
    projectId: 'flutter-project-383010',
    storageBucket: 'flutter-project-383010.appspot.com',
    iosClientId:
        '823124571438-482i9tol0ruo5vu7flmrkkp83fuat9aa.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication.RunnerTests',
  );
}
