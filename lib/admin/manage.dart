import 'dart:io';
import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../models/produk.dart';
import 'manage_kategori.dart';
import 'manage_produk.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  final Kategori _kategori = Kategori();
  final Produk _produk = Produk();

  List<Map<String, dynamic>> kategoriList = [];
  List<Map<String, dynamic>> produkList = [];
  int? filterKategoriId;

  @override
  void initState() {
    super.initState();
    _loadKategori();
    _loadProduk();
  }

  Future<void> _loadKategori() async {
    kategoriList = await _kategori.getKategori();
    setState(() {});
  }

  Future<void> _loadProduk() async {
    produkList = await _produk.getProduk();
    setState(() {});
  }

  List<Map<String, dynamic>> get filteredProdukList {
    if (filterKategoriId == null) return produkList;
    return produkList.where((p) => p['kategori_id'] == filterKategoriId).toList();
  }

  Future<void> _deleteProduk(int id) async {
    await _produk.deleteProduk(id);
    _loadProduk();
  }

  Future<void> _confirmDelete(int id) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,  
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8D6E63),
              foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteProduk(id);
    }
  }

  String formatRupiah(num number) {
    String numStr = number % 1 == 0 ? number.toInt().toString() : number.toString();
    return 'Rp ' + numStr.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Produk & Kategori'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageKategoriPage()),
                      ).then((_) => _loadKategori());
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD7CCC8)),
                    child: const Text('Kategori', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageProdukPage()),
                      ).then((_) {
                        _loadProduk();
                        _loadKategori();
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD7CCC8)),
                    child: const Text('Produk', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Filter Kategori: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: filterKategoriId,
                  hint: const Text('Semua'),
                  dropdownColor: Colors.white,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Semua')),
                    ...kategoriList.map((e) => DropdownMenuItem<int>(
                          value: e['kategori_id'],
                          child: Text(e['kategori']),
                        )),
                  ],
                  onChanged: (val) => setState(() => filterKategoriId = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: filteredProdukList.length,
              itemBuilder: (context, index) {
                final p = filteredProdukList[index];
                final kategoriName = kategoriList.firstWhere(
                  (k) => k['kategori_id'] == p['kategori_id'],
                  orElse: () => {'kategori': '-'},
                )['kategori'];
                return Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: p['foto_produk'] != null && p['foto_produk'].isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.file(
                                  File(p['foto_produk']),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                    color: Color(0xFFD7CCC8),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                                child: const Center(child: Icon(Icons.image, size: 40)),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['nama_produk'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(kategoriName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('Harga: ${formatRupiah(p['harga'])}', style: const TextStyle(fontSize: 12)),
                            Text('Stok: ${p['stok']}', style: const TextStyle(fontSize: 12)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ManageProdukPage(editProdukId: p['produk_id'])),
                                      ).then((_) => _loadProduk());
                                    },
                                    icon: const Icon(Icons.edit, color: Colors.black)),
                                IconButton(
                                    onPressed: () => _confirmDelete(p['produk_id']),
                                    icon: const Icon(Icons.delete, color: Colors.red)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
