import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'models/kategori.dart';
import 'models/produk.dart';
import 'profile.dart';
import 'search.dart';
import 'cart.dart';
import 'dart:io';
import 'session_manager.dart'; 

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

  final List<Map<String, String>> featuredItems = [
    {
      'gambar': 'assets/image/vas_bunga.jpg',
      'name': 'Vas Bunga',
      'description': 'Cantik untuk dekorasi rumah'
    },
    {
      'gambar': 'assets/image/hiasan_dinding.jpg',
      'name': 'Hiasan Dinding',
      'description': 'Tambahkan sentuhan artistik'
    },
    {
      'gambar': 'assets/image/kursi.jpeg',
      'name': 'Kursi Kayu',
      'description': 'Nyaman dan elegan'
    },
  ];

  final List<Map<String, dynamic>> testimonials = [
    {"name": "Aulia", "rating": 5, "comment": "Kualitas produk sangat bagus! Pengiriman cepat."},
    {"name": "Reno", "rating": 4, "comment": "Craft-nya rapi dan sesuai gambar. Recommended!"},
    {"name": "Mira", "rating": 5, "comment": "Suka banget! Handmade-nya keliatan premium."},
  ];

  @override
  void initState() {
    super.initState();
    checkSession();
    loadCategories();
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
                ? 'assets/image/lainnya.jpg'
                : cat['gambar'].toString(),
          };
        }).toList();
      });
    } catch (e) {
      setState(() => categories = []);
    }
  }

  Widget buildCategoryImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Image.asset('assets/image/lainnya.jpg', fit: BoxFit.cover);
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
            const Center(child: Text("Explore")),
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
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featuredItems.length,
              separatorBuilder: (context, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = featuredItems[index];
                return Card(
                  elevation: 6,
                  color: Colors.white,
                  shadowColor: Colors.black.withOpacity(0.22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.asset(
                            item['gambar']!,
                            height: 140,
                            width: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(item['name']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(item['description']!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ),
                      ],
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
                      onPressed: () {},
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
                              child: buildCategoryImage(c['gambar']),
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
          const Text('Testimonials', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CarouselSlider.builder(
            itemCount: testimonials.length,
            itemBuilder: (context, index, _) {
              final t = testimonials[index];
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(i < t['rating'] ? Icons.star : Icons.star_border, color: Colors.orange, size: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(t['comment'], style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                  ],
                ),
              );
            },
            options: CarouselOptions(height: 160, enlargeCenterPage: true, autoPlay: true),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
