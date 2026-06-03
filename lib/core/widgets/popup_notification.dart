import 'package:flutter/material.dart';

// =====================================================================
// TIPE POPUP
// =====================================================================
enum PopupType { success, error, warning, info, maintenance }

// =====================================================================
// POPUP NOTIFICATION - Bisa dipanggil dari halaman mana saja
//
// Cara pakai:
//   PopupNotification.show(
//     context: context,
//     type: PopupType.success,
//     title: "Berhasil!",
//     message: "Data telah disimpan.",
//   );
// =====================================================================
class PopupNotification {
  static Future<void> show({
    required BuildContext context,
    required PopupType type,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "popup",
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => _PopupContent(
        type: type,
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }
}

// =====================================================================
// WIDGET ISI POPUP
// =====================================================================
class _PopupContent extends StatefulWidget {
  final PopupType type;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _PopupContent({
    required this.type,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  State<_PopupContent> createState() => _PopupContentState();
}

class _PopupContentState extends State<_PopupContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    _iconRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  // =====================================================================
  // KONFIGURASI TIAP TIPE
  // =====================================================================
  _PopupConfig get _config {
    switch (widget.type) {
      case PopupType.success:
        return _PopupConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconBg: const Color(0xFF065F46),
          icon: Icons.check_circle_rounded,
          buttonColor: const Color(0xFF10B981),
          glowColor: const Color(0xFF10B981),
        );
      case PopupType.error:
        return _PopupConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconBg: const Color(0xFF7F1D1D),
          icon: Icons.cancel_rounded,
          buttonColor: const Color(0xFFEF4444),
          glowColor: const Color(0xFFEF4444),
        );
      case PopupType.warning:
        return _PopupConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconBg: const Color(0xFF78350F),
          icon: Icons.warning_rounded,
          buttonColor: const Color(0xFFF59E0B),
          glowColor: const Color(0xFFF59E0B),
        );
      case PopupType.info:
        return _PopupConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFF4338CA), Color(0xFF3730A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconBg: const Color(0xFF1E1B4B),
          icon: Icons.info_rounded,
          buttonColor: const Color(0xFF4338CA),
          glowColor: const Color(0xFF4338CA),
        );
      case PopupType.maintenance:
        return _PopupConfig(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconBg: const Color(0xFF334155),
          icon: Icons.construction_rounded,
          buttonColor: const Color(0xFFF59E0B),
          glowColor: const Color(0xFFF59E0B),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: cfg.glowColor.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===================================================
                // HEADER GRADIENT
                // ===================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(gradient: cfg.gradient),
                  child: Column(
                    children: [
                      // Icon animasi
                      AnimatedBuilder(
                        animation: _iconController,
                        builder: (_, __) => Transform.scale(
                          scale: _iconScale.value,
                          child: Transform.rotate(
                            angle: _iconRotate.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: cfg.iconBg,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                cfg.icon,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dekorasi garis kecil
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ===================================================
                // BODY — JUDUL & PESAN
                // ===================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===================================================
                // TOMBOL
                // ===================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cfg.buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: cfg.buttonColor.withValues(alpha: 0.4),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onPressed?.call();
                      },
                      child: Text(
                        widget.buttonText ?? "Oke, Mengerti",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// MODEL KONFIGURASI
// =====================================================================
class _PopupConfig {
  final LinearGradient gradient;
  final Color iconBg;
  final IconData icon;
  final Color buttonColor;
  final Color glowColor;

  const _PopupConfig({
    required this.gradient,
    required this.iconBg,
    required this.icon,
    required this.buttonColor,
    required this.glowColor,
  });
}