import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // =========================================================
  // INIT NOTIFICATION
  // =========================================================
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // =====================================================
      // ANDROID INIT
      // =====================================================
      const android =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // =====================================================
      // IOS INIT
      // =====================================================
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // =====================================================
      // INITIALIZE
      // =====================================================
      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: ios,
        ),
      );

      // =====================================================
      // REQUEST PERMISSION
      // =====================================================
      final androidImpl =
          _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        await androidImpl
            .requestNotificationsPermission();
      }

      _initialized = true;

      debugPrint(
        "✅ Notification initialized",
      );
    } catch (e) {
      debugPrint(
        "❌ Notification init error: $e",
      );
    }
  }

  // =========================================================
  // FORMAT TANGGAL
  // =========================================================
  static String today() {
    final now = DateTime.now();

    return
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // =========================================================
  // CEK ABSENSI MASUK
  // =========================================================
  static Future<bool> sudahAbsenHariIni() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) return true;

      final result = await Supabase.instance.client
          .from('absensi')
          .select('id')
          .eq('user_id', user.id)
          .eq('tanggal', today())
          .limit(1);

      return result.isNotEmpty;
    } catch (e) {
      debugPrint(
        "❌ Error cek absensi: $e",
      );

      return true;
    }
  }

  // =========================================================
  // CEK ABSENSI PULANG
  // =========================================================
  static Future<bool>
      sudahAbsenPulangHariIni() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) return true;

      final result = await Supabase.instance.client
          .from('absensi')
          .select('jam_pulang')
          .eq('user_id', user.id)
          .eq('tanggal', today())
          .limit(1);

      if (result.isEmpty) return false;

      final jamPulang =
          result.first['jam_pulang'];

      return jamPulang != null &&
          jamPulang.toString().isNotEmpty;
    } catch (e) {
      debugPrint(
        "❌ Error cek absensi pulang: $e",
      );

      return true;
    }
  }

  // =========================================================
  // CEK LOGBOOK
  // =========================================================
  static Future<bool>
      sudahIsiLogbookHariIni() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) return true;

      final result = await Supabase.instance.client
          .from('logbook')
          .select('id')
          .eq('user_id', user.id)
          .eq('tanggal', today())
          .limit(1);

      return result.isNotEmpty;
    } catch (e) {
      debugPrint(
        "❌ Error cek logbook: $e",
      );

      return true;
    }
  }

  // =========================================================
  // SHOW NOTIFICATION
  // =========================================================
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'digilok_channel',
            'DIGILOK Notification',
            channelDescription:
                'Notifikasi DIGILOK',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),

          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "❌ Notification error: $e",
      );
    }
  }

  // =========================================================
  // CHECK REMINDER
  // =========================================================
  static Future<void>
      checkTodayReminder() async {
    try {
      final now = DateTime.now();

      // =====================================================
      // ABSENSI MASUK
      // =====================================================
      if (now.hour >= 9) {
        final sudahAbsen =
            await sudahAbsenHariIni();

        if (!sudahAbsen) {
          await showNotification(
            id: 100,

            title: '📍 Reminder Absensi',

            body:
                'Kamu belum melakukan absensi hari ini.',
          );
        }
      }

      // =====================================================
      // LOGBOOK
      // =====================================================
      if (now.hour >= 12) {
        final sudahLogbook =
            await sudahIsiLogbookHariIni();

        if (!sudahLogbook) {
          await showNotification(
            id: 101,

            title: '📝 Reminder Logbook',

            body:
                'Jangan lupa isi logbook hari ini.',
          );
        }
      }

      // =====================================================
      // ABSENSI PULANG
      // =====================================================
      if (now.hour >= 16) {
        final sudahPulang =
            await sudahAbsenPulangHariIni();

        if (!sudahPulang) {
          await showNotification(
            id: 102,

            title:
                '🏠 Reminder Absen Pulang',

            body:
                'Jangan lupa melakukan absensi pulang.',
          );
        }
      }
    } catch (e) {
      debugPrint(
        "❌ Reminder error: $e",
      );
    }
  }

  // =========================================================
  // CANCEL ALL NOTIFICATION
  // =========================================================
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint(
        "❌ Cancel notification error: $e",
      );
    }
  }
}