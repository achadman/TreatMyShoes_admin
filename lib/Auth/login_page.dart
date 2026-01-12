// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import supabase langsung untuk logout jika bukan admin
// Sesuaikan import di bawah ini dengan nama folder di project admin kamu
import 'package:treatmyshoes_admin/Auth/auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthServices();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Login Logic
  void login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Cek Input Kosong
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Coba login
      await authService.signInWithEmailPassword(email, password);

      // 3. Validasi: Apakah ini email Admin?
      // GANTI 'admin@treatmyshoes.com' dengan email admin aslimu
      final currentUser = Supabase.instance.client.auth.currentUser;
      // GANTI email di bawah ini agar sesuai dengan yang kamu buat di Supabase
      // 2. Coba login
      await authService.signInWithEmailPassword(email, password);

      // 3. Ambil user yang baru saja login
      if (currentUser != null) {
        // Kita paksa email dari database dan inputan menjadi huruf kecil semua sebelum dibandingkan
        String emailDariDatabase = currentUser.email!.toLowerCase();
        String emailAdminResmi =
            "admintreatmyshoes3@gmail.com"; // Tulis kecil semua di sini

        if (emailDariDatabase != emailAdminResmi) {
          await authService.signOut(); // Tendang jika tidak cocok
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Akses Ditolak: Anda bukan Admin!"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print("Selamat datang Admin! Login sukses.");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Login: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF18ADFF);
    const Color primaryPurple2 = Color(0xFF778873);

    return Scaffold(
      body: Stack(
        children: [
          // Lingkaran dekorasi kiri atas
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: primaryPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),

          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              // Logo
              SizedBox(
                child: Image.asset(
                  "assets/Images/Logo.png",
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 40),

              // Teks Judul
              const Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "Silahkan login untuk mengelola pesanan",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Input Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Admin',
                  labelStyle: const TextStyle(color: primaryPurple2),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: primaryPurple,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryPurple,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryPurple2,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: primaryPurple2),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: primaryPurple,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryPurple,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryPurple2,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'LOGIN ADMIN',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
