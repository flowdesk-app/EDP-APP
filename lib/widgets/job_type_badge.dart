import 'package:flutter/material.dart';

class JobTypeBadge extends StatelessWidget {
  final String? jobType;
  final bool compact;

  const JobTypeBadge({
    super.key,
    required this.jobType,
    this.compact = false,
  });

  static Color getColor(String? type) {
    switch (type) {
      case 'New':
        return const Color(0xFF1976D2); // Vibrant Blue
      case 'Re-coating':
        return const Color(0xFFB86B14); // Warm Brown / Ochre
      case 'Coating':
        return const Color(0xFFD32F2F); // Vibrant Red
      case 'Lapping Compound':
        return const Color(0xFF00897B); // Teal
      default:
        return const Color(0xFF5F6368); // Grey
    }
  }

  static IconData getIcon(String? type) {
    switch (type) {
      case 'New':
        return Icons.fiber_new;
      case 'Re-coating':
        return Icons.build;
      case 'Coating':
        return Icons.layers_clear;
      case 'Lapping Compound':
        return Icons.science;
      default:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (jobType == null || jobType!.isEmpty) ? 'Job' : jobType!;
    final color = getColor(jobType);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getIcon(jobType), size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class SetsBadge extends StatelessWidget {
  final int? numberOfSets;
  final bool compact;

  const SetsBadge({
    super.key,
    this.numberOfSets,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE65100); // Deep Amber / Orange
    final count = numberOfSets ?? 0;
    final text = count > 0 ? '$count ${count == 1 ? "Set" : "Sets"}' : 'Assembly';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFF9800), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
