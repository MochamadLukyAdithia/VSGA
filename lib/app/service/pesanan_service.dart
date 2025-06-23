// lib/services/transaction_service.dart

import 'package:vsga/app/models/Tansaksi.dart';
import 'package:vsga/app/service/database_service.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Insert new transaction
  Future<int> insertTransaction(Transaction transaction) async {
    try {
      final db = await _databaseService.database;

      // Start transaction untuk memastikan atomicity
      return await db.transaction((txn) async {
        // Insert transaction
        final transactionId = await txn.insert('transactions', {
          'id': transaction.id,
          'customer_name': transaction.customerName,
          'customer_phone': transaction.customerPhone,
          'customer_address': transaction.customerAddress,
          'total_amount': transaction.totalAmount,
          'status': transaction.status.toString().split('.').last,
          'order_time': transaction.orderTime.toIso8601String(),
          'gps_location': transaction.gpsLocation,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Insert transaction items
        for (final item in transaction.items) {
          await txn.insert('transaction_items', {
            'transaction_id': transaction.id,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.price,
            'subtotal': item.price * item.quantity,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        return transactionId;
      });
    } catch (e) {
      print('Error inserting transaction: $e');
      throw Exception('Failed to insert transaction: $e');
    }
  }

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final db = await _databaseService.database;

      final transactionMaps = await db.query(
        'transactions',
        orderBy: 'order_time DESC',
      );

      List<Transaction> transactions = [];

      for (final transactionMap in transactionMaps) {
        // Get transaction items
        final itemMaps = await db.query(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [transactionMap['id']],
        );

        final items = itemMaps
            .map(
              (itemMap) => TransactionItem(
                productName: itemMap['product_name'] as String,
                quantity: itemMap['quantity'] as int,
                price: itemMap['price'] as int,
              ),
            )
            .toList();

        transactions.add(
          Transaction(
            id: transactionMap['id'] as String,
            customerName: transactionMap['customer_name'] as String,
            customerPhone: transactionMap['customer_phone'] as String,
            customerAddress: transactionMap['customer_address'] as String,
            items: items,
            totalAmount: transactionMap['total_amount'] as int,
            status: _parseTransactionStatus(transactionMap['status'] as String),
            orderTime: DateTime.parse(transactionMap['order_time'] as String),
            gpsLocation: transactionMap['gps_location'] as String,
          ),
        );
      }

      return transactions;
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }

  // Get transactions by status
  Future<List<Transaction>> getTransactionsByStatus(
    TransactionStatus status,
  ) async {
    try {
      final db = await _databaseService.database;

      final transactionMaps = await db.query(
        'transactions',
        where: 'status = ?',
        whereArgs: [status.toString().split('.').last],
        orderBy: 'order_time DESC',
      );

      List<Transaction> transactions = [];

      for (final transactionMap in transactionMaps) {
        final itemMaps = await db.query(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [transactionMap['id']],
        );

        final items = itemMaps
            .map(
              (itemMap) => TransactionItem(
                productName: itemMap['product_name'] as String,
                quantity: itemMap['quantity'] as int,
                price: itemMap['price'] as int,
              ),
            )
            .toList();

        transactions.add(
          Transaction(
            id: transactionMap['id'] as String,
            customerName: transactionMap['customer_name'] as String,
            customerPhone: transactionMap['customer_phone'] as String,
            customerAddress: transactionMap['customer_address'] as String,
            items: items,
            totalAmount: transactionMap['total_amount'] as int,
            status: _parseTransactionStatus(transactionMap['status'] as String),
            orderTime: DateTime.parse(transactionMap['order_time'] as String),
            gpsLocation: transactionMap['gps_location'] as String,
          ),
        );
      }

      return transactions;
    } catch (e) {
      print('Error getting transactions by status: $e');
      return [];
    }
  }

  // Update transaction status
  Future<bool> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) async {
    try {
      final db = await _databaseService.database;

      final result = await db.update(
        'transactions',
        {
          'status': status.toString().split('.').last,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      return result > 0;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  // Get transaction by ID
  Future<Transaction?> getTransactionById(String transactionId) async {
    try {
      final db = await _databaseService.database;

      final transactionMaps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );

      if (transactionMaps.isEmpty) return null;

      final transactionMap = transactionMaps.first;

      // Get transaction items
      final itemMaps = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      final items = itemMaps
          .map(
            (itemMap) => TransactionItem(
              productName: itemMap['product_name'] as String,
              quantity: itemMap['quantity'] as int,
              price: itemMap['price'] as int,
            ),
          )
          .toList();

      return Transaction(
        id: transactionMap['id'] as String,
        customerName: transactionMap['customer_name'] as String,
        customerPhone: transactionMap['customer_phone'] as String,
        customerAddress: transactionMap['customer_address'] as String,
        items: items,
        totalAmount: transactionMap['total_amount'] as int,
        status: _parseTransactionStatus(transactionMap['status'] as String),
        orderTime: DateTime.parse(transactionMap['order_time'] as String),
        gpsLocation: transactionMap['gps_location'] as String,
      );
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  // Get today's revenue
  Future<int> getTodayRevenue() async {
    try {
      final db = await _databaseService.database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await db.rawQuery(
        '''
        SELECT SUM(total_amount) as revenue
        FROM transactions 
        WHERE status = ? 
        AND order_time >= ? 
        AND order_time < ?
      ''',
        ['completed', startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );

      return (result.first['revenue'] as int?) ?? 0;
    } catch (e) {
      print('Error getting today revenue: $e');
      return 0;
    }
  }

  // Get transactions count by status
  Future<Map<String, int>> getTransactionCounts() async {
    try {
      final db = await _databaseService.database;

      final result = await db.rawQuery('''
        SELECT status, COUNT(*) as count
        FROM transactions
        GROUP BY status
      ''');

      Map<String, int> counts = {'pending': 0, 'completed': 0, 'cancelled': 0};

      for (final row in result) {
        counts[row['status'] as String] = row['count'] as int;
      }

      return counts;
    } catch (e) {
      print('Error getting transaction counts: $e');
      return {'pending': 0, 'completed': 0, 'cancelled': 0};
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final db = await _databaseService.database;

      return await db.transaction((txn) async {
        // Delete transaction items first
        await txn.delete(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [transactionId],
        );

        // Delete transaction
        final result = await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [transactionId],
        );

        return result > 0;
      });
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Helper method to parse transaction status
  TransactionStatus _parseTransactionStatus(String status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  // Insert sample data for testing
  Future<void> insertSampleData() async {
    try {
      final sampleTransactions = [
        Transaction(
          id: 'TRX001',
          customerName: 'Ahmad Rizki',
          customerPhone: '081234567890',
          customerAddress: 'Jl. Mawar No. 123, Jakarta',
          items: [
            TransactionItem(
              productName: 'Roti Tawar Gandum',
              quantity: 2,
              price: 15000,
            ),
            TransactionItem(
              productName: 'Croissant Original',
              quantity: 1,
              price: 25000,
            ),
          ],
          totalAmount: 55000,
          status: TransactionStatus.completed,
          orderTime: DateTime.now().subtract(const Duration(hours: 2)),
          gpsLocation: '-6.2088, 106.8456',
        ),
        Transaction(
          id: 'TRX002',
          customerName: 'Siti Nurhaliza',
          customerPhone: '081987654321',
          customerAddress: 'Jl. Melati No. 456, Bandung',
          items: [
            TransactionItem(
              productName: 'Donat Coklat',
              quantity: 5,
              price: 12000,
            ),
          ],
          totalAmount: 60000,
          status: TransactionStatus.pending,
          orderTime: DateTime.now().subtract(const Duration(minutes: 30)),
          gpsLocation: '-6.9175, 107.6191',
        ),
        Transaction(
          id: 'TRX003',
          customerName: 'Budi Santoso',
          customerPhone: '081555666777',
          customerAddress: 'Jl. Anggrek No. 789, Surabaya',
          items: [
            TransactionItem(
              productName: 'Croissant Original',
              quantity: 3,
              price: 25000,
            ),
            TransactionItem(
              productName: 'Donat Coklat',
              quantity: 2,
              price: 12000,
            ),
          ],
          totalAmount: 99000,
          status: TransactionStatus.cancelled,
          orderTime: DateTime.now().subtract(const Duration(days: 1)),
          gpsLocation: '-7.2575, 112.7521',
        ),
      ];

      for (final transaction in sampleTransactions) {
        await insertTransaction(transaction);
      }

      print('Sample transactions inserted successfully');
    } catch (e) {
      print('Error inserting sample data: $e');
    }
  }
}
