import 'package:flutter/foundation.dart';

class CartItem {
  final int produkId;
  final String nama;
  final double harga;
  final String imageUrl; // New field for product image
  int qty;

  CartItem({
    required this.produkId,
    required this.nama,
    required this.harga,
    required this.imageUrl, // Must be provided
    this.qty = 1,
  });

  factory CartItem.fromMap(Map<String, dynamic> m) {
    return CartItem(
      produkId: (m['produk_id'] as num).toInt(),
      nama: m['nama_produk'].toString(),
      harga: (m['harga'] as num).toDouble(),
      imageUrl: m['foto_produk'].toString(), // Assuming 'foto_produk' is the key for image URL
      qty: (m['qty'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'produk_id': produkId,
        'nama_produk': nama,
        'harga': harga,
        'foto_produk': imageUrl, // Include image URL in map
        'qty': qty,
      };
}

class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(Map<String, dynamic> product) {
    final item = CartItem.fromMap(product);

    final index =
        _items.indexWhere((e) => e.produkId == item.produkId);

    if (index >= 0) {
      _items[index].qty += 1;
    } else {
      _items.add(item);
    }

    notifyListeners();
  }

  void removeItem(int produkId) {
    _items.removeWhere((e) => e.produkId == produkId);
    notifyListeners();
  }

  double get total => _items.fold(
      0.0, (sum, item) => sum + (item.harga * item.qty));

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
