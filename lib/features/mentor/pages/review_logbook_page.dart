import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewLogbookPage extends StatefulWidget {
  const ReviewLogbookPage({super.key});

  @override
  State<ReviewLogbookPage> createState() => _ReviewLogbookPageState();
}

class _ReviewLogbookPageState extends State<ReviewLogbookPage> {
  List<String> siswaIds = [];
  String selectedFilter = "all"; 
  bool isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    loadSiswa();
  }

  // ================= AMBIL DATA SISWA BIMBINGAN =================
  Future<void> loadSiswa() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final siswa = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('mentor_id', user.id);

        if (mounted) {
          setState(() {
            siswaIds = List<String>.from(siswa.map((e) => e['id']));
            isInitialLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isInitialLoading = false);
      showFloatingNotification("Gagal mengambil data siswa bimbingan", false);
    }
  }

  // ================= STREAM DATA LOGBOOK VIA SUPABASE =================
  Stream<List<Map<String, dynamic>>> streamLogbook() {
    return Supabase.instance.client
        .from('logbook')
        .stream(primaryKey: ['id'])
        .map((data) {
      var result = data.where((row) {
        final isSiswa = siswaIds.contains(row['user_id']);
        if (selectedFilter == "all") return isSiswa;
        return isSiswa && row['status'] == selectedFilter;
      }).toList();

      result.sort((a, b) =>
          b['created_at'].toString().compareTo(a['created_at'].toString()));
      return result;
    });
  }

  // ================= STYLING COMPONENT HELPER =================
  Color getStatusThemeColor(String status) {
    if (status == 'approved') return const Color(0xFF10B981); // Hijau Emerald
    if (status == 'rejected') return const Color(0xFFEF4444); // Merah Rose
    return const Color(0xFFF59E0B); // Amber Orange
  }

  String statusText(String status) {
    if (status == 'approved') return "Disetujui";
    if (status == 'rejected') return "Ditolak";
    return "Pending";
  }

  // ================= PROCESS: UPDATE STATUS LOGBOOK =================
  Future<bool> updateStatus(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('logbook')
          .update({'status': status})
          .eq('id', id);

      showFloatingNotification("Logbook berhasil di-${statusText(status)}", true);
      return true;
    } catch (e) {
      showFloatingNotification("Gagal memperbarui status logbook", false);
      return false;
    }
  }

  // ================= FLOATING NOTIFICATION BANNER =================
  void showFloatingNotification(String msg, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ================= POPUP DIALOG DI TENGAH (LIVE UPDATE TOTAL) =================
  void showDetailDialog(Map item) async {
    String namaUser = "Memuat nama...";
    String currentStatus = item['status'] ?? 'pending';

    // Menunggu respon penutupan dialog untuk memperbarui halaman utama
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Ambil data nama siswa
            Supabase.instance.client
                .from('users')
                .select('name')
                .eq('id', item['user_id'])
                .single()
                .then((value) {
                  if (context.mounted) {
                    setDialogState(() => namaUser = value['name'] ?? '-');
                  }
                }).catchError((_) {
                  if (context.mounted) {
                    setDialogState(() => namaUser = "Siswa Anonim");
                  }
                });

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.all(20),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Detail Logbook",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // User Identity Badge Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF6C63FF),
                            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(namaUser, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text(item['tanggal'] ?? "-", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Logbook Content Section
                    Text(item['judul'] ?? "-", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                      child: Text(item['kategori'] ?? "Umum", style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 14),
                    const Text("Deskripsi Kegiatan:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      item['deskripsi'] ?? "Tidak ada deskripsi tambahan.",
                      style: TextStyle(color: Colors.grey[800], height: 1.5, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Action Button State Conditional
                    if (currentStatus == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                bool success = await updateStatus(item['id'], 'rejected');
                                if (success) {
                                  setDialogState(() => currentStatus = 'rejected');
                                  if (context.mounted) Navigator.pop(context, 'rejected'); // Kembalikan status ke page utama
                                }
                              },
                              child: const Text("Tolak", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                bool success = await updateStatus(item['id'], 'approved');
                                if (success) {
                                  setDialogState(() => currentStatus = 'approved');
                                  if (context.mounted) Navigator.pop(context, 'approved'); // Kembalikan status ke page utama
                                }
                              },
                              child: const Text("Setujui", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: getStatusThemeColor(currentStatus).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Logbook ini telah ${statusText(currentStatus)}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: getStatusThemeColor(currentStatus), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Tutup", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Memicu refresh UI halaman utama agar data langsung pindah filter/berubah badge di list utama
    if (mounted) {
      setState(() {});
    }
  }

  // ================= RENDER SUB-WIDGET: CHIP FILTER LAYER =================
  Widget filterBtn(String label, String value) {
    final isActive = selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C63FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFF6C63FF) : Colors.grey[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ================= MAIN BUILD METHOD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C63FF),
      appBar: AppBar(
        title: const Text("Review Logbook", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        filterBtn("Semua", "all"),
                        filterBtn("Pending", "pending"),
                        filterBtn("Disetujui", "approved"),
                        filterBtn("Ditolak", "rejected"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: isInitialLoading
                        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))))
                        : StreamBuilder<List<Map<String, dynamic>>>(
                            stream: streamLogbook(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))));
                              }

                              final data = snapshot.data ?? [];

                              if (data.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 12),
                                      Text("Tidak ada data logbook siswa", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: data.length,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                itemBuilder: (context, i) {
                                  final item = data[i];
                                  final themeColor = getStatusThemeColor(item['status']);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => showDetailDialog(item),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey[100]!),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(5),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  item['tanggal'] ?? "-",
                                                  style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: themeColor.withAlpha(25),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    statusText(item['status']),
                                                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item['judul'] ?? "-",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D2D2D)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['deskripsi'] ?? "-",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                                            ),
                                          ],
                                        ),
                                      ),
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
          ),
        ],
      ),
    );
  }
}