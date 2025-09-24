import 'package:flutter/material.dart';
import '../models/order.dart';

// 매출 항목 위젯 (주문 내역용)
class SalesItem extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const SalesItem({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          '주문 #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.formattedOrderDate),
            Text('상품 ${order.items.length}개'),
          ],
        ),
        trailing: Text(
          order.formattedTotalAmount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// 상품별 판매 통계 위젯
class ProductSalesItem extends StatelessWidget {
  final String productName;
  final int totalQuantity;
  final int totalSales;

  const ProductSalesItem({
    Key? key,
    required this.productName,
    required this.totalQuantity,
    required this.totalSales,
  }) : super(key: key);

  // 금액 포맷팅
  String get _formattedSales {
    return '${totalSales.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('판매 수량: ${totalQuantity}개'),
                Text(
                  _formattedSales,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 일별 매출 통계 카드
class DailySalesCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? backgroundColor;
  final Color? textColor;

  const DailySalesCard({
    Key? key,
    required this.title,
    required this.value,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor ?? Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textColor ?? Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}