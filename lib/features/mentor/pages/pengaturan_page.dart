import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  double radius = 100;
  double? lat;
  double? lng;

  TimeOfDay jamMasukMulai = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay jamMasukAkhir = const TimeOfDay(hour: 8, minute: 15);
  TimeOfDay jamPulang = const TimeOfDay(hour: 16, minute: 0);

  bool isLoading = true;
  bool isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    loadSetting();
  }

  Future<void> loadSetting() async {
    try {
      final data = await Supabase.instance.client
          .from('pengaturan_absensi')
          .select()
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          radius = (data['radius'] ?? 100).toDouble();
          
          // DIUBAH: Mengambil dari kolom 'latitude' dan 'longitude' Supabase
          lat = data['latitude'];
          lng = data['longitude'];
          
          jamMasukMulai = _parseTime(data['jam_masuk_mulai'] ?? "08:00:00");
          jamMasukAkhir = _parseTime(data['jam_masuk_akhir'] ?? "08:15:00");
          jamPulang = _parseTime(data['jam_pulang'] ?? "16:00:00");
        });
      }
    } catch (e) {
      showMsg("Gagal memuat data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  TimeOfDay _parseTime(String time) {
    final p = time.split(":");
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String formatTime(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  Future<void> ambilLokasi() async {
    setState(() => isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        showMsg("Izin lokasi ditolak permanen. Buka pengaturan HP.");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        lat = pos.latitude;
        lng = pos.longitude;
      });

      showMsg("Lokasi berhasil diperbarui", success: true);
    } catch (e) {
      showMsg("Gagal mengambil lokasi: $e");
    } finally {
      setState(() => isGettingLocation = false);
    }
  }

  Future<void> simpan() async {
    if (lat == null || lng == null) {
      showMsg("Harap ambil lokasi kantor terlebih dahulu");
      return;
    }

    try {
      setState(() => isLoading = true);

      final existingData = await Supabase.instance.client
          .from('pengaturan_absensi')
          .select()
          .limit(1)
          .maybeSingle();

      // DIUBAH: Menggunakan key 'latitude' dan 'longitude' agar sinkron dengan database
      final payload = {
        "radius": radius.toInt(),
        "latitude": lat,
        "longitude": lng,
        "jam_masuk_mulai": "${formatTime(jamMasukMulai)}:00",
        "jam_masuk_akhir": "${formatTime(jamMasukAkhir)}:00",
        "jam_pulang": "${formatTime(jamPulang)}:00",
      };

      if (existingData == null) {
        await Supabase.instance.client.from('pengaturan_absensi').insert(payload);
      } else {
        await Supabase.instance.client
            .from('pengaturan_absensi')
            .update(payload)
            .eq('id', existingData['id']);
      }

      showMsg("Pengaturan berhasil disimpan", success: true);
    } catch (e) {
      showMsg("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMsg(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  Widget _buildTimeTile(String title, TimeOfDay time, Function(TimeOfDay) onSelect) {
    return ListTile(
      title: Text(title),
      trailing: Text(formatTime(time), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      onTap: () async {
        final selected = await showTimePicker(context: context, initialTime: time);
        if (selected != null) onSelect(selected);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan Kantor & Absensi")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- KARTU RADIUS ---
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Radius Maksimal Absensi (Meter)", style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: radius,
                            min: 10,
                            max: 1000,
                            divisions: 99,
                            label: "${radius.toInt()} m",
                            onChanged: (v) => setState(() => radius = v),
                          ),
                          Text("${radius.toInt()} meter", style: const TextStyle(fontSize: 18, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- KARTU LOKASI ---
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Lokasi Kantor (Mentor)", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          if (lat != null)
                            Text("Koordinat: $lat, $lng", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey))
                          else
                            const Text("Lokasi belum diatur", style: TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          isGettingLocation
                              ? const CircularProgressIndicator()
                              : ElevatedButton.icon(
                                  onPressed: ambilLokasi,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text("Perbarui Lokasi GPS"),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- KARTU JAM KERJA ---
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        _buildTimeTile("Mulai Absen Masuk", jamMasukMulai, (t) => setState(() => jamMasukMulai = t)),
                        _buildTimeTile("Batas Akhir Masuk", jamMasukAkhir, (t) => setState(() => jamMasukAkhir = t)),
                        _buildTimeTile("Jam Pulang", jamPulang, (t) => setState(() => jamPulang = t)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: simpan,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("SIMPAN SEMUA PENGATURAN", style: TextStyle(fontSize: 16)),
                  )
                ],
              ),
            ),
    );
  }
}