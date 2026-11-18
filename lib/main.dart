
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'service/notification_service.dart';

@pragma('vm:entry-point')
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Mendaftarkan handler notifikasi background
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Inisialisasi layanan notifikasi dan mengambil token FCM
  await NotificationService.initialize();

  // Menjalankan aplikasi
  runApp(const MoneyTrackApp());
}
