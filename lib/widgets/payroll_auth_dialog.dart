import 'package:flutter/material.dart';

class PayrollAuthService {
  // In-memory unlock flag. Resets to false whenever the browser window is refreshed.
  static bool _isSessionUnlocked = false;

  /// Check if the current session has already authenticated with password 1212
  static bool get isUnlocked => _isSessionUnlocked;

  /// Lock the session again (e.g. user manually clicks lock or logs out)
  static void lock() {
    _isSessionUnlocked = false;
  }

  /// Manually set unlocked (used by verification dialog)
  static void unlock() {
    _isSessionUnlocked = true;
  }

  /// Request password verification if not already unlocked.
  /// Password is 1212.
  /// Returns `true` if authorized, `false` otherwise.
  static Future<bool> ensureAuthorized(BuildContext context, {String? targetSection}) async {
    if (_isSessionUnlocked) {
      return true;
    }

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PayrollPasswordDialog(targetSection: targetSection),
    );

    if (success == true) {
      _isSessionUnlocked = true;
      return true;
    }
    return false;
  }
}

class _PayrollPasswordDialog extends StatefulWidget {
  final String? targetSection;

  const _PayrollPasswordDialog({this.targetSection});

  @override
  State<_PayrollPasswordDialog> createState() => _PayrollPasswordDialogState();
}

class _PayrollPasswordDialogState extends State<_PayrollPasswordDialog> {
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

    // Required password: 1212
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
    final sectionName = widget.targetSection ?? 'Payroll Management';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
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
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_person_outlined, color: Color(0xFF4338CA), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock $sectionName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Payroll Security Verification',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Enter password to open Overview, Statement, Pay Slips, Bank Transfer, Leave Register, Staff Loans, and Biometrics.\n\nOnce unlocked, all sections remain accessible until the window is refreshed.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscureText,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Password',
                hintText: 'Enter 1212',
                prefixIcon: const Icon(Icons.key, size: 20, color: Color(0xFF4338CA)),
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
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _verify,
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: const Text('Unlock Payroll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
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

/// Fallback lock view for any payroll protected tab if accessed without unlocking
class PayrollLockedPlaceholder extends StatelessWidget {
  final String sectionTitle;
  final VoidCallback onUnlocked;

  const PayrollLockedPlaceholder({
    super.key,
    required this.sectionTitle,
    required this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 48, color: Color(0xFF4338CA)),
            ),
            const SizedBox(height: 20),
            Text(
              '$sectionTitle is Locked',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This administrative section requires password authorization.\nEnter password to open Overview, Statements, Payslips, Bank Transfers, Leave, Loans & Biometrics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await PayrollAuthService.ensureAuthorized(context, targetSection: sectionTitle);
                if (ok) {
                  onUnlocked();
                }
              },
              icon: const Icon(Icons.key, size: 18),
              label: const Text('Enter Password (1212) to Unlock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
