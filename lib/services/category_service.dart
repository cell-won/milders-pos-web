import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import 'database_service.dart';

// 카테고리 관리 서비스
class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final DatabaseService _dbService = DatabaseService();

  // 모든 카테고리 조회 (순서대로 정렬)
  Future<List<Category>> getAllCategories() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'order_num ASC',
      );

      return List.generate(maps.length, (i) {
        return Category.fromMap(maps[i]);
      });
    } catch (e) {
      print('카테고리 조회 오류: $e');
      return [];
    }
  }

  // 특정 카테고리 조회
  Future<Category?> getCategoryById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Category.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('카테고리 조회 오류: $e');
      return null;
    }
  }

  // 카테고리 추가
  Future<int?> addCategory(String name) async {
    try {
      final db = await _dbService.database;

      // 다음 순서 번호 계산
      final List<Map<String, dynamic>> result = await db.rawQuery(
          'SELECT MAX(order_num) as max_order FROM categories'
      );
      int nextOrder = (result.first['max_order'] ?? 0) + 1;

      final DateTime now = DateTime.now();
      final category = Category(
        name: name,
        order: nextOrder,
        createdAt: now,
        updatedAt: now,
      );

      int id = await db.insert('categories', category.toMap());
      return id;
    } catch (e) {
      print('카테고리 추가 오류: $e');
      return null;
    }
  }

  // 카테고리 수정
  Future<bool> updateCategory(int id, String name) async {
    try {
      final db = await _dbService.database;
      final DateTime now = DateTime.now();

      int result = await db.update(
        'categories',
        {
          'name': name,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      print('카테고리 수정 오류: $e');
      return false;
    }
  }

  // 카테고리 삭제 (해당 카테고리의 상품이 있으면 삭제 불가)
  Future<bool> deleteCategory(int id) async {
    try {
      final db = await _dbService.database;

      // 해당 카테고리에 속한 상품이 있는지 확인
      final List<Map<String, dynamic>> products = await db.query(
        'products',
        where: 'category_id = ?',
        whereArgs: [id],
      );

      if (products.isNotEmpty) {
        print('해당 카테고리에 속한 상품이 있어 삭제할 수 없습니다.');
        return false;
      }

      int result = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      print('카테고리 삭제 오류: $e');
      return false;
    }
  }

  // 카테고리 순서 변경
  Future<bool> updateCategoryOrder(int categoryId, int newOrder) async {
    try {
      final db = await _dbService.database;
      final DateTime now = DateTime.now();

      // 현재 카테고리의 순서 조회
      final currentCategory = await getCategoryById(categoryId);
      if (currentCategory == null) return false;

      int currentOrder = currentCategory.order;
      if (currentOrder == newOrder) return true; // 변경할 필요 없음

      // 트랜잭션으로 순서 재정렬
      await db.transaction((txn) async {
        if (currentOrder < newOrder) {
          // 아래로 이동: 현재 위치와 새 위치 사이의 카테고리들을 위로 한 칸씩
          await txn.rawUpdate(
            'UPDATE categories SET order_num = order_num - 1, updated_at = ? '
                'WHERE order_num > ? AND order_num <= ?',
            [now.toIso8601String(), currentOrder, newOrder],
          );
        } else {
          // 위로 이동: 새 위치와 현재 위치 사이의 카테고리들을 아래로 한 칸씩
          await txn.rawUpdate(
            'UPDATE categories SET order_num = order_num + 1, updated_at = ? '
                'WHERE order_num >= ? AND order_num < ?',
            [now.toIso8601String(), newOrder, currentOrder],
          );
        }

        // 현재 카테고리를 새 위치로 이동
        await txn.update(
          'categories',
          {
            'order_num': newOrder,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [categoryId],
        );
      });

      return true;
    } catch (e) {
      print('카테고리 순서 변경 오류: $e');
      return false;
    }
  }

  // 카테고리 순서 위로 이동
  Future<bool> moveCategoryUp(int categoryId) async {
    try {
      final category = await getCategoryById(categoryId);
      if (category == null || category.order <= 1) return false;

      return await updateCategoryOrder(categoryId, category.order - 1);
    } catch (e) {
      print('카테고리 위로 이동 오류: $e');
      return false;
    }
  }

  // 카테고리 순서 아래로 이동
  Future<bool> moveCategoryDown(int categoryId) async {
    try {
      final categories = await getAllCategories();
      final category = categories.firstWhere((c) => c.id == categoryId);

      if (category.order >= categories.length) return false;

      return await updateCategoryOrder(categoryId, category.order + 1);
    } catch (e) {
      print('카테고리 아래로 이동 오류: $e');
      return false;
    }
  }
}