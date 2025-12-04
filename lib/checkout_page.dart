import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'cart_manager.dart';
import 'session_manager.dart';
import 'models/user.dart' as UserModel; // Alias to avoid conflict with flutter User
import 'models/produk.dart' as ProdukModel; // Import Produk model
import 'profile.dart'; // (masih ada kalau dibutuhkan)
import 'home_page.dart'; // (masih ada kalau dibutuhkan)
import 'db/db_helper.dart'; // Import DBHelper
import 'order_history_page.dart'; // <-- TAMBAHKAN INI

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final UserModel.User _userModel = UserModel.User();
  final ProdukModel.Produk _produkModel = ProdukModel.Produk();
  Map<String, dynamic>? _currentUser;
  bool _isLoadingUser = true;
  String _selectedPaymentMethod = 'QRIS';
  final TextEditingController _addressController = TextEditingController();
  final NumberFormat currencyFormat = NumberFormat("#,###", "id_ID");
  final double shippingCost = 40000;
  final double newCustomerDiscountRate = 0.20; // 20%
  final int maxDiscountTransactions = 2;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);
    try {
      final email = await SessionManager.getEmail();
      if (email != null) {
        final user = await _userModel.getUserByEmail(email);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _addressController.text = _currentUser?['alamat'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  double _calculateDiscountAmount(double subtotal) {
    if (_currentUser != null && (_currentUser!['transaction_count'] ?? 0) < maxDiscountTransactions) {
      return subtotal * newCustomerDiscountRate;
    }
    return 0.0;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('User data not found. Please log in.'))
              : Consumer<CartManager>(
                  builder: (context, cartManager, child) {
                    if (cartManager.items.isEmpty) {
                      return const Center(child: Text("Your cart is empty."));
                    }

                    final subtotal = cartManager.total;
                    final discountAmount = _calculateDiscountAmount(subtotal);
                    final total = subtotal + shippingCost - discountAmount;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEBE9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Text(
                                'Choose Payment Method',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          _buildOrderSummaryRow('Subtotal', subtotal),
                          _buildOrderSummaryRow('Shipping', shippingCost),
                          if (discountAmount > 0)
                            _buildOrderSummaryRow('Discount New User', -discountAmount, isDiscount: true),
                          const Divider(),
                          _buildOrderSummaryRow('Total', total, isTotal: true),
                          const SizedBox(height: 20),
                          const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          _buildPaymentMethodTile('QRIS', 'assets/images/logoQRIS.png'),
                          _buildPaymentMethodTile('GOPAY', 'assets/images/logoGOPAY.png'),
                          _buildPaymentMethodTile('OVO', 'assets/images/logoOVO.jpg'),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Order Confirmation"),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("Terima kasih atas pesanan Anda, ${_currentUser?['nama'] ?? 'Pengguna'}!"),
                                            const SizedBox(height: 10),
                                            const Text('Rincian Pesanan:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ...cartManager.items.map((item) => Text(
                                                '- ${item.nama} (x${item.qty}) - Rp ${currencyFormat.format(item.harga)}')),
                                            const SizedBox(height: 10),
                                            Text('Subtotal: Rp ${currencyFormat.format(subtotal)}'),
                                            Text('Pengiriman: Rp ${currencyFormat.format(shippingCost)}'),
                                            if (discountAmount > 0)
                                              Text('Diskon Pengguna Baru: -Rp ${currencyFormat.format(discountAmount)}'),
                                            Text('Total: Rp ${currencyFormat.format(total)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 20),
                                            const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Text(_selectedPaymentMethod),
                                            const SizedBox(height: 10),
                                            if (_selectedPaymentMethod == 'QRIS')
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Silakan scan QRIS di bawah ini:'),
                                                  const SizedBox(height: 5),
                                                  Center(
                                                    child: Image.asset('assets/images/logoQRIS.png', width: 150, height: 150),
                                                  ),
                                                ],
                                              )
                                            else if (_selectedPaymentMethod == 'GOPAY' || _selectedPaymentMethod == 'OVO')
                                              const Text('Silakan transfer ke nomor: 08123456789'),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text("Batal"),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                        TextButton(
                                          child: const Text("Konfirmasi"),
                                          onPressed: () async {
                                            Navigator.of(context).pop(); // close dialog

                                            if (_currentUser == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Gagal menempatkan pesanan: Data pengguna tidak ditemukan.")),
                                              );
                                              return;
                                            }

                                            // Save transaction
                                            final dbHelper = DBHelper();
                                            final int? userId = _currentUser!['user_id'];
                                            if (userId == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Gagal menempatkan pesanan: User ID tidak ditemukan.")),
                                              );
                                              return;
                                            }

                                            debugPrint('DEBUG: User ID for transaction: $userId');

                                            int transactionId = -1;
                                            try {
                                              transactionId = await dbHelper.insertTransaction({
                                                'user_id': userId,
                                                'total': total,
                                                'shipping_cost': shippingCost,
                                                'discount_amount': discountAmount,
                                                'payment_method': _selectedPaymentMethod,
                                                'address': _addressController.text,
                                                'status': 'Selesai', // tandai selesai
                                              });
                                              debugPrint('DEBUG: Transaction inserted with ID: $transactionId');
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Gagal menyimpan transaksi. Error: $e")),
                                              );
                                              debugPrint('ERROR: Failed to insert transaction: $e');
                                              return;
                                            }

                                            if (transactionId <= 0) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Gagal menyimpan transaksi.")),
                                              );
                                              debugPrint('ERROR: Transaction ID is not valid: $transactionId');
                                              return;
                                            }

                                            // Save details
                                            try {
                                              final details = cartManager.items.map((item) => {
                                                    'transaksi_id': transactionId,
                                                    'produk_id': item.produkId,
                                                    'nama_produk': item.nama,
                                                    'harga': item.harga,
                                                    'qty': item.qty,
                                                  }).toList();
                                              await dbHelper.insertTransactionDetails(details);
                                              debugPrint('DEBUG: Transaction details inserted for transaction ID: $transactionId');
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Gagal menyimpan detail transaksi. Error: $e")),
                                              );
                                              debugPrint('ERROR: Failed to insert transaction details: $e');
                                              return;
                                            }

                                            // Update stock
                                            try {
                                              for (var item in cartManager.items) {
                                                final currentProduct = await _produkModel.getProdukById(item.produkId);
                                                if (currentProduct.isNotEmpty) {
                                                  final currentStock = (currentProduct['stok'] as num).toInt();
                                                  final newStock = currentStock - item.qty;
                                                  await _produkModel.updateProdukStock(item.produkId, newStock);
                                                }
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Gagal memperbarui stok. Error: $e")),
                                              );
                                              return;
                                            }

                                            // Update user transaction_count
                                            try {
                                              final currentCount = (_currentUser!['transaction_count'] ?? 0);
                                              await _userModel.updateTransactionCount(_currentUser!['user_id'], currentCount + 1);
                                              await _loadUserData();
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Gagal update jumlah transaksi user. Error: $e")),
                                              );
                                              return;
                                            }

                                            // Bersihkan keranjang & pindah ke Riwayat
                                            cartManager.clearCart();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Pesanan berhasil ditempatkan!")),
                                            );

                                            if (!mounted) return;
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                                              (route) => route.isFirst,
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8D6E63),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text('Place Order', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildOrderSummaryRow(String title, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: isTotal ? 20 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            '${isDiscount ? '-' : ''}IDR ${currencyFormat.format(amount.abs())}${isDiscount ? ' (20%)' : ''}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String method, String imagePath) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _selectedPaymentMethod == method ? const Color(0xFFD7CCC8) : const Color(0xFFEFEBE9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selectedPaymentMethod == method ? const Color(0xFF8D6E63) : Colors.grey.shade400,
            width: _selectedPaymentMethod == method ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 40, height: 40),
            const SizedBox(width: 16),
            Text(method, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
