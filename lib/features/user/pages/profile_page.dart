import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/pages/splash_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "...";
  String email = "...";
  String role = "User / Intern";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select('name, role')
            .eq('id', user.id)
            .single();
            
        if (!mounted) return;

        setState(() {
          name = data['name'] ?? 'No Name';
          email = user.email ?? 'No Email';
          role = data['role'] != null 
              ? data['role'].toString().toUpperCase() 
              : 'USER / INTERN';
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      debugPrint("Gagal memuat profil: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Profil Pengguna", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // AVATAR SECTION
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFF6C63FF),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "U",
                              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(role, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 32),
                  
                  // INFORMATION CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF6C63FF)),
                          title: const Text("Nama Lengkap", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          subtitle: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87)),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.mail_outline_rounded, color: Color(0xFF6C63FF)),
                          title: const Text("Alamat Email", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // LOGOUT TRIGGER BUTTON
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // ✅ AMANKAN: Ambil navigator & messenger utama halaman sebelum masuk dialog
                      final rootNavigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        // ✅ FIX 1: Ubah nama variabel context dialog menjadi dialogContext
                        builder: (dialogContext) => Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
                                const SizedBox(height: 16),
                                const Text("Konfirmasi Keluar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text("Apakah kamu yakin ingin keluar?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text("Batal", style: TextStyle(color: Colors.black54)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () async {
                                          try {
                                            // ✅ FIX 2: Tutup dialog dengan dialogContext secara aman
                                            Navigator.pop(dialogContext);
                                            
                                            // Proses Log Out dari Supabase
                                            await Supabase.instance.client.auth.signOut();
                                            
                                            // ✅ FIX 3: Gunakan rootNavigator yang sudah diekstrak di atas agar tidak memicu async gap error
                                            rootNavigator.pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (context) => const SplashPage()),
                                              (route) => false,
                                            );
                                          } catch (e) {
                                            debugPrint("Kesalahan SignOut: $e");
                                            if (!mounted) return;
                                            scaffoldMessenger.showSnackBar(
                                              SnackBar(content: Text("Gagal keluar: $e"), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        child: const Text("Keluar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}