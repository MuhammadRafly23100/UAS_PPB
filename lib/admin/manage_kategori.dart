import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/kategori.dart';
import '../models/Produk.dart';

class ManageKategoriPage extends StatefulWidget {
  const ManageKategoriPage({super.key});

  @override
  State<ManageKategoriPage> createState() => _ManageKategoriPageState();
}

class _ManageKategoriPageState extends State<ManageKategoriPage>
    with SingleTickerProviderStateMixin {
  final Kategori _kategori = Kategori();
  final Produk _produk = Produk();

  final _formKey = GlobalKey<FormState>();
  TextEditingController namaController = TextEditingController();
  TextEditingController descController = TextEditingController();

  String? imagePath; 

  List<Map<String, dynamic>> kategoriList = [];
  int? editingKategoriId;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadKategori();

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(Function setStateDialog) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setStateDialog(() {
        imagePath = picked.path;
      });
    }
  }

  Future<void> _loadKategori() async {
    kategoriList = await _kategori.getKategori();
    setState(() {});
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    namaController.clear();
    descController.clear();
    imagePath = null;
    editingKategoriId = null;
  }

  Future<void> _saveKategori() async {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic> row = {
      'kategori': namaController.text,
      'deskripsi': descController.text,
      'gambar': imagePath ?? "",   
    };

    bool isNew = editingKategoriId == null;

    try {
      int result;
      if (isNew) {
        result = await _kategori.insertKategori(row);
      } else {
        result = await _kategori.updateKategori(editingKategoriId!, row);
      }

      if (result > 0) {
        _resetForm();
        _loadKategori();
        Navigator.pop(context);
        _showSuccess(
            isNew ? 'Category successfully added' : 'Category successfully updated');
      } else {
        _showError(
            isNew ? 'Failed to add category' : 'Failed to update category');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _deleteKategori(int id) async {
    bool confirmed = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this category?'),
            actions: [
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      int result = await _kategori.deleteKategori(id);
      if (result > 0) {
        _loadKategori();
        _showSuccess('Category successfully deleted');
      } else {
        _showError('Failed to delete category');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _editKategori(Map<String, dynamic> kategori) {
    setState(() {
      editingKategoriId = kategori['kategori_id'];
      namaController.text = kategori['kategori'];
      descController.text = kategori['deskripsi'];
      imagePath = kategori['gambar'];  
    });
    _showFormDialog();
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(editingKategoriId == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
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
                    child: imagePath == null
                        ? const Center(child: Text("No Image Selected"))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(imagePath!), fit: BoxFit.cover),
                          ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(setStateDialog),
                    icon: const Icon(Icons.image),
                    label: const Text("Choose Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D6E63),
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                    validator: (val) =>
                        val!.isEmpty ? 'Category Name must be filled' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (val) =>
                        val!.isEmpty ? 'Description must be filled' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              onPressed: () {
                _resetForm();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63),
                foregroundColor: Colors.black,
              ),
              onPressed: _saveKategori,
              child: Text(editingKategoriId == null ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }


  void _showSuccess(String message) async {
    _animController.forward(from: 0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  void _showError(String message) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Kategori'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7CCC8),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    _resetForm();
                    _showFormDialog();
                  },
                  child: const Text('Add Category'),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: kategoriList.isEmpty
                    ? const Center(child: Text('No categories yet'))
                    : ListView.builder(
                        itemCount: kategoriList.length,
                        itemBuilder: (context, index) {
                          final k = kategoriList[index];
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: k['gambar'] == null || k['gambar'] == ""
                                  ? const Icon(Icons.image_not_supported, size: 40)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(k['gambar']),
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                              title: Text(
                                k['kategori'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(k['deskripsi']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.black),
                                    onPressed: () => _editKategori(k),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteKategori(k['kategori_id']),
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
        ),
      ),
    );
  }
}
