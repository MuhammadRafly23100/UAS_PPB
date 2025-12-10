import 'package:flutter/material.dart';
import 'db/db_helper.dart';
import 'login.dart';
import 'models/user.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  final User _user = User();

  String selectedRole = "pembeli";

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              width: 100,
              child: Image.asset(
                'assets/images/logo.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Full Name',
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
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
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
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
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
              controller: _noTelpController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Nomor Telepon',
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
              controller: _alamatController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Alamat',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: 'pembeli', child: Text('Pembeli')),
                DropdownMenuItem(value: 'mitra', child: Text('Mitra')),
              ],
              onChanged: (value) {
                setState(() => selectedRole = value!);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelText: "Role",
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  final noTelp = _noTelpController.text.trim();
                  final alamat = _alamatController.text.trim();

                  if (name.isEmpty ||
                      email.isEmpty ||
                      password.isEmpty ||
                      noTelp.isEmpty ||
                      alamat.isEmpty) {
                    _showDialog('Error', 'Semua field harus diisi');
                    return;
                  }

                  if (!RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(email)) {
                    _showDialog('Error', 'Email harus menggunakan @gmail.com');
                    return;
                  }

                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$')
                      .hasMatch(password)) {
                    _showDialog('Error',
                        'Password harus berisi setidaknya 8 karakter, termasuk huruf kapital, huruf kecil, angka, dan simbol khusus.');
                    return;
                  }

                  final existingUser = await _user.getUserByEmail(email);
                  if (existingUser != null) {
                    _showDialog('Error', 'Email sudah terdaftar');
                    return;
                  }

                  int res = await _user.registerUser(
                    nama: name,
                    email: email,
                    password: password,
                    noTelp: noTelp,
                    alamat: alamat,
                    role: selectedRole,
                  );

                  if (res != -1) {
                    _showDialog('Sukses', 'Registrasi sukses! Silahkan login.');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  } else {
                    _showDialog('Error', 'Registrasi gagal, silahkan coba lagi');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun? '),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
