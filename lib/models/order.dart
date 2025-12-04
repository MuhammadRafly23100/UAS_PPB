class OrderItemModel {
  final int productId;
  final String name;
  final double price;
  final int qty;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
  });

  Map<String, dynamic> toMap(int orderId) => {
        'order_id': orderId,
        'product_id': productId,
        'name': name,
        'price': price,
        'qty': qty,
      };

  factory OrderItemModel.fromMap(Map<String, dynamic> m) => OrderItemModel(
        productId: (m['product_id'] as num).toInt(),
        name: m['name'].toString(),
        price: (m['price'] as num).toDouble(),
        qty: (m['qty'] as num).toInt(),
      );
}

class OrderModel {
  final int id; // autoincrement
  final String userId;
  final DateTime createdAt;
  final double total;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toMapNoItems() => {
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
        'total': total,
      };

  factory OrderModel.fromMap(Map<String, dynamic> m, List<OrderItemModel> items) =>
      OrderModel(
        id: (m['id'] as num).toInt(),
        userId: m['user_id'].toString(),
        createdAt: DateTime.parse(m['created_at'].toString()),
        total: (m['total'] as num).toDouble(),
        items: items,
      );
}
