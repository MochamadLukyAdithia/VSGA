// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Method untuk inisialisasi database secara eksplisit
  Future<void> initializeDatabase() async {
    if (_database == null) {
      _database = await _initDatabase();
    }
  }

  Future<Database> get database async {
    // Pastikan database sudah diinisialisasi
    await initializeDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'app_database.db');
      print('Database path: $path'); // Debug log

      return await openDatabase(
        path,
        version: 4, // Increment version untuk menambah role
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) {
          print('Database opened successfully'); // Debug log
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      print('Creating database tables...'); // Debug log

      // Buat tabel users dengan role
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          email TEXT NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL CHECK(role IN ('user', 'admin')),
          created_at TEXT NOT NULL,
          UNIQUE(username, role),
          UNIQUE(email, role)
        )
      ''');

      // Buat tabel accelerometer
      await db.execute('''
        CREATE TABLE accelerometer(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          x REAL NOT NULL,
          y REAL NOT NULL,
          z REAL NOT NULL,
          timestamp TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Buat tabel products
      await db.execute('''
        CREATE TABLE products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          stock INTEGER NOT NULL DEFAULT 0,
          description TEXT NOT NULL,
          image_url TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Buat tabel transactions
      await db.execute('''
        CREATE TABLE transactions(
          id TEXT PRIMARY KEY,
          customer_name TEXT NOT NULL,
          customer_phone TEXT NOT NULL,
          customer_address TEXT NOT NULL,
          total_amount INTEGER NOT NULL,
          status TEXT NOT NULL CHECK(status IN ('pending', 'completed', 'cancelled')),
          order_time TEXT NOT NULL,
          gps_location TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Buat tabel transaction_items
      await db.execute('''
        CREATE TABLE transaction_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          price INTEGER NOT NULL,
          subtotal INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
        )
      ''');

      // Buat index untuk performa yang lebih baik
      await db.execute('CREATE INDEX idx_users_username_role ON users(username, role)');
      await db.execute('CREATE INDEX idx_users_email_role ON users(email, role)');
      await db.execute('CREATE INDEX idx_transactions_status ON transactions(status)');
      await db.execute('CREATE INDEX idx_transactions_order_time ON transactions(order_time)');
      await db.execute('CREATE INDEX idx_transaction_items_transaction_id ON transaction_items(transaction_id)');

      // Insert default users
      await _insertDefaultUsers(db);

      // Insert default products
      await _insertDefaultProducts(db);

      print('Database tables created successfully'); // Debug log
    } catch (e) {
      print('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    try {
      print('Upgrading database from version $oldVersion to $newVersion');
      
      if (oldVersion < 2) {
        // Add products table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            stock INTEGER NOT NULL DEFAULT 0,
            description TEXT NOT NULL,
            image_url TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        
        // Insert default products
        await _insertDefaultProducts(db);
        print('Products table added and default data inserted');
      }

      if (oldVersion < 3) {
        // Add transactions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions(
            id TEXT PRIMARY KEY,
            customer_name TEXT NOT NULL,
            customer_phone TEXT NOT NULL,
            customer_address TEXT NOT NULL,
            total_amount INTEGER NOT NULL,
            status TEXT NOT NULL CHECK(status IN ('pending', 'completed', 'cancelled')),
            order_time TEXT NOT NULL,
            gps_location TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Add transaction_items table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transaction_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price INTEGER NOT NULL,
            subtotal INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
          )
        ''');

        // Create indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_order_time ON transactions(order_time)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transaction_items_transaction_id ON transaction_items(transaction_id)');

        print('Transaction tables added successfully');
      }

      if (oldVersion < 4) {
        // Add role column to users table
        await db.execute('ALTER TABLE users ADD COLUMN role TEXT DEFAULT "user"');
        
        // Update existing users to have role
        await db.execute('UPDATE users SET role = "user" WHERE role IS NULL');
        
        // Recreate users table with proper constraints
        await db.execute('''
          CREATE TABLE users_new(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL CHECK(role IN ('user', 'admin')),
            created_at TEXT NOT NULL,
            UNIQUE(username, role),
            UNIQUE(email, role)
          )
        ''');
        
        // Copy data from old table
        await db.execute('''
          INSERT INTO users_new (id, username, email, password, role, created_at)
          SELECT id, username, email, password, COALESCE(role, 'user'), created_at FROM users
        ''');
        
        // Drop old table and rename new table
        await db.execute('DROP TABLE users');
        await db.execute('ALTER TABLE users_new RENAME TO users');
        
        // Create indexes
        await db.execute('CREATE INDEX idx_users_username_role ON users(username, role)');
        await db.execute('CREATE INDEX idx_users_email_role ON users(email, role)');
        
        // Insert default admin if not exists
        await _insertDefaultUsers(db);
        
        print('Users table updated with role support');
      }
    } catch (e) {
      print('Error upgrading database: $e');
      rethrow;
    }
  }

  Future<void> _insertDefaultUsers(Database db) async {
    try {
      // Check if default users already exist
      final existingUsers = await db.query('users', limit: 1);
      if (existingUsers.isNotEmpty) {
        print('Default users already exist, skipping insertion');
        return;
      }

      // Insert default user
      String userHashedPassword = _hashPassword('luky123');
      await db.insert('users', {
        'username': 'luky',
        'email': 'luky@gmail.com',
        'password': userHashedPassword,
        'role': 'user',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insert default admin
      String adminHashedPassword = _hashPassword('admin123');
      await db.insert('users', {
        'username': 'admin',
        'email': 'admin@gmail.com',
        'password': adminHashedPassword,
        'role': 'admin',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Default users inserted successfully');
    } catch (e) {
      print('Error inserting default users: $e');
    }
  }

  Future<void> _insertDefaultProducts(Database db) async {
    try {
      // Check if products already exist
      final existingProducts = await db.query('products', limit: 1);
      if (existingProducts.isNotEmpty) {
        print('Default products already exist, skipping insertion');
        return;
      }

      final defaultProducts = [
        {
          'name': 'Roti Tawar Gandum',
          'price': 15000.0,
          'stock': 50,
          'description': 'Roti tawar gandum segar dan bergizi',
          'image_url': 'assets/images/roti_tawar.jpg',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Croissant Original',
          'price': 25000.0,
          'stock': 30,
          'description': 'Croissant dengan tekstur berlapis dan renyah',
          'image_url': 'assets/images/croissant.jpg',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Donat Coklat',
          'price': 12000.0,
          'stock': 40,
          'description': 'Donat lembut dengan topping coklat manis',
          'image_url': 'assets/images/donat_coklat.jpg',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];

      for (final product in defaultProducts) {
        await db.insert('products', product);
      }
      
      print('Default products inserted successfully');
    } catch (e) {
      print('Error inserting default products: $e');
    }
  }

  Future<void> insertSensorAccelerometer(
    double x,
    double y,
    double z,
    DateTime? timestamp,
  ) async {
    try {
      final db = await database;
      await db.insert('accelerometer', {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('Accelerometer data inserted successfully'); // Debug log
    } catch (e) {
      print('Error inserting accelerometer data: $e');
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> authenticateUserWithRole(String username, String password, String role) async {
    try {
      final db = await database;
      String hashedPassword = _hashPassword(password);

      print('Authenticating user: $username with role: $role'); // Debug log

      final result = await db.query(
        'users',
        where: '(username = ? OR email = ?) AND password = ? AND role = ?',
        whereArgs: [username, username, hashedPassword, role],
      );

      print('Query result: ${result.length} rows found'); // Debug log
      return result.isNotEmpty;
    } catch (e) {
      print('Error authenticating user: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserDataWithRole(String username, String role) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: '(username = ? OR email = ?) AND role = ?',
        whereArgs: [username, username, role],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<bool> checkUsernameExists(String username, String role) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'username = ? AND role = ?',
        whereArgs: [username, role],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<bool> checkEmailExists(String email, String role) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'email = ? AND role = ?',
        whereArgs: [email, role],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<bool> createUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final db = await database;
      String hashedPassword = _hashPassword(password);
      
      await db.insert('users', {
        'username': username,
        'email': email,
        'password': hashedPassword,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updatePassword(String username, String newPassword, String role) async {
    try {
      final db = await database;
      String hashedPassword = _hashPassword(newPassword);
      
      final result = await db.update(
        'users',
        {'password': hashedPassword},
        where: 'username = ? AND role = ?',
        whereArgs: [username, role],
      );
      
      return result > 0;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  // Backward compatibility methods
  Future<bool> authenticateUser(String username, String password) async {
    return await authenticateUserWithRole(username, password, 'user');
  }

  Future<Map<String, dynamic>?> getUserData(String username) async {
    return await getUserDataWithRole(username, 'user');
  }

  // Method untuk reset database (berguna untuk testing)
  Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'app_database.db');
      await deleteDatabase(path);
      _database = null;
      await initializeDatabase();
      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  // Method untuk cek apakah database sudah ada
  Future<bool> isDatabaseExists() async {
    try {
      String path = join(await getDatabasesPath(), 'app_database.db');
      return await databaseExists(path);
    } catch (e) {
      print('Error checking database existence: $e');
      return false;
    }
  }

  // Method untuk mendapatkan semua tabel yang ada
  Future<List<String>> getTables() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      return result.map((row) => row['name'] as String).toList();
    } catch (e) {
      print('Error getting tables: $e');
      return [];
    }
  }

  // Method untuk menghitung jumlah record di setiap tabel
  Future<Map<String, int>> getTableCounts() async {
    try {
      final db = await database;
      final tables = await getTables();
      Map<String, int> counts = {};
      
      for (String table in tables) {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        counts[table] = result.first['count'] as int;
      }
      
      return counts;
    } catch (e) {
      print('Error getting table counts: $e');
      return {};
    }
  }
}