import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/internship_repository.dart';
import '../widgets/statistics_card.dart';
import 'internship_management_page.dart';

class InternshipDashboardPage extends StatefulWidget {
const InternshipDashboardPage({super.key});

@override
State<InternshipDashboardPage> createState() =>
_InternshipDashboardPageState();
}

class _InternshipDashboardPageState
extends State<InternshipDashboardPage> {
final InternshipRepository _repository =
InternshipRepository();

final supabase = Supabase.instance.client;

bool isLoading = true;
bool isSavingQuota = false;

Map<String, int> statistics = {};

final TextEditingController quotaController = TextEditingController();

int maxQuota = 20;
@override
void initState() {
super.initState();
loadDashboard();
}

@override
void dispose() {
quotaController.dispose();
super.dispose();
}

Future<void> loadDashboard() async {
try {
final stats =
await _repository.getDashboardStatistics();

  // Ambil max_quota dari tabel internship_settings
  final settingsData = await supabase
      .from('internship_settings')
      .select('max_quota')
      .eq('id', 1)
      .maybeSingle();

  if (mounted) {
    setState(() {
      statistics = stats;
      maxQuota = settingsData?['max_quota'] ?? 20;
      quotaController.text = maxQuota.toString();
      isLoading = false;
    });
  }
} catch (e) {
  debugPrint(e.toString());
  if (mounted) {
    setState(() => isLoading = false);
  }
}
}

Future<void> saveQuota() async {
final input = int.tryParse(quotaController.text.trim());
if (input == null || input < 1) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Kuota tidak valid. Masukkan angka minimal 1.')),
  );
  return;
}

setState(() => isSavingQuota = true);

try {
  await supabase
      .from('internship_settings')
      .upsert({'id': 1, 'max_quota': input, 'updated_at': DateTime.now().toIso8601String()});

  if (mounted) {
    setState(() {
      maxQuota = input;
      isSavingQuota = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kuota berhasil disimpan.'),
        backgroundColor: Colors.green,
      ),
    );
  }
} catch (e) {
  if (mounted) {
    setState(() => isSavingQuota = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal menyimpan: $e')),
    );
  }
}
}

int get total =>
statistics['total'] ?? 0;

int get pending =>
statistics['pending'] ?? 0;

int get diterima =>
statistics['diterima'] ?? 0;

