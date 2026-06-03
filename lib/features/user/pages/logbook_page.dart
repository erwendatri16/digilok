import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogbookPage extends StatefulWidget {
  const LogbookPage({super.key});

  @override
  State<LogbookPage> createState() =>
      _LogbookPageState();
}

class _LogbookPageState
    extends State<LogbookPage> {
  String selectedFilter = 'pending';

  // =====================================================
  // STREAM REALTIME
  // =====================================================
  late final Stream<
      List<Map<String, dynamic>>> logbookStream;

  // =====================================================
  // INIT
  // =====================================================
  @override
  void initState() {
    super.initState();

    final user =
        Supabase.instance.client.auth.currentUser;

    logbookStream = Supabase.instance.client
        .from('logbook')
        .stream(primaryKey: ['id'])
        .eq('user_id', user!.id)
        .order(
          'updated_at',
          ascending: false,
        );
  }

  // =====================================================
  // NOTIFICATION
  // =====================================================
  void showFloatingNotification(
    String msg,
    bool isSuccess,
  ) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _FloatingNotification(
        message: msg,
        isSuccess: isSuccess,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  // =====================================================
  // STATUS COLOR
  // =====================================================
  Color getStatusColor(String s) {
    if (s == "approved") {
      return const Color(0xFF10B981);
    }

    if (s == "rejected") {
      return Colors.redAccent;
    }

    return Colors.amber[700]!;
  }

  // =====================================================
  // INPUT DECORATION
  // =====================================================
  InputDecoration customInputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6C63FF),
        size: 20,
      ),

      filled: true,

      fillColor: Colors.grey[50],

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: BorderSide(
          color: Colors.grey[200]!,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: BorderSide(
          color: Colors.grey[200]!,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Color(0xFF6C63FF),
          width: 1.5,
        ),
      ),
    );
  }

  // =====================================================
  // FILTER BUTTON
  // =====================================================
  Widget buildFilterButton(
    String label,
    String value,
  ) {
    final isActive =
        selectedFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = value;
          });
        },

        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 250),

          margin:
              const EdgeInsets.symmetric(
            horizontal: 4,
          ),

          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
          ),

          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF6C63FF)
                : Colors.grey[100],

            borderRadius:
                BorderRadius.circular(14),
          ),

          child: Center(
            child: Text(
              label,

              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.grey[700],

                fontWeight:
                    FontWeight.bold,

                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DIALOG TAMBAH
  // =====================================================
  void showTambahDialog() {
    final judulC =
        TextEditingController();

    final deskripsiC =
        TextEditingController();

    DateTime? selectedDate;

    String? kategori;

    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(24),
        ),

        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),

            child: StatefulBuilder(
              builder:
                  (ctx, setStateDialog) {
                return Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [
                        const Text(
                          "Tambah Logbook",

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              ctx,
                            );
                          },

                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        final picked =
                            await showDatePicker(
                          context: ctx,

                          initialDate:
                              DateTime.now(),

                          firstDate:
                              DateTime(2025),

                          lastDate:
                              DateTime(2030),
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate =
                                picked;
                          });
                        }
                      },

                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey[50],

                          borderRadius:
                              BorderRadius
                                  .circular(14),

                          border: Border.all(
                            color: Colors
                                .grey[200]!,
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,

                          children: [
                            Text(
                              selectedDate ==
                                      null
                                  ? "Pilih tanggal"
                                  : selectedDate
                                      .toString()
                                      .split(
                                          " ")[0],
                            ),

                            const Icon(
                              Icons
                                  .calendar_today_rounded,
                              color: Color(
                                  0xFF6C63FF),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: judulC,

                      decoration:
                          customInputDecoration(
                        "Judul Kegiatan",

                        Icons.title_rounded,
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<
                        String>(
                      value: kategori,

                      decoration:
                          customInputDecoration(
                        "Kategori",

                        Icons.category_rounded,
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: "meeting",
                          child:
                              Text("Meeting"),
                        ),

                        DropdownMenuItem(
                          value: "project",
                          child:
                              Text("Project"),
                        ),

                        DropdownMenuItem(
                          value:
                              "pelatihan",
                          child: Text(
                              "Pelatihan"),
                        ),

                        DropdownMenuItem(
                          value:
                              "lainnya",
                          child:
                              Text("Lainnya"),
                        ),
                      ],

                      onChanged: (v) {
                        setStateDialog(() {
                          kategori = v;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          deskripsiC,

                      maxLines: 4,

                      decoration:
                          customInputDecoration(
                        "Deskripsi",

                        Icons
                            .description_rounded,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                                  0xFF6C63FF),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        14),
                          ),
                        ),

                        onPressed: () async {
                          if (selectedDate ==
                                  null ||
                              judulC
                                  .text
                                  .isEmpty ||
                              kategori ==
                                  null ||
                              deskripsiC
                                  .text
                                  .isEmpty) {
                            showFloatingNotification(
                              "Lengkapi semua data",
                              false,
                            );

                            return;
                          }

                          try {
                            final user =
                                Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser;

                            await Supabase
                                .instance
                                .client
                                .from(
                                    'logbook')
                                .insert({
                              'user_id':
                                  user!.id,

                              'tanggal':
                                  selectedDate
                                      .toString()
                                      .split(
                                          " ")[0],

                              'judul': judulC
                                  .text
                                  .trim(),

                              'kategori':
                                  kategori,

                              'deskripsi':
                                  deskripsiC
                                      .text
                                      .trim(),

                              'status':
                                  'pending',

                              'updated_at':
                                  DateTime
                                      .now()
                                      .toUtc()
                                      .toIso8601String(),
                            });

                            if (!ctx.mounted) {
                              return;
                            }

                            Navigator.pop(
                                ctx);

                            showFloatingNotification(
                              "Logbook berhasil ditambahkan",
                              true,
                            );
                          } catch (e) {
                            showFloatingNotification(
                              "Error: $e",
                              false,
                            );
                          }
                        },

                        child: const Text(
                          "Simpan",

                          style: TextStyle(
                            color:
                                Colors.white,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // KONFIRMASI HAPUS
  // =====================================================
  void konfirmasiHapus(dynamic id) {
    showDialog(
      context: context,

      builder: (ctx) => AlertDialog(
        title: const Text(
          "Hapus Logbook?",
        ),

        content: const Text(
          "Data tidak bisa dikembalikan.",
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },

            child: const Text("Batal"),
          ),

          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.redAccent,
            ),

            onPressed: () async {
              try {
                final user =
                    Supabase.instance.client
                        .auth.currentUser;

                await Supabase.instance.client
                    .from('logbook')
                    .delete()
                    .eq('id', id)
                    .eq('user_id', user!.id);

                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                showFloatingNotification(
                  "Logbook berhasil dihapus",
                  true,
                );
              } catch (e) {
                showFloatingNotification(
                  "Error: $e",
                  false,
                );
              }
            },

            child: const Text(
              "Hapus",
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: const Text(
          "Logbook",

          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,

        foregroundColor: Colors.black,

        elevation: 0.5,

        automaticallyImplyLeading: false,
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        heroTag: "logbookFab",

        onPressed: showTambahDialog,

        backgroundColor:
            const Color(0xFF6C63FF),

        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),

        label: const Text(
          "Tambah",

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(16),

            child: Row(
              children: [
                buildFilterButton(
                  "Menunggu",
                  "pending",
                ),

                buildFilterButton(
                  "Disetujui",
                  "approved",
                ),

                buildFilterButton(
                  "Ditolak",
                  "rejected",
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<
                List<
                    Map<String,
                        dynamic>>>(
              stream: logbookStream,

              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFF6C63FF),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                    ),
                  );
                }

                final data =
                    snapshot.data ?? [];

                final filteredData = data
                    .where(
                      (e) =>
                          (e['status'] ??
                                  'pending')
                              .toString()
                              .toLowerCase() ==
                          selectedFilter,
                    )
                    .toList();

                if (filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Icon(
                          Icons
                              .folder_open_rounded,

                          size: 70,

                          color:
                              Colors.grey[300],
                        ),

                        const SizedBox(
                            height: 14),

                        Text(
                          "Belum ada logbook",

                          style: TextStyle(
                            color:
                                Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  cacheExtent: 1000,

                  itemCount:
                      filteredData.length,

                  padding:
                      const EdgeInsets.only(
                    left: 14,
                    right: 14,
                    bottom: 100,
                  ),

                  itemBuilder:
                      (context, i) {
                    final item =
                        filteredData[i];

                    final status =
                        item['status']
                                ?.toString() ??
                            'pending';

                    return Card(
                      elevation: 0.3,

                      margin:
                          const EdgeInsets
                              .symmetric(
                        vertical: 6,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    18),

                        side: BorderSide(
                          color: Colors
                              .grey[200]!,
                        ),
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(16),

                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              8,

                                          vertical:
                                              4,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color: getStatusColor(
                                                  status)
                                              .withValues(
                                                  alpha:
                                                      0.1),

                                          borderRadius:
                                              BorderRadius.circular(
                                                  6),
                                        ),

                                        child: Text(
                                          status
                                              .toUpperCase(),

                                          style:
                                              TextStyle(
                                            color:
                                                getStatusColor(
                                                    status),

                                            fontSize:
                                                10,

                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              8),

                                      Text(
                                        (item['tanggal'] ??
                                                '-')
                                            .toString()
                                            .replaceAll(
                                                '-',
                                                '/'),

                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,

                                          fontSize:
                                              12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          10),

                                  Text(
                                    item['judul'] ??
                                        '-',

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,

                                      fontSize:
                                          16,
                                    ),
                                  ),

                                  const SizedBox(
                                      height:
                                          6),

                                  Text(
                                    item['deskripsi'] ??
                                        '-',

                                    style:
                                        TextStyle(
                                      color: Colors
                                          .grey[600],

                                      fontSize:
                                          13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (status ==
                                'pending')
                              Column(
                                children: [
                                  IconButton(
                                    onPressed:
                                        () {},

                                    icon:
                                        const Icon(
                                      Icons
                                          .edit_note_rounded,

                                      color: Colors
                                          .blueAccent,
                                    ),
                                  ),

                                  IconButton(
                                    onPressed:
                                        () {
                                      konfirmasiHapus(
                                        item[
                                            'id'],
                                      );
                                    },

                                    icon:
                                        const Icon(
                                      Icons
                                          .delete_outline_rounded,

                                      color: Colors
                                          .redAccent,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// FLOATING NOTIFICATION OVERLAY
// =====================================================
class _FloatingNotification extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDone;

  const _FloatingNotification({
    required this.message,
    required this.isSuccess,
    required this.onDone,
  });

  @override
  State<_FloatingNotification> createState() =>
      _FloatingNotificationState();
}

class _FloatingNotificationState
    extends State<_FloatingNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDone());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: widget.isSuccess
                    ? const Color(0xFF10B981)
                    : Colors.redAccent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}