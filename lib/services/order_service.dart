import 'package:sqflite/sqflite.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'database_service.dart';

// 주문 관리 서비스
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final DatabaseService _dbService = DatabaseService();

  // 주문 생성 (장바구니 아이템들로부터)
  Future<int?> createOrder(List<CartItem> cartItems) async {
    if (cartItems.isEmpty) return null;

    try {
      final db = await _dbService.database;
      int orderId = 0;

      // 트랜잭션으로 주문과 주문 상품을 함께 처리
      await db.transaction((txn) async {
        // 총 금액 계산
        int totalAmount = cartItems.fold(0, (sum, item) => sum + item.subtotal);

        // 주문 테이블에 삽입
        final order = Order(
          totalAmount: totalAmount,
          orderDate: DateTime.now(),
          items: [],
        );

        orderId = await txn.insert('orders', order.toMap());

        // 주문 상품 테이블에 삽입
        for (CartItem cartItem in cartItems) {
          final orderItem = OrderItem(
            orderId: orderId,
            productId: cartItem.product.id!,
            productName: cartItem.product.name,
            unitPrice: cartItem.product.price,
            quantity: cartItem.quantity,
            subtotal: cartItem.subtotal,
          );

          await txn.insert('order_items', orderItem.toMap());
        }
      });

      return orderId;
    } catch (e) {
      print('주문 생성 오류: $e');
      return null;
    }
  }

  // 모든 주문 조회 (최신순)
  Future<List<Order>> getAllOrders() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> orderMaps = await db.query(
        'orders',
        orderBy: 'order_date DESC',
      );

      List<Order> orders = [];
      for (Map<String, dynamic> orderMap in orderMaps) {
        Order order = Order.fromMap(orderMap);

        // 주문 상품 조회
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [order.id],
        );

        List<OrderItem> items = itemMaps.map((itemMap) => OrderItem.fromMap(itemMap)).toList();

        orders.add(Order(
          id: order.id,
          totalAmount: order.totalAmount,
          orderDate: order.orderDate,
          items: items,
        ));
      }

      return orders;
    } catch (e) {
      print('주문 조회 오류: $e');
      return [];
    }
  }

  // 특정 기간의 주문 조회
  Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> orderMaps = await db.query(
        'orders',
        where: 'order_date >= ? AND order_date <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'order_date DESC',
      );

      List<Order> orders = [];
      for (Map<String, dynamic> orderMap in orderMaps) {
        Order order = Order.fromMap(orderMap);

        // 주문 상품 조회
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [order.id],
        );

        List<OrderItem> items = itemMaps.map((itemMap) => OrderItem.fromMap(itemMap)).toList();

        orders.add(Order(
          id: order.id,
          totalAmount: order.totalAmount,
          orderDate: order.orderDate,
          items: items,
        ));
      }

      return orders;
    } catch (e) {
      print('기간별 주문 조회 오류: $e');
      return [];
    }
  }

  // 오늘의 주문 조회
  Future<List<Order>> getTodaysOrders() async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getOrdersByDateRange(startOfDay, endOfDay);
  }

  // 특정 주문 조회
  Future<Order?> getOrderById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> orderMaps = await db.query(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (orderMaps.isEmpty) return null;

      Order order = Order.fromMap(orderMaps.first);

      // 주문 상품 조회
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      List<OrderItem> items = itemMaps.map((itemMap) => OrderItem.fromMap(itemMap)).toList();

      return Order(
        id: order.id,
        totalAmount: order.totalAmount,
        orderDate: order.orderDate,
        items: items,
      );
    } catch (e) {
      print('주문 조회 오류: $e');
      return null;
    }
  }

  // 주문 취소/반품 (전체 주문 취소)
  Future<bool> cancelOrder(int orderId) async {
    try {
      final db = await _dbService.database;

      // 트랜잭션으로 주문과 주문 상품을 함께 삭제
      await db.transaction((txn) async {
        await txn.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
        await txn.delete('orders', where: 'id = ?', whereArgs: [orderId]);
      });

      return true;
    } catch (e) {
      print('주문 취소 오류: $e');
      return false;
    }
  }

  // 특정 상품 반품 (수량 조절)
  Future<bool> returnOrderItem(int orderId, int productId, int returnQuantity) async {
    try {
      final db = await _dbService.database;

      await db.transaction((txn) async {
        // 현재 주문 상품 정보 조회
        final List<Map<String, dynamic>> itemMaps = await txn.query(
          'order_items',
          where: 'order_id = ? AND product_id = ?',
          whereArgs: [orderId, productId],
        );

        if (itemMaps.isEmpty) return;

        OrderItem orderItem = OrderItem.fromMap(itemMaps.first);

        if (returnQuantity >= orderItem.quantity) {
          // 전체 반품 - 주문 상품 삭제
          await txn.delete(
            'order_items',
            where: 'order_id = ? AND product_id = ?',
            whereArgs: [orderId, productId],
          );
        } else {
          // 부분 반품 - 수량과 소계 업데이트
          int newQuantity = orderItem.quantity - returnQuantity;
          int newSubtotal = orderItem.unitPrice * newQuantity;

          await txn.update(
            'order_items',
            {
              'quantity': newQuantity,
              'subtotal': newSubtotal,
            },
            where: 'order_id = ? AND product_id = ?',
            whereArgs: [orderId, productId],
          );
        }

        // 주문 총액 재계산
        final List<Map<String, dynamic>> remainingItems = await txn.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        if (remainingItems.isEmpty) {
          // 모든 상품이 반품된 경우 주문 삭제
          await txn.delete('orders', where: 'id = ?', whereArgs: [orderId]);
        } else {
          // 새로운 총액 계산 및 업데이트
          int newTotalAmount = remainingItems.fold(0, (sum, item) => sum + (item['subtotal'] as int));
          await txn.update(
            'orders',
            {'total_amount': newTotalAmount},
            where: 'id = ?',
            whereArgs: [orderId],
          );
        }
      });

      return true;
    } catch (e) {
      print('상품 반품 오류: $e');
      return false;
    }
  }

  // 일별 매출 통계
  Future<Map<String, int>> getDailySalesStats(DateTime date) async {
    try {
      final db = await _dbService.database;
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // 총 매출액
      final List<Map<String, dynamic>> totalResult = await db.rawQuery(
        'SELECT SUM(total_amount) as total FROM orders WHERE order_date >= ? AND order_date <= ?',
        [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );

      // 총 주문 수
      final List<Map<String, dynamic>> countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE order_date >= ? AND order_date <= ?',
        [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );

      return {
        'totalSales': totalResult.first['total'] ?? 0,
        'totalOrders': countResult.first['count'] ?? 0,
      };
    } catch (e) {
      print('일별 매출 통계 오류: $e');
      return {'totalSales': 0, 'totalOrders': 0};
    }
  }

  // 상품별 판매 통계
  Future<List<Map<String, dynamic>>> getProductSalesStats(DateTime startDate, DateTime endDate) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT 
          oi.product_name,
          SUM(oi.quantity) as total_quantity,
          SUM(oi.subtotal) as total_sales
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        WHERE o.order_date >= ? AND o.order_date <= ?
        GROUP BY oi.product_id, oi.product_name
        ORDER BY total_sales DESC
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      return result;
    } catch (e) {
      print('상품별 판매 통계 오류: $e');
      return [];
    }
  }
}