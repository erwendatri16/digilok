import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessControlPage extends StatefulWidget {
  const AccessControlPage({super.key});

  @override
  State<AccessControlPage> createState() => _AccessControlPageState();
}

class _AccessControlPageState extends State<AccessControlPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> allMentors = [];
  bool isLoading = true;
  bool isMaintenanceMode = false;
  
  final _searchController = TextEditingController();
  String selectedFilterRole = 'Semua';

  @override
  void initState() {
    super.initState();
    fetchAccessData();
    fetchMaintenanceStatus();
  }

  Future<void> fetchMaintenanceStatus() async {
    try {
      final data = await supabase.from('system_settings').select('is_active').eq('id', 'maintenance_mode').maybeSingle();
      if (data != null && mounted) {
        setState(() { isMaintenanceMode = data['is_active'] ?? false; });
      }
    } catch (e) {
      debugPrint("Maintenance fetch error: $e");
    }
  }

Future<void> toggleMaintenanceMode(bool newValue) async {
  try {
    await supabase
        .from('system_settings')
        .update({'is_active': newValue})
        .eq('id', 'maintenance_mode');

    // Ambil ulang dari database
    await fetchMaintenanceStatus();

    showSnackBar(
      newValue
          ? "Mode Pemeliharaan Aktif!"
          : "Mode Pemeliharaan Nonaktif!",
    );
  } catch (e) {
    showSnackBar("Error: $e", isError: true);
  }
}

  Future<void> fetchAccessData() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase.from('users').select().order('name', ascending: true);
      if (mounted) {
        setState(() {
          allUsers = List<Map<String, dynamic>>.from(data);
          allMentors = allUsers.where((u) => u['role'] == 'mentor').toList();
          applyFilter();
          isLoading = false;
        });
      }
    } catch (e) {
      showSnackBar("Gagal memuat data: $e", isError: true);
      setState(() => isLoading = false);
    }
  }

  void applyFilter() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final role = user['role'] ?? 'user';
        bool matchesSearch = name.contains(query) || email.contains(query);
        bool matchesFilter = selectedFilterRole == 'Semua' || role.toLowerCase() == selectedFilterRole.toLowerCase();
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> insertAuditLog(String aksi, String detail) async {
    try {
      final currentUser = supabase.auth.currentUser;
      await supabase.from('audit_logs').insert({
        'admin_id': currentUser?.id,
        'admin_name': currentUser?.email?.split('@')[0] ?? 'Admin',
        'aksi': aksi,
        'detail': detail,
      });
    } catch (e) {
      debugPrint("Gagal log: $e");
    }
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus, String userName) async {
    bool newStatus = !currentStatus;
    try {
      await supabase.from('users').update({'is_active': newStatus}).eq('id', userId);
      await insertAuditLog(newStatus ? 'STATUS: AKTIF' : 'STATUS: BLOKIR', "Mengubah status $userName");
      showSnackBar("Akses status diperbarui!");
      fetchAccessData();
    } catch (e) {
      showSnackBar("Gagal: $e", isError: true);
    }
  }

  Future<void> updateUserRole(String userId, String oldRole, String newRole, String userName) async {
    if (oldRole == newRole) return;
    try {
      await supabase.from('users').update({'role': newRole}).eq('id', userId);
      await insertAuditLog('UBAH ROLE', "Mengubah role $userName");
      showSnackBar("Tingkat akses berhasil diubah!");
      fetchAccessData();
    } catch (e) {
      showSnackBar("Gagal: $e", isError: true);
    }
  }

  void showAssignMentorDialog(String userId, String userName, String? currentMentorId) {
    String? selectedMentorId = currentMentorId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Tugaskan Mentor untuk $userName"),
        content: allMentors.isEmpty
            ? const Text("Belum ada instruktur mentor di database.")
            : DropdownButtonFormField<String>(
                value: selectedMentorId,
                hint: const Text("Pilih Mentor"),
                items: allMentors.map((m) => DropdownMenuItem(value: m['id'].toString(), child: Text(m['name'] ?? 'Mentor'))).toList(),
                onChanged: (val) => selectedMentorId = val,
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          if (allMentors.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await supabase.from('users').update({'mentor_id': selectedMentorId}).eq('id', userId);
                  showSnackBar("Mentor bimbingan berhasil ditugaskan!");
                  fetchAccessData();
                } catch (e) {
                  showSnackBar("Error: $e", isError: true);
                }
              },
              child: const Text("Tugaskan"),
            ),
        ],
      ),
    );
  }

  void showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.redAccent : Colors.green, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20)));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Akses & Keamanan Peran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(width < 600 ? 12.0 : 32.0),
        child: Column(
          children: [
            // PANEL MAINTENANCE RESPONSIVE
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  Icon(Icons.construction_rounded, color: isMaintenanceMode ? Colors.amber : Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Aktifkan Maintenance Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(isMaintenanceMode ? "Hanya Admin yang bisa login." : "Kunci gerbang masuk selain admin", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(value: isMaintenanceMode, activeColor: Colors.amber, onChanged: toggleMaintenanceMode),
                ],
              ),
            ),

            // INPUT PENCARIAN RESPONSIVE (Ubah dari Row ke Column jika layar sangat sempit)
            Flex(
              direction: width < 600 ? Axis.vertical : Axis.horizontal,
              children: [
                Expanded(
                  flex: width < 600 ? 0 : 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => applyFilter(),
                    decoration: InputDecoration(
                      hintText: "Cari nama/email...",
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                if (width < 600) const SizedBox(height: 10) else const SizedBox(width: 16),
                Expanded(
                  flex: width < 600 ? 0 : 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFilterRole,
                        items: ['Semua', 'User', 'Mentor', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) { if (val != null) { setState(() { selectedFilterRole = val; applyFilter(); }); } },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // DATA LIST AKSES RESPONSIVE
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                  : filteredUsers.isEmpty
                      ? const Center(child: Text("Data tidak ditemukan."))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final String r = user['role'] ?? 'user';
                            final bool active = user['is_active'] ?? true;

                            // RENDERING ENGINE ADAPTIF (Ganti Struktur Sesuai Ukuran Layar HP/PC)
                            if (width < 768) {
                              // Tampilan Kartu Kompak untuk HP
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.shield_rounded, color: active ? Colors.green : Colors.redAccent, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Email: ${user['email'] ?? '-'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (r == 'user')
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF).withAlpha(20), foregroundColor: const Color(0xFF6C63FF), elevation: 0),
                                            onPressed: () => showAssignMentorDialog(user['id'], user['name'], user['mentor_id']),
                                            child: const Text("Mentor", style: TextStyle(fontSize: 11)),
                                          ),
                                        DropdownButton<String>(
                                          value: r[0].toUpperCase() + r.substring(1),
                                          items: ['User', 'Mentor', 'Admin'].map((ri) => DropdownMenuItem(value: ri, child: Text(ri, style: const TextStyle(fontSize: 12)))).toList(),
                                          onChanged: (newRole) => updateUserRole(user['id'], r, newRole!.toLowerCase(), user['name']),
                                        ),
                                        Row(
                                          children: [
                                            Text(active ? "AKTIF" : "BLOKIR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? Colors.green : Colors.redAccent)),
                                            Switch(value: active, activeColor: Colors.green, inactiveThumbColor: Colors.redAccent, onChanged: (_) => toggleUserStatus(user['id'], active, user['name'])),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }

                            // Tampilan Baris Melebar untuk Layar PC Desktop
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: active ? Colors.green : Colors.redAccent, size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text("Email: ${user['email'] ?? '-'}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ]),
                                  ),
                                  if (r == 'user') ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: user['mentor_id'] == null ? Colors.orange.withAlpha(25) : Colors.blue.withAlpha(25), foregroundColor: user['mentor_id'] == null ? Colors.orange : Colors.blue, elevation: 0),
                                      icon: const Icon(Icons.engineering_rounded, size: 16),
                                      label: Text(user['mentor_id'] == null ? "Assign Mentor" : "Ganti Mentor", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () => showAssignMentorDialog(user['id'], user['name'], user['mentor_id']),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: r[0].toUpperCase() + r.substring(1),
                                        style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                                        items: ['User', 'Mentor', 'Admin'].map((roleItem) => DropdownMenuItem(value: roleItem, child: Text(roleItem))).toList(),
                                        onChanged: (newRole) => updateUserRole(user['id'], r, newRole!.toLowerCase(), user['name']),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Switch(value: active, activeColor: Colors.green, inactiveThumbColor: Colors.redAccent, onChanged: (_) => toggleUserStatus(user['id'], active, user['name'])),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}