import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  Map<String, dynamic>? setting;

  bool sudahMasuk = false;
  bool sudahPulang = false;
  bool isLoading = true;

  // =====================================================
  // CLOCK REALTIME
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

  int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String formatTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  String todayString() =>
      DateTime.now().toIso8601String().split("T")[0];

  // =====================================================
  // INIT
  // =====================================================
  @override
  void initState() {
    super.initState();
    initAll();
    clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => currentTime = DateTime.now());
      },
    );
  }

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
      showFloatingNotification("Gagal memuat data", false);
    }
    if (mounted) setState(() => isLoading = false);
  }

  // =====================================================
  // LOAD SETTING
  // =====================================================
  Future<void> loadSetting() async {
    try {
      setting = await Supabase.instance.client
          .from('pengaturan_absensi')
          .select()
          .limit(1)
          .maybeSingle();
    } catch (e) {
      showFloatingNotification("Gagal memuat pengaturan absensi", false);
    }
  }

  // =====================================================
  // GET ABSENSI HARI INI
  // =====================================================
  Future<Map?> getTodayAbsensi() async {
    final user = Supabase.instance.client.auth.currentUser;
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
      sudahMasuk = data['jam_masuk'] != null;
      sudahPulang = data['jam_pulang'] != null;
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
        showFloatingNotification("Lokasi kantor belum diatur", false);
        return false;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showFloatingNotification("GPS perangkat tidak aktif", false);
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showFloatingNotification("Izin lokasi ditolak", false);
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final jarak = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        setting!['latitude'],
        setting!['longitude'],
      );

      final radius = setting!['radius'] ?? 100;

      if (jarak > radius) {
        showFloatingNotification(
          "Diluar radius kantor (${jarak.toInt()} meter)",
          false,
        );
        return false;
      }

      return true;
    } catch (e) {
      showFloatingNotification("Gagal mendeteksi GPS", false);
      return false;
    }
  }

  // =====================================================
  // DIALOG: SUDAH ABSEN (proteksi double absen)
  // =====================================================
  void showSudahAbsenDialog(String tipe) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Sudah Absen $tipe",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Kamu sudah melakukan absen $tipe hari ini.\nDouble absen tidak diperbolehkan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Mengerti",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DIALOG: KONFIRMASI SEBELUM ABSEN
  // =====================================================
  Future<bool> showKonfirmasiDialog(String tipe) async {
    final now = TimeOfDay.now();
    final jamSekarang = formatTime(now);
    final warna = tipe == "Masuk"
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final icon = tipe == "Masuk"
        ? Icons.login_rounded
        : Icons.logout_rounded;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: warna, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                "Konfirmasi Absen $tipe",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Waktu saat ini: $jamSekarang\nApakah kamu yakin ingin absen $tipe sekarang?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warna,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Ya, Absen",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  // =====================================================
  // DIALOG: BERHASIL ABSEN (popup interaktif)
  // =====================================================
  void showBerhasilAbsenDialog(String tipe, String status, String jam) {
    final warna = tipe == "Masuk"
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final icon = tipe == "Masuk"
        ? Icons.check_circle_rounded
        : Icons.home_rounded;

    Color statusColor;
    if (status == "Terlambat" || status == "Pulang Cepat") {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF10B981);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon animasi
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (_, val, child) =>
                    Transform.scale(scale: val, child: child),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: warna.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: warna, size: 48),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Absen $tipe Berhasil! 🎉",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),

              const SizedBox(height: 12),

              // ── Info jam
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Jam $tipe",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      jam,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Info status
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warna,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Oke, Terima Kasih!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ABSEN MASUK
  // =====================================================
  Future<void> absenMasuk() async {
    // ── Proteksi double absen: popup informatif
    if (sudahMasuk) {
      showSudahAbsenDialog("Masuk");
      return;
    }

    // ── Konfirmasi sebelum absen
    final konfirmasi = await showKonfirmasiDialog("Masuk");
    if (!konfirmasi) return;

    if (!await cekRadius()) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final now = TimeOfDay.now();
      final jamStr = formatTime(now);

      String status = "Hadir";

      if (setting != null && setting!['jam_masuk_akhir'] != null) {
        final akhir = parseTime(setting!['jam_masuk_akhir']);
        if (toMinutes(now) > toMinutes(akhir)) {
          status = "Terlambat";
        }
      }

      await Supabase.instance.client.from('absensi').insert({
        'user_id': user!.id,
        'tanggal': todayString(),
        'jam_masuk': jamStr,
        'status_masuk': status,
      });

      if (!mounted) return;

      setState(() => sudahMasuk = true);

      // ── Popup berhasil interaktif
      showBerhasilAbsenDialog("Masuk", status, jamStr);
    } catch (e) {
      showFloatingNotification("Error absen masuk", false);
    }
  }

  // =====================================================
  // ABSEN PULANG
  // =====================================================
  Future<void> absenPulang() async {
    if (!sudahMasuk) {
      showFloatingNotification("Belum absen masuk", false);
      return;
    }

    // ── Proteksi double absen: popup informatif
    if (sudahPulang) {
      showSudahAbsenDialog("Pulang");
      return;
    }

    // ── Konfirmasi sebelum absen
    final konfirmasi = await showKonfirmasiDialog("Pulang");
    if (!konfirmasi) return;

    if (!await cekRadius()) return;

    try {
      final existing = await getTodayAbsensi();

      if (existing == null) {
        showFloatingNotification("Data absensi tidak ditemukan", false);
        return;
      }

      final now = TimeOfDay.now();
      final jamStr = formatTime(now);

      String status = "Pulang";

      if (setting != null && setting!['jam_pulang'] != null) {
        final pulang = parseTime(setting!['jam_pulang']);
        if (toMinutes(now) < toMinutes(pulang)) {
          status = "Pulang Cepat";
        }
      }

      await Supabase.instance.client
          .from('absensi')
          .update({
        'jam_pulang': jamStr,
        'status_pulang': status,
      }).eq('id', existing['id']);

      if (!mounted) return;

      setState(() => sudahPulang = true);

      // ── Popup berhasil interaktif
      showBerhasilAbsenDialog("Pulang", status, jamStr);
    } catch (e) {
      showFloatingNotification("Error absen pulang", false);
    }
  }

  // =====================================================
  // SNACKBAR (untuk error & info ringan)
  // =====================================================
  void showFloatingNotification(String msg, bool isSuccess) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    final formattedDate =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "Pulang : ${setting!['jam_pulang']}",
              style: const TextStyle(color: Colors.white),
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
    final stringJam = DateFormat('HH:mm:ss').format(currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
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
                ? "✅ Presensi lengkap hari ini"
                : sudahMasuk
                    ? "💼 Waktunya fokus bekerja"
                    : "📍 Silakan lakukan absen masuk",
            style: TextStyle(
              fontSize: 13,
              color: sudahPulang || sudahMasuk
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
          child: ElevatedButton.icon(
            onPressed: sudahMasuk ? () => showSudahAbsenDialog("Masuk") : absenMasuk,
            icon: Icon(
              sudahMasuk ? Icons.check_rounded : Icons.login_rounded,
              size: 20,
            ),
            label: Text(sudahMasuk ? "Sudah Masuk" : "Absen Masuk"),
            style: ElevatedButton.styleFrom(
              backgroundColor: sudahMasuk
                  ? Colors.grey[300]
                  : const Color(0xFF10B981),
              foregroundColor: sudahMasuk ? Colors.grey[600] : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: !sudahMasuk
                ? null
                : sudahPulang
                    ? () => showSudahAbsenDialog("Pulang")
                    : absenPulang,
            icon: Icon(
              sudahPulang ? Icons.check_rounded : Icons.logout_rounded,
              size: 20,
            ),
            label: Text(sudahPulang ? "Sudah Pulang" : "Absen Pulang"),
            style: ElevatedButton.styleFrom(
              backgroundColor: !sudahMasuk
                  ? null
                  : sudahPulang
                      ? Colors.grey[300]
                      : const Color(0xFFEF4444),
              foregroundColor: sudahPulang ? Colors.grey[600] : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}