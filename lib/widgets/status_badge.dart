import 'package:flutter/material.dart';
import '../models/step_model.dart';

class StatusBadge extends StatelessWidget {
  final StepStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case StepStatus.completed:
        bg = const Color(0xFFE6F4EA);
        fg = const Color(0xFF1E8E3E);
        break;
      case StepStatus.inProgress:
        bg = const Color(0xFFE8F0FE);
        fg = const Color(0xFF29B6F6);
        break;
      default:
        bg = const Color(0xFFF1F3F4);
        fg = const Color(0xFF5F6368);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        stepStatusLabel(status),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
