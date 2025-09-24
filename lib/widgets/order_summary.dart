import 'package:flutter/material.dart';
import '../models/order.dart';

// 주문 요약 위젯 (화면 하단 고정)
class OrderSummary extends StatelessWidget {
  final List<CartItem> cartItems;
  final int totalAmount;
  final VoidCallback onConfirmOrder;
  final VoidCallback onClearCart;
  final Function(CartItem)? onIncreaseQuantity; // 수량 증가 콜백 추가
  final Function(CartItem)? onDecreaseQuantity; // 수량 감소 콜백 추가

  const OrderSummary({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.onConfirmOrder,
    required this.onClearCart,
    this.onIncreaseQuantity, // 선택적 매개변수
    this.onDecreaseQuantity, // 선택적 매개변수
  }) : super(key: key);

  // 총 금액을 포맷팅
  String get _formattedTotalAmount {
    return '${totalAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  // 총 상품 개수 계산
  int get _totalItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기로 가로/세로 판단 (더 정확한 방법)
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height && screenSize.width > 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: isLandscape ? _buildLandscapeLayout(context) : _buildPortraitLayout(context),
    );
  }

  // 세로 화면 레이아웃 (기존 방식)
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 장바구니 상품 목록 (확장 가능) - 스크롤 가능 영역
        if (cartItems.isNotEmpty)
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3, // 화면 높이의 30% 제한
            ),
            child: ExpansionTile(
              title: Text(
                '선택된 상품 ($_totalItemCount개)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.25, // 더 작은 높이 제한
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartItems[index];
                      return ListTile(
                        dense: true,
                        title: Text(cartItem.product.name),
                        subtitle: Text(
                          '${cartItem.product.formattedPrice} x ${cartItem.quantity}개',
                        ),
                        trailing: Text(
                          cartItem.formattedSubtotal,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // 총액 및 버튼 영역 - 고정 크기로 축소
        Container(
          height: 80, // 고정 높이로 설정
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // 총액 표시 - 크기 축소
              Expanded(
                child: Text(
                  _formattedTotalAmount,
                  style: const TextStyle(
                    fontSize: 20, // 크기 축소 (24 -> 20)
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8), // 간격 축소

              // 버튼 영역 - 가로 배치로 변경
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 장바구니 비우기 버튼 (왼쪽)
                  if (cartItems.isNotEmpty)
                    SizedBox(
                      width: 80, // 버튼 크기 축소
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onClearCart,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          foregroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          '비우기',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // 주문 확정 버튼 (오른쪽)
                  SizedBox(
                    width: 100, // 버튼 크기 축소
                    height: 40,
                    child: ElevatedButton(
                      onPressed: cartItems.isEmpty ? null : onConfirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cartItems.isEmpty ? Colors.grey : Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        cartItems.isEmpty ? '상품 선택' : '주문 확정',
                        style: const TextStyle(
                          fontSize: 12, // 폰트 크기 축소
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 가로 화면 레이아웃 (세로 배치 + 수량 조절 기능)
  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 상단: 선택된 상품 제목
          if (cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '선택된 상품 ($_totalItemCount개)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

          // 중간: 선택된 상품 목록 (스크롤 가능 + 수량 조절)
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
              child: Text(
                '선택된 상품이 없습니다',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            )
                : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상품명
                        Text(
                          cartItem.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // 가격 및 소계
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cartItem.product.formattedPrice,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              cartItem.formattedSubtotal,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 수량 조절 버튼 (간단한 ElevatedButton 사용)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '수량:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 감소 버튼 (단순한 ElevatedButton)
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: onDecreaseQuantity != null
                                        ? () {
                                      print('감소 클릭: ${cartItem.product.name}');
                                      onDecreaseQuantity!(cartItem);
                                    }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                    child: const Icon(Icons.remove, size: 18),
                                  ),
                                ),

                                // 수량 표시
                                Container(
                                  width: 50,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.symmetric(
                                      horizontal: BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                // 증가 버튼 (단순한 ElevatedButton)
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: onIncreaseQuantity != null
                                        ? () {
                                      print('증가 클릭: ${cartItem.product.name}');
                                      onIncreaseQuantity!(cartItem);
                                    }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                    child: const Icon(Icons.add, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 구분선
          if (cartItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              height: 1,
              color: Colors.grey[300],
            ),

          // 하단: 총액 표시
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _formattedTotalAmount,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 하단: 버튼 영역
          Row(
            children: [
              // 장바구니 비우기 버튼
              if (cartItems.isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClearCart,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '비우기',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),

              if (cartItems.isNotEmpty) const SizedBox(width: 8),

              // 주문 확정 버튼
              Expanded(
                flex: cartItems.isEmpty ? 1 : 2, // 상품이 없을 때는 전체 너비 사용
                child: ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : onConfirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cartItems.isEmpty ? Colors.grey : Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    cartItems.isEmpty ? '상품 선택' : '주문 확정',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}