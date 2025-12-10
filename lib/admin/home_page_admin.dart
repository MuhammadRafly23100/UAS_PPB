import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/produk.dart'; // Import Produk model
import '../login.dart';
import 'manage.dart';
import 'dart:io'; // Import dart:io for File
import 'product_detail_admin_page.dart'; // Import the admin product detail page
import 'admin_order_history_page.dart'; // Import the admin order history page

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({super.key});

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  int userCount = 0;
  int shippingCount = 0;
  int _currentIndex = 0;
  List<Map<String, dynamic>> latestProducts = []; // To store latest products

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadData();
    _loadLatestProducts(); // Load latest products
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  Future<void> _loadData() async {
    final _user = User();
    final users = await _user.getUserCount();
    final shipments = await _user.getPendingShippingCount();
    setState(() {
      userCount = users;
      shippingCount = shipments;
    });
  }

  Future<void> _loadLatestProducts() async {
    final produk = Produk();
    final products = await produk.getLatestProduk(4); // Get 4 latest products
    setState(() {
      latestProducts = products;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
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

  Widget _buildCurrentPage() {
    if (_currentIndex == 0) {
      return _buildHomePage();
    } else {
      return _buildManagePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 40, color: Colors.brown),
                      const SizedBox(height: 8),
                      const Text('Users',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '$userCount pengguna',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminOrderHistoryPage()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 40, color: Colors.brown),
                        const SizedBox(height: 8),
                        const Text('Riwayat Pesanan',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '$shippingCount pesanan',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Text('Featured Crafts', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          latestProducts.isEmpty
              ? const Center(child: Text("Tidak ada produk unggulan ditemukan"))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: latestProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75, // Adjust as needed for vertical layout
                  ),
                  itemBuilder: (context, index) {
                    final item = latestProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailAdminPage(productId: item['produk_id']),
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
                              child: buildImage(
                                item['foto_produk'] ?? 'assets/images/lainnya.jpg',
                                height: 120,
                                width: double.infinity,
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
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildManagePage() {
    return ManagePage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crafty - Admin'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2EDE5),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildCurrentPage(),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF2EDE5),
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF5D4037),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() {
          _currentIndex = index;
        }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Manage'),
        ],
      ),
    );
  }
}
