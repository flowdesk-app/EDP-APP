import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../models/job_model.dart';
import '../utils/company_utils.dart';
import '../utils/pdf_invoice_api.dart';
import '../utils/pdf_tax_invoice_api.dart';

class DocumentGenerationService {
  /// Builds a Sales Order data object strictly from current job details
  /// and live database company storage (so database edits reflect immediately).
  static InvoiceData buildSalesOrderData(JobModel job, {double? rateOverride}) {
    final company = findCompanyForJob(job.customerName);

    final pos = company?.placeOfSupply.isNotEmpty == true
        ? company!.placeOfSupply
        : (company?.state.isNotEmpty == true ? company!.state : 'Tamil Nadu (33)');

    final isIntraState = pos.toLowerCase().contains('tamil nadu') ||
        pos.toLowerCase().contains('tamilnadu') ||
        pos.contains('(33)') ||
        pos.endsWith('33');

    // Reference formatting
    String reference = '';
    if (job.purchaseOrderNumber != null && job.purchaseOrderNumber!.trim().isNotEmpty) {
      reference = job.purchaseOrderNumber!.trim();
      if (job.purchaseOrderDate != null) {
        reference += ' DT ${DateFormat('dd MMM yyyy').format(job.purchaseOrderDate!).toUpperCase()}';
      }
    } else if (job.returnableGatePassNumber != null && job.returnableGatePassNumber!.trim().isNotEmpty) {
      reference = 'Rgp:${job.returnableGatePassNumber!.trim()}';
      if (job.returnableGatePassDate != null) {
        reference += ' DT ${DateFormat('dd.MM.yyyy').format(job.returnableGatePassDate!)}';
      }
    } else {
      reference = 'Job #${job.jobId}';
    }

    // Description and Title formatting
    String title = '';
    final descLines = <String>[];

    final rawPartNo = job.partNumber?.trim() ?? '';
    final rawDesc = job.partDescription?.trim() ?? '';
    final rawWheel = job.wheelSize?.trim() ?? '';

    if (rawPartNo.isNotEmpty && !RegExp(r'^\d+$').hasMatch(rawPartNo) && rawPartNo.toLowerCase() != 'assembly') {
      title = rawPartNo;
      if (rawWheel.isNotEmpty) {
        descLines.add(rawWheel.startsWith('EDP') ? rawWheel : 'EDP - $rawWheel');
      } else if (rawDesc.isNotEmpty) {
        descLines.add(rawDesc.startsWith('EDP') ? rawDesc : 'EDP - $rawDesc');
      }
    } else if (rawDesc.isNotEmpty) {
      title = rawDesc;
      if (rawWheel.isNotEmpty && rawWheel != rawDesc) {
        descLines.add(rawWheel.startsWith('EDP') ? rawWheel : 'EDP - $rawWheel');
      }
      if (rawPartNo.isNotEmpty) {
        descLines.add('Drg no :$rawPartNo');
      }
    } else if (rawWheel.isNotEmpty) {
      final lines = rawWheel.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.length > 1) {
        title = lines[0].startsWith('EDP') ? lines[0] : 'EDP - ${lines[0]}';
        descLines.addAll(lines.sublist(1));
      } else {
        title = rawWheel.startsWith('EDP') ? rawWheel : 'EDP - $rawWheel';
      }
      if (rawPartNo.isNotEmpty) {
        descLines.add('Drg no :$rawPartNo');
      }
    } else {
      title = 'EDP Grinding Wheel';
      if (rawPartNo.isNotEmpty) {
        descLines.add('Drg no :$rawPartNo');
      }
    }

    if (job.diamondPowderGritSize != null && job.diamondPowderGritSize!.trim().isNotEmpty) {
      final grit = job.diamondPowderGritSize!.trim();
      final fullText = '$title ${descLines.join(' ')}';
      if (!fullText.toLowerCase().contains(grit.toLowerCase())) {
        descLines.add('Grit: $grit');
      }
    }

    final billAddr = company?.billingAddress.isNotEmpty == true
        ? company!.billingAddress
        : (company?.shippingAddress ?? '');

