import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AntrianPage extends StatefulWidget {
  const AntrianPage({super.key});

  @override
  State<AntrianPage> createState() => _AntrianPageState();
}

class _AntrianPageState extends State<AntrianPage> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  // Stream data dari VIEW agar nama customer sudah terbawa
  Stream<List<Map<String, dynamic>>> _getAntrianStream() {
    return supabase
        .from('order_with_profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  // Ambil nomor HP dari tabel profiles
  Future<String?> _getPhoneNumber(String userId) async {
    final data = await supabase.from('profiles').select('phone').eq('id', userId).maybeSingle();
    return data?['phone'];
  }

  // Notifikasi WhatsApp
  void _sendWhatsAppNotif(String phone, String name, String status) async {
    String formattedPhone = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
    String pesan = "Halo $name, pesanan sepatu kamu di *TreatMyShoes* berstatus: *$status*. Terimakasih!";
    var whatsappUrl = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(pesan)}");
    if (await canLaunchUrl(whatsappUrl)) await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  }

  // Pop-up Konfirmasi Swipe
  Future<bool?> _showConfirmDialog(String action, String name) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Konfirmasi $action"),
        content: Text("Apakah Anda yakin ingin mengubah status pesanan $name menjadi $action?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Ya, Yakin"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: CupertinoSearchTextField(
            controller: _searchController,
            placeholder: "Cari nama pelanggan...",
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // 2. Info Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: const Text(
            "💡 Tips: Geser Kanan (Mulai) | Geser Kiri (Selesai)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),

        // 3. List Antrian dengan Swipe
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getAntrianStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final antrian = snapshot.data!.where((item) {
                final isNotArrived = item['status'] != 'arrived';
                final matchesSearch = (item['customer_name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                return isNotArrived && matchesSearch;
              }).toList();

              if (antrian.isEmpty) {
                return const Center(child: Text("Tidak ada antrian yang cocok."));
              }

              return ListView.builder(
                itemCount: antrian.length,
                itemBuilder: (context, index) {
                  final order = antrian[index];
                  final customerName = order['customer_name'] ?? "Customer";

                  return Dismissible(
                    key: Key(order['id'].toString()),
                    // Konfirmasi sebelum swipe benar-benar dijalankan
                    confirmDismiss: (direction) async {
                      String action = (direction == DismissDirection.startToEnd) ? "Mulai Proses" : "Selesai";
                      return await _showConfirmDialog(action, customerName);
                    },
                    // Background Geser Kanan (Processing)
                    background: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.play_arrow_solid, color: Colors.white),
                          SizedBox(width: 10),
                          Text("PROSES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Background Geser Kiri (Arrived)
                    secondaryBackground: Container(
                      color: Colors.green,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("SELESAI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white),
                        ],
                      ),
                    ),
                    onDismissed: (direction) async {
                      String newStatus = (direction == DismissDirection.startToEnd) ? 'processing' : 'arrived';
                      String label = (newStatus == 'processing') ? "Sedang Diproses" : "Siap Diambil";

                      // Update ke tabel orders asli
                      await supabase.from('orders').update({'status': newStatus}).eq('id', order['id']);

                      // Ambil nomor HP & Notif WA
                      String? phone = await _getPhoneNumber(order['user_id']);
                      if (phone != null) {
                        _sendWhatsAppNotif(phone, customerName, label);
                      }
                    },
                    child: _buildAntrianCard(order, index + 1),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAntrianCard(Map<String, dynamic> order, int no) {
    String status = order['status'] ?? 'pending';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF24465F),
          child: Text("$no", style: const TextStyle(color: Colors.white)),
        ),
        title: Text(order['customer_name'] ?? "Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${order['treatment_name']}\nStatus: ${status.toUpperCase()}"),
        trailing: Icon(
          status == 'pending' ? CupertinoIcons.timer : CupertinoIcons.settings,
          color: status == 'pending' ? Colors.red : Colors.blue,
        ),
      ),
    );
  }
}