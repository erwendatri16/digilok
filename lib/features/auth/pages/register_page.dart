import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();

  final instansi = TextEditingController();
  final lokasi = TextEditingController();

  final mulai = TextEditingController();
  final selesai = TextEditingController();

  String role = "user";

  List<Map<String, dynamic>> mentors = [];
  String? mentorId;

  bool loading = false;
  bool loadingMentor = true;

  double? lat;
  double? lng;

  @override
  void initState() {
    super.initState();
    fetchMentor();
  }

  // ================= FETCH MENTOR =================
  Future<void> fetchMentor() async {
    try {
      final res = await Supabase.instance.client
          .from('users')
          .select('id,name,instansi,role');

      final mentorOnly = res.where((e) => e['role'] == 'mentor').toList();

      setState(() {
        mentors = List<Map<String, dynamic>>.from(mentorOnly);
        loadingMentor = false;
      });
    } catch (e) {
      debugPrint("ERROR FETCH MENTOR: $e");
      setState(() => loadingMentor = false);
    }
  }

  // ================= DATE =================
  Future<void> pickDate(TextEditingController c) async {
    DateTime? d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4338CA),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1B4B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (d != null) {
      c.text =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
  }

  // ================= GPS =================
  Future<void> getLocation() async {
    LocationPermission p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied) return;

    Position pos = await Geolocator.getCurrentPosition();

    setState(() {
      lat = pos.latitude;
      lng = pos.longitude;
    });
  }

  // ================= REGISTER =================
  Future<void> register() async {
    if (!email.text.contains("@")) {
      showMsg("Email tidak valid");
      return;
    }

    if (role == "user") {
      if (mentorId == null) {
        showMsg("Pilih mentor dulu");
        return;
      }
      if (mulai.text.isEmpty || selesai.text.isEmpty) {
        showMsg("Isi tanggal magang");
        return;
      }
    }

    setState(() => loading = true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      final user = res.user;

      if (user != null) {
        if (role == "user") {
          await Supabase.instance.client.from('users').insert({
            'id': user.id,
            'name': name.text,
            'email': email.text.trim(),
            'role': 'user',
            'mentor_id': mentorId,
            'instansi': instansi.text,
            'lokasi': lokasi.text,
            'mulai_date': mulai.text,
            'selesai_date': selesai.text,
          });
        } else {
          await Supabase.instance.client.from('users').insert({
            'id': user.id,
            'name': name.text,
            'email': email.text.trim(),
            'role': 'mentor',
            'instansi': instansi.text,
            'latitude': lat,
            'longitude': lng,
          });
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 10),
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 70),
              SizedBox(height: 20),
              Text(
                "Berhasil!",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E1B4B)),
              ),
              SizedBox(height: 8),
              Text(
                "Akun kamu berhasil dibuat",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF4338CA),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String msg = e.toString();
      if (msg.contains("user_already_exists")) {
        msg = "Email sudah terdaftar";
      }
      showMsg(msg);
    }

    setState(() => loading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget input(String label, TextEditingController c,
      {bool isPass = false, VoidCallback? tap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        obscureText: isPass,
        readOnly: tap != null,
        onTap: tap,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color(0xFF1E1B4B).withAlpha(140), fontWeight: FontWeight.w500),
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
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // ===== LOGO =====
                Center(
                  child: Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withAlpha(60),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/logo.jpeg', // ← PATH DIUBAH
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.book_rounded, color: Color(0xFF4338CA), size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "DIGILOK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(28),
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
                    children: [
                      const Text(
                        "Buat Akun",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text("Mahasiswa/Siswa"),
                            selected: role == "user",
                            selectedColor: const Color(0xFF4338CA),
                            disabledColor: Colors.grey[100],
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: role == "user" ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (_) => setState(() => role = "user"),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text("Mentor"),
                            selected: role == "mentor",
                            selectedColor: const Color(0xFF4338CA),
                            disabledColor: Colors.grey[100],
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: role == "mentor" ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (_) => setState(() => role = "mentor"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      input("Nama Lengkap", name),
                      input("Email", email),
                      input("Password", pass, isPass: true),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: role == "user"
                            ? Column(
                                key: const ValueKey("user"),
                                children: [
                                  input("Asal Universitas/Sekolah", instansi),
                                  input("Tempat Magang", lokasi),
                                  input("Tanggal Mulai", mulai, tap: () => pickDate(mulai)),
                                  input("Tanggal Selesai", selesai, tap: () => pickDate(selesai)),
                                  const SizedBox(height: 8),
                                  loadingMentor
                                      ? const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(color: Color(0xFF4338CA)),
                                        )
                                      : DropdownButtonFormField<String>(
                                          value: mentorId,
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B)),
                                          items: mentors.isEmpty
                                              ? [
                                                  const DropdownMenuItem<String>(
                                                    value: null,
                                                    child: Text("Belum ada mentor"),
                                                  )
                                                ]
                                              : mentors.map<DropdownMenuItem<String>>((m) {
                                                  final nama = m['name'] ?? '';
                                                  final instansiMentor = m['instansi'] ?? '';
                                                  return DropdownMenuItem<String>(
                                                    value: m['id'].toString(),
                                                    child: Text("$nama - $instansiMentor"),
                                                  );
                                                }).toList(),
                                          onChanged: mentors.isEmpty
                                              ? null
                                              : (String? v) => setState(() => mentorId = v),
                                          decoration: InputDecoration(
                                            labelText: "Pilih Mentor",
                                            labelStyle: TextStyle(color: const Color(0xFF1E1B4B).withAlpha(140), fontWeight: FontWeight.w500),
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
                                          ),
                                        ),
                                ],
                              )
                            : Column(
                                key: const ValueKey("mentor"),
                                children: [
                                  input("Nama Instansi/Perusahaan", instansi),
                                  const SizedBox(height: 4),
                                  ElevatedButton.icon(
                                    onPressed: getLocation,
                                    icon: const Icon(Icons.location_on_rounded, size: 20),
                                    label: const Text("Gunakan Lokasi Saya", style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF312E81),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      lat == null
                                          ? "📍 Lokasi GPS belum diambil"
                                          : "✅ Terkunci!\nLat: $lat\nLng: $lng",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: lat == null ? Colors.amber[900] : Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: const Color(0xFF4338CA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                          shadowColor: const Color(0xFF4338CA).withAlpha(100),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Text(
                                "Daftar Akun",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Sudah Punya Akun? Masuk",
                          style: TextStyle(
                            color: Color(0xFF4338CA),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}