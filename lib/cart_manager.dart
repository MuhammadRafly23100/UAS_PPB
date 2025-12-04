import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for CartPage
import 'package:intl/intl.dart'; // Added for currency formatting
import 'dart:io'; // Added for File operations
import 'package:provider/provider.dart'; // Added for Consumer
import 'checkout_page.dart'; // Added for navigation to CheckoutPage

class CartItem {
  final int produkId;
  final String nama;
  final double harga;
  final String imageUrl; // New field for product image
  int qty;

  CartItem({
    required this.produkId,
    required this.nama,
    required this.harga,
    required this.imageUrl, // Must be provided
    this.qty = 1,
  });

  factory CartItem.fromMap(Map<String, dynamic> m) {
    return CartItem(
      produkId: (m['produk_id'] as num).toInt(),
      nama: m['nama_produk'].toString(),
      harga: (m['harga'] as num).toDouble(),
      imageUrl: m['foto_produk'].toString(), // Assuming 'foto_produk' is the key for image URL
      qty: (m['qty'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'produk_id': produkId,
        'nama_produk': nama,
        'harga': harga,
        'foto_produk': imageUrl, // Include image URL in map
        'qty': qty,
      };
}

class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(Map<String, dynamic> product) {
    final item = CartItem.fromMap(product);

    final index =
        _items.indexWhere((e) => e.produkId == item.produkId);

    if (index >= 0) {
      _items[index].qty += 1;
    } else {
      _items.add(item);
    }

    notifyListeners();
  }

  void removeItem(int produkId) {
    _items.removeWhere((e) => e.produkId == produkId);
    notifyListeners();
  }

  double get total => _items.fold(
      0.0, (sum, item) => sum + (item.harga * item.qty));

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

// Moved CartPage from cart.dart
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final NumberFormat currencyFormat = NumberFormat("#,###", "id_ID");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Cart"),
        backgroundColor: Colors.brown,
      ),
      body: Consumer<CartManager>(
        builder: (context, cartManager, child) {
          if (cartManager.items.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          return ListView.builder(
            itemCount: cartManager.items.length,
            itemBuilder: (context, index) {
              final item = cartManager.items[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 80,
                    height: 80,
                    child: Builder(builder: (context) {
                      final imagePath = item.imageUrl;
                      debugPrint('Cart item image path for ${item.nama}: $imagePath');
                      if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
                        return Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        );
                      } else {
                        debugPrint('Cart item image file does not exist or path is null/empty: $imagePath');
                        return Container(
                          color: Colors.grey[300], // Placeholder color
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      }
                    }),
                  ),
                  title: Text(item.nama),
                  subtitle: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (item.qty > 1) {
                            setState(() => item.qty--);
                          } else {
                            cartManager.removeItem(item.produkId);
                          }
                        },
                      ),
                      Text("Qty: ${item.qty}"),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => item.qty++);
                        },
                      ),
                    ],
                  ),
                  trailing: Text(
                    "Rp ${currencyFormat.format(item.harga * item.qty)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<CartManager>(
        builder: (context, cartManager, child) {
          if (cartManager.items.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: Rp ${currencyFormat.format(cartManager.total)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckoutPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Checkout"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
