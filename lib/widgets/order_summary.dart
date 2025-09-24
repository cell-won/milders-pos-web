import 'package:flutter/material.dart';
import '../models/order.dart';

// 주문 요약 위젯 (화면 하단 고정)
class OrderSummary extends StatelessWidget {
  final List<CartItem> cartItems;
  final int totalAmount;
  final VoidCallback onConfirmOrder;
  final VoidCallback onClearCart;

  const OrderSummary({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.onConfirmOrder,
    required this.onClearCart,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 장바구니 상품 목록 (확장 가능)
          if (cartItems.isNotEmpty)
            ExpansionTile(
              title: Text(
                '선택된 상품 ($_totalItemCount개)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: cartItems.map((cartItem) {
                return ListTile(
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
              }).toList(),
            ),

          // 총액 및 버튼 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 총액 표시
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '총 금액',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formattedTotalAmount,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 버튼 영역
                Column(
                  children: [
                    // 장바구니 비우기 버튼
                    if (cartItems.isNotEmpty)
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: onClearCart,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            foregroundColor: Colors.grey,
                          ),
                          child: const Text('비우기'),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // 주문 확정 버튼
                    SizedBox(
                      width: 120,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty ? null : onConfirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cartItems.isEmpty ? Colors.grey : Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          cartItems.isEmpty ? '상품 선택' : '주문 확정',
                          style: const TextStyle(
                            fontSize: 16,
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
      ),
    );
  }
}