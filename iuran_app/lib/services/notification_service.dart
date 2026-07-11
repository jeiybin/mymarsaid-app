import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Inisialisasi Firebase Cloud Messaging
  static Future<void> initialize() async {
    // Meminta izin notifikasi
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint(
      "Status Permission: ${settings.authorizationStatus}",
    );

    // Mengambil FCM Token
    String? token = await _firebaseMessaging.getToken();

    debugPrint("================================");
    debugPrint("FCM TOKEN");
    debugPrint(token);
    debugPrint("================================");

    // Saat token berubah
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("TOKEN BARU");
      debugPrint(newToken);

      // Nanti kita kirim ke Flask
      // saveToken(newToken);
    });

    // Notifikasi diterima saat aplikasi sedang dibuka
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("NOTIFIKASI MASUK");

      debugPrint(
        message.notification?.title,
      );

      debugPrint(
        message.notification?.body,
      );
    });

    // User menekan notifikasi
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint("NOTIFIKASI DIBUKA");
      },
    );
  }
}