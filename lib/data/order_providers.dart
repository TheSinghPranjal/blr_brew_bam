import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order_models.dart';

final kitchenOrdersProvider =
    NotifierProvider<KitchenOrdersNotifier, List<TableOrder>>(
  KitchenOrdersNotifier.new,
);

class KitchenOrdersNotifier extends Notifier<List<TableOrder>> {
  @override
  List<TableOrder> build() => seedKitchenOrders();

  void advanceDish(String orderId, String dishId) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          _advanceOrderDish(order, dishId)
        else
          order,
    ];
  }

  TableOrder _advanceOrderDish(TableOrder order, String dishId) {
    final dishes = [
      for (final dish in order.dishes)
        if (dish.id == dishId && dish.status.next != null)
          dish.copyWith(status: dish.status.next!)
        else
          dish,
    ];

    var status = order.status;
    if (dishes.every((d) => d.status == DishStatus.prepared)) {
      status = TableOrderStatus.ready;
    } else if (dishes.any((d) => d.status != DishStatus.pending)) {
      status = TableOrderStatus.preparing;
    }

    return order.copyWith(dishes: dishes, status: status);
  }

  void markOrderCompleted(String orderId) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(status: TableOrderStatus.completed)
        else
          order,
    ];
  }
}

/// Dishes that became prepared since last check — for waiter notifications.
final preparedDishAlertsProvider =
    NotifierProvider<PreparedAlertsNotifier, List<String>>(
  PreparedAlertsNotifier.new,
);

class PreparedAlertsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void notifyPrepared(String message) {
    state = [message, ...state].take(20).toList();
  }

  void dismiss(int index) {
    state = [...state]..removeAt(index);
  }
}
