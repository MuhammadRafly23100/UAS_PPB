import 'package:flutter/material.dart';
import 'models/produk.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'cart_manager.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final Produk _produk = Produk();
  Map<String, dynamic>? product;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final fetchedProduct = await _produk.getProdukById(widget.productId);
      if (mounted) {
        setState(() {
          product = fetchedProduct;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product: $e')),
      );
    }
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: width, height: height);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, width: width, height: height);
    }
    return Image.asset('assets/images/lainnya.jpg',
        fit: BoxFit.cover, width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? const Center(child: Text('Product not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildImage(
                          product!['foto_produk'] ?? 'assets/images/lainnya.jpg',
                          height: 250,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product!['nama_produk']?.toString() ?? '-',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${(product!['harga'] as num).toDouble().toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product!['deskripsi']?.toString() ?? '-',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Stock: ${(product!['stok'] as num).toInt()}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: product == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final normalized = {
                  'produk_id': (product!['produk_id'] as num).toInt(),
                  'nama_produk': product!['nama_produk'].toString(),
                  'harga': (product!['harga'] as num).toDouble(),
                  'stok': (product!['stok'] as num).toInt(),
                  'foto_produk': product!['foto_produk']?.toString() ?? 'assets/images/lainnya.jpg', // Ensure a default image is always passed
                  'deskripsi': product!['deskripsi']?.toString(),
                };

                Provider.of<CartManager>(context, listen: false)
                    .addItem(normalized);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${product!['nama_produk']} added to cart!')),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add to Cart'),
              backgroundColor: const Color(0xFF8D6E63),
              foregroundColor: Colors.white,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
