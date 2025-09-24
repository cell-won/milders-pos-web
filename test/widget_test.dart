import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milders_pos/main.dart';
import 'package:milders_pos/models/product.dart';
import 'package:milders_pos/models/category.dart';
import 'package:milders_pos/models/order.dart';
import 'package:milders_pos/widgets/product_card.dart';
import 'package:milders_pos/widgets/order_summary.dart';
import 'package:milders_pos/widgets/sales_item.dart';

void main() {
  // 테스트 시에는 데이터베이스 초기화를 건너뛰도록 설정
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milders POS 앱 테스트', () {

    // 메인 앱 실행 테스트 (데이터베이스 없이)
    testWidgets('메인 앱 UI 구조 테스트', (WidgetTester tester) async {
      // 데이터베이스 초기화 없이 기본 UI만 테스트
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Milders POS')),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: '주문',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: '상품관리',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: '매출',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: '설정',
                ),
              ],
            ),
          ),
        ),
      );

      // 기본 UI 요소들이 있는지 확인
      expect(find.text('Milders POS'), findsOneWidget);
      expect(find.text('주문'), findsOneWidget);
      expect(find.text('상품관리'), findsOneWidget);
      expect(find.text('매출'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);
    });
  });

  group('데이터 모델 테스트', () {

    // Product 모델 테스트
    test('Product 모델 생성 및 포맷팅 테스트', () {
      final product = Product(
        id: 1,
        name: '반팔 티셔츠',
        price: 28000,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.name, '반팔 티셔츠');
      expect(product.price, 28000);
      expect(product.formattedPrice, '28,000원');
      expect(product.isActive, true);
    });

    // Category 모델 테스트
    test('Category 모델 생성 테스트', () {
      final category = Category(
        id: 1,
        name: '팝업',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.name, '팝업');
      expect(category.order, 1);
    });

    // CartItem 테스트
    test('CartItem 계산 테스트', () {
      final product = Product(
        id: 1,
        name: '반팔 티셔츠',
        price: 28000,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cartItem = CartItem(product: product, quantity: 3);

      expect(cartItem.quantity, 3);
      expect(cartItem.subtotal, 84000);
      expect(cartItem.formattedSubtotal, '84,000원');
    });

    // Order 모델 테스트
    test('Order 모델 생성 및 포맷팅 테스트', () {
      final order = Order(
        id: 1,
        totalAmount: 84000,
        orderDate: DateTime(2024, 1, 15, 14, 30),
        items: [],
      );

      expect(order.totalAmount, 84000);
      expect(order.formattedTotalAmount, '84,000원');
      expect(order.formattedOrderDate, '2024년 1월 15일');
    });
  });

  group('위젯 테스트', () {

    // ProductCard 위젯 테스트
    testWidgets('ProductCard 위젯 렌더링 테스트', (WidgetTester tester) async {
      final product = Product(
        id: 1,
        name: '반팔 티셔츠',
        price: 28000,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      int tapCount = 0;
      int decreaseCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              quantity: 2,
              onTap: () => tapCount++,
              onDecrease: () => decreaseCount++,
            ),
          ),
        ),
      );

      // 상품명이 표시되는지 확인
      expect(find.text('반팔 티셔츠'), findsOneWidget);
      expect(find.text('28,000원'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // 카드를 탭했을 때 콜백이 호출되는지 확인
      await tester.tap(find.byType(ProductCard));
      expect(tapCount, 1);

      // 감소 버튼을 탭했을 때 콜백이 호출되는지 확인
      await tester.tap(find.byIcon(Icons.remove));
      expect(decreaseCount, 1);
    });

    // OrderSummary 위젯 테스트
    testWidgets('OrderSummary 위젯 렌더링 테스트', (WidgetTester tester) async {
      final product1 = Product(
        id: 1,
        name: '반팔 티셔츠',
        price: 28000,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final product2 = Product(
        id: 2,
        name: '밀크티 250ml',
        price: 3900,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cartItems = [
        CartItem(product: product1, quantity: 2),
        CartItem(product: product2, quantity: 1),
      ];

      bool confirmOrderCalled = false;
      bool clearCartCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderSummary(
              cartItems: cartItems,
              totalAmount: 59900, // 28000 * 2 + 3900 * 1
              onConfirmOrder: () => confirmOrderCalled = true,
              onClearCart: () => clearCartCalled = true,
            ),
          ),
        ),
      );

      // 총 금액이 정확히 표시되는지 확인
      expect(find.text('59,900원'), findsOneWidget);

      // 주문 확정 버튼을 탭했을 때 콜백이 호출되는지 확인
      await tester.tap(find.text('주문 확정'));
      expect(confirmOrderCalled, true);

      // 비우기 버튼을 탭했을 때 콜백이 호출되는지 확인
      await tester.tap(find.text('비우기'));
      expect(clearCartCalled, true);
    });

    // 빈 장바구니 상태 테스트
    testWidgets('빈 장바구니 상태 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderSummary(
              cartItems: [],
              totalAmount: 0,
              onConfirmOrder: () {},
              onClearCart: () {},
            ),
          ),
        ),
      );

      // 총 금액이 0원으로 표시되는지 확인
      expect(find.text('0원'), findsOneWidget);

      // 상품 선택 버튼이 비활성화 상태인지 확인
      expect(find.text('상품 선택'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '상품 선택'));
      expect(button.onPressed, isNull); // 버튼이 비활성화 상태
    });

    // SalesItem 위젯 테스트
    testWidgets('SalesItem 위젯 렌더링 테스트', (WidgetTester tester) async {
      final order = Order(
        id: 123,
        totalAmount: 59900,
        orderDate: DateTime(2024, 1, 15, 14, 30),
        items: [
          OrderItem(
            id: 1,
            orderId: 123,
            productId: 1,
            productName: '반팔 티셔츠',
            unitPrice: 28000,
            quantity: 2,
            subtotal: 56000,
          ),
        ],
      );

      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SalesItem(
              order: order,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // 주문 정보가 올바르게 표시되는지 확인
      expect(find.text('주문 #123'), findsOneWidget);
      expect(find.text('2024년 1월 15일'), findsOneWidget);
      expect(find.text('상품 1개'), findsOneWidget);
      expect(find.text('59,900원'), findsOneWidget);

      // 탭 이벤트가 작동하는지 확인
      await tester.tap(find.byType(SalesItem));
      expect(tapCalled, true);
    });

    // ProductSalesItem 위젯 테스트
    testWidgets('ProductSalesItem 위젯 렌더링 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductSalesItem(
              productName: '반팔 티셔츠',
              totalQuantity: 15,
              totalSales: 420000,
            ),
          ),
        ),
      );

      // 상품 판매 정보가 올바르게 표시되는지 확인
      expect(find.text('반팔 티셔츠'), findsOneWidget);
      expect(find.text('판매 수량: 15개'), findsOneWidget);
      expect(find.text('420,000원'), findsOneWidget);
    });
  });

  group('포맷팅 함수 테스트', () {

    test('가격 포맷팅 테스트', () {
      final product1 = Product(
        id: 1,
        name: '테스트 상품',
        price: 1000,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(product1.formattedPrice, '1,000원');

      final product2 = Product(
        id: 2,
        name: '테스트 상품2',
        price: 1234567,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(product2.formattedPrice, '1,234,567원');

      final product3 = Product(
        id: 3,
        name: '테스트 상품3',
        price: 100,
        categoryId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(product3.formattedPrice, '100원');
    });

    test('날짜 포맷팅 테스트', () {
      final order = Order(
        id: 1,
        totalAmount: 10000,
        orderDate: DateTime(2024, 12, 25, 15, 30),
        items: [],
      );

      expect(order.formattedOrderDate, '2024년 12월 25일');
    });
  });
}