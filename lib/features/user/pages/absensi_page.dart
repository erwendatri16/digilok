import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() =>
      _AbsensiPageState();
}

class _AbsensiPageState
    extends State<AbsensiPage> {
  Map<String, dynamic>? setting;

  bool sudahMasuk = false;
  bool sudahPulang = false;
  bool isLoading = true;

  // =====================================================
  // CLOCK REALTIME RINGAN
  // =====================================================
  DateTime currentTime = DateTime.now();

  Timer? clockTimer;

  // =====================================================
  // HELPER
  // =====================================================
  TimeOfDay parseTime(String time) {
    final parts = time.split(":");

    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  int toMinutes(TimeOfDay t) {
    return t.hour * 60 + t.minute;
  }

  String formatTime(TimeOfDay t) {
    return
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  String todayString() {
    return DateTime.now()
        .toIso8601String()
        .split("T")[0];
  }

  // =====================================================
  // INIT
  // =====================================================
  @override
  void initState() {
    super.initState();

    initAll();

    // ===================================================
    // TIMER JAM REALTIME
    // ===================================================
    clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            currentTime = DateTime.now();
          });
        }
      },
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================
  @override
  void dispose() {
    clockTimer?.cancel();

    super.dispose();
  }

  // =====================================================
  // INIT ALL
  // =====================================================
  Future<void> initAll() async {
    try {
      await loadSetting();

      await cekStatusHariIni();
    } catch (e) {
      showFloatingNotification(
        "Gagal memuat data",
        false,
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // LOAD SETTING
  // =====================================================
  Future<void> loadSetting() async {
    try {
      setting = await Supabase
          .instance.client
          .from('pengaturan_absensi')
          .select()
          .limit(1)
          .maybeSingle();
    } catch (e) {
      showFloatingNotification(
        "Gagal memuat pengaturan absensi",
        false,
      );
    }
  }

  // =====================================================
  // GET ABSENSI HARI INI
  // =====================================================
  Future<Map?> getTodayAbsensi() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    return await Supabase.instance.client
        .from('absensi')
        .select()
        .eq('user_id', user!.id)
        .eq('tanggal', todayString())
        .maybeSingle();
  }

  // =====================================================
  // CEK STATUS
  // =====================================================
  Future<void> cekStatusHariIni() async {
    final data = await getTodayAbsensi();

    if (data != null) {
      sudahMasuk =
          data['jam_masuk'] != null;

      sudahPulang =
          data['jam_pulang'] != null;
    }
  }

  // =====================================================
  // CEK RADIUS GPS
  // =====================================================
  Future<bool> cekRadius() async {
    try {
      if (setting == null ||
          setting!['latitude'] == null ||
          setting!['longitude'] == null) {
        showFloatingNotification(
          "Lokasi kantor belum diatur",
          false,
        );

        return false;
      }

      // ===============================================
      // CEK SERVICE GPS
      // ===============================================
      bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        showFloatingNotification(
          "GPS perangkat tidak aktif",
          false,
        );

        return false;
      }

      // ===============================================
      // CEK PERMISSION
      // ===============================================
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        showFloatingNotification(
          "Izin lokasi ditolak",
          false,
        );

        return false;
      }

      // ===============================================
      // GET POSITION (RINGAN)
      // ===============================================
      final pos =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.medium,
      );

      final jarak =
          Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        setting!['latitude'],
        setting!['longitude'],
      );

      final radius =
          setting!['radius'] ?? 100;

      if (jarak > radius) {
        showFloatingNotification(
          "Diluar radius kantor (${jarak.toInt()} meter)",
          false,
        );

        return false;
      }

      return true;
    } catch (e) {
      showFloatingNotification(
        "Gagal mendeteksi GPS",
        false,
      );

      return false;
    }
  }

  // =====================================================
  // ABSEN MASUK
  // =====================================================
  Future<void> absenMasuk() async {
    try {
      if (sudahMasuk) {
        showFloatingNotification(
          "Sudah absen masuk",
          false,
        );

        return;
      }

      if (!await cekRadius()) return;

      final user =
          Supabase.instance.client.auth.currentUser;

      final now = TimeOfDay.now();

      String status = "Hadir";

      if (setting != null &&
          setting!['jam_masuk_akhir'] != null) {
        final akhir = parseTime(
          setting!['jam_masuk_akhir'],
        );

        if (toMinutes(now) >
            toMinutes(akhir)) {
          status = "Terlambat";
        }
      }

      await Supabase.instance.client
          .from('absensi')
          .insert({
        'user_id': user!.id,
        'tanggal': todayString(),
        'jam_masuk': formatTime(now),
        'status_masuk': status,
      });

      if (!mounted) return;

      setState(() {
        sudahMasuk = true;
      });

      showFloatingNotification(
        "Absen masuk berhasil ($status)",
        true,
      );
    } catch (e) {
      showFloatingNotification(
        "Error absen masuk",
        false,
      );
    }
  }

  // =====================================================
  // ABSEN PULANG
  // =====================================================
  Future<void> absenPulang() async {
    try {
      if (!sudahMasuk) {
        showFloatingNotification(
          "Belum absen masuk",
          false,
        );

        return;
      }

      if (sudahPulang) {
        showFloatingNotification(
          "Sudah absen pulang",
          false,
        );

        return;
      }

      if (!await cekRadius()) return;

      final existing =
          await getTodayAbsensi();

      if (existing == null) {
        showFloatingNotification(
          "Data absensi tidak ditemukan",
          false,
        );

        return;
      }

      final now = TimeOfDay.now();

      String status = "Pulang";

      if (setting != null &&
          setting!['jam_pulang'] != null) {
        final pulang = parseTime(
          setting!['jam_pulang'],
        );

        if (toMinutes(now) <
            toMinutes(pulang)) {
          status = "Pulang Cepat";
        }
      }

      await Supabase.instance.client
          .from('absensi')
          .update({
        'jam_pulang': formatTime(now),
        'status_pulang': status,
      }).eq('id', existing['id']);

      if (!mounted) return;

      setState(() {
        sudahPulang = true;
      });

      showFloatingNotification(
        "Absen pulang berhasil ($status)",
        true,
      );
    } catch (e) {
      showFloatingNotification(
        "Error absen pulang",
        false,
      );
    }
  }

  // =====================================================
  // SNACKBAR
  // =====================================================
  void showFloatingNotification(
    String msg,
    bool isSuccess,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        behavior:
            SnackBarBehavior.floating,

        backgroundColor: isSuccess
            ? const Color(0xFF10B981)
            : Colors.redAccent,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),

        margin: const EdgeInsets.all(16),

        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: const Text(
          "Absensi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,

        foregroundColor: Colors.black,

        elevation: 0.5,
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Color(0xFF6C63FF),
              ),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),

              child: Column(
                children: [
                  infoCard(),

                  const SizedBox(height: 24),

                  jamDinamisCard(),

                  const SizedBox(height: 32),

                  tombolAbsensi(),
                ],
              ),
            ),
    );
  }

  // =====================================================
  // INFO CARD
  // =====================================================
  Widget infoCard() {
    final formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF8A84FF),
          ],
        ),

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            formattedDate,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (setting != null) ...[
            Text(
              "Masuk : ${setting!['jam_masuk_mulai']} - ${setting!['jam_masuk_akhir']}",

              style: const TextStyle(
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Pulang : ${setting!['jam_pulang']}",

              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // JAM DIGITAL
  // =====================================================
  Widget jamDinamisCard() {
    final stringJam =
        DateFormat('HH:mm:ss')
            .format(currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),

      child: Column(
        children: [
          Text(
            stringJam,

            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            sudahPulang
                ? "Presensi lengkap hari ini"
                : sudahMasuk
                    ? "Waktunya fokus bekerja"
                    : "Silakan lakukan absen masuk",

            style: TextStyle(
              fontSize: 13,

              color:
                  sudahPulang || sudahMasuk
                      ? const Color(0xFF10B981)
                      : Colors.amber[800],

              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // BUTTON ABSENSI
  // =====================================================
  Widget tombolAbsensi() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed:
                sudahMasuk
                    ? null
                    : absenMasuk,

            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF10B981),

              padding:
                  const EdgeInsets.symmetric(
                vertical: 20,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),

            child: Text(
              sudahMasuk
                  ? "Sudah Masuk"
                  : "Absen Masuk",
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: ElevatedButton(
            onPressed:
                (!sudahMasuk || sudahPulang)
                    ? null
                    : absenPulang,

            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFEF4444),

              padding:
                  const EdgeInsets.symmetric(
                vertical: 20,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),

            child: Text(
              sudahPulang
                  ? "Sudah Pulang"
                  : "Absen Pulang",
            ),
          ),
        ),
      ],
    );
  }
}