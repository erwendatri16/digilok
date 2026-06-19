class InternshipApplication {
  final String id;
  final String nomorPengajuan;
  final String namaLengkap;
  final String email;
  final String noHp;
  final String asalKampus;
  final String jurusan;
  final DateTime periodeMulai;
  final DateTime periodeSelesai;
  final String? urlSuratPengantar;
  final String? urlKtm;
  final String? urlCv;
  final String? urlSuratBalasan;
  final String status;
  final String? alasanPenolakan;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  InternshipApplication({
    required this.id,
    required this.nomorPengajuan,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    required this.asalKampus,
    required this.jurusan,
    required this.periodeMulai,
    required this.periodeSelesai,
    this.urlSuratPengantar,
    this.urlKtm,
    this.urlCv,
    this.urlSuratBalasan,
    required this.status,
    this.alasanPenolakan,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory InternshipApplication.fromJson(
    Map<String, dynamic> json,
  ) {
    return InternshipApplication(
      id: json['id'] ?? '',
      nomorPengajuan: json['nomor_pengajuan'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'] ?? '',
      asalKampus: json['asal_kampus'] ?? '',
      jurusan: json['jurusan'] ?? '',
      periodeMulai: DateTime.parse(
        json['periode_mulai'],
      ),
      periodeSelesai: DateTime.parse(
        json['periode_selesai'],
      ),
      urlSuratPengantar:
          json['url_surat_pengantar'],
      urlKtm: json['url_ktm'],
      urlCv: json['url_cv'],
      urlSuratBalasan: json['url_surat_balasan'],
      status: json['status'] ?? 'pending',
      alasanPenolakan:
          json['alasan_penolakan'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(
              json['created_at'],
            )
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(
              json['reviewed_at'],
            )
          : null,
      reviewedBy: json['reviewed_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomor_pengajuan': nomorPengajuan,
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_hp': noHp,
      'asal_kampus': asalKampus,
      'jurusan': jurusan,
      'periode_mulai':
          periodeMulai.toIso8601String(),
      'periode_selesai':
          periodeSelesai.toIso8601String(),
      'url_surat_pengantar':
          urlSuratPengantar,
      'url_ktm': urlKtm,
      'url_cv': urlCv,
      'url_surat_balasan': urlSuratBalasan,
      'status': status,
      'alasan_penolakan':
          alasanPenolakan,
      'created_at':
          createdAt?.toIso8601String(),
      'reviewed_at':
          reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
    };
  }
}