import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'database_service.dart';

// 상품 관리 서비스
class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final DatabaseService _dbService = DatabaseService();

  // 모든 활성 상품 조회 (순서대로 정렬)
  Future<List<Product>> getAllActiveProducts() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'product_order ASC, name ASC', // 순서로 정렬 후 이름순
      );

      return List.generate(maps.length, (i) {
        return Product.fromMap(maps[i]);
      });
    } catch (e) {
      print('활성 상품 조회 오류: $e');
      return [];
    }
  }

  // 특정 카테고리의 활성 상품 조회
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'category_id = ? AND is_active = ?',
        whereArgs: [categoryId, 1],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return Product.fromMap(maps[i]);
      });
    } catch (e) {
      print('카테고리별 상품 조회 오류: $e');
      return [];
    }
  }

  // 모든 상품 조회 (관리용 - 비활성 상품 포함)
  Future<List<Product>> getAllProducts() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        orderBy: 'product_order ASC, name ASC', // 순서로 정렬
      );

      return List.generate(maps.length, (i) {
        return Product.fromMap(maps[i]);
      });
    } catch (e) {
      print('전체 상품 조회 오류: $e');
      return [];
    }
  }

  // 특정 상품 조회
  Future<Product?> getProductById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('상품 조회 오류: $e');
      return null;
    }
  }

  // 상품 추가
  Future<int?> addProduct(String name, int price, int categoryId) async {
    try {
      final db = await _dbService.database;
      final DateTime now = DateTime.now();

      // 다음 순서 번호 계산
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT MAX(product_order) as max_order FROM products WHERE category_id = ?',
        [categoryId],
      );
      int nextOrder = (result.first['max_order'] ?? 0) + 1;

      final product = Product(
        name: name,
        price: price,
        categoryId: categoryId,
        order: nextOrder,
        createdAt: now,
        updatedAt: now,
      );

      int id = await db.insert('products', product.toMap());
      return id;
    } catch (e) {
      print('상품 추가 오류: $e');
      return null;
    }
  }

  // 상품 수정
  Future<bool> updateProduct(int id, String name, int price, int categoryId) async {
    try {
      final db = await _dbService.database;
      final DateTime now = DateTime.now();

      int result = await db.update(
        'products',
        {
          'name': name,
          'price': price,
          'category_id': categoryId,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      print('상품 수정 오류: $e');
      return false;
    }
  }

  // 상품 활성화/비활성화
  Future<bool> toggleProductStatus(int id) async {
    try {
      final db = await _dbService.database;
      final DateTime now = DateTime.now();

      // 현재 상태 확인
      final product = await getProductById(id);
      if (product == null) return false;

      int newStatus = product.isActive ? 0 : 1;

      int result = await db.update(
        'products',
        {
          'is_active': newStatus,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      print('상품 상태 변경 오류: $e');
      return false;
    }
  }

  // 상품 삭제 (실제 삭제가 아닌 비활성화)
  Future<bool> deleteProduct(int id) async {
    try {
      final db = await _dbService.database;
      final DateTime now = DateTime.now();

      int result = await db.update(
        'products',
        {
          'is_active': 0,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      print('상품 삭제 오류: $e');
      return false;
    }
  }

  // 상품 완전 삭제 (주의: 주문 내역이 있으면 삭제 불가)
  Future<bool> permanentDeleteProduct(int id) async {
    try {
      final db = await _dbService.database;

      // 해당 상품의 주문 내역이 있는지 확인
      final List<Map<String, dynamic>> orderItems = await db.query(
        'order_items',
        where: 'product_id = ?',
        whereArgs: [id],
      );

      if (orderItems.isNotEmpty) {
        print('해당 상품의 주문 내역이 있어 완전 삭제할 수 없습니다.');
        return false;
      }

      int result = await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      print('상품 완전 삭제 오류: $e');
      return false;
    }
  }

  // 상품명으로 검색
  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'name LIKE ? AND is_active = ?',
        whereArgs: ['%$keyword%', 1],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return Product.fromMap(maps[i]);
      });
    } catch (e) {
      print('상품 검색 오류: $e');
      return [];
    }
  }

  // 카테고리별 상품 개수 조회
  Future<int> getProductCountByCategory(int categoryId) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE category_id = ? AND is_active = ?',
        [categoryId, 1],
      );

      return result.first['count'] as int;
    } catch (e) {
      print('카테고리별 상품 개수 조회 오류: $e');
      return 0;
    }
  }

  // 상품 순서 변경
  Future<bool> updateProductOrder(int productId, int newOrder) async {
    try {
      final db = await _dbService.database;
      final DateTime now = DateTime.now();

      // 현재 상품 정보 조회
      final currentProduct = await getProductById(productId);
      if (currentProduct == null) return false;

      int currentOrder = currentProduct.order;
      int categoryId = currentProduct.categoryId;

      if (currentOrder == newOrder) return true; // 변경할 필요 없음

      // 트랜잭션으로 순서 재정렬
      await db.transaction((txn) async {
        if (currentOrder < newOrder) {
          // 아래로 이동: 현재 위치와 새 위치 사이의 상품들을 위로 한 칸씩
          await txn.rawUpdate(
            'UPDATE products SET product_order = product_order - 1, updated_at = ? '
                'WHERE category_id = ? AND product_order > ? AND product_order <= ?',
            [now.toIso8601String(), categoryId, currentOrder, newOrder],
          );
        } else {
          // 위로 이동: 새 위치와 현재 위치 사이의 상품들을 아래로 한 칸씩
          await txn.rawUpdate(
            'UPDATE products SET product_order = product_order + 1, updated_at = ? '
                'WHERE category_id = ? AND product_order >= ? AND product_order < ?',
            [now.toIso8601String(), categoryId, newOrder, currentOrder],
          );
        }

        // 현재 상품을 새 위치로 이동
        await txn.update(
          'products',
          {
            'product_order': newOrder,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
      });

      return true;
    } catch (e) {
      print('상품 순서 변경 오류: $e');
      return false;
    }
  }
}