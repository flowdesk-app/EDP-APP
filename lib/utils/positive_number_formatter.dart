import 'package:flutter/services.dart';

/// Formatter that strictly enforces positive integer input (> 0):
/// - Rejects typing '0' as the first character (prevents entering 0)
/// - Strips leading zeros if pasted (e.g. "05" -> "5", "0" or "00" -> "")
/// - Only allows digits (1-9 for leading digit, 0-9 for subsequent digits)
class PositiveNumberInputFormatter extends TextInputFormatter {
  const PositiveNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    // Block standalone '0' or leading zeros like "00", "01"
    if (newValue.text.startsWith('0')) {
      final stripped = newValue.text.replaceFirst(RegExp(r'^0+'), '');
      if (stripped.isEmpty) {
        return oldValue.text.isEmpty ? const TextEditingValue() : oldValue;
      }
      return TextEditingValue(
        text: stripped,
        selection: TextSelection.collapsed(offset: stripped.length),
      );
    }
    // Only positive digits allowed
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(newValue.text)) {
      return oldValue;
    }
    return newValue;
  }
}
