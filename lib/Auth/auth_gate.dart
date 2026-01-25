import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:treatmyshoes_admin/Auth/login_page.dart';
import 'package:treatmyshoes_admin/pages/main_scree.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Null get session => null;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Mendengarkan status autentikasi dari Supabase
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Jika sedang loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // Jika ada session (sudah login), arahkan ke Beranda Admin
        if (session != null) {
          return const AdminMainScreen();
        }

        // Jika tidak ada session, arahkan ke Login
        return const LoginPage();
      },
    );
  }
}
