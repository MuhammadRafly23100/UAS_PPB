import 'package:flutter/material.dart';

import 'dart:io';
import 'package:provider/provider.dart';
import '../models/produk.dart';


class ProductDetailAdminPage extends StatefulWidget {
  final int productId;

  const ProductDetailAdminPage({super.key, required this.productId});

  @override
  State<ProductDetailAdminPage> createState() => _ProductDetailAdminPageState();
}

class _ProductDetailAdminPageState extends State<ProductDetailAdminPage> {
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

  Widget _buildImage(String? path, {double? width, double? height}) {
    if (path == null || path.isEmpty) {
      return Image.asset('assets/images/lainnya.jpg', fit: BoxFit.cover, width: width, height: height);
    }
    
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: width, height: height);
    }
    
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: width, height: height, errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/lainnya.jpg', fit: BoxFit.cover, width: width, height: height);
        });
      }
    } catch (e) {
      debugPrint('Error loading image from path: $path, Error: $e');
    }
    
    return Image.asset('assets/images/lainnya.jpg', fit: BoxFit.cover, width: width, height: height);
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
      // Admin view: disable Add to Cart button to prevent admins from adding items
      // to the shopping cart. Keep floatingActionButton null for admin pages.
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
