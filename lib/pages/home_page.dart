import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A7F91),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async => await supabase.auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Stream ke tabel 'orders' langsung agar Realtime lancar jaya
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!;
          if (orders.isEmpty) return const Center(child: Text("Belum ada pesanan."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final DateTime date = DateTime.parse(order['created_at']);
              final String formattedDate = DateFormat('dd MMM, HH:mm', 'id_ID').format(date);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                          child: Icon(Icons.person, color: _getStatusColor(order['status'])),
                        ),
                        // --- PERBAIKAN NAMA DISINI ---
                        title: FutureBuilder<PostgrestMap>(
                          future: supabase
                              .from('profiles')
                              .select()
                              .eq('id', order['user_id'])
                              .single(),
                          builder: (context, profileSnapshot) {
                            if (profileSnapshot.hasData) {
                              // Mengambil kolom 'name' dari tabel profiles
                              return Text(
                                profileSnapshot.data!['name'] ?? "User Tanpa Nama",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              );
                            }
                            return const Text("Memuat nama...", style: TextStyle(fontSize: 12));
                          },
                        ),
                        subtitle: Text(
                          "ID: ${order['id'].toString().substring(0, 8)} | $formattedDate",
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['status']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(order['status']),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                "Layanan: ${order['service_type'] ?? 'Sepatu'}",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => _showUpdateStatusDialog(context, order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7F91),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Update Status"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- LOGIKA HELPER ---

  String _getStatusText(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'pending': return "Menunggu";
      case 'processed': return "Diproses";
      case 'shipped': return "Dikirim";
      case 'arrived': return "Selesai";
      default: return "Status: $status";
    }
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'arrived': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showUpdateStatusDialog(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Update Status Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _statusOption(context, order['id'], "pending", "Menunggu", Icons.hourglass_top, Colors.orange),
              _statusOption(context, order['id'], "processed", "Proses Cuci", Icons.wash, Colors.blue),
              _statusOption(context, order['id'], "shipped", "Sedang Dikirim", Icons.local_shipping, Colors.purple),
              _statusOption(context, order['id'], "arrived", "Selesai", Icons.check_circle, Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _statusOption(BuildContext context, dynamic orderId, String value, String label, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () async {
        await Supabase.instance.client
            .from('orders')
            .update({'status': value})
            .eq('id', orderId);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}