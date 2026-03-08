import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _error;
  bool _obscurePass = true;
  final _auth = AuthService();

  Future<void> _signUp() async {
    setState(() { _loading = true; _error = null; });
    final result = await _auth.signUp(
        _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    setState(() { _loading = false; });
    if (result == 'success') {
      setState(() { _otpSent = true; });
    } else {
      setState(() { _error = result; });
    }
  }

  Future<void> _confirmOtp() async {
    setState(() { _loading = true; _error = null; });
    final result = await _auth.confirmSignUp(
        _emailCtrl.text.trim(), _otpCtrl.text.trim());
    setState(() { _loading = false; });
    if (result == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please sign in. ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      setState(() { _error = result; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Join ArtisanAI Boost 🎨',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513))),
              const SizedBox(height: 6),
              const Text('Create your free account',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 28),

              if (!_otpSent) ...[
                // Name
                TextField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration('Full Name', Icons.person_outline),
                ),
                const SizedBox(height: 16),

                // Email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: _inputDecoration('Password (min 8 chars)', Icons.lock_outline)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
              ] else ...[
                // OTP Field
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.email, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verification code sent to your email. Please check your inbox.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      letterSpacing: 8),
                  decoration: _inputDecoration('Enter OTP Code', Icons.pin),
                ),
              ],

              const SizedBox(height: 12),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red.shade700,
                          fontSize: 13)),
                ),

              const SizedBox(height: 20),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_otpSent ? _confirmOtp : _signUp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_otpSent ? 'Verify OTP' : 'Create Account',
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                              color: Color(0xFF8B4513),
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF8B4513)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
