import '../db/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class User{
  final DBHelper _dbHelper = DBHelper();

  Future<int> registerUser({
    required String nama,
    required String email,
    required String password,
    required String noTelp,
    required String alamat,
    required String role,
  }) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert('users', {
        'nama': nama,
        'email': email,
        'password': password,
        'no_telp': noTelp,
        'alamat': alamat,
        'role': role,
      });
    } catch (e) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateTransactionCount(int userId, int count) async {
    final db = await _dbHelper.database;
    try {
      return await db.update(
        'users',
        {'transaction_count': count},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      print('Failed to update transaction count: $e');
      return -1;
    }
  }

  Future<int> updatePassword(String email, String newPassword) async {
    final db = await _dbHelper.database;
    try {
      return await db.update(
        'users',
        {'password': newPassword},
        where: 'email = ?',
        whereArgs: [email],
      );
    } catch (e) {
      print('Failed to update password: $e');
      return -1;
    }
  }

  Future<int> updateUserAvatar(int userId, String path) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {'avatar': path},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'nama': user['nama'],
        'email': user['email'],
        'no_telp': user['no_telp'],
        'alamat': user['alamat'],
        'avatar': user['avatar'],
      },
      where: 'user_id = ?',
      whereArgs: [user['user_id']],
    );
  }

  Future<void> deleteAllUsers() async {
    final db = await _dbHelper.database;
    await db.delete('users');
  }

  Future<int> getUserCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingShippingCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM transaksi WHERE user_id = ?', [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
