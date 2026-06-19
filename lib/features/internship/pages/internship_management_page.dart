import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final result = await showDialog<_MgmtTerimaResult>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _MgmtTerimaDialog(namaLengkap: item.namaLengkap),
      );
      if (result == null) return;

      try {
        String? urlSuratBalasan;
        if (result.file != null) {
          urlSuratBalasan =
              await _uploadSuratBalasan(item.id, result.file!);
        }
        await _repository.approveApplication(
          applicationId: item.id,
          reviewerId: reviewerId,
          urlSuratBalasan: urlSuratBalasan,
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

  // ── UPLOAD SURAT BALASAN ──────────────────────────────────────────────────

  Future<String?> _uploadSuratBalasan(
      String applicationId, PlatformFile file) async {
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final ext = file.extension ?? 'pdf';
    final fileName =
        'surat_balasan_${applicationId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _repository.supabase.storage
        .from('surat-balasan')
        .uploadBinary(fileName, bytes,
            fileOptions: FileOptions(contentType: 'application/$ext'));

    return _repository.supabase.storage
        .from('surat-balasan')
        .getPublicUrl(fileName);
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

          // ── STATUS CHIP TABS (FIXED: SEIMBANG BAGI RATA 4 KOLOM) ──────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              // Setiap item dalam status list akan dibungkus Expanded secara adil
              children: _statusTabs.map((status) {
                final isSelected = selectedStatus == status;
                final color = _statusColor(status);
                
                return Expanded(
                  child: Container(
                    // Memberi margin kanan ke semua item kecuali item terakhir agar pas di layout layar
                    margin: EdgeInsets.only(
                      right: status == _statusTabs.last ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => selectedStatus = status);
                        filterData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? color : _kCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected ? color : _kBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _statusIcon(status),
                              size: 13,
                              color: isSelected ? Colors.white : color,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _kTextSub,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

// =============================================================================
// DATA CLASS — hasil dialog terima
// =============================================================================
class _MgmtTerimaResult {
  final PlatformFile? file;
  const _MgmtTerimaResult({this.file});
}

// =============================================================================
// DIALOG TERIMA — stateful dengan upload surat balasan
// =============================================================================
class _MgmtTerimaDialog extends StatefulWidget {
  final String namaLengkap;
  const _MgmtTerimaDialog({required this.namaLengkap});

  @override
  State<_MgmtTerimaDialog> createState() => _MgmtTerimaDialogState();
}

class _MgmtTerimaDialogState extends State<_MgmtTerimaDialog> {
  PlatformFile? _file;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: _kColorDiterima, size: 22),
          SizedBox(width: 8),
          Text('Terima Pengajuan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yakin menerima pengajuan dari ${widget.namaLengkap}?',
              style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Surat Balasan (opsional)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload surat balasan/penerimaan untuk peserta magang.',
              style: TextStyle(fontSize: 12, color: _kTextSub),
            ),
            const SizedBox(height: 10),
            if (_file == null)
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _kColorDiterima.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _kColorDiterima.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.upload_file_rounded,
                          color: _kColorDiterima, size: 28),
                      SizedBox(height: 6),
                      Text('Tap untuk pilih file',
                          style: TextStyle(
                              color: _kColorDiterima,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('PDF, DOC, DOCX',
                          style:
                              TextStyle(color: _kTextSub, fontSize: 11)),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kColorDiterima.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _kColorDiterima.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kColorDiterima.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.insert_drive_file_rounded,
                          color: _kColorDiterima, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _file!.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kTextPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _file!.size > 0
                                ? _formatBytes(_file!.size)
                                : 'Ukuran tidak diketahui',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextSub),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.swap_horiz_rounded,
                          color: _kAccent, size: 18),
                      tooltip: 'Ganti file',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _file = null),
                      icon: const Icon(Icons.close_rounded,
                          color: _kColorDitolak, size: 18),
                      tooltip: 'Hapus file',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: _kTextSub)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kColorDiterima,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () =>
              Navigator.pop(context, _MgmtTerimaResult(file: _file)),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Terima'),
        ),
      ],
    );
  }
}