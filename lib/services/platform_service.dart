import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'web_storage_service.dart';
import 'category_service.dart';
import 'product_service.dart';
import 'order_service.dart';
import '../models/category.dart' as CategoryModel;
import '../models/product.dart';
import '../models/order.dart';

// 플랫폼별 데이터베이스 서비스 통합 관리
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  late final dynamic _service;
  bool _initialized = false;

  // 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _service = WebStorageService();
      await _service.initialize();
    } else {
      _service = DatabaseService();
      await _service.database; // SQLite 초기화
    }

    _initialized = true;
  }

  // === 카테고리 관리 ===
  Future<List<CategoryModel.Category>> getAllCategories() async {
    await initialize();

    if (kIsWeb) {
      return await _service.getAllCategories();
    } else {
      final categoryService = CategoryService();
      return await categoryService.getAllCategories();
    }
  }

  Future<CategoryModel.Category?> getCategoryById(int id) async {
    await initialize();

    if (kIsWeb) {
      return await _service.getCategoryById(id);
    } else {
      final categoryService = CategoryService();
      return await categoryService.getCategoryById(id);
    }
  }

  Future<int> addCategory(String name) async {
    await initialize();

    if (kIsWeb) {
      return await _service.addCategory(name);
    } else {
      final categoryService = CategoryService();
      return await categoryService.addCategory(name) ?? 0;
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    await initialize();

    if (kIsWeb) {
      return await _service.updateCategory(id, name);
    } else {
      final categoryService = CategoryService();
      return await categoryService.updateCategory(id, name);
    }
  }

  Future<bool> deleteCategory(int id) async {
    await initialize();

    if (kIsWeb) {
      return await _service.deleteCategory(id);
    } else {
      final categoryService = CategoryService();
      return await categoryService.deleteCategory(id);
    }
  }

  Future<bool> updateCategoryOrder(int categoryId, int newOrder) async {
    await initialize();

    if (kIsWeb) {
      return await _service.updateCategoryOrder(categoryId, newOrder);
    } else {
      final categoryService = CategoryService();
      return await categoryService.updateCategoryOrder(categoryId, newOrder);
    }
  }

  // === 상품 관리 ===
  Future<List<Product>> getAllProducts() async {
    await initialize();

    if (kIsWeb) {
      return await _service.getAllProducts();
    } else {
      final productService = ProductService();
      return await productService.getAllProducts();
    }
  }

  Future<List<Product>> getAllActiveProducts() async {
    await initialize();

    if (kIsWeb) {
      return await _service.getAllActiveProducts();
    } else {
      final productService = ProductService();
      return await productService.getAllActiveProducts();
    }
  }

  Future<Product?> getProductById(int id) async {
    await initialize();

    if (kIsWeb) {
      return await _service.getProductById(id);
    } else {
      final productService = ProductService();
      return await productService.getProductById(id);
    }
  }

  Future<int> addProduct(String name, int price, int categoryId) async {
    await initialize();

    if (kIsWeb) {
      return await _service.addProduct(name, price, categoryId);
    } else {
      final productService = ProductService();
      return await productService.addProduct(name, price, categoryId) ?? 0;
    }
  }

  Future<bool> updateProduct(int id, String name, int price, int categoryId) async {
    await initialize();

    if (kIsWeb) {
      return await _service.updateProduct(id, name, price, categoryId);
    } else {
      final productService = ProductService();
      return await productService.updateProduct(id, name, price, categoryId);
    }
  }

  Future<bool> toggleProductStatus(int id) async {
    await initialize();

    if (kIsWeb) {
      return await _service.toggleProductStatus(id);
    } else {
      final productService = ProductService();
      return await productService.toggleProductStatus(id);
    }
  }

  Future<bool> deleteProduct(int id) async {
    await initialize();

    if (kIsWeb) {
      return await _service.deleteProduct(id);
    } else {
      final productService = ProductService();
      return await productService.deleteProduct(id);
    }
  }

  Future<bool> updateProductOrder(int productId, int newOrder) async {
    await initialize();

    if (kIsWeb) {
      return await _service.updateProductOrder(productId, newOrder);
    } else {
      final productService = ProductService();
      return await productService.updateProductOrder(productId, newOrder);
    }
  }

  // === 주문 관리 ===
  Future<List<Order>> getAllOrders() async {
    await initialize();

    if (kIsWeb) {
      return await _service.getAllOrders();
    } else {
      final orderService = OrderService();
      return await orderService.getAllOrders();
    }
  }

  Future<int?> createOrder(List<CartItem> cartItems) async {
    await initialize();

    if (kIsWeb) {
      return await _service.createOrder(cartItems);
    } else {
      final orderService = OrderService();
      return await orderService.createOrder(cartItems);
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    await initialize();

    if (kIsWeb) {
      return await _service.cancelOrder(orderId);
    } else {
      final orderService = OrderService();
      return await orderService.cancelOrder(orderId);
    }
  }

  Future<Map<String, int>> getDailySalesStats(DateTime date) async {
    await initialize();

    if (kIsWeb) {
      return await _service.getDailySalesStats(date);
    } else {
      final orderService = OrderService();
      return await orderService.getDailySalesStats(date);
    }
  }

  Future<List<Map<String, dynamic>>> getProductSalesStats(DateTime startDate, DateTime endDate) async {
    await initialize();

    if (kIsWeb) {
      return await _service.getProductSalesStats(startDate, endDate);
    } else {
      final orderService = OrderService();
      return await orderService.getProductSalesStats(startDate, endDate);
    }
  }

  // 데이터 초기화
  Future<void> resetDatabase() async {
    await initialize();

    if (kIsWeb) {
      await _service.resetDatabase();
    } else {
      await _service.resetDatabase();
    }
  }
}