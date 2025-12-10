import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for NumberFormat
import 'models/produk.dart';
import 'product_detail_page.dart';
import 'dart:io'; // Import for File
import 'search.dart'; // Import SearchPage

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final Produk _produk = Produk();
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await _produk.getProduk(); // Fetch all products
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
      }
    } catch (e) {
      debugPrint('Error loading all products: $e');
      if (mounted) {
        setState(() {
          _allProducts = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSearch() {
    if (_searchController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPage(query: _searchController.text),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildProductImage(String? path, {double? width, double? height}) {
    if (path == null || path.isEmpty) {
      return Image.asset('assets/images/lainnya.jpg', fit: BoxFit.cover, width: width, height: height);
    }
    
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: width, height: height);
    }
    
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, width: width, height: height);
    }
    
    return Image.asset('assets/images/lainnya.jpg', fit: BoxFit.cover, width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Products'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search crafts...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (v) => _navigateToSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _navigateToSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allProducts.isEmpty
                    ? const Center(child: Text('Tidak ada produk ditemukan.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.75, // Adjust as needed
                        ),
                        itemCount: _allProducts.length,
                        itemBuilder: (context, index) {
                          final product = _allProducts[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailPage(productId: product['produk_id']),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: _buildProductImage(
                                        product['foto_produk'],
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      product['nama_produk'],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      'Rp ${NumberFormat("#,###", "id_ID").format(product['harga'])}',
                                      style: const TextStyle(fontSize: 14, color: Colors.green),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
                                    child: Text(
                                      'Stok: ${product['stok']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
