import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// PAGE
import 'review_logbook_page.dart';
import 'monitoring_absensi_page.dart';
import 'penilaian_page.dart';
import 'laporan_mentor_page.dart';
import 'pengaturan_page.dart';
import 'profile_page.dart';

// AUTH
import '../../auth/pages/login_page.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  int index = 0;

  final pages = [
    const MentorHomePage(),
    const ReviewLogbookPage(),
    const MonitoringAbsensiPage(),
    const LaporanMentorPage(),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Review"),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: "Absensi"),
          BottomNavigationBarItem(icon: Icon(Icons.insert_drive_file), label: "Laporan"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// ================= HOME ================= ///
////////////////////////////////////////////////////////////

class MentorHomePage extends StatefulWidget {
  const MentorHomePage({super.key});

  @override
  State<MentorHomePage> createState() => _MentorHomePageState();
}

class _MentorHomePageState extends State<MentorHomePage> {
  String nama = "";
  String tanggal = "";

  List<String> siswaIds = [];

  int totalSiswa = 0;
  int totalHadirHariIni = 0;

  DateTime? lastNewestTime;
  bool firstLoad = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= FORMAT =================
  String formatTanggalIndo(DateTime now) {
    final hari = [
      "Senin","Selasa","Rabu","Kamis","Jumat","Sabtu","Minggu"
    ];

    final bulan = [
      "Januari","Februari","Maret","April","Mei","Juni",
      "Juli","Agustus","September","Oktober","November","Desember"
    ];

    return "${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}";
  }

  // ================= LOAD =================
  Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;

    final dataUser = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', user!.id)
        .single();

    final now = DateTime.now();

    final siswa = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('mentor_id', user.id);

    final siswaIdList = List<String>.from(siswa.map((e) => e['id']));

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final absensi = await Supabase.instance.client
        .from('absensi')
        .select()
        .inFilter('user_id', siswaIdList)
        .gte('tanggal', today);

    setState(() {
      nama = dataUser['name'] ?? "";
      tanggal = formatTanggalIndo(now);
      siswaIds = siswaIdList;
      totalSiswa = siswaIdList.length;
      totalHadirHariIni = absensi.length;
    });
  }

  // ================= STREAM =================
  Stream<List<Map<String, dynamic>>> streamPending() {
    return Supabase.instance.client
        .from('logbook')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      return data.where((row) =>
          siswaIds.contains(row['user_id']) &&
          row['status'] == 'pending').toList();
    });
  }

  // ================= NOTIF =================
  void showNotif() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text("Logbook baru masuk!")),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin mau keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // ✅ FIX: Langsung push ke LoginPage, hapus semua stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF4A47A3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 20),

              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hallo, $nama 👋",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(tanggal,
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),

                    GestureDetector(
                      onTap: logout,
                      child: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [

                      // STAT
                      Row(
                        children: [
                          statCard("Mahasiswa/Siswa", totalSiswa, Colors.blue, Icons.people),
                          statCard("Hadir", totalHadirHariIni, Colors.green, Icons.check),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // MENU
                      Row(
                        children: [
                          menuItem(Icons.star, "Penilaian", () {
                            // ✅ FIX: Push biasa, bukan named route
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const PenilaianPage()));
                          }),
                          menuItem(Icons.settings, "Pengaturan", () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const PengaturanPage()));
                          }),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Logbook Pending",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: streamPending(),
                          builder: (context, snapshot) {

                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final data = snapshot.data!;

                            if (data.isEmpty) {
                              return const Center(
                                child: Text("Belum ada logbook"),
                              );
                            }

                            final newestRaw = data.first['created_at'];
                            if (newestRaw != null) {
                              final newest = DateTime.parse(newestRaw);

                              if (!firstLoad &&
                                  (lastNewestTime == null ||
                                      newest.isAfter(lastNewestTime!))) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  showNotif();
                                });
                              }

                              lastNewestTime = newest;
                            }

                            firstLoad = false;

                            return ListView.builder(
                              itemCount: data.length,
                              itemBuilder: (context, i) {
                                final item = data[i];

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F1FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['judul'] ?? "-",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text(item['deskripsi'] ?? "-"),
                                      const SizedBox(height: 5),
                                      const Text("Menunggu Review",
                                          style: TextStyle(color: Colors.orange)),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================= COMPONENT =================
  Widget statCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.9), color],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text("$value",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget menuItem(IconData icon, String title, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF)),
              const SizedBox(height: 10),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}