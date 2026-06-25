import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/pages/user_dashboard.dart';
import '../../mentor/pages/mentor_dashboard.dart';
import 'register_page.dart';
import '../../../core/widgets/popup_notification.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  // =========================================================
  // CEK MAINTENANCE MODE
  // =========================================================
  Future<bool> _isMaintenanceActive() async {
    try {
      final data = await Supabase.instance.client
          .from('system_settings')
          .select('is_active')
          .eq('id', 'maintenance_mode')
          .maybeSingle();
      return data?['is_active'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      PopupNotification.show(
        context: context,
        type: PopupType.warning,
        title: "Form Tidak Lengkap",
        message: "Alamat email dan kata sandi tidak boleh kosong!",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        final String userRole = data['role'] ?? 'user';

        // =========================================================
        // CEK STATUS AKUN — BLOKIR JIKA is_active = false
        // =========================================================
        final bool isActive = data['is_active'] ?? true;
        if (!isActive) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            setState(() => isLoading = false);
            PopupNotification.show(
              context: context,
              type: PopupType.error,
              title: "Akun Diblokir",
              message: "Akun Anda telah diblokir oleh admin.\nHubungi admin untuk informasi lebih lanjut.",
            );
          }
          return;
        }

        // =========================================================
        // BLOKIR JIKA MAINTENANCE AKTIF
        // =========================================================
        final maintenance = await _isMaintenanceActive();
        if (maintenance) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            setState(() => isLoading = false);
            PopupNotification.show(
              context: context,
              type: PopupType.maintenance,
              title: "Sedang Pemeliharaan",
              message: "Aplikasi sedang dalam pemeliharaan.\nCoba beberapa saat lagi.",
            );
          }
          return;
        }

        if (!mounted) return;

        switch (userRole) {
          case 'user':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
            break;
          case 'mentor':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MentorDashboard()));
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        PopupNotification.show(
          context: context,
          type: PopupType.error,
          title: "Login Gagal",
          message: "Periksa kembali email & kata sandi Anda.",
        );
      }
    }
  }

  void showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
              Color(0xFF4338CA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: kIsWeb ? 420 : double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== LOGO =====
                        Center(
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withAlpha(60),
                                  blurRadius: 25,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icons/logo.jpeg', // ← PATH DIUBAH
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.book_rounded, size: 70, color: Color(0xFF4338CA));
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "DIGILOK",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1B4B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sistem Absensi & Logbook Digital",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1E1B4B).withAlpha(150),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ===== EMAIL =====
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B)),
                          decoration: InputDecoration(
                            labelText: "Alamat Email",
                            labelStyle: TextStyle(color: const Color(0xFF1E1B4B).withAlpha(140), fontWeight: FontWeight.w500),
                            prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF4338CA)),
                            filled: true,
                            fillColor: Colors.grey[50],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ===== PASSWORD =====
                        TextField(
                          controller: _passwordController,
                          obscureText: !isPasswordVisible,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B)),
                          decoration: InputDecoration(
                            labelText: "Kata Sandi",
                            labelStyle: TextStyle(color: const Color(0xFF1E1B4B).withAlpha(140), fontWeight: FontWeight.w500),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF4338CA)),
                            suffixIcon: IconButton(
                              icon: Icon(isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF4338CA)),
                              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ===== TOMBOL MASUK =====
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4338CA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: const Color(0xFF4338CA).withAlpha(100),
                          ),
                          onPressed: isLoading ? null : handleLogin,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  "Masuk",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                ),
                        ),

                        // ===== REGISTER =====
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Belum punya akun? ",
                              style: TextStyle(
                                color: const Color(0xFF1E1B4B).withAlpha(140),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                                );
                              },
                              child: const Text(
                                "Daftar Sekarang",
                                style: TextStyle(
                                  color: Color(0xFF4338CA),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}