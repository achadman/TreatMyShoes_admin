import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:treatmyshoes_admin/pages/antrian_page.dart';
import 'package:treatmyshoes_admin/pages/home_page.dart';
import 'package:treatmyshoes_admin/pages/laporan_page.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  // 1. Variabel untuk menentukan halaman mana yang aktif
  int _selectedIndex = 0;

  // 2. Daftar Title yang akan berubah otomatis
  final List<String> _titles = [
    "Manajemen Pesanan",
    "Antrian Cuci",
    "Laporan Pemasukan",
  ];

  // 3. Daftar Widget Halaman
  final List<Widget> _pages = [
    const AdminHomePage(),
    const AntrianPage(),
    const LaporanPage(),
  ];

  // FUNGSI LOGOUT DENGAN KONFIRMASI
  void _showLogoutConfirmation() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true, // Admin bisa klik di luar untuk batal
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari aplikasi Admin?",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context), // Tutup Dialog
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              // Tutup Dialog dulu sebelum proses berat
              Navigator.pop(context);

              // Sign out
              await Supabase.instance.client.auth.signOut();

              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF24465F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF24465F)),
              accountName: const Text("Admin TreatMyShoes"),
              accountEmail: const Text("admintreatmyshoes3@gmail.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: Color(0xFF24465F),
                  size: 40,
                ),
              ),
            ),
            _drawerItem(CupertinoIcons.square_list, "Manajemen Pesanan", 0),
            _drawerItem(CupertinoIcons.timer, "Antrian Cuci", 1),
            _drawerItem(
              CupertinoIcons.chart_bar_square,
              "Laporan Pemasukan",
              2,
            ),

            const Spacer(), // Mendorong logout ke bagian paling bawah
            const Divider(),

            // TOMBOL LOGOUT (Index 99)
            _drawerItem(
              CupertinoIcons.power,
              "Logout",
              99,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // Body berubah sesuai index
      body: _pages[_selectedIndex],
    );
  }

  // Helper widget untuk menu drawer agar kode lebih bersih
  Widget _drawerItem(IconData icon, String label, int index, {Color? color}) {
    bool isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color:
            color ??
            (isSelected ? const Color(0xFF18ADFF) : const Color(0xFF24465F)),
      ),
      title: Text(
        label,
        style: TextStyle(
          color:
              color ?? (isSelected ? const Color(0xFF18ADFF) : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);

        if (index == 99) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _showLogoutConfirmation();
          });
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }
}
