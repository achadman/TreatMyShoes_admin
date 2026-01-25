import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:treatmyshoes_admin/Auth/login_page.dart';
import 'package:treatmyshoes_admin/pages/main_scree.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: "https://buflzpusvcwtrkorpwen.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1Zmx6cHVzdmN3dHJrb3Jwd2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNzY1NzgsImV4cCI6MjA4MDg1MjU3OH0.D9SjUjysOMKka_6dFiKyr3G-t7LeXxMXepCKeLJ2qEI",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      debugShowCheckedModeBanner: false,
      title: 'TreatMyShoes Admin',
      
      // LOGIN PAGE SEBAGAI GERBANG UTAMA
      home: const LoginPage(), 

      routes: {
        '/login': (context) => const LoginPage(),
        '/admin_main': (context) => const AdminMainScreen(),
      },
    );
  }
}
