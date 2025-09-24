import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/sales_item.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  List<Map<String, dynamic>> _productStats = [];
  Map<String, int> _todayStats = {};
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 데이터 로드
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 모든 주문 조회
      final orders = await _orderService.getAllOrders();

      // 오늘의 통계
      final todayStats = await _orderService.getDailySalesStats(_selectedDate);

      // 이번 달 상품별 통계
      DateTime startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      DateTime endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
      final productStats = await _orderService.getProductSalesStats(startOfMonth, endOfMonth);

      setState(() {
        _orders = orders;
        _todayStats = todayStats;
        _productStats = productStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 오류: $e')),
        );
      }
    }
  }

  // 날짜 선택기
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  // 주문 상세 다이얼로그
  Future<void> _showOrderDetailDialog(Order order) async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text('주문 #${order.id}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text('주문 시간: ${order.formattedOrderDate}'),
                const SizedBox(height: 16),
                const Text('주문 상품:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: order.items.length,
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('${item.productName} x${item.quantity}'),
                                  ),
                                  Text(item.formattedSubtotal),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('총 금액:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            order.formattedTotalAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                ),
              ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('주문 취소'),
                      content: const Text('이 주문을 취소하시겠습니까?\n취소된 주문은 복구할 수 없습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('아니오'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('예, 취소합니다'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final success = await _orderService.cancelOrder(order.id!);
                    if (success) {
                      Navigator.of(context).pop();
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('주문이 취소되었습니다')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('주문 취소에 실패했습니다')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('주문 취소'),
              ),
            ],
          );
        },
    );
  }

  // 금액 포맷팅 함수
  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    )}원';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('매출 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '오늘 매출'),
            Tab(text: '주문 내역'),
            Tab(text: '상품별 통계'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 오늘 매출 탭
          _buildTodaySalesTab(),
          // 주문 내역 탭
          _buildOrderHistoryTab(),
          // 상품별 통계 탭
          _buildProductStatsTab(),
        ],
      ),
    );
  }

  // 오늘 매출 탭
  Widget _buildTodaySalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 날짜 표시
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _selectDate,
                    child: const Text('날짜 변경'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 매출 통계 카드
          Row(
            children: [
              // 총 매출액
              Expanded(
                child: DailySalesCard(
                  title: '총 매출액',
                  value: _formatAmount(_todayStats['totalSales'] ?? 0),
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                ),
              ),

              const SizedBox(width: 8),

              // 총 주문 수
              Expanded(
                child: DailySalesCard(
                  title: '총 주문 수',
                  value: '${_todayStats['totalOrders'] ?? 0}건',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 평균 주문 금액
          if ((_todayStats['totalOrders'] ?? 0) > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '평균 주문 금액',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      _formatAmount((_todayStats['totalSales'] ?? 0) ~/ (_todayStats['totalOrders'] ?? 1)),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 주문 내역 탭
  Widget _buildOrderHistoryTab() {
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          '주문 내역이 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return SalesItem(
          order: order,
          onTap: () => _showOrderDetailDialog(order),
        );
      },
    );
  }

  // 상품별 통계 탭
  Widget _buildProductStatsTab() {
    if (_productStats.isEmpty) {
      return const Center(
        child: Text(
          '이번 달 판매 내역이 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[100],
          child: Text(
            '${_selectedDate.year}년 ${_selectedDate.month}월 상품별 판매 통계',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 통계 리스트
        Expanded(
          child: ListView.builder(
            itemCount: _productStats.length,
            itemBuilder: (context, index) {
              final stat = _productStats[index];
              final productName = stat['product_name'] as String;
              final totalQuantity = stat['total_quantity'] as int;
              final totalSales = stat['total_sales'] as int;

              return ProductSalesItem(
                productName: productName,
                totalQuantity: totalQuantity,
                totalSales: totalSales,
              );
            },
          ),
        ),
      ],
    );
  }
}