import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/flowdesk_logo.dart';
import 'owner/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  final _api = ApiService();

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = await _api.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    setState(() {
      _loading = false;
    });

    if (user == null) {
      setState(() {
        _error = 'Invalid email or password.';
      });
      return;
    }

    if (!mounted) return;

    // Both Admin and Employee use the MainLayout now
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: FlowdeskLogo(fontSize: 48)),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Job Work Tracking Platform',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDec('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: _inputDec('Password', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFD93025), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29B6F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Tap to autofill demo credentials:',
                style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
              ),
              const SizedBox(height: 8),
              _demoHint('Admin', 'admin@flowdesk.com', 'password123'),
              _demoHint('Employee', 'employee@flowdesk.com', 'password123'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoHint(String role, String email, String pass) {
    return GestureDetector(
      onTap: () {
        _emailCtrl.text = email;
        _passCtrl.text = pass;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.touch_app, size: 16, color: Color(0xFF29B6F6)),
            const SizedBox(width: 8),
            Text(
              '$role: $email',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF29B6F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22, color: const Color(0xFF5F6368)),
      filled: true,
      fillColor: const Color(0xFFF1F3F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
