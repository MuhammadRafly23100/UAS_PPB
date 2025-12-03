import '../db/db_helper.dart';

class Produk{
  final DBHelper _dbHelper = DBHelper();

  Future<List<Map<String, dynamic>>> getProduk() async {
    final db = await _dbHelper.database;
    return await db.query('produk');
  }

  Future<int> insertProduk(Map<String, dynamic> row) async {
    final db = await _dbHelper.database;
    return await db.insert('produk', row);
  }

  Future<Map<String, dynamic>> getProdukById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'produk',
      where: 'produk_id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : {};
  }

  Future<int> updateProduk(int id, Map<String, dynamic> row) async {
    final db = await _dbHelper.database;
    return await db.update('produk', row,
        where: 'produk_id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduk(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('produk', where: 'produk_id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getLatestProduk(int limit) async {
    final db = await _dbHelper.database;
    return await db.query(
      'produk',
      orderBy: 'produk_id DESC', // Assuming produk_id increments with new products
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getProdukByKategori(int kategoriId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'produk',
      where: 'kategori_id = ?',
      whereArgs: [kategoriId],
    );
  }

  Future<int> updateProdukStock(int produkId, int newStock) async {
    final db = await _dbHelper.database;
    return await db.update(
      'produk',
      {'stok': newStock},
      where: 'produk_id = ?',
      whereArgs: [produkId],
    );
  }
}
