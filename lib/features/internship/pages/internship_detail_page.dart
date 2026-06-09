import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/internship_application_model.dart';
import '../repositories/internship_repository.dart';

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

class InternshipDetailPage extends StatefulWidget {
  const InternshipDetailPage({super.key});

  @override
  State<InternshipDetailPage> createState() => _InternshipDetailPageState();
}

class _InternshipDetailPageState extends State<InternshipDetailPage> {
  final InternshipRepository _repository = InternshipRepository();
  late InternshipApplication item;
  bool _initialized = false;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      item = ModalRoute.of(context)!.settings.arguments as InternshipApplication;
      _initialized = true;
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) => DateFormat('dd MMMM yyyy', 'id').format(d);

  Color _statusColor(String s) {
    switch (s) {
      case 'diterima': return _kColorDiterima;
      case 'ditolak':  return _kColorDitolak;
      default:         return _kColorPending;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'diterima': return Icons.check_circle_rounded;
      case 'ditolak':  return Icons.cancel_rounded;
      default:         return Icons.hourglass_empty_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'diterima': return 'Diterima';
      case 'ditolak':  return 'Ditolak';
      default:         return 'Pending';
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL dokumen tidak tersedia')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka dokumen')),
      );
    }
  }

  // ── AKSI TERIMA ──────────────────────────────────────────────────────────

  Future<void> _handleTerima() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _kColorDiterima, size: 22),
            SizedBox(width: 8),
            Text('Terima Pengajuan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Yakin ingin menerima pengajuan dari ${item.namaLengkap}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _kTextSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kColorDiterima,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terima'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final reviewerId = Supabase.instance.client.auth.currentUser?.id ?? '';
      await _repository.approveApplication(
        applicationId: item.id,
        reviewerId: reviewerId,
      );
      if (!mounted) return;
      setState(() {
        item = InternshipApplication(
          id: item.id,
          nomorPengajuan: item.nomorPengajuan,
          namaLengkap: item.namaLengkap,
          email: item.email,
          noHp: item.noHp,
          asalKampus: item.asalKampus,
          jurusan: item.jurusan,
          periodeMulai: item.periodeMulai,
          periodeSelesai: item.periodeSelesai,
          urlSuratPengantar: item.urlSuratPengantar,
          urlKtm: item.urlKtm,
          urlCv: item.urlCv,
          status: 'diterima',
          alasanPenolakan: item.alasanPenolakan,
          createdAt: item.createdAt,
          reviewedAt: DateTime.now(),
          reviewedBy: reviewerId,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Pengajuan ${item.namaLengkap} diterima'),
          backgroundColor: _kColorDiterima,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: _kColorDitolak),
      );
    }
    setState(() => _isProcessing = false);
  }

  // ── AKSI TOLAK ───────────────────────────────────────────────────────────

  Future<void> _handleTolak() async {
    final alasanController = TextEditingController();

    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: _kColorDitolak, size: 22),
            SizedBox(width: 8),
            Text('Tolak Pengajuan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan alasan penolakan (opsional):',
                style: TextStyle(fontSize: 13, color: _kTextSub)),
            const SizedBox(height: 10),
            TextField(
              controller: alasanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Kuota sudah penuh...',
                hintStyle: const TextStyle(fontSize: 13, color: _kTextSub),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kAccent),
                ),
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
              backgroundColor: _kColorDitolak,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, alasanController.text.trim()),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (alasan == null) return; // user tekan Batal

    setState(() => _isProcessing = true);
    try {
      final reviewerId = Supabase.instance.client.auth.currentUser?.id ?? '';
      await _repository.rejectApplication(
        applicationId: item.id,
        reviewerId: reviewerId,
        alasan: alasan,
      );
      if (!mounted) return;
      setState(() {
        item = InternshipApplication(
          id: item.id,
          nomorPengajuan: item.nomorPengajuan,
          namaLengkap: item.namaLengkap,
          email: item.email,
          noHp: item.noHp,
          asalKampus: item.asalKampus,
          jurusan: item.jurusan,
          periodeMulai: item.periodeMulai,
          periodeSelesai: item.periodeSelesai,
          urlSuratPengantar: item.urlSuratPengantar,
          urlKtm: item.urlKtm,
          urlCv: item.urlCv,
          status: 'ditolak',
          alasanPenolakan: alasan.isEmpty ? null : alasan,
          createdAt: item.createdAt,
          reviewedAt: DateTime.now(),
          reviewedBy: reviewerId,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Pengajuan ${item.namaLengkap} ditolak'),
          backgroundColor: _kColorDitolak,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: _kColorDitolak),
      );
    }
    setState(() => _isProcessing = false);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        title: const Text(
          'Detail Pengajuan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),

      // ── TOMBOL AKSI di bottom (hanya jika pending) ────────────────────
      bottomNavigationBar: item.status == 'pending'
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: _kCardBg,
                border: Border(top: BorderSide(color: _kBorder)),
              ),
              child: _isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(color: _kAccent))
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleTolak,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Tolak',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kColorDitolak,
                              side: const BorderSide(color: _kColorDitolak),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _handleTerima,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Terima Pengajuan',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kColorDiterima,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER CARD ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _kAccent.withValues(alpha: 0.10),
                    child: Text(
                      item.namaLengkap.isNotEmpty
                          ? item.namaLengkap[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: _kAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.namaLengkap,
                    style: const TextStyle(
                        color: _kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.nomorPengajuan,
                    style: const TextStyle(color: _kTextSub, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  // Badge status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(item.status),
                            color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(item.status),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // Alasan penolakan (jika ada)
                  if (item.status == 'ditolak' &&
                      item.alasanPenolakan != null &&
                      item.alasanPenolakan!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kColorDitolak.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kColorDitolak.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alasan Penolakan',
                              style: TextStyle(
                                  color: _kColorDitolak,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(item.alasanPenolakan!,
                              style: const TextStyle(
                                  color: _kTextPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── INFO PRIBADI ─────────────────────────────────────────────
            _buildSection(
              title: 'Informasi Pribadi',
              icon: Icons.person_rounded,
              children: [
                _buildInfoRow(Icons.email_rounded, 'Email', item.email),
                _buildInfoRow(Icons.phone_rounded, 'No HP', item.noHp),
                _buildInfoRow(
                    Icons.school_rounded, 'Asal Kampus', item.asalKampus),
                _buildInfoRow(
                    Icons.book_rounded, 'Jurusan', item.jurusan),
              ],
            ),

            const SizedBox(height: 12),

            // ── PERIODE MAGANG ────────────────────────────────────────────
            _buildSection(
              title: 'Periode Magang',
              icon: Icons.calendar_month_rounded,
              children: [
                _buildInfoRow(Icons.play_arrow_rounded, 'Mulai',
                    _formatDate(item.periodeMulai)),
                _buildInfoRow(Icons.stop_rounded, 'Selesai',
                    _formatDate(item.periodeSelesai)),
              ],
            ),

            const SizedBox(height: 12),

            // ── DOKUMEN ───────────────────────────────────────────────────
            _buildSection(
              title: 'Dokumen',
              icon: Icons.folder_rounded,
              children: [
                _buildDocRow(
                  icon: Icons.description_rounded,
                  label: 'Surat Pengantar',
                  url: item.urlSuratPengantar,
                ),
                _buildDocRow(
                  icon: Icons.badge_rounded,
                  label: 'KTM / Kartu Pelajar',
                  url: item.urlKtm,
                ),
                _buildDocRow(
                  icon: Icons.article_rounded,
                  label: 'Curriculum Vitae',
                  url: item.urlCv,
                ),
              ],
            ),

            // Info review (jika sudah direview)
            if (item.reviewedAt != null) ...[
              const SizedBox(height: 12),
              _buildSection(
                title: 'Info Review',
                icon: Icons.rate_review_rounded,
                children: [
                  _buildInfoRow(Icons.access_time_rounded, 'Direview pada',
                      _formatDate(item.reviewedAt!)),
                ],
              ),
            ],

            // Padding bawah untuk bottomNavigationBar
            if (item.status == 'pending') const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── SECTION WRAPPER ───────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    color: _kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ── ROW INFO ──────────────────────────────────────────────────────────────
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _kTextSub),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: _kTextSub, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── ROW DOKUMEN ───────────────────────────────────────────────────────────
  Widget _buildDocRow({
    required IconData icon,
    required String label,
    required String? url,
  }) {
    final bool available = url != null && url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kTextSub),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: _kTextPrimary, fontSize: 13)),
          ),
          GestureDetector(
            onTap: available ? () => _openUrl(url) : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: available
                    ? _kAccent.withValues(alpha: 0.10)
                    : _kBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    available
                        ? Icons.open_in_new_rounded
                        : Icons.block_rounded,
                    size: 13,
                    color: available ? _kAccent : _kTextSub,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    available ? 'Buka' : 'Tidak ada',
                    style: TextStyle(
                        color: available ? _kAccent : _kTextSub,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}