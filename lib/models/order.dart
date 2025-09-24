import 'product.dart';

// 주문 데이터 모델
class Order {
  final int? id;
  final int totalAmount; // 총 금액
  final DateTime orderDate;
  final List<OrderItem> items; // 주문 상품 목록

  Order({
    this.id,
    required this.totalAmount,
    required this.orderDate,
    required this.items,
  });

  // 데이터베이스에서 가져올 때 사용 (items는 별도 조회)
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      totalAmount: map['total_amount'],
      orderDate: DateTime.parse(map['order_date']),
      items: [], // 별도로 조회해서 채움
    );
  }

  // 데이터베이스에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'order_date': orderDate.toIso8601String(),
    };
  }

  // 총 금액을 천원 단위로 포맷팅
  String get formattedTotalAmount {
    return '${totalAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  // 주문 날짜를 한국식으로 포맷팅
  String get formattedOrderDate {
    return '${orderDate.year}년 ${orderDate.month}월 ${orderDate.day}일';
  }

  @override
  String toString() {
    return 'Order(id: $id, totalAmount: $totalAmount, orderDate: $orderDate, itemCount: ${items.length})';
  }
}

// 주문 상품 데이터 모델
class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final String productName; // 주문 당시 상품명 (상품 정보 변경에 영향 받지 않음)
  final int unitPrice; // 주문 당시 단가
  final int quantity; // 수량
  final int subtotal; // 소계 (unitPrice * quantity)

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  // 데이터베이스에서 가져올 때 사용
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      unitPrice: map['unit_price'],
      quantity: map['quantity'],
      subtotal: map['subtotal'],
    );
  }

  // 데이터베이스에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  // 단가를 천원 단위로 포맷팅
  String get formattedUnitPrice {
    return '${unitPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  // 소계를 천원 단위로 포맷팅
  String get formattedSubtotal {
    return '${subtotal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  @override
  String toString() {
    return 'OrderItem(productName: $productName, quantity: $quantity, subtotal: $subtotal)';
  }
}

// 장바구니 아이템 (주문 전 임시 저장용)
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // 소계 계산
  int get subtotal => product.price * quantity;

  // 소계를 포맷팅
  String get formattedSubtotal {
    return '${subtotal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  @override
  String toString() {
    return 'CartItem(product: ${product.name}, quantity: $quantity, subtotal: $subtotal)';
  }
}