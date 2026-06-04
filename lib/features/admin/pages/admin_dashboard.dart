import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Pastikan import SplashPage ini aktif dan jalurnya sesuai dengan proyekmu
import '../../auth/pages/splash_page.dart'; 
import 'user_management_page.dart';
import 'access_control_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  
  // Key global untuk mengontrol buka-tutup Drawer (Sidebar versi HP) secara aman
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int totalUsers = 0;
  int totalMentors = 0;
  int totalAdmins = 0;
  int totalAbsensiHariIni = 0;
  int totalLogbookHariIni = 0;
  bool isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardStats();
  }

  // ================= FETCH STATISTIK DASHBOARD (REALTIME) =================
  Future<void> fetchDashboardStats() async {
    if (!mounted) return;
    setState(() => isStatsLoading = true);

    int usersCount = 0;
    int mentorsCount = 0;
    int adminsCount = 0;
    int absensiCount = 0;
    int logbookCount = 0;

    try {
      final usersData = await supabase.from('users').select('role');
      for (var row in usersData) {
        String role = row['role'] ?? 'user';
        if (role == 'user') usersCount++;
        if (role == 'mentor') mentorsCount++;
        if (role == 'admin') adminsCount++;
      }
    } catch (e) {
      debugPrint("Error users: $e");
    }

    final String hariIni = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final absensiLog = await supabase.from('absensi').select('id').eq('tanggal', hariIni);
      absensiCount = absensiLog.length;
    } catch (e) {
      debugPrint("Absensi error: $e");
    }

    try {
      final logbookLog = await supabase.from('logbook').select('id').eq('tanggal', hariIni);
      logbookCount = logbookLog.length;
    } catch (e) {
      debugPrint("Logbook error: $e");
    }

    if (mounted) {
      setState(() {
        totalUsers = usersCount;
        totalMentors = mentorsCount;
        totalAdmins = adminsCount;
        totalAbsensiHariIni = absensiCount;
        totalLogbookHariIni = logbookCount;
        isStatsLoading = false;
      });
    }
  }

  // ================= PROSES LOGOUT FIX TOTAL (ANTI-BLANK SCREEN) =================
  Future<void> handleLogout() async {
    // 1. Jika Drawer di HP/Tablet sedang terbuka, tutup dulu agar navigasi lancar
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }

    try {
      // 2. Putus hubungan sesi token login di database Supabase pusat
      await supabase.auth.signOut();
      
      // 3. Kembalikan secara fisik ke SplashPage sebagai gerbang pengecekan auth utama aplikasi
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SplashPage()),
          (route) => false, // Hapus bersih tumpukan halaman agar tidak bisa di-back fisik
        );
      }
    } catch (e) {
      debugPrint("Gagal memproses keluar sistem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 1024; // Detektor ukuran monitor PC/Laptop

    return Scaffold(
      key: _scaffoldKey, // Pasangkan key penutup drawer di sini
      backgroundColor: const Color(0xFFF8FAFC),
      
      // Munculkan AppBar & tombol hamburger menu jika dibuka di HP / Tablet
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("DIGILOK Admin Suite", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              backgroundColor: const Color(0xFF1E1B4B),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            
      // Sisi Sidebar otomatis melipat masuk menjadi Drawer geser di HP
      drawer: !isDesktop ? _buildSidebar(isInsideDrawer: true) : null,
      
      body: Row(
        children: [
          // Jika layar Desktop monitor lebar, tampilkan Sidebar permanen di sisi kiri
          if (isDesktop) _buildSidebar(isInsideDrawer: false),

          // Konten Utama Dashboard Utama (Sisi Kanan)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth < 600 ? 16.0 : 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BARIS BAR ATAS (HEADER)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ringkasan Sistem", 
                              style: TextStyle(fontSize: screenWidth < 600 ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))
                            ),
                            const SizedBox(height: 4),
                            const Text("Pantau statistik data dan log aktivitas DIGILOK secara realtime.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
                        onPressed: fetchDashboardStats,
                        tooltip: "Refresh Data",
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // IMPLEMENTASI RESPONSIVE STATISTIK CARDS
                  isStatsLoading
                      ? const Center(child: LinearProgressIndicator(color: Color(0xFF6C63FF)))
                      : _buildResponsiveStats(screenWidth),
                  const SizedBox(height: 32),

                  // LIVE AUDIT LOG MONITORING SYSTEM (REALTIME STREAM)
                  const Text(
                    "Live Audit Log Sistem (Realtime)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    height: 450, // Batasan tinggi container audit log agar nyaman di-scroll di HP
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase.from('audit_logs').stream(primaryKey: ['id']).order('created_at', ascending: false).limit(20),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Center(child: Text("Gagal memuat log sistem."));
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                        
                        final logs = snapshot.data ?? [];
                        if (logs.isEmpty) return const Center(child: Text("Belum ada riwayat tercatat hari ini.", style: TextStyle(color: Colors.grey)));

                        return ListView.separated(
                          itemCount: logs.length,
                          padding: const EdgeInsets.all(12),
                          separatorBuilder: (_, __) => const Divider(color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final String aksi = log['aksi'] ?? 'LOG';
                            
                            Color badgeColor = Colors.grey;
                            if (aksi.contains('UBAH') || aksi.contains('ASSIGN')) badgeColor = Colors.amber;
                            if (aksi.contains('BLOKIR') || aksi.contains('HAPUS') || aksi.contains('MAINTENANCE')) badgeColor = Colors.redAccent;
                            if (aksi.contains('AKTIF') || aksi.contains('TAMBAH')) badgeColor = Colors.green;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Flex(
                                direction: screenWidth < 768 ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: screenWidth < 768 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        (log['created_at'] ?? '').toString().substring(11, 19),
                                        style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: badgeColor.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                                        child: Text(aksi, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  if (screenWidth < 768) const SizedBox(height: 6) else const SizedBox(width: 16),
                                  Expanded(
                                    flex: screenWidth < 768 ? 0 : 1,
                                    child: Text(
                                      log['detail'] ?? "-",
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (screenWidth < 768) const SizedBox(height: 2),
                                  Text(
                                    "Oleh: ${log['admin_name'] ?? 'Admin'}",
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UTILITY BUILDER: BUILD SIDEBAR / DRAWER NAVIGASI =================
  Widget _buildSidebar({required bool isInsideDrawer}) {
    return Container(
      width: 260,
      height: double.infinity,
      color: const Color(0xFF1E1B4B),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gavel_rounded, color: Color(0xFF6C63FF), size: 24),
              SizedBox(width: 12),
              Text("ADMIN SUITE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 40),
          _sidebarItem(Icons.dashboard_rounded, "Dashboard Utama", true, () {
            if (isInsideDrawer) Navigator.pop(context); 
          }),
          _sidebarItem(Icons.manage_accounts_rounded, "Manajemen User", false, () {
            if (isInsideDrawer) Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage()));
          }),
          _sidebarItem(Icons.verified_user_rounded, "Kontrol Akses & Role", false, () {
            if (isInsideDrawer) Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessControlPage()));
          }),
          const Spacer(),
          _sidebarItem(Icons.logout_rounded, "Keluar Sistem", false, handleLogout, isDanger: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ================= UTILITY BUILDER: RESPONSIVE STAT CARDS GRID =================
  Widget _buildResponsiveStats(double width) {
    var cards = [
      _statCard("Total Siswa", totalUsers.toString(), Icons.people_alt_rounded, Colors.blue),
      _statCard("Total Mentor", totalMentors.toString(), Icons.school_rounded, Colors.orange),
      _statCard("Absen Hari Ini", totalAbsensiHariIni.toString(), Icons.co_present_rounded, Colors.green),
      _statCard("Logbook Masuk", totalLogbookHariIni.toString(), Icons.menu_book_rounded, Colors.purple),
    ];

    if (width < 600) {
      // Tampilan HP Tegak: Menurun Vertikal Satu per Satu
      return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
    } else if (width < 1024) {
      // Tampilan Tablet: Grid Kotak 2 Kolom Kiri Kanan
      return Column(
        children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
        ],
      );
    } else {
      // Tampilan Monitor PC Desktop: Melebar Sejajar Horizontal Sekaligus
      return Row(
        children: [
          Expanded(child: cards[0]), const SizedBox(width: 16),
          Expanded(child: cards[1]), const SizedBox(width: 16),
          Expanded(child: cards[2]), const SizedBox(width: 16),
          Expanded(child: cards[3]),
        ],
      );
    }
  }

  Widget _sidebarItem(IconData icon, String title, bool isActive, VoidCallback onTap, {bool isDanger = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? const Color(0xFF6C63FF) : Colors.transparent,
        leading: Icon(icon, color: isDanger ? Colors.redAccent : (isActive ? Colors.white : Colors.grey[400]), size: 18),
        title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : (isActive ? Colors.white : Colors.grey[300]), fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: color.withAlpha(20), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          )
        ],
      ),
    );
  }
}