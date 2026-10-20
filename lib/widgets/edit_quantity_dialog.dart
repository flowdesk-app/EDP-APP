import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';

Future<bool?> showEditQuantityDialog({
  required BuildContext context,
  required JobModel job,
  required void Function(JobModel updatedJob) onJobUpdated,
}) async {
  final bool isLappingCompound = job.jobType == 'Lapping Compound';
  final int currentQty = isLappingCompound ? (job.syringeQuantity ?? 0) : (job.quantity ?? 0);
  final String qtyLabel = isLappingCompound ? 'Syringe Quantity' : 'Quantity';
  final bool isAssembly = job.isAssembly || (job.numberOfSets != null && job.numberOfSets! > 0);
  final int currentSets = job.numberOfSets ?? 0;

  final controller = TextEditingController(text: currentQty > 0 ? '$currentQty' : '');
  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

  final setsController = TextEditingController(text: currentSets > 0 ? '$currentSets' : '');

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      bool isSubmitting = false;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note, color: Color(0xFF0288D1), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAssembly ? 'Edit Quantity & Sets' : 'Edit $qtyLabel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        job.partNumber?.isNotEmpty == true
                            ? job.partNumber!
                            : (job.customerName?.isNotEmpty == true ? job.customerName! : 'Job #${job.jobId}'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Current $qtyLabel:', style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
                            Text('$currentQty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF202124))),
                          ],
                        ),
                        if (isAssembly) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Sets:', style: TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
                              Text('$currentSets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFE65100))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'New $qtyLabel',
                      hintText: 'Enter new $qtyLabel',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.tag),
                    ),
                  ),
                  if (isAssembly) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: setsController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Number of Sets',
                        hintText: 'Enter number of sets',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.layers, color: Color(0xFFE65100)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'You will be asked to confirm before changes are saved.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF757575), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                    onPressed: isSubmitting
                    ? null
                    : () async {
                        final text = controller.text.trim();
                        final newQty = int.tryParse(text);
                        if (newQty == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid number')),
                          );
                          return;
                        }
                        if (newQty < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quantity cannot be negative')),
                          );
                          return;
                        }

                        int? newSets;
                        if (isAssembly) {
                          final setsText = setsController.text.trim();
                          if (setsText.isNotEmpty) {
                            newSets = int.tryParse(setsText);
                            if (newSets == null || newSets < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid number of sets')),
                              );
                              return;
                            }
                          }
                        }

                        final bool qtyChanged = newQty != currentQty;
                        final bool setsChanged = isAssembly && (newSets != currentSets);

                        if (!qtyChanged && !setsChanged) {
                          Navigator.pop(dialogCtx, false);
                          return;
                        }

                        // Check delivered quantity constraint
                        if (!isLappingCompound && (job.deliveredQuantity ?? 0) > newQty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Quantity cannot be less than already delivered quantity (${job.deliveredQuantity})'),
                            ),
                          );
                          return;
                        }

                        // Ask for confirmation
                        final bool? confirmed = await showDialog<bool>(
                          context: context,
                          builder: (confirmCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                SizedBox(width: 8),
                                Text('Confirm Change'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Are you sure you want to change details for "${job.partNumber ?? job.customerName ?? 'this job'}"?',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                if (qtyChanged) ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFFE082)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('$qtyLabel: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Row(
                                          children: [
                                            Text('$currentQty', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8),
                                              child: Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
                                            ),
                                            Text('$newQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (setsChanged) ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFFB74D)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Sets: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                        Row(
                                          children: [
                                            Text('$currentSets', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8),
                                              child: Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
                                            ),
                                            Text('${newSets ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmCtx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(confirmCtx, true),
                                child: const Text('Confirm'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        setDialogState(() => isSubmitting = true);

                        try {
                          final updatedJob = isLappingCompound
                              ? job.copyWith(syringeQuantity: newQty, numberOfSets: newSets)
                              : job.copyWith(quantity: newQty, numberOfSets: newSets);

                          await ApiService().updateJob(updatedJob);

                          if (context.mounted) {
                            onJobUpdated(updatedJob);
                            Navigator.pop(dialogCtx, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Job updated successfully'),
                                backgroundColor: Color(0xFF2E7D32),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}

class EditQuantityCell extends StatelessWidget {
  final JobModel job;
  final void Function(JobModel updatedJob)? onJobUpdated;

  const EditQuantityCell({
    super.key,
    required this.job,
    this.onJobUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLappingCompound = job.jobType == 'Lapping Compound';
    final int qty = isLappingCompound ? (job.syringeQuantity ?? 0) : (job.quantity ?? 0);
    final String label = isLappingCompound ? 'Syringe Qty' : 'Quantity';
    final bool hasSets = job.isAssembly || (job.numberOfSets != null && job.numberOfSets! > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$qty',
              style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w500),
            ),
            if (hasSets) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
                ),
                child: Text(
                  '${job.numberOfSets ?? 0} Sets',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                showEditQuantityDialog(
                  context: context,
                  job: job,
                  onJobUpdated: (updated) {
                    if (onJobUpdated != null) {
                      onJobUpdated!(updated);
                    }
                  },
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF90CAF9), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 11, color: Color(0xFF1976D2)),
                    SizedBox(width: 2),
                    Text(
                      'Edit',
                      style: TextStyle(fontSize: 10, color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
