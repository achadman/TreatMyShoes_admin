// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final supabase = Supabase.instance.client;
  
  String _selectedFilter = 'Hari Ini';
  final List<String> _filterOptions = ['Hari Ini', 'Kemarin', '7 Hari Terakhir'];
  bool _isLoading = false; // Tambahkan variabel ini

  // Fungsi untuk menampilkan Pesan Error/Info
  void _showStatus(String message, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // LOGIKA EKSPOR CSV
  Future<void> _exportToCSV() async {
    setState(() => _isLoading = true);

    try {
      // 1. Tentukan Tanggal (Sesuai Filter yang dipilih)
      DateTime now = DateTime.now();
      DateTime startDate;
      if (_selectedFilter == 'Kemarin') {
        startDate = DateTime(now.year, now.month, now.day - 1);
      } else if (_selectedFilter == '7 Hari Terakhir') {
        startDate = now.subtract(const Duration(days: 7));
      } else {
        startDate = DateTime(now.year, now.month, now.day);
      }

      // 2. Ambil data dari Supabase (Gunakan view order_with_profiles)
      final List<Map<String, dynamic>> response = await supabase
          .from('order_with_profiles')
          .select()
          .eq('status', 'arrived')
          .gte('created_at', startDate.toIso8601String());

      if (response.isEmpty) {
        _showStatus("Tidak ada data pesanan selesai untuk filter ini.");
        return;
      }

      // 3. Susun Baris CSV
      List<List<dynamic>> rows = [];
      rows.add(["ID Pesanan", "Tanggal", "Pelanggan", "Layanan", "Total Harga"]);

      for (var row in response) {
        rows.add([
          row['id'],
          row['created_at'],
          row['customer_name'],
          row['treatment_name'],
          row['total_price'],
        ]);
      }

      // 4. Konversi & Simpan File
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Laporan_${_selectedFilter.replaceAll(' ', '_')}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // 5. Bagikan
      await Share.shareXFiles([XFile(path)], text: 'Laporan TreatMyShoes');
      _showStatus("Laporan Berhasil Dibuat!", color: Colors.green);
    } catch (e) {
      _showStatus("Gagal ekspor: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchLaporanData() async {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    if (_selectedFilter == 'Kemarin') {
      startDate = DateTime(now.year, now.month, now.day - 1);
      endDate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
    } else if (_selectedFilter == '7 Hari Terakhir') {
      startDate = now.subtract(const Duration(days: 7));
    } else {
      startDate = DateTime(now.year, now.month, now.day);
    }

    final response = await supabase
        .from('orders')
        .select('total_price')
        .eq('status', 'arrived')
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());

    double totalPemasukan = 0;
    for (var item in response) {
      totalPemasukan += (item['total_price'] ?? 0);
    }

    return {
      'totalPemasukan': totalPemasukan,
      'totalPesanan': response.length,
    };
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // DROPDOWN FILTER
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Rentang Waktu:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        items: _filterOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (val) => setState(() => _selectedFilter = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchLaporanData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? {'totalPemasukan': 0.0, 'totalPesanan': 0};

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // KARTU UTAMA
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF24465F), Color(0xFF18ADFF)]),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pemasukan $_selectedFilter", style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 10),
                            Text(_formatRupiah(data['totalPemasukan']),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.checkmark_seal, color: Colors.white),
                                const SizedBox(width: 8),
                                Text("${data['totalPesanan']} Pesanan Selesai", style: const TextStyle(color: Colors.white)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // BAGIAN TOMBOL DOWNLOAD
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Ringkasan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon( 
                            onPressed: _isLoading ? null : _exportToCSV,
                            icon: const Icon(CupertinoIcons.doc_text_fill, size: 18, color: Colors.green),
                            label: const Text("Ekspor CSV", style: TextStyle(color: Colors.green)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildDetailTile(icon: CupertinoIcons.bag, label: "Pesanan Masuk", value: "${data['totalPesanan']} Item"),
                      _buildDetailTile(
                        icon: CupertinoIcons.money_dollar_circle,
                        label: "Rata-rata Pendapatan",
                        value: _formatRupiah(data['totalPesanan'] > 0 ? data['totalPemasukan'] / data['totalPesanan'] : 0),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        
        // OVERLAY LOADING SAAT DOWNLOAD
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          )
      ],
    );
  }

  Widget _buildDetailTile({required IconData icon, required String label, required String value}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF24465F)),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}