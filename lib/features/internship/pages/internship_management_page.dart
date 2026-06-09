import 'package:flutter/material.dart';

import '../models/internship_application_model.dart';
import '../repositories/internship_repository.dart';
import '../widgets/application_card.dart';

// ===========================================================================
// COLOR TOKENS
// ===========================================================================
const _kBgPage        = Color(0xFFF0F2F8);
const _kAccent        = Color(0xFF3D3DB4);
const _kCardBg        = Colors.white;
const _kBorder        = Color(0xFFE2E8F0);
const _kTextPrimary   = Color(0xFF0F172A);
const _kTextSub       = Color(0xFF64748B);
const _kColorPending  = Color(0xFFF59E0B);
const _kColorDiterima = Color(0xFF10B981);
const _kColorDitolak  = Color(0xFFEF4444);
const _kColorSemua    = Color(0xFF3D3DB4);

class InternshipManagementPage extends StatefulWidget {
  const InternshipManagementPage({super.key});

  @override
  State<InternshipManagementPage> createState() =>
      _InternshipManagementPageState();
}

class _InternshipManagementPageState
    extends State<InternshipManagementPage> {
  final InternshipRepository _repository = InternshipRepository();

  List<InternshipApplication> applications = [];
  List<InternshipApplication> filtered = [];

  bool isLoading = true;
  String selectedStatus = 'Semua';

  final TextEditingController searchController = TextEditingController();
  final List<String> _statusTabs = ['Semua', 'pending', 'diterima', 'ditolak'];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ── DATA ──────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final data = await _repository.getApplications();
      setState(() {
        applications = data;
        filtered = data;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => isLoading = false);
  }

  void filterData() {
    final keyword = searchController.text.toLowerCase();
    List<InternshipApplication> temp = applications;
    if (selectedStatus != 'Semua') {
      temp = temp.where((e) => e.status == selectedStatus).toList();
    }
    if (keyword.isNotEmpty) {
      temp = temp
          .where((e) => e.namaLengkap.toLowerCase().contains(keyword))
          .toList();
    }
    setState(() => filtered = temp);
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────

  Future<void> _updateStatus(
      InternshipApplication item, String newStatus) async {
    final color = newStatus == 'diterima' ? _kColorDiterima : _kColorDitolak;
    final icon = newStatus == 'diterima'
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final reviewerId = _repository.supabase.auth.currentUser?.id ?? '';

    if (newStatus == 'diterima') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            const Text('Terima Pengajuan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: Text(
              'Yakin ingin menerima pengajuan dari ${item.namaLengkap}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: _kTextSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Terima'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      try {
        await _repository.approveApplication(
          applicationId: item.id,
          reviewerId: reviewerId,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: _kColorDitolak,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    } else {
      final alasanController = TextEditingController();
      final alasan = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            const Text('Tolak Pengajuan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alasan penolakan (opsional):',
                  style: TextStyle(fontSize: 13, color: _kTextSub)),
              const SizedBox(height: 10),
              TextField(
                controller: alasanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Kuota sudah penuh...',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: _kTextSub),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kAccent)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: _kTextSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () =>
                  Navigator.pop(ctx, alasanController.text.trim()),
              child: const Text('Tolak'),
            ),
          ],
        ),
      );
      if (alasan == null) return;

      try {
        await _repository.rejectApplication(
          applicationId: item.id,
          reviewerId: reviewerId,
          alasan: alasan,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: _kColorDitolak,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'diterima'
              ? '✅ Pengajuan ${item.namaLengkap} diterima'
              : '❌ Pengajuan ${item.namaLengkap} ditolak',
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    await loadData();
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  int _countByStatus(String status) {
    if (status == 'Semua') return applications.length;
    return applications.where((e) => e.status == status).length;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':  return _kColorPending;
      case 'diterima': return _kColorDiterima;
      case 'ditolak':  return _kColorDitolak;
      default:         return _kColorSemua;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':  return 'Pending';
      case 'diterima': return 'Diterima';
      case 'ditolak':  return 'Ditolak';
      default:         return 'Semua';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':  return Icons.hourglass_empty_rounded;
      case 'diterima': return Icons.check_circle_rounded;
      case 'ditolak':  return Icons.cancel_rounded;
      default:         return Icons.folder_copy_rounded;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        title: const Text(
          'Manajemen Magang',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh_rounded, color: _kAccent),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ── SEARCH BAR ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => filterData(),
                style:
                    const TextStyle(fontSize: 14, color: _kTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari nama mahasiswa...',
                  hintStyle:
                      const TextStyle(color: _kTextSub, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _kTextSub, size: 20),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: _kTextSub),
                          onPressed: () {
                            searchController.clear();
                            filterData();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── STATUS CHIP TABS ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statusTabs.map((status) {
                final isSelected = selectedStatus == status;
                final color = _statusColor(status);
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedStatus = status);
                    filterData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? color : _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected ? color : _kBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(_statusIcon(status),
                            size: 14,
                            color: isSelected ? Colors.white : color),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : _kTextSub,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_countByStatus(status)}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // ── RESULT COUNT ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${filtered.length} pengajuan ditemukan',
              style: const TextStyle(color: _kTextSub, fontSize: 12),
            ),
          ),

          const SizedBox(height: 8),

          // ── LIST ──────────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kAccent))
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _buildCard(filtered[index]),
                      ),
          ),
        ],
      ),
    );
  }

  // ── CARD ──────────────────────────────────────────────────────────────────

  Widget _buildCard(InternshipApplication item) {
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(
            context,
            '/internship-detail',
            arguments: item,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Baris atas: avatar + info + badge ──
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _kAccent.withValues(alpha: 0.10),
                      child: Text(
                        item.namaLengkap.isNotEmpty
                            ? item.namaLengkap[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: _kAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ApplicationCard(
                        application: item,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(item.status),
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),

                // ── Tombol aksi (pending only) ──
                if (item.status == 'pending') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: _kBorder),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(item, 'ditolak'),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Tolak',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kColorDitolak,
                            side: const BorderSide(color: _kColorDitolak),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(item, 'diterima'),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Terima',
                              style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kColorDiterima,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded, size: 48, color: _kAccent),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pengajuan',
            style: TextStyle(
                color: _kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            selectedStatus == 'Semua'
                ? 'Data pengajuan magang akan muncul di sini.'
                : 'Tidak ada pengajuan dengan status "${_statusLabel(selectedStatus)}".',
            style: const TextStyle(color: _kTextSub, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}