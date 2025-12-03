import 'dart:io'; // Import for File
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/db_helper.dart';
import 'session_manager.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  final NumberFormat currencyFormat = NumberFormat("#,###", "id_ID");

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final email = await SessionManager.getEmail();
      if (email != null) {
        final userId = await SessionManager.getUserId(); // Get user_id from SessionManager

        if (userId != null) {
          final dbHelper = DBHelper();
          final transactions = await dbHelper.getTransactionsByUserId(userId);

          // Fetch details for each transaction
          for (var transaction in transactions) {
            final details = await dbHelper.getTransactionDetails(transaction['transaksi_id']);
            transaction['details'] = details;
          }

          if (mounted) {
            setState(() {
              _transactions = transactions;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading order history: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('Anda belum memiliki riwayat pesanan.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    final List<Map<String, dynamic>> details = transaction['details'] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID Transaksi: ${transaction['transaksi_id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            Text('Tanggal: ${transaction['tanggal']}'),
                            const SizedBox(height: 10),
                            const Text('Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...details.map((detail) => Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (detail['foto_produk'] != null)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: FileImage(File(detail['foto_produk'])),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              detail['nama_produk'],
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${detail['qty']} x Rp ${currencyFormat.format(detail['harga'])}',
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 10),
                            Text('Metode Pembayaran: ${transaction['payment_method']}'),
                            Text('Alamat Pengiriman: ${transaction['address']}'),
                            Text('Biaya Pengiriman: Rp ${currencyFormat.format(transaction['shipping_cost'])}'),
                            if (transaction['discount_amount'] > 0)
                              Text('Diskon: -Rp ${currencyFormat.format(transaction['discount_amount'])}'),
                            const Divider(),
                            Text(
                              'Total: Rp ${currencyFormat.format(transaction['total'])}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
