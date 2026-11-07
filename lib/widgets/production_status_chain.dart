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

    void addArrow({required bool isRemaining}) {
      spans.add(TextSpan(
        text: ' -> ',
        style: TextStyle(
          color: isRemaining ? const Color(0xFF9E9E9E) : const Color(0xFF202124),
          fontWeight: FontWeight.normal,
        ),
      ));
    }

    // 1. Origin: EDP
    spans.add(const TextSpan(
      text: 'EDP',
      style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w500),
    ));

    // 2. Preceding Suppliers (e.g., SKMT)
    final rawSuppliers = job.supplierChain.isNotEmpty
        ? job.supplierChain
        : (job.supplier != null
            ? [job.supplier!]
            : (job.destinationName?.isNotEmpty == true ? [job.destinationName!] : []));

    for (final s in rawSuppliers) {
      final trimmed = s.trim();
      final lower = trimmed.toLowerCase();
      if (lower == 'edp' ||
          lower == 'edp production' ||
          lower == 'production' ||
          trimmed.isEmpty ||
          trimmed.startsWith('Delivered') ||
          trimmed.startsWith('Returned')) {
        continue;
      }
      addArrow(isRemaining: false);
      spans.add(TextSpan(
        text: trimmed,
        style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w500),
      ));
    }

    // 3. Sequential Production Stages
    for (int i = 0; i < kProductionStages.length; i++) {
      final stage = kProductionStages[i];
      final isCurrent = (i == currentIndex) && !isDeliveredOrReady;
      final isDone = i < currentIndex || isDeliveredOrReady;
      final isRemaining = i > currentIndex && !isDeliveredOrReady;

      addArrow(isRemaining: isRemaining && !isCurrent);

      final displayName = stage == 'Start' ? 'Production Start' : stage;

      Color color;
      FontWeight weight;
      if (isCurrent) {
        color = const Color(0xFF2E7D32);
        weight = FontWeight.bold;
      } else if (isDone) {
        color = const Color(0xFF202124);
        weight = FontWeight.w500;
      } else {
        color = const Color(0xFF9E9E9E);
        weight = FontWeight.normal;
      }

      spans.add(TextSpan(
        text: displayName,
        style: TextStyle(color: color, fontWeight: weight),
      ));
    }

    // 4. Completed / Ready for Dispatch
    if (isDeliveredOrReady) {
      addArrow(isRemaining: false);
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
        if (showExpectedDate && job.expectedProductionStageDate != null && (job.status == 'Production' || job.productionStage != null) && !isDeliveredOrReady) ...[
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
        if (job.currentLocation.isNotEmpty &&
            ((job.quantity ?? 0) - (job.deliveredQuantity ?? 0) - (job.returnedQuantity ?? 0)) > 0 &&
            ((job.quantity ?? 0) - (job.deliveredQuantity ?? 0) - (job.returnedQuantity ?? 0)) < (job.quantity ?? 0))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Available at ${job.currentLocation}: ${(job.quantity ?? 0) - (job.deliveredQuantity ?? 0) - (job.returnedQuantity ?? 0)}',
              style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
