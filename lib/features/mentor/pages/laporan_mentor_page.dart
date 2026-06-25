import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Dibutuhkan untuk memuat rootBundle asset logo
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
    initData();
  }

  // ================= AMBIL DATA BERDASARKAN STRUKTUR DB ASLI =================
  Future<void> initData() async {
    try {
      setState(() => isLoading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Ambil nama Mentor yang sedang login saat ini
      final mentorData = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .single();

      final mentorName = mentorData['name'] ?? "";

      // 2. Ambil seluruh ID Siswa dari tabel users yang kolom mentor_id-nya adalah ID kita
      final dataAnakDidik = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('mentor_id', user.id);

      List<String> listIdSiswa = [];
      for (var siswa in dataAnakDidik) {
        if (siswa['id'] != null) {
          listIdSiswa.add(siswa['id'].toString());
        }
      }

      // Jika mentor belum dikaitkan ke anak didik manapun di tabel users, langsung stop agar data tidak bocor
      if (listIdSiswa.isEmpty) {
        if (!mounted) return;
        setState(() {
          namaMentor = mentorName;
          penilaian = [];
          logbook = [];
          absensi = [];
          isLoading = false;
        });
        return;
      }

      // 3. Tarik data dari ketiga tabel dengan filter listIdSiswa (Hanya Anak Didikan Saja!)
      final p = await Supabase.instance.client
          .from('penilaian')
          .select()
          .filter('user_id', 'in', listIdSiswa);

      final l = await Supabase.instance.client
          .from('logbook')
          .select('*, users(name)')
          .filter('user_id', 'in', listIdSiswa);

      final a = await Supabase.instance.client
          .from('absensi')
          .select('*, users(name)')
          .filter('user_id', 'in', listIdSiswa);

      if (!mounted) return;

      setState(() {
        namaMentor = mentorName;
        penilaian = List<Map<String, dynamic>>.from(p);
        logbook = List<Map<String, dynamic>>.from(l);
        absensi = List<Map<String, dynamic>>.from(a);
        isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error memuat data: $e")),
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
    if (e['users'] != null && e['users']['name'] != null) {
      return e['users']['name'];
    }
    return "-";
  }

  // ================= EXPORT PDF DENGAN LOGO KOP BERPASANG =================
  Future<void> exportAllPdf() async {
    try {
      final pdf = pw.Document();

      // Memuat Gambar Logo Kiri dan Kanan dari Assets Project Anda
      final ByteData logoBanjarmasinData = await rootBundle.load('assets/icons/logo_banjarmasin.png');
      final ByteData logoData = await rootBundle.load('assets/icons/logo.jpeg');

      final imageLogoBanjarmasin = pw.MemoryImage(logoBanjarmasinData.buffer.asUint8List());
      final imageLogo = pw.MemoryImage(logoData.buffer.asUint8List());

      String today =
          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [

            // KOP SURAT DENGAN LOGO KANAN KIRI
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(imageLogoBanjarmasin, width: 50, height: 50),
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        "LAPORAN MENTOR DIGILOK",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Nama Mentor: $namaMentor",
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Tanggal Cetak: $today",
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.Image(imageLogo, width: 50, height: 50),
              ],
            ),

            // Garis Pembatas Kop Surat
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 15),

            // ================= PENILAIAN =================
            pw.Text("A. PENILAIAN",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.TableHelper.fromTextArray(
              headers: ["Nama", "NIM", "Nilai"],
              data: penilaian.map((e) => [
                ambil(e, ["nama"]),
                ambil(e, ["nim"]),
                ambil(e, ["nilai_akhir"]),
              ]).toList(),
            ),

            pw.SizedBox(height: 15),

            // ================= LOGBOOK =================
            pw.Text("B. LOGBOOK",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.TableHelper.fromTextArray(
              headers: ["Nama", "Kegiatan", "Tanggal"],
              data: logbook.map((e) => [
                ambil(e, ["nama", "user_nama"]),
                ambil(e, ["kegiatan", "deskripsi", "aktivitas", "isi"]),
                ambil(e, ["tanggal", "created_at"]),
              ]).toList(),
            ),

            pw.SizedBox(height: 15),

            // ================= ABSENSI =================
            pw.Text("C. ABSENSI",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.TableHelper.fromTextArray(
              headers: ["Nama", "Tanggal", "Status"],
              data: absensi.map((e) => [
                ambil(e, ["nama"]),
                ambil(e, ["tanggal"]),
                ambil(e, ["status_masuk", "status"]),
              ]).toList(),
            ),

            pw.SizedBox(height: 35),

            // ================= TTD MENTOR =================
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Pembimbing Lapangan,"),
                  pw.SizedBox(height: 50),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mencetak PDF: $e")),
      );
    }
  }

  // ================= CARD TOTAL DATA =================
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

  // ================= LIST DATA VIEW =================
  Widget buildList(List<Map<String, dynamic>> data, String type) {
    if (data.isEmpty) {
      return const Center(child: Text("Belum ada data anak didik"));
    }

    return RefreshIndicator(
      onRefresh: initData,
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
                    Text("Kegiatan: ${ambil(item, ["kegiatan", "deskripsi", "aktivitas", "isi"])}"),
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

  // ================= MAIN UI =================
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