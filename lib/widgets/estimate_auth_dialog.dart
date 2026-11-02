import 'package:flutter/material.dart';

class EstimateAuthService {
  static bool _isSessionUnlocked = false;

  /// Check if the current session has already authenticated
  static bool get isUnlocked => _isSessionUnlocked;

  /// Lock the session again (e.g. user manually clicks lock or logs out)
  static void lock() {
    _isSessionUnlocked = false;
  }

  /// Request password verification if not already unlocked.
  /// Returns `true` if authorized, `false` otherwise.
  static Future<bool> ensureAuthorized(BuildContext context, {String? targetDescription}) async {
    if (_isSessionUnlocked) {
      return true;
    }

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EstimatePasswordDialog(targetDescription: targetDescription),
    );

    if (success == true) {
      _isSessionUnlocked = true;
      return true;
    }
    return false;
  }
}

class _EstimatePasswordDialog extends StatefulWidget {
  final String? targetDescription;

  const _EstimatePasswordDialog({this.targetDescription});

  @override
  State<_EstimatePasswordDialog> createState() => _EstimatePasswordDialogState();
}

class _EstimatePasswordDialogState extends State<_EstimatePasswordDialog> {
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  void _verify() {
    final entered = _passwordCtrl.text.trim();
    if (entered.isEmpty) {
      setState(() {
        _errorMessage = 'Password is required';
      });
      return;
    }

    // Default password as specified: 1212
    if (entered == '1212') {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'Incorrect password. Access denied.';
        _passwordCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFF0288D1), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimates Access',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Owner Security Verification',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.targetDescription != null
                  ? 'Please enter the authorization password to ${widget.targetDescription}:'
                  : 'Please enter the authorization password to access Estimates and Price Calculations:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscureText,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _verify,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirm & Enter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
