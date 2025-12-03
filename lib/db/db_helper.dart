import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app_db.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
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
            created_at TEXT DEFAULT (datetime('now','localtime'))
          )
        ''');

        await db.execute('''
          CREATE TABLE transaksi(
            transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            total INTEGER,
            tanggal TEXT DEFAULT (datetime('now','localtime'))
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
      },
    );
  }
}
