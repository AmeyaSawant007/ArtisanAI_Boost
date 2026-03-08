import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'signup_screen.dart';
import 'main.dart';

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
  bool _obscurePass = true;
  final _auth = AuthService();

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final result = await _auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() { _loading = false; });
    if (result == 'success') {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      setState(() { _error = result; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    // ✅ FIXED: replaced emoji with logo.png
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ArtisanAI Boost',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513))),
                    const SizedBox(height: 6),
                    const Text('Empowering Indian Artisans with AI',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text('Welcome Back 👋',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513))),
              const SizedBox(height: 6),
              const Text('Sign in to continue',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

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
                decoration: _inputDecoration('Password', Icons.lock_outline)
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
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 13)),
                ),

              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Sign Up Link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SignUpScreen())),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
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
