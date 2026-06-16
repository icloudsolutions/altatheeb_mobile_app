import 'package:flutter/material.dart';

/// Consistent pill-shaped status badge used across invoices, attendance, etc.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 11.0 : 12.0;
    final hPad = small ? 8.0 : 10.0;
    final vPad = small ? 3.0 : 5.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience factory methods for common statuses.
extension StatusBadgeX on StatusBadge {
  static StatusBadge invoicePaid(String label) =>
      StatusBadge(label: label, color: const Color(0xFF2E7D32), icon: Icons.check_circle_outline);

  static StatusBadge invoicePending(String label) =>
      StatusBadge(label: label, color: const Color(0xFF1565C0), icon: Icons.schedule_outlined);

  static StatusBadge invoiceCancelled(String label) =>
      StatusBadge(label: label, color: const Color(0xFF9E9E9E), icon: Icons.cancel_outlined);

  static StatusBadge attendancePresent(String label) =>
      StatusBadge(label: label, color: const Color(0xFF2E7D32), icon: Icons.check_circle_outline);

  static StatusBadge attendanceAbsent(String label) =>
      StatusBadge(label: label, color: const Color(0xFFC62828), icon: Icons.cancel_outlined);

  static StatusBadge attendanceLate(String label) =>
      StatusBadge(label: label, color: const Color(0xFFF57F17), icon: Icons.schedule);

  static StatusBadge attendanceExcused(String label) =>
      StatusBadge(label: label, color: const Color(0xFF1565C0), icon: Icons.info_outline);
}
