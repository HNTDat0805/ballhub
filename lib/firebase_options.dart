// Tệp được tạo tự động bởi FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình [FirebaseOptions] mặc định cho ứng dụng Firebase của bạn.
///
/// Ví dụ sử dụng:
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLm8rJ4j7SKUc88i8xMAQwZwsqSVErDUI',
    appId: '1:756451917358:web:27f59db37ecd3ee505e9bf',
    messagingSenderId: '756451917358',
    projectId: 'ballhub-ac5a7',
    authDomain: 'ballhub-ac5a7.firebaseapp.com',
    storageBucket: 'ballhub-ac5a7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCQ3si8bILqjw_FS0cDeUZ8y8v2S1ELigs',
    appId: '1:756451917358:android:d071a98cbb81ea9c05e9bf',
    messagingSenderId: '756451917358',
    projectId: 'ballhub-ac5a7',
    storageBucket: 'ballhub-ac5a7.firebasestorage.app',
  );
}
