// 상품 데이터 모델
class Product {
  final int? id;
  final String name;
  final int price; // 원 단위로 저장 (소수점 피하기 위해)
  final int categoryId;
  final int order; // 상품 순서 필드 추가
  final bool isActive; // 상품 활성화 상태
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.order = 0, // 기본값 0
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // 데이터베이스에서 가져올 때 사용
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      categoryId: map['category_id'],
      order: map['product_order'] ?? 0, // 기본값 0
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 데이터베이스에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_id': categoryId,
      'product_order': order, // order는 예약어라 product_order로 저장
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 가격을 천원 단위로 포맷팅 (예: 28000 → "28,000원")
  String get formattedPrice {
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  // 상품 복사 (수정 시 사용)
  Product copyWith({
    int? id,
    String? name,
    int? price,
    int? categoryId,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}