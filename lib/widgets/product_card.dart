import 'package:flutter/material.dart';
import '../models/product.dart';

// 상품 카드 위젯 (주문 화면에서 사용)
class ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onDecrease;

  const ProductCard({
    Key? key,
    required this.product,
    required this.quantity,
    required this.onTap,
    required this.onDecrease,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // 패딩을 12 -> 8로 줄임
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상품명 (Flexible로 감싸서 크기에 맞춤)
              Flexible(
                flex: 2,
                child: Center(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16, // 폰트 크기 축소 (16 -> 12)
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 4), // 간격 축소 (8 -> 4)

              // 가격 (Flexible로 감싸기)
              Flexible(
                flex: 1,
                child: Center(
                  child: Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 16, // 폰트 크기 축소 (14 -> 10)
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(height: 4), // 간격 축소

              // 하단 버튼 영역 (Flexible로 감싸기)
              Flexible(
                flex: 1,
                child: _buildBottomSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 하단 섹션 (수량 표시 또는 추가 버튼)
  Widget _buildBottomSection() {
    if (quantity > 0) {
      // 수량이 있을 때: 수량 조절 버튼
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 패딩 축소
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 감소 버튼
            InkWell(
              onTap: onDecrease,
              child: const Padding(
                padding: EdgeInsets.all(2), // 패딩 축소
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                  size: 16, // 아이콘 크기 축소 (16 -> 14)
                ),
              ),
            ),

            // 수량 표시
            Flexible(
              child: Text(
                quantity.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // 폰트 크기 축소 (14 -> 12)
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 증가는 전체 카드 탭으로 처리
            const Icon(
              Icons.add,
              color: Colors.white,
              size: 16, // 아이콘 크기 축소 (16 -> 14)
            ),
          ],
        ),
      );
    } else {
      // 수량이 0일 때: "탭하여 추가" 메시지
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4), // 패딩 축소
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            '탭하여 추가',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10, // 폰트 크기 축소 (12 -> 10)
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}