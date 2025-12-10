import 'package:flutter/material.dart';
import 'models/user.dart';

class ForgotPwPage extends StatefulWidget {
  const ForgotPwPage({super.key});

  @override
  State<ForgotPwPage> createState() => _ForgotPwPageState();
}

class _ForgotPwPageState extends State<ForgotPwPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final User _user = User();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  void _showDialog(String title, String message, {bool goBack = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.brown)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              if (goBack) Navigator.pop(context); 
            },
            child: const Text('OK', style: TextStyle(color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(email);
  }

  bool _isPasswordValid(String password) {
  return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_]).{8,}$')
      .hasMatch(password);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showDialog('Error!', 'Silahkan isi semua field!');
      return;
    }

    if (!_isEmailValid(email)) {
      _showDialog('Error!', 'Email harus menggunakan @gmail.com');
      return;
    }

    if (!_isPasswordValid(password)) {
      _showDialog('Error!',
          'Password harus berisi setidaknya 8 karakter, termasuk huruf kapital, huruf kecil, angka, dan simbol khusus.');
      return;
    }

    if (password != confirm) {
      _showDialog('Error', 'Password dan konfirmasi tidak sesuai');
      return;
    }

    final user = await _user.getUserByEmail(email);
    if (user == null) {
      _showDialog('Error', 'Email tidak terdaftar');
      return;
    }

    final res = await _user.updatePassword(email, password);
    if (res > 0) {
      _showDialog('Sukses!', 'Password sudah berhasil direset', goBack: true);
    } else {
      _showDialog('Error', 'gagal reset password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.brown[200],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan email dan password baru Anda',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Masukkan Email Anda',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password baru',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Konfirmasi Password',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
