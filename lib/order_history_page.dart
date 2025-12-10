import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'session_manager.dart';
import 'db/db_helper.dart';
import 'models/user.dart' as UserModel;
import 'dart:io'; // Import for File

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final UserModel.User _userModel = UserModel.User();
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
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
        final user = await _userModel.getUserByEmail(email);
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
          if (_currentUser != null) {
            final dbHelper = DBHelper();
            final userId = _currentUser!['user_id'];
            if (userId != null) {
              final transactions = await dbHelper.getTransactionsByUserId(userId);
              setState(() {
                _transactions = transactions;
              });
            }
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
        debugPrint('OrderHistoryPage: _transactions count: ${_transactions.length}');
        if (_transactions.isNotEmpty) {
          debugPrint('OrderHistoryPage: First transaction: ${_transactions.first}');
        }
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
          : _currentUser == null
              ? const Center(child: Text('User data not found. Please log in.'))
              : _transactions.isEmpty
                  ? const Center(child: Text('Anda belum memiliki riwayat pesanan.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ID: ${transaction['transaksi_id']}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tanggal: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.parse(transaction['tanggal_transaksi']))}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total Pembayaran: Rp ${currencyFormat.format(transaction['total'])}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Metode Pembayaran: ${transaction['payment_method']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Alamat Pengiriman: ${transaction['address']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Biaya Pengiriman: Rp ${currencyFormat.format(transaction['shipping_cost'])}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: DBHelper().getTransactionDetails(transaction['transaksi_id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return const Text('Tidak ada detail produk.');
                                    } else {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Detail Produk:',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          ...snapshot.data!.map((detail) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  children: [
                                                    if (detail['foto_produk'] != null && detail['foto_produk'].toString().isNotEmpty)
                                                      Builder(
                                                        builder: (context) {
                                                          String imagePath = detail['foto_produk'];
                                                          debugPrint('OrderHistoryPage: Attempting to load image from path: $imagePath');
                                                          File imageFile = File(imagePath);
                                                          if (imageFile.existsSync()) {
                                                            debugPrint('OrderHistoryPage: File exists: $imagePath');
                                                            return Image.file(
                                                              imageFile,
                                                              width: 50,
                                                              height: 50,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                debugPrint('OrderHistoryPage: Failed to render file image $imagePath. Error: $error');
                                                                return const Icon(Icons.broken_image, size: 50);
                                                              },
                                                            );
                                                          } else {
                                                            debugPrint('OrderHistoryPage: File does NOT exist: $imagePath');
                                                            // Fallback for assets if the file path doesn't exist, though it should be a file path
                                                            if (imagePath.startsWith('assets/')) {
                                                              return Image.asset(
                                                                imagePath,
                                                                width: 50,
                                                                height: 50,
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  debugPrint('OrderHistoryPage: Failed to load asset image $imagePath. Error: $error');
                                                                  return const Icon(Icons.broken_image, size: 50);
                                                                },
                                                              );
                                                            }
                                                            return const Icon(Icons.broken_image, size: 50);
                                                          }
                                                        },
                                                      ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '${detail['nama_produk']} (x${detail['qty']})',
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Rp ${currencyFormat.format(detail['harga'])}',
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ],
                                      );
                                    }
                                  },
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
