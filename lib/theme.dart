import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6D45E8);
  static const dark = Color(0xFF0B1630);
  static const bg = Color(0xFFF7F7FA);
  static const border = Color(0xFFE5E7EB);
  static const muted = Color(0xFF6B7280);
  static const hint = Color(0xFF9CA3AF);
  static const chip = Color(0xFFEDEDF2);
  static const high = Color(0xFFEF4444);
  static const medium = Color(0xFFF59E0B);
  static const low = Color(0xFF10B981);

  static Color priority(String p) {
    switch (p) {
      case 'High':
        return high;
      case 'Medium':
        return medium;
      default:
        return low;
    }
  }
}

ThemeData buildAppTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, primary: AppColors.primary),
      scaffoldBackgroundColor: Colors.white,
    );

OutlineInputBorder _border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );

InputDecoration fieldDecoration({String? hint, Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.hint, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffix,
      border: _border(AppColors.border),
      enabledBorder: _border(AppColors.border),
      focusedBorder: _border(AppColors.primary),
      errorBorder: _border(AppColors.high),
      focusedErrorBorder: _border(AppColors.high),
    );

/// Small uppercase grey label used above inputs (EMAIL ADDRESS, TITLE ...)
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.muted,
          ),
        ),
      );
}

/// App logo: rounded white tile with a Flutter icon and a small orange Firebase badge.
/// (Replace with your own Image.asset if you export the logo from Figma.)
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.28),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Center(
                child: Icon(Icons.flutter_dash,
                    size: size * 0.55, color: const Color(0xFF0175C2)),
              ),
            ),
            Positioned(
              right: -size * 0.08,
              bottom: -size * 0.08,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.local_fire_department,
                    size: size * 0.2, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}

/// "• High" style pill.
class PriorityTag extends StatelessWidget {
  final String priority;
  final String? label;
  const PriorityTag(this.priority, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.priority(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label ?? priority,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool iconFirst;
  final Color color;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.iconFirst = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withAlpha(160),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null && iconFirst) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (icon != null && !iconFirst) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
                ],
              ),
      ),
    );
  }
}
