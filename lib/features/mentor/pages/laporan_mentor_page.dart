import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class LaporanMentorPage extends StatefulWidget {
  const LaporanMentorPage({super.key});

  @override
  State<LaporanMentorPage> createState() => _LaporanMentorPageState();
}

class _LaporanMentorPageState extends State<LaporanMentorPage>
    with SingleTickerProviderStateMixin {

  late TabController tabController;

  List<Map<String, dynamic>> penilaian = [];
  List<Map<String, dynamic>> logbook = [];
  List<Map<String, dynamic>> absensi = [];

  bool isLoading = true;
  String namaMentor = "";

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    loadAllData();
    loadMentor();
  }

  // ================= LOAD MENTOR =================
  Future<void> loadMentor() async {
    final user = Supabase.instance.client.auth.currentUser;

    final data = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', user!.id)
        .single();

    if (!mounted) return;

    setState(() {
      namaMentor = data['name'] ?? "";
    });
  }

  // ================= LOAD DATA (FIX JOIN USERS) =================
  Future<void> loadAllData() async {
    try {
      final p = await Supabase.instance.client.from('penilaian').select();

      // 🔥 FIX: JOIN users biar nama muncul
      final l = await Supabase.instance.client
          .from('logbook')
          .select('*, users(name)');

      final a = await Supabase.instance.client
          .from('absensi')
          .select('*, users(name)');

      if (!mounted) return;

      setState(() {
        penilaian = List<Map<String, dynamic>>.from(p);
        logbook = List<Map<String, dynamic>>.from(l);
        absensi = List<Map<String, dynamic>>.from(a);
        isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= HELPER FLEXIBLE =================
  String ambil(Map e, List<String> keys) {
    for (var k in keys) {
      if (e[k] != null && e[k].toString().isNotEmpty) {
        return e[k].toString();
      }
    }

    // 🔥 cek relasi users
    if (e['users'] != null && e['users']['name'] != null) {
      return e['users']['name'];
    }

    return "-";
  }

  // ================= EXPORT PDF =================
  Future<void> exportAllPdf() async {
    final pdf = pw.Document();

    String today =
        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [

          // HEADER
          pw.Center(
            child: pw.Text(
              "LAPORAN MENTOR DIGILOK",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          pw.SizedBox(height: 5),
          pw.Center(child: pw.Text("Tanggal Cetak: $today")),

          pw.SizedBox(height: 20),

          // ================= PENILAIAN =================
          pw.Text("A. PENILAIAN",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

          pw.TableHelper.fromTextArray(
            headers: ["Nama", "NIM", "Nilai"],
            data: penilaian.map((e) => [
              ambil(e, ["nama"]),
              ambil(e, ["nim"]),
              ambil(e, ["nilai_akhir"]),
            ]).toList(),
          ),

          pw.SizedBox(height: 20),

          // ================= LOGBOOK (FIX TOTAL) =================
          pw.Text("B. LOGBOOK",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

          pw.TableHelper.fromTextArray(
            headers: ["Nama", "Kegiatan", "Tanggal"],
            data: logbook.map((e) => [

              // 🔥 NAMA AUTO (JOIN USERS)
              ambil(e, ["nama", "user_nama"]),

              // 🔥 KEGIATAN AUTO
              ambil(e, [
                "kegiatan",
                "deskripsi",
                "aktivitas",
                "isi",
                "catatan",
                "logbook"
              ]),

              ambil(e, ["tanggal", "created_at"]),
            ]).toList(),
          ),

          pw.SizedBox(height: 20),

          // ================= ABSENSI =================
          pw.Text("C. ABSENSI",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

          pw.TableHelper.fromTextArray(
            headers: ["Nama", "Tanggal", "Status"],
            data: absensi.map((e) => [
              ambil(e, ["nama"]),
              ambil(e, ["tanggal"]),
              ambil(e, ["status_masuk", "status"]),
            ]).toList(),
          ),

          pw.SizedBox(height: 40),

          // ================= TTD =================
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Pembimbing Lapangan"),
                pw.SizedBox(height: 40),
                pw.Text(
                  namaMentor.isEmpty ? "________________" : namaMentor,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ================= CARD =================
  Widget card(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    );
  }

  // ================= LIST FIX =================
  Widget buildList(List<Map<String, dynamic>> data, String type) {
    if (data.isEmpty) {
      return const Center(child: Text("Belum ada data"));
    }

    return RefreshIndicator(
      onRefresh: loadAllData,
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, i) {
          final item = data[i];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                ambil(item, ["nama"]),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (type == "penilaian")
                    Text("Nilai: ${ambil(item, ["nilai_akhir"])}"),

                  if (type == "logbook")
                    Text("Kegiatan: ${ambil(item, [
                      "kegiatan",
                      "deskripsi",
                      "aktivitas",
                      "isi"
                    ])}"),

                  if (type == "absensi")
                    Text("Tanggal: ${ambil(item, ["tanggal"])}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Laporan Mentor"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "Penilaian"),
            Tab(text: "Logbook"),
            Tab(text: "Absensi"),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                Row(
                  children: [
                    card("Penilaian", penilaian.length.toString(), Colors.blue.shade100),
                    card("Logbook", logbook.length.toString(), Colors.green.shade100),
                    card("Absensi", absensi.length.toString(), Colors.orange.shade100),
                  ],
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton.icon(
                    onPressed: exportAllPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Export Semua Laporan"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      buildList(penilaian, "penilaian"),
                      buildList(logbook, "logbook"),
                      buildList(absensi, "absensi"),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}