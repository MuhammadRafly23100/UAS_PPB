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
}