    final shipAddr = company?.shippingAddress.isNotEmpty == true
        ? company!.shippingAddress
        : billAddr;

    final soNumber = (job.salesOrderNumber != null && job.salesOrderNumber!.trim().isNotEmpty)
        ? job.salesOrderNumber!.trim()
        : 'SO-2627-${job.jobId}';

    final effectiveRate = rateOverride ?? job.itemRate ?? 0.0;

    return InvoiceData(
      invoiceTitle: 'SALES ORDER',
      salesOrderNo: soNumber,
      salesOrderDate: job.salesOrderDate ?? DateTime.now(),
      billToName: company?.name.isNotEmpty == true ? company!.name : (job.customerName ?? 'Customer'),
      billToAddress: billAddr,
      billToGstin: company?.gstin ?? '',
      billToVendorCode: company?.vendorCode ?? '',
      shipToName: company?.name.isNotEmpty == true ? company!.name : (job.customerName ?? 'Customer'),
      shipToAddress: shipAddr,
      shipToGstin: company?.gstin ?? '',
      shipToVendorCode: company?.vendorCode ?? '',
      placeOfSupply: pos,
      orderDate: job.customerOrderDate ?? job.createdDate,
      reference: reference,
      items: [
        InvoiceItem(
          title: title,
          description: descLines.join('\n'),
          hsnCode: '68042110',
          quantity: job.quantity ?? 1,
          rate: effectiveRate,
        ),
      ],
      taxPercentage: 18.0,
      taxLabel: isIntraState ? 'CGST (9%) + SGST (9%)' : 'IGST (18%)',
    );
  }

  /// Builds a Tax Invoice data object strictly from current job details
  /// and live database company storage (so database edits reflect immediately).
  static TaxInvoiceData buildTaxInvoiceData(
    JobModel job, {
    double? rateOverride,
    TaxType? taxTypeOverride,
    double? manualRounding,
  }) {
    final company = findCompanyForJob(job.customerName);

    final pos = company?.placeOfSupply.isNotEmpty == true
        ? company!.placeOfSupply
        : (company?.state.isNotEmpty == true ? company!.state : 'Tamil Nadu (33)');

    // Tax type determination
    TaxType taxType = TaxType.igst18;
    if (taxTypeOverride != null) {
      taxType = taxTypeOverride;
    } else {
      final isSez = company?.billingAddress.toLowerCase().contains('sez') == true ||
          company?.shippingAddress.toLowerCase().contains('sez') == true ||
          pos.toLowerCase().contains('sez');
      final isIntraState = pos.toLowerCase().contains('tamil nadu') ||
          pos.toLowerCase().contains('tamilnadu') ||
          pos.contains('(33)') ||
          pos.endsWith('33');

      if (isSez) {
        taxType = TaxType.lutExempt;
      } else if (isIntraState) {
        taxType = TaxType.cgstSgst9;
      } else {
        taxType = TaxType.igst18;
      }
    }

    // PO#
    String poNo = '';
    if (job.purchaseOrderNumber != null && job.purchaseOrderNumber!.trim().isNotEmpty) {
      poNo = job.purchaseOrderNumber!.trim();
      if (job.purchaseOrderDate != null) {
        poNo += ' DT ${DateFormat('dd MMM yyyy').format(job.purchaseOrderDate!).toUpperCase()}';
      }
    } else if (job.returnableGatePassNumber != null && job.returnableGatePassNumber!.trim().isNotEmpty) {
      poNo = 'Rgp:${job.returnableGatePassNumber!.trim()}';
    } else {
      poNo = 'Job #${job.jobId}';
    }

    // Reference
    String reference = '';
    if (job.returnableGatePassNumber != null && job.returnableGatePassNumber!.trim().isNotEmpty) {
      reference = 'Rgp:${job.returnableGatePassNumber!.trim()}';
      if (job.returnableGatePassDate != null) {
        reference += ' DT ${DateFormat('dd.MM.yyyy').format(job.returnableGatePassDate!)}';
      }
    } else {
      reference = 'Job #${job.jobId}';
    }

    // DOC Ref
    String docRef = '';
    if (taxType == TaxType.lutExempt) {
      docRef = 'LUT NO; AD330326082684X DT 26.03.2026';
    } else if (job.deliveryChalanNumber != null && job.deliveryChalanNumber!.trim().isNotEmpty) {
      docRef = 'DC NO: ${job.deliveryChalanNumber!.trim()}';
      if (job.deliveryChalanDate != null) {
        docRef += ' DT ${DateFormat('dd.MM.yyyy').format(job.deliveryChalanDate!)}';
      }
    }

    // Delivery Ref
    String deliveryRef = '';
    if (job.deliveryChalanNumber != null && job.deliveryChalanNumber!.trim().isNotEmpty) {
      deliveryRef = 'TPNO ${job.deliveryChalanNumber!.trim()}';
      if (job.deliveryChalanDate != null) {
        deliveryRef += ' DT ${DateFormat('dd.MM.yyyy').format(job.deliveryChalanDate!)}';
      }
    }

    // Description lines
    final descLines = <String>[];
    if (job.wheelSize != null && job.wheelSize!.trim().isNotEmpty) {
      descLines.add('EDP - ${job.wheelSize!.trim()}');
    } else if (job.partDescription != null && job.partDescription!.trim().isNotEmpty) {
      descLines.add('EDP - ${job.partDescription!.trim()}');
    } else {
      descLines.add('EDP Grinding Wheel');
    }
    if (job.partNumber != null && job.partNumber!.trim().isNotEmpty) {
      descLines.add('Drg no ;${job.partNumber!.trim()}');
    }
    if (job.diamondPowderGritSize != null && job.diamondPowderGritSize!.trim().isNotEmpty) {
      descLines.add('Grit: ${job.diamondPowderGritSize!.trim()}');
    }

    final billAddr = company?.billingAddress.isNotEmpty == true
        ? company!.billingAddress
        : (company?.shippingAddress ?? '');

    final shipAddr = company?.shippingAddress.isNotEmpty == true
        ? company!.shippingAddress
        : billAddr;

    final invoiceNumber = (job.invoiceNumber != null && job.invoiceNumber!.trim().isNotEmpty)
        ? job.invoiceNumber!.trim()
        : '2627-${job.jobId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(6, '0')}';

    final effectiveRate = rateOverride ?? job.itemRate ?? 0.0;

    return TaxInvoiceData(
      invoiceNo: invoiceNumber,
      invoiceDate: job.invoiceDate ?? DateTime.now(),
      poNo: poNo,
      placeOfSupply: pos,
      reference: reference,
      docRef: docRef,
      deliveryRef: deliveryRef,
      billToName: company?.name.isNotEmpty == true ? company!.name : (job.customerName ?? 'Customer'),
      billToAddress: billAddr,
      billToGstin: company?.gstin ?? '',
      billToVendorCode: company?.vendorCode ?? '',
      shipToName: company?.name.isNotEmpty == true ? company!.name : (job.customerName ?? 'Customer'),
      shipToAddress: shipAddr,
      shipToGstin: company?.gstin ?? '',
      shipToVendorCode: company?.vendorCode ?? '',
      items: [
        TaxInvoiceItem(
          description: descLines.join('\n'),
          hsnCode: '68042110',
          quantity: job.quantity ?? 1,
          rate: effectiveRate,
        ),
      ],
      taxType: taxType,
      manualRounding: manualRounding,
    );
  }

  /// Displays the full PDF preview in a clean modal dialog with Print and Download options.
  static void showPdfPreviewDialog(
    BuildContext context, {
    required String title,
    required String documentNumber,
    required Future<Uint8List> Function() pdfBuilder,
    VoidCallback? onRegenerate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 1000,
            height: 850,
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF202124))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        documentNumber,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF202124),
                elevation: 1,
                actions: [
                  if (onRegenerate != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onRegenerate();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Regenerate with Latest Data'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) => pdfBuilder(),
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: '${documentNumber.replaceAll(' ', '_')}.pdf',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
