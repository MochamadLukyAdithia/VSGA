// lib/services/product_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:vsga/app/models/Produk.dart';
import 'database_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  final DatabaseService _databaseService = DatabaseService();

  factory ProductService() => _instance;
  ProductService._internal();

  // Method untuk inisialisasi tabel produk
  Future<void> initializeProductTable() async {
    try {
      final db = await _databaseService.database;
      
      // Cek apakah tabel products sudah ada
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='products'",
      );
      
      if (result.isEmpty) {
        await _createProductTable(db);
        await _insertDefaultProducts(db);
        print('Product table created and default data inserted');
      } else {
        print('Product table already exists');
      }
    } catch (e) {
      print('Error initializing product table: $e');
      rethrow;
    }
  }

  Future<void> _createProductTable(Database db) async {
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
  }

  Future<void> _insertDefaultProducts(Database db) async {
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
  }

  // CREATE - Tambah produk baru
  Future<Product?> createProduct(Product product) async {
    try {
      final db = await _databaseService.database;
      final productMap = product.toMap();
      productMap.remove('id'); // Remove id karena auto increment
      
      final id = await db.insert('products', productMap);
      print('Product created with id: $id');
      
      return await getProductById(id);
    } catch (e) {
      print('Error creating product: $e');
      return null;
    }
  }

  // READ - Ambil semua produk
  Future<List<Product>> getAllProducts() async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'products',
        orderBy: 'created_at DESC',
      );
      
      return result.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  // READ - Ambil produk berdasarkan ID
  Future<Product?> getProductById(int id) async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isNotEmpty) {
        return Product.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error getting product by id: $e');
      return null;
    }
  }

  // READ - Cari produk berdasarkan nama
  Future<List<Product>> searchProducts(String query) async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'products',
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      
      return result.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // READ - Ambil produk dengan stock rendah
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'products',
        where: 'stock <= ?',
        whereArgs: [threshold],
        orderBy: 'stock ASC',
      );
      
      return result.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error getting low stock products: $e');
      return [];
    }
  }

  // UPDATE - Update produk
  Future<bool> updateProduct(Product product) async {
    try {
      if (product.id == null) {
        print('Cannot update product: ID is null');
        return false;
      }

      final db = await _databaseService.database;
      final productMap = product.toMap();
      productMap['updated_at'] = DateTime.now().toIso8601String();
      
      final rowsAffected = await db.update(
        'products',
        productMap,
        where: 'id = ?',
        whereArgs: [product.id],
      );
      
      print('Updated $rowsAffected rows');
      return rowsAffected > 0;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // UPDATE - Update stock produk
  Future<bool> updateStock(int productId, int newStock) async {
    try {
      final db = await _databaseService.database;
      final rowsAffected = await db.update(
        'products',
        {
          'stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
      
      print('Updated stock for product $productId: $newStock');
      return rowsAffected > 0;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  // UPDATE - Kurangi stock (untuk pembelian)
  Future<bool> reduceStock(int productId, int quantity) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        print('Product not found');
        return false;
      }

      if (product.stock < quantity) {
        print('Insufficient stock. Available: ${product.stock}, Required: $quantity');
        return false;
      }

      return await updateStock(productId, product.stock - quantity);
    } catch (e) {
      print('Error reducing stock: $e');
      return false;
    }
  }

  // DELETE - Hapus produk
  Future<bool> deleteProduct(int id) async {
    try {
      final db = await _databaseService.database;
      final rowsAffected = await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('Deleted $rowsAffected rows');
      return rowsAffected > 0;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Utility - Hitung total produk
  Future<int> getTotalProductCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting product count: $e');
      return 0;
    }
  }

  // Utility - Hitung total nilai stock
  Future<double> getTotalStockValue() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT SUM(price * stock) as total FROM products',
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error calculating total stock value: $e');
      return 0.0;
    }
  }

  // Utility - Reset semua data produk
  Future<void> resetProductData() async {
    try {
      final db = await _databaseService.database;
      await db.delete('products');
      await _insertDefaultProducts(db);
      print('Product data reset successfully');
    } catch (e) {
      print('Error resetting product data: $e');
    }
  }

  // Utility - Export data produk ke List<Map>
  Future<List<Map<String, dynamic>>> exportProductData() async {
    try {
      final db = await _databaseService.database;
      return await db.query('products', orderBy: 'id ASC');
    } catch (e) {
      print('Error exporting product data: $e');
      return [];
    }
  }
}