
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel notificationChannel =
    AndroidNotificationChannel(
  'moneytrack_channel',
  'MoneyTrack Notifications',
  description: 'Notifikasi dari aplikasi MoneyTrack',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Notifikasi background: ${message.messageId}');
  debugPrint('Judul: ${message.notification?.title}');
  debugPrint('Isi: ${message.notification?.body}');
}

class NotificationService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Meminta izin notifikasi
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Status izin notifikasi: ${settings.authorizationStatus}');

    // Inisialisasi notifikasi lokal
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await localNotifications.initialize(
  settings: initializationSettings,
);

    // Membuat channel notifikasi Android
    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(notificationChannel);

    // Mengambil token FCM
    final token = await messaging.getToken();

    debugPrint('================================');
    debugPrint('FCM TOKEN MONEYTRACK:');
    debugPrint(token);
    debugPrint('================================');

    // Memantau perubahan token
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM TOKEN BARU: $newToken');
    });

    // Menampilkan notifikasi saat aplikasi terbuka
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Notifikasi diterima: ${message.notification?.title}');
      debugPrint('Isi: ${message.notification?.body}');

      final notification = message.notification;

      if (notification != null) {
        await localNotifications.show(
  id: message.hashCode,
  title: notification.title ?? 'MoneyTrack',
  body: notification.body ?? 'Ada pemberitahuan baru',
  notificationDetails: NotificationDetails(
    android: AndroidNotificationDetails(
      notificationChannel.id,
      notificationChannel.name,
      channelDescription: notificationChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  ),
);
      }
    });

    // Saat pengguna membuka notifikasi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Aplikasi dibuka melalui notifikasi');
    });

    // Jika aplikasi dibuka dari kondisi tertutup melalui notifikasi
    final initialMessage = await messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('Aplikasi dibuka dari notifikasi awal');
    }
  }
}
