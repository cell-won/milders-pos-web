import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';

// 데이터베이스 서비스 (웹 확장 시 이 부분만 교체하면 됨)
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'milders_pos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: _onOpen,
    );
  }

  // 데이터베이스 테이블 생성
  Future<void> _onCreate(Database db, int version) async {
    // 카테고리 테이블
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        order_num INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 상품 테이블
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        product_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // 주문 테이블
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount INTEGER NOT NULL,
        order_date TEXT NOT NULL
      )
    ''');

    // 주문 상품 테이블
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');

    // 초기 데이터 삽입
    await _insertInitialData(db);
  }

  // 데이터베이스 열릴 때 실행
  Future<void> _onOpen(Database db) async {
    // 외래키 제약 조건 활성화
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // 초기 데이터 삽입
  Future<void> _insertInitialData(Database db) async {
    DateTime now = DateTime.now();

    // 기본 카테고리 "팝업" 추가
    int categoryId = await db.insert('categories', {
      'name': '팝업',
      'order_num': 1,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    // 초기 상품 5개 추가
    List<Map<String, dynamic>> initialProducts = [
      {
        'name': '반팔 티셔츠',
        'price': 28000,
        'category_id': categoryId,
        'product_order': 1,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'name': '맨투맨 티셔츠',
        'price': 39000,
        'category_id': categoryId,
        'product_order': 2,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'name': '밀크티 250ml',
        'price': 3900,
        'category_id': categoryId,
        'product_order': 3,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'name': '안경닦이',
        'price': 3000,
        'category_id': categoryId,
        'product_order': 4,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'name': '스티커',
        'price': 2000,
        'category_id': categoryId,
        'product_order': 5,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
    ];

    for (Map<String, dynamic> product in initialProducts) {
      await db.insert('products', product);
    }
  }

  // 데이터베이스 연결 종료
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // 데이터베이스 재설정 (개발/테스트용)
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'milders_pos.db');
    await deleteDatabase(path);
    _database = null;
  }
}