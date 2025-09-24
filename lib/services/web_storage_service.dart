import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';

// 웹용 간단한 저장소 서비스
class WebStorageService {
  static final WebStorageService _instance = WebStorageService._internal();
  factory WebStorageService() => _instance;
  WebStorageService._internal();

  SharedPreferences? _prefs;

  // 초기화
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _initializeData();
  }

  // 초기 데이터 설정
  Future<void> _initializeData() async {
    final categories = await getAllCategories();
    if (categories.isEmpty) {
      await _insertInitialData();
    }
  }

  // 초기 데이터 삽입
  Future<void> _insertInitialData() async {
    final now = DateTime.now();

    // 기본 카테고리 추가
    final category = Category(
      id: 1,
      name: '팝업',
      order: 1,
      createdAt: now,
      updatedAt: now,
    );
    await _saveCategory(category);

    // 초기 상품들 추가
    final products = [
      Product(id: 1, name: '반팔 티셔츠', price: 28000, categoryId: 1, order: 1, createdAt: now, updatedAt: now),
      Product(id: 2, name: '맨투맨 티셔츠', price: 39000, categoryId: 1, order: 2, createdAt: now, updatedAt: now),
      Product(id: 3, name: '밀크티 250ml', price: 3900, categoryId: 1, order: 3, createdAt: now, updatedAt: now),
      Product(id: 4, name: '안경닦이', price: 3000, categoryId: 1, order: 4, createdAt: now, updatedAt: now),
      Product(id: 5, name: '스티커', price: 2000, categoryId: 1, order: 5, createdAt: now, updatedAt: now),
    ];

    for (int i = 0; i < products.length; i++) {
      await _saveProduct(products[i]);
    }

    // 카운터 초기화
    await _setCounter('categories', 1);
    await _setCounter('products', 5);
    await _setCounter('orders', 0);
  }

  // 카운터 관리
  Future<int> _getNextId(String type) async {
    final currentId = _prefs!.getInt('counter_$type') ?? 0;
    await _prefs!.setInt('counter_$type', currentId + 1);
    return currentId + 1;
  }

  Future<void> _setCounter(String type, int value) async {
    await _prefs!.setInt('counter_$type', value);
  }

  // === 카테고리 관리 ===
  Future<List<Category>> getAllCategories() async {
    final jsonString = _prefs!.getString('categories') ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => Category.fromMap(item)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<Category?> getCategoryById(int id) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> _saveCategory(Category category) async {
    final categories = await getAllCategories();
    final existingIndex = categories.indexWhere((c) => c.id == category.id);

    if (existingIndex >= 0) {
      categories[existingIndex] = category;
    } else {
      categories.add(category);
    }

    final jsonString = json.encode(categories.map((c) => c.toMap()).toList());
    await _prefs!.setString('categories', jsonString);
    return category.id ?? 0;
  }

  Future<int> addCategory(String name) async {
    final id = await _getNextId('categories');
    final now = DateTime.now();
    final categories = await getAllCategories();
    final nextOrder = categories.length + 1;

    final category = Category(
      id: id,
      name: name,
      order: nextOrder,
      createdAt: now,
      updatedAt: now,
    );

    return await _saveCategory(category);
  }

  // === 상품 관리 ===
  Future<List<Product>> getAllProducts() async {
    final jsonString = _prefs!.getString('products') ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => Product.fromMap(item)).toList();
  }

  Future<List<Product>> getAllActiveProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<Product?> getProductById(int id) async {
    final products = await getAllProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> _saveProduct(Product product) async {
    final products = await getAllProducts();
    final existingIndex = products.indexWhere((p) => p.id == product.id);

    if (existingIndex >= 0) {
      products[existingIndex] = product;
    } else {
      products.add(product);
    }

    final jsonString = json.encode(products.map((p) => p.toMap()).toList());
    await _prefs!.setString('products', jsonString);
    return product.id ?? 0;
  }

  Future<int> addProduct(String name, int price, int categoryId) async {
    final id = await _getNextId('products');
    final now = DateTime.now();
    final products = await getAllProducts();
    final nextOrder = products.where((p) => p.categoryId == categoryId).length + 1;

    final product = Product(
      id: id,
      name: name,
      price: price,
      categoryId: categoryId,
      order: nextOrder,
      createdAt: now,
      updatedAt: now,
    );

    return await _saveProduct(product);
  }

  // === 주문 관리 ===
  Future<List<Order>> getAllOrders() async {
    final ordersJson = _prefs!.getString('orders') ?? '[]';
    final itemsJson = _prefs!.getString('order_items') ?? '[]';

    final List<dynamic> ordersList = json.decode(ordersJson);
    final List<dynamic> itemsList = json.decode(itemsJson);

    final orders = ordersList.map((item) => Order.fromMap(item)).toList();
    final orderItems = itemsList.map((item) => OrderItem.fromMap(item)).toList();

    // 주문에 아이템들 연결
    for (var order in orders) {
      final items = orderItems.where((item) => item.orderId == order.id).toList();
      order.items.clear();
      order.items.addAll(items);
    }

    return orders..sort((a, b) => b.orderDate.compareTo(a.orderDate));
  }

  Future<int?> createOrder(List<CartItem> cartItems) async {
    if (cartItems.isEmpty) return null;

    final orderId = await _getNextId('orders');
    final now = DateTime.now();
    final totalAmount = cartItems.fold(0, (sum, item) => sum + item.subtotal);

    // 주문 생성
    final order = Order(
      id: orderId,
      totalAmount: totalAmount,
      orderDate: now,
      items: [],
    );

    final orders = await getAllOrders();
    orders.add(order);
    final ordersJson = json.encode(orders.map((o) => o.toMap()).toList());
    await _prefs!.setString('orders', ordersJson);

    // 주문 아이템들 생성
    final itemsJson = _prefs!.getString('order_items') ?? '[]';
    final List<dynamic> itemsList = json.decode(itemsJson);
    final orderItems = itemsList.map((item) => OrderItem.fromMap(item)).toList();

    for (var cartItem in cartItems) {
      final orderItem = OrderItem(
        id: orderItems.length + 1,
        orderId: orderId,
        productId: cartItem.product.id!,
        productName: cartItem.product.name,
        unitPrice: cartItem.product.price,
        quantity: cartItem.quantity,
        subtotal: cartItem.subtotal,
      );
      orderItems.add(orderItem);
    }

    final newItemsJson = json.encode(orderItems.map((oi) => oi.toMap()).toList());
    await _prefs!.setString('order_items', newItemsJson);

    return orderId;
  }

  // 데이터 초기화
  Future<void> resetDatabase() async {
    await _prefs!.clear();
    await _initializeData();
  }
}