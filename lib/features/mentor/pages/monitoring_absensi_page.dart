import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonitoringAbsensiPage extends StatefulWidget {
  const MonitoringAbsensiPage({super.key});

  @override
  State<MonitoringAbsensiPage> createState() =>
      _MonitoringAbsensiPageState();
}

class _MonitoringAbsensiPageState extends State<MonitoringAbsensiPage> {
  List<String> siswaIds = [];
  Map<String, String> userMap = {};

  bool isReady = false;

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    loadSiswa();
  }

  // ================= LOAD SISWA =================
  Future<void> loadSiswa() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      final data = await Supabase.instance.client
          .from('users')
          .select('id,name')
          .eq('mentor_id', user!.id);

      final ids =
          List<String>.from(data.map((e) => e['id'].toString()));

      final Map<String, String> map = {
        for (var e in data)
          e['id'].toString(): (e['name'] ?? 'User').toString()
      };

      if (!mounted) return;

      setState(() {
        siswaIds = ids;
        userMap = map;
        isReady = true;
      });
    } catch (e) {
      debugPrint("ERROR LOAD SISWA: $e");
    }
  }

  // ================= FORMAT =================
  String formatTanggal(DateTime date) {
    const bulan = [
      "",
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

    return "${date.day} ${bulan[date.month]} ${date.year}";
  }

  // ================= STREAM =================
  Stream<List<Map<String, dynamic>>> streamAbsensi() {
    return Supabase.instance.client
        .from('absensi')
        .stream(primaryKey: ['id'])
        .order('tanggal', ascending: false)
        .map((data) {
      return data.where((row) {
        if (!siswaIds.contains(row['user_id'].toString())) {
          return false;
        }

        if (startDate == null || endDate == null) return true;

        final tanggal = DateTime.tryParse(row['tanggal'] ?? '');
        if (tanggal == null) return false;

        return tanggal.isAfter(startDate!.subtract(const Duration(days: 1))) &&
            tanggal.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    });
  }

  // ================= DATE PICK =================
  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  // ================= STATUS FINAL =================
  String getStatus(Map item) {

    // PRIORITAS PULANG
    if (item['status_pulang'] != null &&
        item['status_pulang'].toString().isNotEmpty) {
      return item['status_pulang'];
    }

    // PRIORITAS MASUK
    if (item['status_masuk'] != null &&
        item['status_masuk'].toString().isNotEmpty) {
      return item['status_masuk'];
    }

    return "Belum Absen";
  }

  // ================= WARNA =================
  Color getStatusColor(String status) {
    switch (status) {
      case "Hadir":
        return Colors.green;
      case "Terlambat":
        return Colors.orange;
      case "Pulang":
        return Colors.blue;
      case "Pulang Cepat":
        return Colors.red;
      default:
        return Colors.grey;
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

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Monitoring Absensi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
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

                      // FILTER
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => pickDate(true),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEBFF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      startDate == null
                                          ? "Tanggal Mulai"
                                          : formatTanggal(startDate!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => pickDate(false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEBFF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      endDate == null
                                          ? "Tanggal Akhir"
                                          : formatTanggal(endDate!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // LIST
                      Expanded(
                        child: !isReady
                            ? const Center(child: CircularProgressIndicator())
                            : StreamBuilder<List<Map<String, dynamic>>>(
                                stream: streamAbsensi(),
                                builder: (context, snapshot) {

                                  if (!snapshot.hasData) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  final data = snapshot.data!;

                                  if (data.isEmpty) {
                                    return const Center(
                                        child: Text("Tidak ada absensi"));
                                  }

                                  return ListView.builder(
                                    itemCount: data.length,
                                    itemBuilder: (context, i) {
                                      final item = data[i];

                                      final status = getStatus(item);
                                      final nama =
                                          userMap[item['user_id']] ?? "User";

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F1FF),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(nama,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),

                                                  Text(item['tanggal'] ?? "-"),

                                                  const SizedBox(height: 5),

                                                  Row(
                                                    children: [
                                                      Text("Masuk: ${item['jam_masuk'] ?? '-'}"),
                                                      const SizedBox(width: 10),
                                                      Text("Pulang: ${item['jam_pulang'] ?? '-'}"),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color: getStatusColor(status),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                status,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
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
}