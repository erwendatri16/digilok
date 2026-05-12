import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/auth/pages/splash_page.dart';
import 'features/auth/pages/login_page.dart';

import 'features/user/services/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // =====================================================
    // FORMAT TANGGAL INDONESIA
    // =====================================================
    await initializeDateFormatting(
      'id_ID',
      null,
    );

    // =====================================================
    // INIT SUPABASE
    // =====================================================
    await Supabase.initialize(
      url:
          'https://ndtatoyctayebjszwvpz.supabase.co',

      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kdGF0b3ljdGF5ZWJqc3p3dnB6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3OTUwNzIsImV4cCI6MjA5MzM3MTA3Mn0.eZ8ceZCDsNkIIKJZ6dWqY2TSPQB_7IziTXzkuf4VPpU',
    );

    debugPrint(
      "✅ Supabase berhasil diinisialisasi",
    );

    // =====================================================
    // INIT NOTIFICATION
    // =====================================================
    await NotificationService.init();

    debugPrint(
      "✅ Notification berhasil diinisialisasi",
    );
  } catch (e) {
    debugPrint(
      "❌ Error inisialisasi aplikasi: $e",
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'DIGILOK',

      // =====================================================
      // THEME APP
      // =====================================================
      theme: ThemeData(
        useMaterial3: true,

        fontFamily: 'Roboto',

        primaryColor: const Color(0xFF6C63FF),

        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF6C63FF),

            foregroundColor: Colors.white,

            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
        ),

        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,

          fillColor: Colors.grey.shade100,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide.none,
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: const BorderSide(
              color: Color(0xFF6C63FF),
              width: 1.5,
            ),
          ),
        ),
      ),

      // =====================================================
      // CHECK REMINDER BACKGROUND
      // =====================================================
      builder: (context, child) {
        Future.microtask(() async {
          try {
            await NotificationService
                .checkTodayReminder();
          } catch (e) {
            debugPrint(
              "❌ Reminder error: $e",
            );
          }
        });

        return child!;
      },

      // =====================================================
      // HALAMAN AWAL
      // =====================================================
      home: const SplashPage(),

      // =====================================================
      // ROUTES
      // =====================================================
      routes: {
        '/login': (context) =>
            const LoginPage(),

        '/splash': (context) =>
            const SplashPage(),
      },
    );
  }
}