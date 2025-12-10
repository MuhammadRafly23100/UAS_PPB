import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'app_db.db');
    debugPrint('DBHelper: Database path: $path');

    return await openDatabase(
      path,
      version: 5, // Increment database version to force upgrade
      onCreate: (db, version) async {
        debugPrint('DBHelper: onCreate triggered, version $version');
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
            tanggal_transaksi TEXT DEFAULT (datetime('now','localtime')),
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
        debugPrint('DBHelper: onUpgrade triggered from version $oldVersion to $newVersion');
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
          // Recreate transaksi table with new columns
          await db.execute('DROP TABLE IF EXISTS transaksi');
          await db.execute('''
            CREATE TABLE transaksi(
              transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              total REAL,
              shipping_cost REAL,
              discount_amount REAL,
              payment_method TEXT,
              address TEXT,
              tanggal_transaksi TEXT DEFAULT (datetime('now','localtime')),
              FOREIGN KEY (user_id) REFERENCES users(user_id)
            )
          ''');
          // Create transaksi_detail table
          await db.execute('DROP TABLE IF EXISTS transaksi_detail'); // Drop and recreate to ensure schema
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
        if (oldVersion < 5) {
          // Ensure the 'tanggal' column is renamed to 'tanggal_transaksi'
          // This is a more robust way to handle column renaming if it wasn't caught by oldVersion < 4
          // Check if 'tanggal' column exists before attempting to rename
          var tableInfo = await db.rawQuery("PRAGMA table_info(transaksi)");
          bool tanggalExists = tableInfo.any((column) => column['name'] == 'tanggal');
          if (tanggalExists) {
            await db.execute('ALTER TABLE transaksi RENAME COLUMN tanggal TO tanggal_transaksi');
          }
        }
      },
    );
  }

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transaksi', transaction);
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
      orderBy: 'tanggal_transaksi DESC',
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

  Future<List<Map<String, dynamic>>> getAllOrderHistory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        t.transaksi_id,
        t.user_id,
        u.nama AS user_nama,
        u.email AS user_email,
        t.total,
        t.shipping_cost,
        t.discount_amount,
        t.payment_method,
        t.address,
        t.tanggal_transaksi,
        td.nama_produk,
        td.harga AS produk_harga,
        td.qty AS produk_qty,
        p.foto_produk
      FROM
        transaksi t
      JOIN
        users u ON t.user_id = u.user_id
      JOIN
        transaksi_detail td ON t.transaksi_id = td.transaksi_id
      JOIN
        produk p ON td.produk_id = p.produk_id
      ORDER BY
        t.tanggal_transaksi DESC
    ''');
  }
}
