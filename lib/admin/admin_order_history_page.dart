import 'package:flutter/material.dart';
import '../../db/db_helper.dart';
import 'dart:io';

class AdminOrderHistoryPage extends StatefulWidget {
  const AdminOrderHistoryPage({super.key});

  @override
  State<AdminOrderHistoryPage> createState() => _AdminOrderHistoryPageState();
}

class _AdminOrderHistoryPageState extends State<AdminOrderHistoryPage> {
  List<Map<String, dynamic>> _orderHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    final dbHelper = DBHelper();
    final data = await dbHelper.getAllOrderHistory();
    setState(() {
      _orderHistory = data;
      _isLoading = false;
    });
  }

  Widget buildImage(String path, {double? width, double? height}) {
    Widget imageWidget;
    if (path.startsWith('assets/')) {
      imageWidget = Image.asset(path, fit: BoxFit.cover);
    } else {
      final file = File(path);
      if (file.existsSync()) {
        imageWidget = Image.file(file, fit: BoxFit.cover);
      } else {
        imageWidget = Image.asset('assets/images/lainnya.jpg', fit: BoxFit.cover);
      }
    }
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan Admin'),
        backgroundColor: const Color(0xFFF2EDE5),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderHistory.isEmpty
              ? const Center(child: Text('Tidak ada riwayat pesanan.'))
              : ListView.builder(
                  itemCount: _orderHistory.length,
                  itemBuilder: (context, index) {
                    final order = _orderHistory[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaksi ID: ${order['transaksi_id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Pembeli: ${order['user_nama']} (${order['user_email']})'),
                            Text('Tanggal: ${order['tanggal_transaksi']}'),
                            Text('Total Pembayaran: Rp${order['total']}'),
                            const SizedBox(height: 10),
                            const Text('Produk Dipesan:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ListTile(
                              leading: buildImage(
                                order['foto_produk'] ?? 'assets/images/lainnya.jpg',
                                width: 50,
                                height: 50,
                              ),
                              title: Text(order['nama_produk']),
                              subtitle: Text('Harga: Rp${order['produk_harga']} x ${order['produk_qty']}'),
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
