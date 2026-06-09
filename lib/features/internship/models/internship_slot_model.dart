class InternshipSlot {
  final String bulan;
  final int kapasitas;
  final int terisi;

  InternshipSlot({
    required this.bulan,
    required this.kapasitas,
    required this.terisi,
  });

  int get sisa => kapasitas - terisi;

  double get persentaseTerisi {
    if (kapasitas == 0) return 0;
    return (terisi / kapasitas) * 100;
  }

  bool get penuh => terisi >= kapasitas;

  factory InternshipSlot.fromJson(
    Map<String, dynamic> json,
  ) {
    return InternshipSlot(
      bulan: json['bulan'] ?? '',
      kapasitas: json['kapasitas'] ?? 10,
      terisi: json['terisi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bulan': bulan,
      'kapasitas': kapasitas,
      'terisi': terisi,
    };
  }
}