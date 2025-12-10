import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/produk.dart';
import 'product_detail_page.dart';
import 'dart:io'; // Import for File

class SearchPage extends StatefulWidget {
  final String query;

  const SearchPage({super.key, required this.query});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Produk _produk = Produk();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  final NumberFormat currencyFormat = NumberFormat("#,###", "id_ID");

  @override
  void initState() {
    super.initState();
    _performSearch(widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _performSearch(widget.query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await _produk.searchProduk(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('Error performing search: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
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

  Widget _buildProductImage(String path, {double? width, double? height}) {
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
        title: Text('Search Results for "${widget.query}"'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(child: Text('Tidak ada produk ditemukan untuk "${widget.query}".'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75, // Adjust as needed
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final product = _searchResults[index];
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
                                  product['foto_produk'] ?? 'assets/images/lainnya.jpg',
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
                                'Rp ${currencyFormat.format(product['harga'])}',
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
    );
  }
}
