// ============================================================
// Order models — kitchen & waiter flow
// ============================================================

enum DishStatus { pending, started, cooking, prepared }

extension DishStatusX on DishStatus {
  String get label {
    switch (this) {
      case DishStatus.pending:
        return 'Pending';
      case DishStatus.started:
        return 'Started';
      case DishStatus.cooking:
        return 'Cooking';
      case DishStatus.prepared:
        return 'Prepared';
    }
  }

  DishStatus? get next {
    switch (this) {
      case DishStatus.pending:
        return DishStatus.started;
      case DishStatus.started:
        return DishStatus.cooking;
      case DishStatus.cooking:
        return DishStatus.prepared;
      case DishStatus.prepared:
        return null;
    }
  }
}

enum TableOrderStatus { preparing, ready, completed }

extension TableOrderStatusX on TableOrderStatus {
  String get label {
    switch (this) {
      case TableOrderStatus.preparing:
        return 'Order Preparing';
      case TableOrderStatus.ready:
        return 'Order Ready';
      case TableOrderStatus.completed:
        return 'Order Completed';
    }
  }
}

class OrderDish {
  final String id;
  final String name;
  final int quantity;
  DishStatus status;

  OrderDish({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.status = DishStatus.pending,
  });

  OrderDish copyWith({DishStatus? status}) => OrderDish(
        id: id,
        name: name,
        quantity: quantity,
        status: status ?? this.status,
      );
}

class TableOrder {
  final String id;
  final String tableName;
  final int tableNumber;
  final DateTime orderedAt;
  final List<OrderDish> dishes;
  TableOrderStatus status;

  TableOrder({
    required this.id,
    required this.tableName,
    required this.tableNumber,
    required this.orderedAt,
    required this.dishes,
    this.status = TableOrderStatus.preparing,
  });

  int get itemCount => dishes.fold(0, (sum, d) => sum + d.quantity);

  bool get allDishesPrepared =>
      dishes.every((d) => d.status == DishStatus.prepared);

  TableOrder copyWith({
    List<OrderDish>? dishes,
    TableOrderStatus? status,
  }) =>
      TableOrder(
        id: id,
        tableName: tableName,
        tableNumber: tableNumber,
        orderedAt: orderedAt,
        dishes: dishes ?? this.dishes,
        status: status ?? this.status,
      );
}

/// Seed orders for cook/waiter screens until backend is wired.
List<TableOrder> seedKitchenOrders() {
  final now = DateTime.now();
  return [
    TableOrder(
      id: 'ord-1',
      tableName: 'Table 4',
      tableNumber: 4,
      orderedAt: now.subtract(const Duration(minutes: 12)),
      dishes: [
        OrderDish(id: 'd1', name: 'Noodles', quantity: 2),
        OrderDish(id: 'd2', name: 'Spring Rolls', quantity: 1),
      ],
    ),
    TableOrder(
      id: 'ord-2',
      tableName: 'Table 7',
      tableNumber: 7,
      orderedAt: now.subtract(const Duration(minutes: 5)),
      dishes: [
        OrderDish(id: 'd3', name: 'Butter Chicken', quantity: 1),
        OrderDish(id: 'd4', name: 'Garlic Naan', quantity: 3),
      ],
    ),
    TableOrder(
      id: 'ord-3',
      tableName: 'Bar 2',
      tableNumber: 102,
      orderedAt: now.subtract(const Duration(minutes: 2)),
      dishes: [
        OrderDish(id: 'd5', name: 'Paneer Tikka', quantity: 1),
      ],
    ),
  ];
}
