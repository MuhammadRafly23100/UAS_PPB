import '../db/db_helper.dart';

class Kategori{
  final DBHelper _dbHelper = DBHelper();

  Future<List<Map<String, dynamic>>> getKategori() async {
    final db = await _dbHelper.database;
    return await db.query('kategori_produk', orderBy: 'kategori_id DESC');
  }

  Future<int> insertKategori(Map<String, dynamic> row) async {
    final db = await _dbHelper.database;
    return await db.insert('kategori_produk', row);
  }

  Future<int> updateKategori(int id, Map<String, dynamic> row) async {
    final db = await _dbHelper.database;
    return await db.update(
      'kategori_produk',
      row,
      where: 'kategori_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteKategori(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'kategori_produk',
      where: 'kategori_id = ?',
      whereArgs: [id],
    );
  }
}
