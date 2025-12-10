import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'cart_manager.dart';
import 'checkout_page.dart'; // Import the new checkout page
import 'dart:io'; // Import for File

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
            return const Center(child: Text("Keranjang kosong"));
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
                    child: Builder(
                      builder: (context) {
                        String imagePath = item.imageUrl;
                        if (imagePath.startsWith('assets/')) {
                          return Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('CartPage: Failed to load asset image $imagePath. Error: $error');
                              return Image.asset(
                                'assets/images/lainnya.jpg', // Fallback image
                                fit: BoxFit.cover,
                              );
                            },
                          );
                        } else {
                          // Assume it's a file path
                          File imageFile = File(imagePath);
                          if (imageFile.existsSync()) {
                            return Image.file(
                              imageFile,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('CartPage: Failed to render file image $imagePath. Error: $error');
                                return Image.asset(
                                  'assets/images/lainnya.jpg', // Fallback image
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          } else {
                            debugPrint('CartPage: File does NOT exist: $imagePath');
                            return Image.asset(
                              'assets/images/lainnya.jpg', // Fallback image
                              fit: BoxFit.cover,
                            );
                          }
                        }
                      },
                    ),
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
