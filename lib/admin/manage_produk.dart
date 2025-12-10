import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'package:path/path.dart' as p; // Import path package
import '../models/kategori.dart';
import '../models/produk.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


class ManageProdukPage extends StatefulWidget {
  final int? editProdukId;

  const ManageProdukPage({super.key, this.editProdukId});

  @override
  State<ManageProdukPage> createState() => _ManageProdukPageState();
}

class _ManageProdukPageState extends State<ManageProdukPage> {
  final Kategori _kategori = Kategori();
  final Produk _produk = Produk();

  final _produkFormKey = GlobalKey<FormState>();
  TextEditingController namaController = TextEditingController();
  TextEditingController deskripsiController = TextEditingController();
  TextEditingController hargaController = TextEditingController();
  TextEditingController stokController = TextEditingController();

  List<Map<String, dynamic>> kategoriList = [];
  int? selectedKategoriId;
  File? selectedFoto;
  int? editingProdukId;
  int? oldStok;

  final _currencyFormatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadKategori();
    if (widget.editProdukId != null) {
      editingProdukId = widget.editProdukId;
      _loadProdukForEdit(editingProdukId!);
    }
  }

  Future<void> _loadKategori() async {
    kategoriList = await _kategori.getKategori();
    setState(() {});
  }

  Future<void> _loadProdukForEdit(int id) async {
    final produk = await _produk.getProdukById(id);
    if (produk != null) {
      setState(() {
        selectedKategoriId = produk['kategori_id'];
        namaController.text = produk['nama_produk'];
        deskripsiController.text = produk['deskripsi'];
        // Ensure harga is stored as a clean number without formatting
        hargaController.text = (produk['harga'] as num).toInt().toString();
        stokController.text = produk['stok'].toString();
        oldStok = produk['stok'];
        selectedFoto = File(produk['foto_produk']);
      });
    }
  }

  Future<void> _pickFoto() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedFoto = File(pickedFile.path));
    }
  }

  void _resetForm() {
    _produkFormKey.currentState?.reset();
    namaController.clear();
    deskripsiController.clear();
    hargaController.clear();
    stokController.clear();
    selectedKategoriId = null;
    selectedFoto = null;
    editingProdukId = null;
    oldStok = null;
  }

  Future<void> _saveProduk() async {
    if (!_produkFormKey.currentState!.validate() || selectedKategoriId == null) return;

    if (selectedFoto == null) {
      _showError('Silakan pilih foto produk');
      return;
    }

    // Parse price by removing all non-digit characters
    String priceText = hargaController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double? harga = double.tryParse(priceText);
    int? stok = int.tryParse(stokController.text);

    if (harga == null || stok == null) {
      _showError('Harga atau stok tidak valid');
      return;
    }

    String? fotoProdukPath;
    if (selectedFoto != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(selectedFoto!.path)}';
        final destinationPath = '${appDir.path}/$fileName';
        final savedImage = await selectedFoto!.copy(destinationPath);
        fotoProdukPath = savedImage.path;
        debugPrint('ManageProdukPage: Image saved to: $fotoProdukPath');
        
        // Verify file exists before saving to database
        if (!await savedImage.exists()) {
          _showError('Gagal menyimpan foto produk');
          return;
        }
      } catch (e) {
        _showError('Error menyimpan foto: $e');
        return;
      }
    }

    Map<String, dynamic> row = {
      'kategori_id': selectedKategoriId,
      'nama_produk': namaController.text,
      'deskripsi': deskripsiController.text,
      'harga': harga,
      'stok': stok,
      'foto_produk': fotoProdukPath,
    };

    bool isNew = editingProdukId == null;

    try {
      int result;
      if (isNew) {
        result = await _produk.insertProduk(row);
      } else {
        result = await _produk.updateProduk(editingProdukId!, row);
      }

      if (result > 0) {
        _resetForm();
        Navigator.pop(context, true);
        _showSuccess(isNew
            ? 'Produk berhasil ditambahkan'
            : 'Produk berhasil diperbarui');
      } else {
        _showError(isNew
            ? 'Gagal menambahkan produk'
            : 'Gagal memperbarui produk');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(editingProdukId == null ? 'Tambah Produk' : 'Edit Produk'),
        backgroundColor: const Color(0xFF8D6E63),
      ),

      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _produkFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedKategoriId,
                  dropdownColor: Colors.white,
                  items: kategoriList.map((e) {
                    return DropdownMenuItem<int>(
                      value: e['kategori_id'],
                      child: Text(e['kategori']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedKategoriId = val),
                  decoration: const InputDecoration(labelText: 'Pilih Kategori'),
                  validator: (val) => val == null ? 'Pilih Kategori' : null,
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() => selectedFoto = File(pickedFile.path));
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: selectedFoto == null
                            ? const Center(child: Text("Tidak ada gambar"))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedFoto!, fit: BoxFit.cover),
                              ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() => selectedFoto = File(pickedFile.path));
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Pilih Foto Produk"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D6E63),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (val) =>
                      val!.isEmpty ? 'Nama produk harus diisi!' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: deskripsiController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  validator: (val) =>
                      val!.isEmpty ? 'Deskripsi harus diisi!' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: hargaController,
                  decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val!.isEmpty ? 'Harga harus diisi!' : null,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text('Stock:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.red),
                      onPressed: () {
                        int current = int.tryParse(stokController.text) ?? 0;
                        if (current > 0) {
                          setState(() =>
                              stokController.text = (current - 1).toString());
                        }
                      },
                    ),
                    SizedBox(
                      width: 50,
                      child: TextFormField(
                        controller: stokController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val!.isEmpty ? 'Stok harus diisi!' : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.green),
                      onPressed: () {
                        int current = int.tryParse(stokController.text) ?? 0;
                        setState(() =>
                            stokController.text = (current + 1).toString());
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D6E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saveProduk,
                    child: Text(
                      editingProdukId == null ? 'Save' : 'Update',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
