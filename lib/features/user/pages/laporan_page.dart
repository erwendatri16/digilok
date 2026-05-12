import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ FIX: Satu import saja — akses TableHelper via pw.TableHelper
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int totalLogbook    = 0;
  int pendingLogbook  = 0;
  int approvedLogbook = 0;
  int rejectedLogbook = 0;
  int totalHadirAbsen = 0;

  bool isLoading    = true;
  bool isExporting  = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final logbookData = await Supabase.instance.client
          .from('logbook')
          .select()
          .eq('user_id', user.id);

      final absensiData = await Supabase.instance.client
          .from('absensi')
          .select()
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        totalLogbook    = logbookData.length;
        pendingLogbook  =
            logbookData.where((e) => e['status'] == 'pending').length;
        approvedLogbook =
            logbookData.where((e) => e['status'] == 'approved').length;
        rejectedLogbook =
            logbookData.where((e) => e['status'] == 'rejected').length;
        totalHadirAbsen = absensiData.length;
        isLoading       = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("loadData error: $e");
    }
  }

  // ================= EXPORT PDF =================
  Future<void> exportPDF(List logbookData) async {
    setState(() => isExporting = true);

    try {
      final pdf  = pw.Document();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => isExporting = false);
        return;
      }

      final now          = DateTime.now();
      final tanggalCetak = "${now.day}-${now.month}-${now.year}";

      String mentorName = "-";
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('mentor_id')
            .eq('id', user.id)
            .single();

        if (userData['mentor_id'] != null) {
          final mentor = await Supabase.instance.client
              .from('users')
              .select('name')
              .eq('id', userData['mentor_id'])
              .single();
          mentorName = mentor['name'] ?? "-";
        }
      } catch (_) {}

      List absensiData = [];
      try {
        absensiData = await Supabase.instance.client
            .from('absensi')
            .select()
            .eq('user_id', user.id)
            .order('tanggal', ascending: false);
      } catch (_) {}

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pdfContext) => [
            pw.Center(
              child: pw.Text(
                "LAPORAN BULANAN MAGANG",
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(child: pw.Text("DIGILOK SYSTEM")),
            pw.Divider(),
            pw.Text("Tanggal Cetak: $tanggalCetak"),
            pw.SizedBox(height: 15),

            pw.Text("1. Ringkasan Aktivitas",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(
                "Total Presensi Kehadiran: $totalHadirAbsen Hari"),
            pw.Text(
                "Total Pengajuan Logbook: $totalLogbook Kegiatan "
                "($approvedLogbook Disetujui, $rejectedLogbook Ditolak, "
                "$pendingLogbook Pending)"),
            pw.SizedBox(height: 15),

            pw.Text("2. Detail Logbook",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),

            pw.TableHelper.fromTextArray(
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              headers: ["Tanggal", "Judul", "Kategori", "Status"],
              data: logbookData
                  .map((e) => [
                        e['tanggal'] ?? '-',
                        e['judul'] ?? '-',
                        e['kategori'] ?? '-',
                        e['status'] ?? '-',
                      ])
                  .toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Text("3. Detail Absensi",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),

            pw.TableHelper.fromTextArray(
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              headers: ["Tanggal", "Jam Masuk", "Jam Pulang"],
              data: absensiData
                  .map((e) => [
                        e['tanggal'] ?? '-',
                        e['jam_masuk'] ?? '-',
                        e['jam_pulang'] ?? '-',
                      ])
                  .toList(),
            ),

            pw.SizedBox(height: 40),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Mengetahui,"),
                  pw.SizedBox(height: 50),
                  pw.Text(mentorName,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
          onLayout: (format) async => pdf.save());
          
    } catch (e) {
      debugPrint("exportPDF error: $e");
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal export PDF: $e"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Laporan",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: const Color(0xFF6C63FF),
              onRefresh: () async {
                setState(() => isLoading = true);
                await loadData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Tombol Export
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: isExporting
                            ? null
                            : () async {
                                if (user == null) return;
                                
                                // ✅ FIX BARU: Ambil messenger state sebelum memasuki celah asinkronus (async gap)
                                final messenger = ScaffoldMessenger.of(context);
                                
                                try {
                                  final data = await Supabase
                                      .instance.client
                                      .from('logbook')
                                      .select()
                                      .eq('user_id', user.id)
                                      .order('created_at',
                                          ascending: false);
                                  await exportPDF(data);
                                } catch (e) {
                                  // ✅ FIX BARU: Cek menggunakan context.mounted bawaan BuildContext local closure
                                  if (!context.mounted) return;
                                  
                                  // Gunakan objek messenger yang sudah diekstrak dengan aman di atas
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        "Gagal memuat data: $e"),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              },
                        icon: isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_rounded,
                                color: Colors.white),
                        label: Text(
                          isExporting
                              ? "Membuat PDF..."
                              : "Export PDF Sekarang",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Statistik Logbook
                    const Text("Statistik Logbook",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                            child: _card("Total Buku",
                                totalLogbook, Colors.blue)),
                        Expanded(
                            child: _card("Pending",
                                pendingLogbook, Colors.orange)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _card("Disetujui",
                                approvedLogbook, Colors.green)),
                        Expanded(
                            child: _card("Ditolak",
                                rejectedLogbook, Colors.red)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Statistik Kehadiran
                    const Text("Statistik Kehadiran",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _card(
                              "Total Kehadiran Absensi",
                              totalHadirAbsen,
                              Colors.teal),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card(String title, int value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: color),
          ),
        ],
      ),
    );
  }
}