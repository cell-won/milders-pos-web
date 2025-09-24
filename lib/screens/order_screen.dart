import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart' as CategoryModel;
import '../models/order.dart';
import '../services/platform_service.dart';
import '../services/settings_service.dart';
import '../widgets/product_card.dart';
import '../widgets/order_summary.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final PlatformService _platformService = PlatformService();
  final SettingsService _settingsService = SettingsService();

  List<CategoryModel.Category> _categories = [];
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  int _selectedCategoryId = -1;
  bool _isLoading = true;
  double _cardSize = 180.0;
  double _cardAspectRatio = 1.2;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSettings();
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    final cardSize = await _settingsService.getCardSize();
    final cardRatio = await _settingsService.getCardAspectRatio();

    setState(() {
      _cardSize = cardSize;
      _cardAspectRatio = cardRatio;
    });
  }

  // 데이터 로드
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _platformService.getAllCategories();
      final products = await _platformService.getAllActiveProducts();

      setState(() {
        _categories = categories;
        _products = products;
        if (_categories.isNotEmpty && _selectedCategoryId == -1) {
          _selectedCategoryId = _categories.first.id!;
        }
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

  // 선택된 카테고리의 상품들 가져오기
  List<Product> get _filteredProducts {
    if (_selectedCategoryId == -1) {
      return _products;
    }
    return _products.where((product) => product.categoryId == _selectedCategoryId).toList();
  }

  // 상품을 장바구니에 추가
  void _addToCart(Product product) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
            (item) => item.product.id == product.id,
      );

      if (existingItemIndex >= 0) {
        _cartItems[existingItemIndex].quantity++;
      } else {
        _cartItems.add(CartItem(product: product));
      }
    });
  }

  // 장바구니에서 상품 수량 감소
  void _removeFromCart(Product product) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
            (item) => item.product.id == product.id,
      );

      if (existingItemIndex >= 0) {
        if (_cartItems[existingItemIndex].quantity > 1) {
          _cartItems[existingItemIndex].quantity--;
        } else {
          _cartItems.removeAt(existingItemIndex);
        }
      }
    });
  }

  // 장바구니에서 특정 상품의 수량 가져오기
  int _getCartQuantity(Product product) {
    final cartItem = _cartItems.firstWhere(
          (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );
    return cartItem.quantity;
  }

  // 총 금액 계산
  int get _totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  // 주문 확정
  Future<void> _confirmOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주문할 상품을 선택해주세요')),
      );
      return;
    }

    try {
      final orderId = await _platformService.createOrder(_cartItems);

      if (orderId != null) {
        setState(() {
          _cartItems.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('주문이 완료되었습니다. (주문번호: $orderId)')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('주문 생성에 실패했습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주문 오류: $e')),
        );
      }
    }
  }

  // 상품 목록 위젯 (재사용 가능)
  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          '등록된 상품이 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: _cardSize,
          childAspectRatio: _cardAspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          final quantity = _getCartQuantity(product);

          return ProductCard(
            product: product,
            quantity: quantity,
            onTap: () => _addToCart(product),
            onDecrease: () => _removeFromCart(product),
          );
        },
      ),
    );
  }

  // 카테고리 탭 위젯 (재사용 가능)
  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      color: Colors.grey[100],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ChoiceChip(
                label: const Text('전체'),
                selected: _selectedCategoryId == -1,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategoryId = -1;
                    });
                  }
                },
              ),
            );
          }

          final category = _categories[index - 1];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChoiceChip(
              label: Text(category.name),
              selected: _selectedCategoryId == category.id,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryId = category.id!;
                  });
                }
              },
            ),
          );
        },
      ),
    );
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

    // 화면 방향 확인
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milders POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
    );
  }

  // 세로 화면 레이아웃 (기존 방식)
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // 카테고리 선택 탭
        _buildCategoryTabs(),

        // 상품 그리드
        Expanded(child: _buildProductGrid()),

        // 주문 요약 (하단 고정)
        OrderSummary(
          cartItems: _cartItems,
          totalAmount: _totalAmount,
          onConfirmOrder: _confirmOrder,
          onClearCart: () {
            setState(() {
              _cartItems.clear();
            });
          },
          onIncreaseQuantity: (cartItem) => _addToCart(cartItem.product),
          onDecreaseQuantity: (cartItem) => _removeFromCart(cartItem.product),
        ),
      ],
    );
  }

  // 가로 화면 레이아웃 (좌우 분할)
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // 왼쪽: 상품 목록 (70% 차지)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // 카테고리 선택 탭
              _buildCategoryTabs(),

              // 상품 그리드
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),

        // 구분선
        Container(
          width: 1,
          color: Colors.grey[300],
        ),

        // 오른쪽: 주문 요약 (30% 차지)
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[50],
            child: OrderSummary(
              cartItems: _cartItems,
              totalAmount: _totalAmount,
              onConfirmOrder: _confirmOrder,
              onClearCart: () {
                setState(() {
                  _cartItems.clear();
                });
              },
              onIncreaseQuantity: (cartItem) => _addToCart(cartItem.product),
              onDecreaseQuantity: (cartItem) => _removeFromCart(cartItem.product),
            ),
          ),
        ),
      ],
    );
  }
}