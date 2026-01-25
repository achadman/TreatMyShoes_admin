// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    // Cek apakah ada sesi aktif saat aplikasi pertama kali dibuka
    _checkExistingSession();
  }

  // Fungsi untuk menangani auto-login jika Admin sudah pernah masuk
  void _checkExistingSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Kita beri sedikit delay 0 agar build selesai dulu baru navigasi
      Future.delayed(Duration.zero, () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin_main');
        }
      });
    }
  }

  void login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email dan Password wajib diisi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Proses Autentikasi ke Supabase
      await authService.signInWithEmailPassword(email, password);

      // 2. Ambil data user secara manual (Tanpa campur tangan Stream/AuthGate)
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        // 3. Cek Profil & Role langsung ke database
        final userData = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        String role = userData?['role'] ?? 'user';
        String adminEmailResmi = "admintreatmyshoes3@gmail.com";

        // 4. Validasi Hak Akses
        if (role == 'owner' || email.toLowerCase() == adminEmailResmi) {
          // JIKA ADMIN: Berhasil masuk
          Navigator.pushReplacementNamed(context, '/admin_main');
        } else {
          // JIKA BUKAN ADMIN: Logout paksa dan tampilkan penolakan
          await authService.signOut();
          _showAccessDeniedDialog();
        }
      }
    } catch (e) {
      _showError("Login Gagal: Akun tidak ditemukan atau salah.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAccessDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Akses Ditolak"),
        content: const Text(
          "Maaf, akun ini tidak terdaftar sebagai Admin. Silakan gunakan akun pengelola yang benar.",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Mengerti"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF18ADFF);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: primaryBlue,
            ),
          ),
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Center(child: Image.asset("assets/Images/Logo2.png", width: 120)),
              const SizedBox(height: 40),
              const Text(
                'Admin Panel',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Kelola pesanan TreatMyShoes di sini",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Admin',
                  prefixIcon: const Icon(
                    CupertinoIcons.mail,
                    color: primaryBlue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    CupertinoIcons.lock,
                    color: primaryBlue,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                    ),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "MASUK SEBAGAI ADMIN",
                          style: TextStyle(
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
