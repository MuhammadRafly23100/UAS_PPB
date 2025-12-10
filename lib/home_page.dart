import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'models/kategori.dart';
import 'models/produk.dart';
import 'profile.dart';
import 'search.dart';
import 'cart.dart';
import 'dart:io';
import 'session_manager.dart';
import 'product_detail_page.dart'; // Import the new product detail page
import 'category_products_page.dart'; // Import the category products page
import 'explore_page.dart'; // Import the new ExplorePage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final Produk _produk = Produk();
  final Kategori _kategori = Kategori();

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> featuredProducts = [];

  final List<String> _testimonialImages = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
  ];

  @override
  void initState() {
    super.initState();
    checkSession();
    loadCategories();
    loadFeaturedProducts();
  }

  Future<void> checkSession() async {
    bool loggedIn = await SessionManager.isLoggedIn();
    if (!loggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> loadCategories() async {
    try {
      final kategori = await _kategori.getKategori();
      if (!mounted) return;
      setState(() {
        categories = kategori.map((cat) {
          return {
            'kategori_id': cat['kategori_id'],
            'kategori': cat['kategori'],
            'gambar': (cat['gambar'] == null || cat['gambar'].toString().isEmpty)
                ? 'assets/images/lainnya.jpg'
                : cat['gambar'].toString(),
          };
        }).toList();
      });
    } catch (e) {
      setState(() => categories = []);
    }
  }

  Future<void> loadFeaturedProducts() async {
    try {
      final products = await _produk.getLatestProduk(3);
      if (!mounted) return;
      setState(() {
        featuredProducts = products;
      });
    } catch (e) {
      setState(() => featuredProducts = []);
    }
  }

  Widget buildImage(String path, {double? width, double? height}) {
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, 
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            homeContent(),
            const ExplorePage(), // Use the new ExplorePage
            CartPage(),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFF2EDE5),
          currentIndex: _currentIndex,
          selectedItemColor: Colors.brown,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
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
          const SizedBox(height: 24),
          const Text('Featured Crafts', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          featuredProducts.isEmpty
              ? const Center(child: Text("Tidak ada produk unggulan ditemukan"))
              : SizedBox(
                  height: 280, // Increased height for the ListView to accommodate taller images
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredProducts.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = featuredProducts[index];
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
                          child: SizedBox(
                            width: 180,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: buildImage(
                                    item['foto_produk'] ?? 'assets/images/lainnya.jpg',
                                    height: 180, // Made image square
                                    width: 180, // Made image square
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                                  child: Text(item['nama_produk']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                  child: Text(item['deskripsi']!, style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 28),
          const Text('Categories', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          categories.isEmpty
              ? const Center(child: Text("Tidak ada kategori ditemukan"))
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final c = categories[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryProductsPage(
                              kategoriId: c['kategori_id'],
                              kategoriName: c['kategori'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: buildImage(c['gambar'], width: 40, height: double.infinity),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c['kategori'],
                              style: const TextStyle(color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 28),
          const Text('Promo', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CarouselSlider(
            items: _testimonialImages.map((imagePath) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            options: CarouselOptions(
              height: 200, // Adjust height as needed
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16/9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.8,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