int get ditolak =>
statistics['ditolak'] ?? 0;

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor:
const Color(0xFFF8FAFC),


  appBar: AppBar(
    title: const Text(
      'Manajemen Magang',
    ),
    backgroundColor: Colors.white,
    elevation: 0,
    actions: [
      IconButton(
        tooltip: 'Refresh',
        onPressed: loadDashboard,
        icon: const Icon(
          Icons.refresh_rounded,
        ),
      )
    ],
  ),

  body: isLoading
      ? const Center(
          child:
              CircularProgressIndicator(),
        )
      : SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // HEADER
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                        24),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius
                          .circular(24),
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(
                          0xFF1E3A8A),
                      Color(
                          0xFF2563EB),
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Portal Magang Diskominfotik',
                      style:
                          TextStyle(
                        color:
                            Colors
                                .white,
                        fontSize:
                            28,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                    SizedBox(
                        height: 8),
                    Text(
                      'Monitoring dan Pengelolaan Pengajuan Magang',
                      style:
                          TextStyle(
                        color: Colors
                            .white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // STATISTIK
              LayoutBuilder(
                builder:
                    (context,
                        constraints) {
                  final isMobile =
                      constraints
                              .maxWidth <
                          700;

                  if (isMobile) {
                    return Column(
                      children: [
                        StatisticsCard(
                          title:
                              'Total Pengajuan',
                          value:
                              total
                                  .toString(),
                          icon:
                              Icons
                                  .folder_copy,
                          color:
                              Colors
                                  .blue,
                        ),
                        const SizedBox(
                            height:
                                12),
                        StatisticsCard(
                          title:
                              'Pending',
                          value:
                              pending
                                  .toString(),
                          icon: Icons
                              .hourglass_bottom,
                          color:
                              Colors
                                  .orange,
                        ),
                        const SizedBox(
                            height:
                                12),
                        StatisticsCard(
                          title:
                              'Diterima',
                          value:
                              diterima
                                  .toString(),
                          icon:
                              Icons
                                  .check_circle,
                          color:
                              Colors
                                  .green,
                        ),
                        const SizedBox(
                            height:
                                12),
                        StatisticsCard(
                          title:
                              'Ditolak',
                          value:
                              ditolak
                                  .toString(),
                          icon:
                              Icons
                                  .cancel,
                          color:
                              Colors
                                  .red,
                        ),
                      ],
                    );
                  }

                  return GridView.count(
                    crossAxisCount:
                        4,
                    shrinkWrap:
                        true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing:
                        16,
                    mainAxisSpacing:
                        16,
                    childAspectRatio:
                        2.5,
                    children: [
                      StatisticsCard(
                        title:
                            'Total Pengajuan',
                        value: total
                            .toString(),
                        icon: Icons
                            .folder_copy,
                        color:
                            Colors
                                .blue,
                      ),
                      StatisticsCard(
                        title:
                            'Pending',
                        value: pending
                            .toString(),
                        icon: Icons
                            .hourglass_bottom,
                        color:
                            Colors
                                .orange,
                      ),
                      StatisticsCard(
                        title:
                            'Diterima',
                        value:
                            diterima
                                .toString(),
                        icon: Icons
                            .check_circle,
                        color:
                            Colors
                                .green,
                      ),
                      StatisticsCard(
                        title:
                            'Ditolak',
                        value:
                            ditolak
                                .toString(),
                        icon: Icons
                            .cancel,
                        color:
                            Colors
                                .red,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(
                height: 24,
              ),

              // PROGRESS
              Card(
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets
                          .all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Progress Pengajuan',
                        style:
                            TextStyle(
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                          height:
                              16),
                      LinearProgressIndicator(
                        value:
                            total ==
                                    0
                                ? 0
                                : (diterima +
                                        ditolak) /
                                    total,
                      ),
                      const SizedBox(
                          height:
                              12),
                      Text(
                        '${diterima + ditolak} dari $total pengajuan telah diproses',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // QUICK ACTION
              Card(
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets
                          .all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Aksi Cepat',
                        style:
                            TextStyle(
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                          height:
                              20),
                      Wrap(
                        spacing:
                            12,
                        runSpacing:
                            12,
                        children: [
                          ElevatedButton
                              .icon(
                            icon:
                                const Icon(
                              Icons
                                  .school,
                            ),
                            label:
                                const Text(
                              'Kelola Pengajuan',
                            ),
                            onPressed:
                                () {
                              Navigator
                                  .push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const InternshipManagementPage(),
                                ),
                              );
                            },
                          ),
                          ElevatedButton
                              .icon(
                            icon:
                                const Icon(
                              Icons
                                  .refresh,
                            ),
                            label:
                                const Text(
                              'Refresh',
                            ),
                            onPressed:
                                loadDashboard,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // PENGATURAN KUOTA
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul + info sisa kuota
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Pengaturan Kuota Magang',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Badge sisa kuota
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (maxQuota - diterima) <= 0
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Sisa: ${(maxQuota - diterima).clamp(0, maxQuota)}',
                              style: TextStyle(
                                color: (maxQuota - diterima) <= 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text(
                        'Diterima: $diterima dari $maxQuota kuota',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // Progress bar kuota terpakai
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: maxQuota == 0 ? 0 : (diterima / maxQuota).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            diterima >= maxQuota ? Colors.red : const Color(0xFF2563EB),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Ubah Kuota Maksimal',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 10),

                      // Input + tombol simpan
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quotaController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Contoh: 50',
                                prefixIcon: const Icon(Icons.people_alt_rounded, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: isSavingQuota ? null : saveQuota,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: isSavingQuota
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),

                      // Peringatan jika kuota penuh
                      if (diterima >= maxQuota) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kuota magang sudah penuh. Pengajuan baru tidak dapat diterima.',
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
);

}
}