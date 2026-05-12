import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PenilaianPage extends StatefulWidget {
  const PenilaianPage({super.key});

  @override
  State<PenilaianPage> createState() => _PenilaianPageState();
}

class _PenilaianPageState extends State<PenilaianPage> {

  final namaC      = TextEditingController();
  final nimC       = TextEditingController();
  final instansiC  = TextEditingController();
  final unitC      = TextEditingController();
  final pembLapC   = TextEditingController();
  final pembAkdC   = TextEditingController();

  String namaMentor = "";

  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = false;

  Map<String, TextEditingController> catatan = {};

  Map<String, int> inti = {
    "Disiplin": 3,
    "Tanggung jawab": 3,
    "Komunikasi": 3,
    "Kerja sama tim": 3,
    "Inisiatif": 3,
    "Kualitas kerja": 3,
  };

  Map<String, int> teknis = {
    "Penguasaan tools": 3,
    "Penyelesaian tugas": 3,
    "Ketelitian": 3,
    "Problem solving": 3,
  };

  Map<String, int> self = {
    "Memahami tugas": 3,
    "Berkembang": 3,
    "Aktif belajar": 3,
  };

  // ================= WARNA PDF =================
  static const _navyPdf      = PdfColor.fromInt(0xFF1E3A8A);
  static const _unguPdf      = PdfColor.fromInt(0xFF6C63FF);
  static const _unguMudaPdf  = PdfColor.fromInt(0xFFF3F1FF);
  static const _abuPdf       = PdfColor.fromInt(0xFFF5F5F5);
  static const _abuGarisPdf  = PdfColor.fromInt(0xFFCCCCCC);
  static const _hitamPdf     = PdfColor.fromInt(0xFF1A1A1A);
  static const _abuTeksPdf   = PdfColor.fromInt(0xFF555555);

  @override
  void initState() {
    super.initState();
    loadMentor();
    for (var k in {...inti, ...teknis, ...self}.keys) {
      catatan[k] = TextEditingController();
    }
  }

