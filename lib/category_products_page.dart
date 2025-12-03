import 'package:flutter/material.dart';
import 'models/produk.dart';
import 'product_detail_page.dart';
import 'dart:io';

class CategoryProductsPage extends StatefulWidget {
  final int kategoriId;
  final String kategoriName;

  const CategoryProductsPage({
    super.key,
    required this.kategoriId,
    required this.kategoriName,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final Produk _produk = Produk();
  List<Map<String, dynamic>> categoryProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
  }

  Future<void> _loadCategoryProducts() async {
    try {
      final products = await _produk.getProdukByKategori(widget.kategoriId);
      if (!mounted) return;
      setState(() {
        categoryProducts = products;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        categoryProducts = [];
        isLoading = false;
      });
      print('Error loading category products: $e');
    }
  }

  Widget _buildImage(String path, {double? width, double? height}) {
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
        title: Text(widget.kategoriName),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryProducts.isEmpty
              ? Center(child: Text("Tidak ada produk ditemukan untuk kategori ${widget.kategoriName}"))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7, // Adjust as needed
                  ),
                  itemCount: categoryProducts.length,
                  itemBuilder: (context, index) {
                    final item = categoryProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(productId: item['produk_id']),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        color: Colors.white,
                        shadowColor: Colors.black.withOpacity(0.22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: _buildImage(
                                item['foto_produk'] ?? 'assets/images/lainnya.jpg',
                                height: 150, // Adjust image height
                                width: double.infinity,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                item['nama_produk']!,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                item['deskripsi']!,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // You can add price or other details here if available in your Produk model
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
