import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart'; // Import for debugPrint

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app_db.db');
    debugPrint('DEBUG: _initDB called. Database path: $path');

    try {
      final db = await openDatabase(
        path,
        version: 4, // Increment database version
        onCreate: (db, version) async {
          debugPrint('DEBUG: onCreate called. Creating database tables...');
          await db.execute('''
            CREATE TABLE users(
              user_id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama TEXT,
              email TEXT UNIQUE,
              password TEXT,
              no_telp TEXT DEFAULT '',
              alamat TEXT DEFAULT '',
              role TEXT DEFAULT 'pembeli',
              avatar TEXT,
              transaction_count INTEGER DEFAULT 0,
              created_at TEXT DEFAULT (datetime('now','localtime'))
            )
          ''');

          await db.execute('''
            CREATE TABLE transaksi(
              transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              total REAL,
              shipping_cost REAL,
              discount_amount REAL,
              payment_method TEXT,
              address TEXT,
              status TEXT DEFAULT 'Diproses', -- New status column
              tanggal TEXT DEFAULT (datetime('now','localtime')),
              FOREIGN KEY (user_id) REFERENCES users(user_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE transaksi_detail(
              transaksi_detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaksi_id INTEGER,
              produk_id INTEGER,
              nama_produk TEXT,
              harga REAL,
              qty INTEGER,
              FOREIGN KEY (transaksi_id) REFERENCES transaksi(transaksi_id),
              FOREIGN KEY (produk_id) REFERENCES produk(produk_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE kategori_produk(
              kategori_id INTEGER PRIMARY KEY AUTOINCREMENT,
              gambar TEXT NOT NULL,
              kategori TEXT NOT NULL,
              deskripsi TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE produk(
              produk_id INTEGER PRIMARY KEY AUTOINCREMENT,
              kategori_id INTEGER NOT NULL,
              nama_produk TEXT NOT NULL,
              deskripsi TEXT NOT NULL,
              harga REAL NOT NULL,
              foto_produk TEXT NOT NULL,
              stok INTEGER NOT NULL,
              created_at TEXT DEFAULT (datetime('now','localtime')),
              FOREIGN KEY (kategori_id) REFERENCES kategori_produk(kategori_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE artikel(
              artikel_id INTEGER PRIMARY KEY AUTOINCREMENT,
              judul TEXT NOT NULL,
              deskripsi TEXT NOT NULL,
              gambar TEXT,
              tanggal TEXT
            )
          ''');
        },

        onUpgrade: (db, oldVersion, newVersion) async {
          debugPrint('DEBUG: Upgrading database from version $oldVersion to $newVersion...');
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE artikel(
                artikel_id INTEGER PRIMARY KEY AUTOINCREMENT,
                judul TEXT NOT NULL,
                deskripsi TEXT NOT NULL,
                gambar TEXT,
                tanggal TEXT
              )
            ''');
          }
          if (oldVersion < 3) {
            await db.execute('ALTER TABLE users ADD COLUMN transaction_count INTEGER DEFAULT 0');
          }
          if (oldVersion < 4) {
            // Add 'status' column to 'transaksi' table if it doesn't exist
            var tableInfo = await db.rawQuery("PRAGMA table_info(transaksi)");
            var statusColumnExists = tableInfo.any((column) => column['name'] == 'status');
            if (!statusColumnExists) {
              await db.execute('ALTER TABLE transaksi ADD COLUMN status TEXT DEFAULT "Diproses"');
            }

            // Create 'transaksi_detail' table if it doesn't exist
            var transaksiDetailTableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='transaksi_detail'");
            if (transaksiDetailTableExists.isEmpty) {
              await db.execute('''
                CREATE TABLE transaksi_detail(
                  transaksi_detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
                  transaksi_id INTEGER,
                  produk_id INTEGER,
                  nama_produk TEXT,
                  harga REAL,
                  qty INTEGER,
                  FOREIGN KEY (transaksi_id) REFERENCES transaksi(transaksi_id),
                  FOREIGN KEY (produk_id) REFERENCES produk(produk_id)
                )
              ''');
            }
          }
        },
      );
      debugPrint('DEBUG: Database opened successfully.');
      return db;
    } on DatabaseException catch (e) {
      debugPrint('ERROR: DatabaseException during _initDB: $e');
      if (e.toString().contains('read-only') || e.toString().contains('readonly')) {
        debugPrint('DEBUG: Database is read-only. Attempting to delete and recreate.');
        await deleteDatabase(path);
        _database = null; // Reset database instance
        return await _initDB(); // Retry initialization
      }
      rethrow; // Re-throw if it's not a read-only error
    } catch (e) {
      debugPrint('ERROR: Unknown error during _initDB: $e');
      rethrow;
    }
  }

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    // Ensure 'status' is included in the transaction map, defaulting if not provided
    final transactionWithStatus = {
      'status': 'Diproses', // Default status for new transactions
      ...transaction,
    };
    return await db.insert('transaksi', transactionWithStatus);
  }

  Future<void> insertTransactionDetails(List<Map<String, dynamic>> details) async {
    final db = await database;
    for (var detail in details) {
      await db.insert('transaksi_detail', detail);
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'transaksi',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionDetails(int transaksiId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        td.transaksi_detail_id,
        td.transaksi_id,
        td.produk_id,
        td.nama_produk,
        td.harga,
        td.qty,
        p.foto_produk
      FROM
        transaksi_detail td
      JOIN
        produk p ON td.produk_id = p.produk_id
      WHERE
        td.transaksi_id = ?
    ''', [transaksiId]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('DEBUG: Database closed.');
  }
}
