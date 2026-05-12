import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'absensi_page.dart';
import 'logbook_page.dart';
import 'laporan_page.dart';
import 'profile_page.dart';

import '../services/notification_service.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int index = 0;

  final pages = [
    const DashboardPage(),
    const AbsensiPage(),
    const LogbookPage(),
    const LaporanPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint_rounded),
            label: "Absensi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: "Logbook",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file_rounded),
            label: "Laporan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int sisaHari = 0;
  int totalHari = 0;

  String namaUser = "User";
  String tanggalHariIni = "";

  bool isLoadingData = true;

  bool belumAbsen = false;
  bool belumLogbook = false;

  @override
  void initState() {
    super.initState();
    initDashboard();
  }

  // =========================================================
  // INIT DASHBOARD
  // =========================================================
  Future<void> initDashboard() async {
    try {
      await loadUserData();
      await hitungMagang();
      await cekReminder();
    } catch (e) {
      debugPrint("Error dashboard: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingData = false;
        });
      }
    }
  }

  // =========================================================
  // LOAD USER
  // =========================================================
  Future<void> loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final data = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    final now = DateTime.now();

    final hari = [
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu"
    ];

    final bulan = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];

    if (!mounted) return;

    setState(() {
      namaUser = data?['name'] ?? 'User';

      tanggalHariIni =
          "${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}";
    });
  }

  // =========================================================
  // HITUNG MAGANG
  // =========================================================
  Future<void> hitungMagang() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final data = await Supabase.instance.client
        .from('users')
        .select('mulai_date, selesai_date')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null ||
        data['mulai_date'] == null ||
        data['selesai_date'] == null) {
      return;
    }

    try {
      final mulai = DateTime.parse(data['mulai_date']);
      final selesai = DateTime.parse(data['selesai_date']);
      final sekarang = DateTime.now();

      if (!mounted) return;

      setState(() {
        totalHari = selesai.difference(mulai).inDays;

        sisaHari = selesai.difference(sekarang).inDays;

        if (sisaHari < 0) {
          sisaHari = 0;
        }
      });
    } catch (e) {
      debugPrint("Format tanggal salah: $e");
    }
  }

  // =========================================================
  // CEK REMINDER
  // =========================================================
  Future<void> cekReminder() async {
    final sudahAbsen =
        await NotificationService.sudahAbsenHariIni();

    final sudahLogbook =
        await NotificationService.sudahIsiLogbookHariIni();

    final now = DateTime.now();

    if (!mounted) return;

    setState(() {
      belumAbsen = !sudahAbsen && now.hour >= 9;
      belumLogbook = !sudahLogbook && now.hour >= 12;
    });
  }

  // =========================================================
  // STREAM ABSENSI REALTIME
  // =========================================================
  Stream<List<Map<String, dynamic>>> absensiHariIni() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    final today = NotificationService.today();

    return Supabase.instance.client
        .from('absensi')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data.where((item) {
            return item['user_id'] == user.id &&
                item['tanggal'] == today;
          }).toList(),
        );
  }

  // =========================================================
  // STREAM LOGBOOK REALTIME
  // =========================================================
  Stream<List<Map<String, dynamic>>> logbookStream() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    final today = NotificationService.today();

    return Supabase.instance.client
        .from('logbook')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data.where((item) {
            return item['user_id'] == user.id &&
                item['tanggal'] == today;
          }).toList(),
        );
  }

  // =========================================================
  // LOGOUT
  // =========================================================
  void tanyakanLogout() {
    final rootNavigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Konfirmasi Keluar",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Apakah kamu yakin ingin keluar dari aplikasi DIGILOK?",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext);

                        await Supabase.instance.client.auth.signOut();

                        rootNavigator.pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Keluar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (isLoadingData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C63FF),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF4A47A3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // =====================================================
              // HEADER
              // =====================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hallo, $namaUser 👋",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tanggalHariIni,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: tanyakanLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // =================================================
                        // DURASI MAGANG
                        // =================================================
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF)
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.hourglass_top_rounded,
                                color: Color(0xFF6C63FF),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Durasi Magang",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      totalHari == 0
                                          ? "Periode belum diatur"
                                          : "Tersisa $sisaHari hari dari $totalHari hari",
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 15,
                                        color:
                                            Color(0xFF4A47A3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =================================================
                        // REMINDER ABSENSI
                        // =================================================
                        if (belumAbsen)
                          Container(
                            margin:
                                const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.orange.shade200,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Kamu belum melakukan absensi hari ini.",
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // =================================================
                        // REMINDER LOGBOOK
                        // =================================================
                        if (belumLogbook)
                          Container(
                            margin:
                                const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    const Color(0xFFD6CCFF),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  color: Color(0xFF6C63FF),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Jangan lupa isi logbook hari ini.",
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),

                        // =================================================
                        // AKTIVITAS TERBARU
                        // =================================================
                        const Text(
                          "Aktivitas Terbaru",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[200]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              // ===========================================
                              // ABSENSI REALTIME
                              // ===========================================
                              StreamBuilder<
                                  List<Map<String, dynamic>>>(
                                stream: absensiHariIni(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child:
                                          LinearProgressIndicator(
                                        color:
                                            Color(0xFF6C63FF),
                                      ),
                                    );
                                  }

                                  final data =
                                      snapshot.data ?? [];

                                  final bool done =
                                      data.isNotEmpty;

                                  WidgetsBinding.instance
                                      .addPostFrameCallback(
                                    (_) {
                                      if (mounted) {
                                        final statusBaru =
                                            !done &&
                                                DateTime.now()
                                                        .hour >=
                                                    9;

                                        if (belumAbsen !=
                                            statusBaru) {
                                          setState(() {
                                            belumAbsen =
                                                statusBaru;
                                          });
                                        }
                                      }
                                    },
                                  );

                                  String text =
                                      "Belum melakukan absensi hari ini";

                                  if (done) {
                                    final jamMasuk =
                                        data.first[
                                                'jam_masuk'] ??
                                            '-';

                                    text =
                                        "Absensi berhasil jam $jamMasuk";
                                  }

                                  return AnimatedContainer(
                                    duration:
                                        const Duration(
                                      milliseconds: 400,
                                    ),
                                    curve:
                                        Curves.easeInOut,
                                    child: Row(
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(
                                            milliseconds:
                                                350,
                                          ),
                                          child: Icon(
                                            done
                                                ? Icons
                                                    .check_circle_rounded
                                                : Icons
                                                    .radio_button_unchecked_rounded,
                                            key: ValueKey(
                                                done),
                                            color: done
                                                ? Colors
                                                    .green
                                                : Colors
                                                    .grey,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 12),
                                        Expanded(
                                          child:
                                              AnimatedSwitcher(
                                            duration:
                                                const Duration(
                                              milliseconds:
                                                  350,
                                            ),
                                            child: Text(
                                              text,
                                              key:
                                                  ValueKey(
                                                      text),
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    14,
                                                color: done
                                                    ? Colors
                                                        .black87
                                                    : Colors
                                                        .black54,
                                                fontWeight:
                                                    done
                                                        ? FontWeight
                                                            .w600
                                                        : FontWeight
                                                            .normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Divider(
                                  height: 1,
                                ),
                              ),

                              // ===========================================
                              // LOGBOOK REALTIME
                              // ===========================================
                              StreamBuilder<
                                  List<Map<String, dynamic>>>(
                                stream: logbookStream(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child:
                                          LinearProgressIndicator(
                                        color:
                                            Color(0xFF6C63FF),
                                      ),
                                    );
                                  }

                                  final data =
                                      snapshot.data ?? [];

                                  final bool done =
                                      data.isNotEmpty;

                                  WidgetsBinding.instance
                                      .addPostFrameCallback(
                                    (_) {
                                      if (mounted) {
                                        final statusBaru =
                                            !done &&
                                                DateTime.now()
                                                        .hour >=
                                                    12;

                                        if (belumLogbook !=
                                            statusBaru) {
                                          setState(() {
                                            belumLogbook =
                                                statusBaru;
                                          });
                                        }
                                      }
                                    },
                                  );

                                  String text =
                                      "Belum mengisi logbook hari ini";

                                  if (done) {
                                    final judul =
                                        data.first[
                                                'judul'] ??
                                            '-';

                                    text =
                                        "Logbook: $judul";
                                  }

                                  return AnimatedContainer(
                                    duration:
                                        const Duration(
                                      milliseconds: 400,
                                    ),
                                    curve:
                                        Curves.easeInOut,
                                    child: Row(
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(
                                            milliseconds:
                                                350,
                                          ),
                                          child: Icon(
                                            done
                                                ? Icons
                                                    .assignment_turned_in_rounded
                                                : Icons
                                                    .assignment_outlined,
                                            key: ValueKey(
                                                done),
                                            color: done
                                                ? const Color(
                                                    0xFF6C63FF)
                                                : Colors
                                                    .grey,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 12),
                                        Expanded(
                                          child:
                                              AnimatedSwitcher(
                                            duration:
                                                const Duration(
                                              milliseconds:
                                                  350,
                                            ),
                                            child: Text(
                                              text,
                                              key:
                                                  ValueKey(
                                                      text),
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    14,
                                                color: done
                                                    ? Colors
                                                        .black87
                                                    : Colors
                                                        .black54,
                                                fontWeight:
                                                    done
                                                        ? FontWeight
                                                            .w600
                                                        : FontWeight
                                                            .normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}