  @override
  void dispose() {
    namaC.dispose(); nimC.dispose(); instansiC.dispose();
    unitC.dispose(); pembLapC.dispose(); pembAkdC.dispose();
    for (var c in catatan.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ================= LOAD =================
  Future<void> loadMentor() async {
    final user = Supabase.instance.client.auth.currentUser;
    final data = await Supabase.instance.client
        .from('users').select('name').eq('id', user!.id).single();
    if (!mounted) return;
    setState(() {
      namaMentor = data['name'] ?? "";
      pembLapC.text = namaMentor;
    });
  }

  // ================= HELPER =================
  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (!mounted || picked == null) return;
    setState(() => isStart ? startDate = picked : endDate = picked);
  }

  String formatDate(DateTime? d) {
    if (d == null) return "-";
    final bulan = ["Jan","Feb","Mar","Apr","Mei","Jun",
                   "Jul","Agt","Sep","Okt","Nov","Des"];
    return "${d.day} ${bulan[d.month - 1]} ${d.year}";
  }

  double avg(Map<String, int> d) =>
      d.values.reduce((a, b) => a + b) / d.length;

  double get nilaiAkhir =>
      (avg(inti) * 0.4) + (avg(teknis) * 0.3) + (avg(self) * 0.3);

  String nilaiLabel(int n) {
    switch (n) {
      case 1: return "Sangat Kurang";
      case 2: return "Kurang";
      case 3: return "Cukup";
      case 4: return "Baik";
      case 5: return "Sangat Baik";
      default: return "-";
    }
  }

  // ✅ BARU: warna label per nilai
  Color _labelColor(int n) {
    switch (n) {
      case 1: return const Color(0xFFDC2626); // merah
      case 2: return const Color(0xFFEA580C); // oranye
      case 3: return const Color(0xFFB45309); // amber gelap
      case 4: return const Color(0xFF16A34A); // hijau
      case 5: return const Color(0xFF15803D); // hijau tua
      default: return Colors.black;
    }
  }

  // ✅ BARU: warna background badge per nilai
  Color _labelBg(int n) {
    switch (n) {
      case 1: return const Color(0xFFFEE2E2);
      case 2: return const Color(0xFFFFEDD5);
      case 3: return const Color(0xFFFEF9C3);
      case 4: return const Color(0xFFDCFCE7);
      case 5: return const Color(0xFFBBF7D0);
      default: return Colors.grey.shade100;
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ================= SIMPAN =================
  Future<void> simpan() async {
    if (namaC.text.isEmpty || nimC.text.isEmpty) {
      _snack("Isi nama dan NIM terlebih dahulu", Colors.red);
      return;
    }
    setState(() => isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('penilaian').insert({
        "user_id": user!.id,
        "nama": namaC.text,
        "nim": nimC.text,
        "instansi": instansiC.text,
        "unit": unitC.text,
        "periode_mulai": startDate?.toIso8601String(),
        "periode_selesai": endDate?.toIso8601String(),
        "pembimbing_lapangan": namaMentor,
        "pembimbing_akademik": pembAkdC.text,
        "nilai_akhir": nilaiAkhir * 20,
        "catatan": {for (var k in catatan.keys) k: catatan[k]!.text},
      });
      if (!mounted) return;
      _snack("Berhasil disimpan", Colors.green);
    } catch (e) {
      if (!mounted) return;
      _snack("Gagal simpan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= EXPORT PDF =================
  Future<void> exportPdf() async {
    setState(() => isLoading = true);

    try {
      final pdf = pw.Document();

      final fontRegular = await PdfGoogleFonts.nunitoRegular();
      final fontBold    = await PdfGoogleFonts.nunitoBold();

      pw.TextStyle ts({
        double size = 9,
        bool bold = false,
        PdfColor color = PdfColors.black,
      }) =>
          pw.TextStyle(
            font: bold ? fontBold : fontRegular,
            fontSize: size,
            color: color,
          );

      pw.Widget infoRow(String label, String value) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 110,
                  child: pw.Text(label, style: ts(bold: true)),
                ),
                pw.Text(": ", style: ts()),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: _abuGarisPdf, width: 0.5),
                      ),
                    ),
                    child: pw.Text(
                      value.isEmpty ? " " : value,
                      style: ts(),
                    ),
                  ),
                ),
              ],
            ),
          );

      pw.Widget cell(String text, pw.TextStyle style, {bool center = false}) =>
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: center
                ? pw.Center(child: pw.Text(text, style: style))
                : pw.Text(text, style: style),
          );

      // ✅ PERBAIKAN PDF: kolom Ket. lebih lebar (52pt) agar "Sangat Kurang" muat
      pw.Widget penilaianTable(
          String title, Map<String, int> data, int startNo) {
        int no = startNo;
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              color: _navyPdf,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: pw.Text(title,
                  style: ts(bold: true, color: PdfColors.white, size: 9)),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: _abuGarisPdf, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(22),   // No
                1: const pw.FlexColumnWidth(3),      // Aspek Penilaian
                2: const pw.FixedColumnWidth(36),    // Nilai (1-5)
                3: const pw.FixedColumnWidth(56),    // ✅ Ket. lebih lebar
                4: const pw.FlexColumnWidth(4),      // Catatan
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _abuPdf),
                  children: [
                    cell("No",              ts(bold: true, size: 8), center: true),
                    cell("Aspek Penilaian", ts(bold: true, size: 8)),
                    cell("Nilai\n(1–5)",    ts(bold: true, size: 8), center: true),
                    cell("Ket.",            ts(bold: true, size: 8), center: true),
                    cell("Catatan",         ts(bold: true, size: 8)),
                  ],
                ),
                // Data rows
                ...data.entries.map((e) {
                  final note = catatan[e.key]?.text ?? "";
                  // ✅ Warna teks Ket. di PDF sesuai nilai
                  PdfColor ketColor;
                  switch (e.value) {
                    case 1: ketColor = const PdfColor.fromInt(0xFFDC2626); break;
                    case 2: ketColor = const PdfColor.fromInt(0xFFEA580C); break;
                    case 3: ketColor = const PdfColor.fromInt(0xFFB45309); break;
                    case 4: ketColor = const PdfColor.fromInt(0xFF16A34A); break;
                    case 5: ketColor = const PdfColor.fromInt(0xFF15803D); break;
                    default: ketColor = _abuTeksPdf;
                  }
                  return pw.TableRow(children: [
                    cell("${no++}",                         ts(size: 8),  center: true),
                    cell(e.key,                             ts(size: 8)),
                    cell("${e.value}",                      ts(size: 9, bold: true), center: true),
                    // ✅ Ket. dengan warna & font bold, wrapping otomatis
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Center(
                        child: pw.Text(
                          nilaiLabel(e.value),
                          style: ts(size: 7.5, bold: true, color: ketColor),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    cell(note.isEmpty ? "-" : note, ts(size: 8)),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
        );
      }

      pw.Widget avgRow(String label, double val) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text("$label : ", style: ts(size: 8, color: _abuTeksPdf)),
              pw.Text(val.toStringAsFixed(2),
                  style: ts(size: 8, bold: true)),
            ],
          );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),

          header: (ctx) => pw.Column(children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: const pw.BoxDecoration(
                color: _unguPdf,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text("FORM PENILAIAN MAGANG",
                      style: ts(size: 14, bold: true, color: PdfColors.white)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "DIGILOK — Sistem Manajemen Magang",
                    style: ts(size: 9, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ]),

          footer: (ctx) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("DIGILOK — Form Penilaian Magang",
                    style: ts(size: 7, color: _abuTeksPdf)),
                pw.Text(
                    "Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}",
                    style: ts(size: 7, color: _abuTeksPdf)),
              ],
            ),
          ),

          build: (ctx) => [

            // IDENTITAS PESERTA
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _unguMudaPdf,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: _unguPdf, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("IDENTITAS PESERTA MAGANG",
                      style: ts(size: 10, bold: true, color: _navyPdf)),
                  pw.Divider(color: _abuGarisPdf, height: 10),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(children: [
                          infoRow("Nama",          namaC.text),
                          infoRow("NIM / NIS",     nimC.text),
                          infoRow("Instansi",       instansiC.text),
                          infoRow("Unit / Bidang",  unitC.text),
                        ]),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(children: [
                          infoRow("Periode",
                              "${formatDate(startDate)} s/d ${formatDate(endDate)}"),
                          infoRow("Pemb. Lapangan", namaMentor),
                          infoRow("Pemb. Akademik", pembAkdC.text),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // KETERANGAN NILAI
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFFFBEA),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFD97706), width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Keterangan Nilai :", style: ts(bold: true, size: 8)),
                  pw.Text("1 = Sangat Kurang", style: ts(size: 8)),
                  pw.Text("2 = Kurang",         style: ts(size: 8)),
                  pw.Text("3 = Cukup",          style: ts(size: 8)),
                  pw.Text("4 = Baik",           style: ts(size: 8)),
                  pw.Text("5 = Sangat Baik",    style: ts(size: 8)),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // TABEL PENILAIAN
            penilaianTable("A.  PENILAIAN INTI  (Bobot 40%)", inti, 1),
            penilaianTable("B.  PENILAIAN TEKNIS  (Bobot 30%)", teknis, inti.length + 1),
            penilaianTable("C.  SELF ASSESSMENT  (Bobot 30%)", self, inti.length + teknis.length + 1),

            // RINGKASAN NILAI
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _abuPdf,
                border: pw.Border.all(color: _abuGarisPdf, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  avgRow("Rata-rata Penilaian Inti    ", avg(inti)),
                  pw.SizedBox(height: 2),
                  avgRow("Rata-rata Penilaian Teknis  ", avg(teknis)),
                  pw.SizedBox(height: 2),
                  avgRow("Rata-rata Self Assessment   ", avg(self)),
                  pw.Divider(color: _abuGarisPdf, height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: const pw.BoxDecoration(
                          color: _navyPdf,
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          "NILAI AKHIR :  ${(nilaiAkhir * 20).toStringAsFixed(1)}  /  100",
                          style: ts(size: 12, bold: true, color: PdfColors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // TANDA TANGAN
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _abuGarisPdf, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text("Pembimbing Lapangan",
                            style: ts(bold: true, size: 9, color: _hitamPdf)),
                        pw.SizedBox(height: 55),
                        pw.Container(
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: _abuGarisPdf, width: 0.8),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          namaMentor.isEmpty
                              ? "( .......................... )"
                              : "( $namaMentor )",
                          style: ts(bold: true, size: 9, color: _hitamPdf),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(width: 0.5, height: 100, color: _abuGarisPdf),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text("Pembimbing Akademik",
                            style: ts(bold: true, size: 9, color: _hitamPdf)),
                        pw.SizedBox(height: 55),
                        pw.Container(
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: _abuGarisPdf, width: 0.8),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          pembAkdC.text.isEmpty
                              ? ""
                              : "( ${pembAkdC.text} )",
                          style: ts(bold: true, size: 9, color: _hitamPdf),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Dicetak: ${formatDate(DateTime.now())}",
                style: ts(size: 7, color: _abuTeksPdf),
              ),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      if (!mounted) return;

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);

    } catch (e) {
      if (!mounted) return;
      _snack("Gagal export PDF: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= WIDGET FORM UI =================
  Widget _field(String label, TextEditingController c,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          const Text(" : "),
          Expanded(
            child: TextField(
              controller: c,
              readOnly: readOnly,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                isDense: true,
                fillColor: readOnly ? Colors.grey[100] : null,
                filled: readOnly,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 150,
            child: Text("Periode Magang", style: TextStyle(fontSize: 13)),
          ),
          const Text(" : "),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                      ),
                      child: Text(
                        startDate == null ? "Pilih tanggal mulai" : formatDate(startDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: startDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text("s/d"),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                      ),
                      child: Text(
                        endDate == null ? "Pilih tanggal selesai" : formatDate(endDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: endDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableUI(Map<String, int> data) {
    int no = 1;
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      // ✅ PERBAIKAN UI: tambah kolom Ket. tersendiri dengan lebar cukup
      columnWidths: const {
        0: FixedColumnWidth(36),   // No
        1: FlexColumnWidth(3),     // Aspek Penilaian
        2: FixedColumnWidth(190),  // Nilai Radio
        3: FixedColumnWidth(100),  // ✅ Ket. (lebar cukup untuk "Sangat Kurang")
        4: FlexColumnWidth(4),     // Catatan
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("No",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("Aspek Penilaian",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("Nilai (1 – 5)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
            // ✅ Header Ket.
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("Ket.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text("Catatan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        ...data.keys.map((k) => TableRow(children: [
              // No
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text("${no++}", style: const TextStyle(fontSize: 12)),
              ),
              // Aspek Penilaian
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(k, style: const TextStyle(fontSize: 12)),
              ),
              // Nilai (radio)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final val = i + 1;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<int>(
                          value: val,
                          groupValue: data[k],
                          activeColor: const Color(0xFF6C63FF),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) => setState(() => data[k] = v!),
                        ),
                        Text("$val", style: const TextStyle(fontSize: 10)),
                      ],
                    );
                  }),
                ),
              ),
              // ✅ Ket. sebagai badge berwarna — rapi & mudah dibaca
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _labelBg(data[k]!),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _labelColor(data[k]!).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      nilaiLabel(data[k]!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _labelColor(data[k]!),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Catatan
              Padding(
                padding: const EdgeInsets.all(6),
                child: TextFormField(
                  controller: catatan[k],
                  minLines: 2,
                  maxLines: null,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: "Opsional...",
                    hintStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ])),
      ],
    );
  }

  Widget _ttdUI(String title, {String? nama}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        Container(
          width: 140,
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey))),
        ),
        const SizedBox(height: 4),
        Text(
          nama != null && nama.isNotEmpty
              ? "( $nama )"
              : "",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Form Penilaian Magang",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // IDENTITAS
                _section(
                  title: "Identitas Peserta Magang",
                  child: Column(children: [
                    _field("Nama",           namaC),
                    _field("NIM / NIS",      nimC),
                    _field("Instansi",        instansiC),
                    _field("Unit / Bidang",  unitC),
                    _periodeField(),
                    _field("Pemb. Lapangan", pembLapC, readOnly: true),
                    _field("Pemb. Akademik", pembAkdC),
                  ]),
                ),

                // KETERANGAN NILAI
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Text(
                    "Keterangan:  1 = Sangat Kurang  |  2 = Kurang  |  3 = Cukup  |  4 = Baik  |  5 = Sangat Baik",
                    style: TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),

                // TABEL PENILAIAN
                _section(
                  title: "A.  Penilaian Inti  (Bobot 40%)",
                  child: _tableUI(inti),
                ),
                _section(
                  title: "B.  Penilaian Teknis  (Bobot 30%)",
                  child: _tableUI(teknis),
                ),
                _section(
                  title: "C.  Self Assessment  (Bobot 30%)",
                  child: _tableUI(self),
                ),

                // NILAI AKHIR
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text("NILAI AKHIR : ",
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(
                        "${(nilaiAkhir * 20).toStringAsFixed(1)}  /  100",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22),
                      ),
                    ],
                  ),
                ),

                // TANDA TANGAN
                _section(
                  title: "Tanda Tangan",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                          child: _ttdUI("Pembimbing Lapangan", nama: namaMentor)),
                      const SizedBox(width: 20),
                      Expanded(
                          child: _ttdUI("Pembimbing Akademik", nama: pembAkdC.text)),
                    ],
                  ),
                ),

                // TOMBOL AKSI
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : exportPdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text("Export PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // LOADING OVERLAY
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    SizedBox(height: 14),
                    Text("Membuat PDF...",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}