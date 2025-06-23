
// Model Classes (pastikan ini ada di file yang sama atau import yang sesuai)
enum TransactionStatus { pending, completed, cancelled }

class Transaction {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<TransactionItem> items;
  final int totalAmount;
  final TransactionStatus status;
  final DateTime orderTime;
  final String gpsLocation;

  Transaction({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderTime,
    required this.gpsLocation,
  });

  // Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'total_amount': totalAmount,
      'status': status.toString().split('.').last,
      'order_time': orderTime.toIso8601String(),
      'gps_location': gpsLocation,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class TransactionItem {
  final String productName;
  final int quantity;
  final int price;

  TransactionItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  // Convert to Map for database insertion
  Map<String, dynamic> toMap(String transactionId) {
    return {
      'transaction_id': transactionId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': price * quantity,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
