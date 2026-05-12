import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String nama = "";
  String email = "";
  String role = ""; // Tambahan role untuk memperjelas identitas login (Siswa/Mentor)
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ================= LOAD DATA USER FROM SUPABASE =================
  Future<void> loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select('name, role') // Mengambil nama dan role dari DB
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            nama = data['name'] ?? "Nama Tidak Diketahui";
            role = data['role'] ?? "user";
            email = user.email ?? "-";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat profil pengguna")),
        );
      }
    }
  }

  // ================= ACTION: PROSES SIGNOUT =================
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan saat logout")),
        );
      }
    }
  }

  // ================= PROMPT: DIALOG KONFIRMASI LOGOUT =================
  void showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Apakah kamu yakin ingin keluar dari aplikasi DIGILOK?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog konfirmasi
                logout(); // Jalankan fungsi logout
              },
              child: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ================= MAIN BUILD METHOD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C63FF), // Background atas disamakan dengan tema utama
      appBar: AppBar(
        title: const Text("Profil Pengguna", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))))
                  : Column(
                      children: [
                        // Avatar dengan Badge Ring Premium
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF6C63FF).withAlpha(40), width: 4),
                              ),
                            ),
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFF6C63FF).withAlpha(25),
                              child: const Icon(Icons.person_rounded, size: 48, color: Color(0xFF6C63FF)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nama Pengguna & Status Role
                        Text(
                          nama,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withAlpha(20),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Card Informasi Detail Akun
                        Container(
                          padding: const EdgeInsets.all(16),
                          // CARI BLOK INI PADA KODE SEBELUMNYA:
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.grey[100]!),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withAlpha(8),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.email_outlined, color: Colors.grey[600], size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Alamat Email", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Tombol Logout Bergaya Premium Modern
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: showLogoutConfirmation, // Memanggil Dialog Konfirmasi
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text(
                              "Keluar Akun",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                            ),
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
}