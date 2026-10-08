import sys
import re

with open('lib/screens/owner/stock_at_edp_screen.dart', 'r') as f:
    content = f.read()

# Add imports if missing
if "import 'storage_selection_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'storage_selection_dialog.dart';\nimport '../../models/item_database_model.dart';")

# Find the _showAddSpareDialog method and patch it
replacement = """  void _showAddSpareDialog() {
    final parentContext = context;
    final partCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final descCtrl = TextEditingController();
    final gritCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    TextEditingController? autoPartCtrl;
    TextEditingController? autoDescCtrl;
    TextEditingController? autoGritCtrl;

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Blank Spare'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Use from Storage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: ctx,
                      builder: (c) => const StorageSelectionDialog(),
                    );
                    if (result != null) {
                      final item = result['item'] as ItemDatabaseModel;
                      
                      if (autoPartCtrl != null) autoPartCtrl!.text = item.itemName;
                      partCtrl.text = item.itemName;
                      
                      final desc = item.description ?? '';
                      if (autoDescCtrl != null) autoDescCtrl!.text = desc;
                      descCtrl.text = desc;
                      
                      final gritRegExp = RegExp(r'Grit\s*[:-]?\s*([0-9/]+)', caseSensitive: false);
                      final match = gritRegExp.firstMatch(desc);
                      if (match != null && match.groupCount >= 1) {
                        if (autoGritCtrl != null) autoGritCtrl!.text = match.group(1)!;
                        gritCtrl.text = match.group(1)!;
                      } else {
                        if (autoGritCtrl != null) autoGritCtrl!.text = '';
                        gritCtrl.text = '';
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (v) => _partNumbers.where((p) => p.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (sel) => partCtrl.text = sel,
                fieldViewBuilder: (ctx, ctrl, node, onSub) {
                  autoPartCtrl = ctrl;
                  if (ctrl.text.isEmpty && partCtrl.text.isNotEmpty) ctrl.text = partCtrl.text;
                  ctrl.addListener(() { partCtrl.text = ctrl.text; });
                  return TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: 'Part Number'));
                },
              ),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              Autocomplete<String>(
                optionsBuilder: (v) => _descriptions.where((p) => p.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (sel) => descCtrl.text = sel,
                fieldViewBuilder: (ctx, ctrl, node, onSub) {
                  autoDescCtrl = ctrl;
                  if (ctrl.text.isEmpty && descCtrl.text.isNotEmpty) ctrl.text = descCtrl.text;
                  ctrl.addListener(() { descCtrl.text = ctrl.text; });
                  return TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: 'Description'));
                },
              ),
              Autocomplete<String>(
                optionsBuilder: (v) => _gritSizes.where((p) => p.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (sel) => gritCtrl.text = sel,
                fieldViewBuilder: (ctx, ctrl, node, onSub) {
                  autoGritCtrl = ctrl;
                  if (ctrl.text.isEmpty && gritCtrl.text.isNotEmpty) ctrl.text = gritCtrl.text;
                  ctrl.addListener(() { gritCtrl.text = ctrl.text; });
                  return TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: 'Grit Size'));
                },
              ),"""

content = re.sub(
    r'  void _showAddSpareDialog\(\) \{.*?fieldViewBuilder: \(ctx, ctrl, node, onSub\) \{\n                  ctrl\.text = gritCtrl\.text;\n                  ctrl\.addListener\(\(\) \{ gritCtrl\.text = ctrl\.text; \}\);\n                  return TextField\(controller: ctrl, focusNode: node, decoration: const InputDecoration\(labelText: \'Grit Size\'\)\);\n                \},\n              \},',
    replacement,
    content,
    flags=re.DOTALL
)

with open('lib/screens/owner/stock_at_edp_screen.dart', 'w') as f:
    f.write(content)

