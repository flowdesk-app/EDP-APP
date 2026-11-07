import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job_model.dart';

const List<String> kProductionStages = [
  'Start',
  'Cleaning',
  'Lacquering',
  'Plating',
  'Tacking',
  'Final Cleaning',
];

String getEffectiveProductionStage(JobModel job) {
  if (job.productionStage != null && job.productionStage!.isNotEmpty) {
    return job.productionStage!;
  }
  return 'Start';
}

String? getNextProductionStage(String currentStage) {
  final idx = kProductionStages.indexOf(currentStage);
  if (idx >= 0 && idx < kProductionStages.length - 1) {
    return kProductionStages[idx + 1];
  }
  return null;
}

String? getPreviousProductionStage(String currentStage) {
  final idx = kProductionStages.indexOf(currentStage);
  if (idx > 0) {
    return kProductionStages[idx - 1];
  }
  return null;
}

class ProductionStatusChain extends StatelessWidget {
  final JobModel job;
  final bool showLabel;
  final bool showExpectedDate;
  final double fontSize;

  const ProductionStatusChain({
    super.key,
    required this.job,
    this.showLabel = true,
    this.showExpectedDate = true,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final currentStage = getEffectiveProductionStage(job);
    final isDeliveredOrReady = job.status == 'Completed' ||
        job.status == 'Delivered' ||
        job.status == 'Closed' ||
        currentStage == 'Ready for Dispatch';

    int currentIndex = kProductionStages.indexOf(currentStage);
    if (currentIndex == -1) {
      if (isDeliveredOrReady) {
        currentIndex = kProductionStages.length - 1;
      } else {
        currentIndex = 0;
      }
    }

    final List<InlineSpan> spans = [];

    for (int i = 0; i <= currentIndex; i++) {
      if (i > 0) {
        spans.add(const TextSpan(
          text: ' -> ',
          style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.normal),
        ));
      }

      final isCurrent = (i == currentIndex) && !isDeliveredOrReady;
      final color = isCurrent ? const Color(0xFF2E7D32) : const Color(0xFF202124);
      final weight = isCurrent ? FontWeight.bold : FontWeight.w500;

      spans.add(TextSpan(
        text: kProductionStages[i],
        style: TextStyle(color: color, fontWeight: weight),
      ));
    }

    if (isDeliveredOrReady) {
      spans.add(const TextSpan(
        text: ' -> ',
        style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.normal),
      ));
      spans.add(const TextSpan(
        text: 'Ready for Dispatch',
        style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          const Text(
            'Production Status',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 4),
        ],
        RichText(
          text: TextSpan(
            children: spans,
            style: TextStyle(fontSize: fontSize, fontFamily: 'Roboto'),
          ),
        ),
        if (showExpectedDate && job.expectedProductionStageDate != null && job.status == 'Production') ...[
          const SizedBox(height: 4),
          Text(
            'Expected: ${DateFormat('dd-MM-yyyy').format(job.expectedProductionStageDate!)}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
