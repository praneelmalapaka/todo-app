import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Firebase configuration for web
      return FirebaseOptions(
        apiKey: "AIzaSyBxP7D1R0G0ugAt4cQwi8YclzO2PcGieTE",
        authDomain: "todo-app-7e695.firebaseapp.com",
        projectId: "todo-app-7e695",
        storageBucket: "todo-app-7e695.firebasestorage.app",
        messagingSenderId: "1053752620044",
        appId: "1:1053752620044:web:d375f293ee1119ca84ea29",
        measurementId: "G-6Y8KB8XD5V"
      );
    } else if (Platform.isWindows) {
      // Firebase configuration for Windows
      return FirebaseOptions(
        apiKey: "AIzaSyBxP7D1R0G0ugAt4cQwi8YclzO2PcGieTE",
        authDomain: "todo-app-7e695.firebaseapp.com",
        projectId: "todo-app-7e695",
        storageBucket: "todo-app-7e695.firebasestorage.app",
        messagingSenderId: "1053752620044",
        appId: "1:1053752620044:web:abf9d0254edeb6b784ea29",
        measurementId: "G-2WFFEGXFDC"
      );
    } else if (Platform.isAndroid) {
      // Firebase configuration for Android
      return FirebaseOptions(
        apiKey: "AIzaSyA17SNvRqTICxBfahDRiqsj1Fl0rRsMBQg", // Replace with your API key
        appId: "1:1053752620044:web:abf9d0254edeb6b784ea29",   // Replace with your app ID
        messagingSenderId: "1053752620044", // Replace with your sender ID
        projectId: "todo-app-7e695", // Replace with your project ID
      );
    } else if (Platform.isIOS) {
      // Firebase configuration for iOS
      return FirebaseOptions(
        apiKey: "AIzaSyA17SNvRqTICxBfahDRiqsj1Fl0rRsMBQg", // Replace with your API key
        appId: "1:1053752620044:web:abf9d0254edeb6b784ea29",   // Replace with your app ID
        messagingSenderId: "1053752620044", // Replace with your sender ID
        projectId: "todo-app-7e695", // Replace with your project ID
      );
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
