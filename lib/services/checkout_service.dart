import 'package:sqflite/sqflite.dart';
import '../db/db_helper.dart';

class CheckoutService {
  final DBHelper _dbHelper = DBHelper();

  Future<int> createTransaction({
    required int userId,
    required double total,
    required double shippingCost,
    required double discount,
    required String paymentMethod,
    required String address,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert('transaksi', {
      'user_id': userId,
      'total': total,
      'shipping_cost': shippingCost,
      'discount_amount': discount,
      'payment_method': paymentMethod,
      'address': address,
      'tanggal': DateTime.now().toIso8601String(),
    });
  }

  Future<void> createTransactionDetails({
    required int transactionId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final db = await _dbHelper.database;
    for (var item in cartItems) {
      await db.insert('transaksi_detail', {
        'transaksi_id': transactionId,
        'produk_id': item['produkId'],
        'nama_produk': item['nama'],
        'harga': item['harga'],
        'qty': item['qty'],
      });
    }
  }
}
