import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart' as CategoryModel;
import '../models/order.dart';
import '../services/platform_service.dart';
import '../widgets/product_card.dart';
import '../widgets/order_summary.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final PlatformService _platformService = PlatformService();

  List<CategoryModel.Category> _categories = [];
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  int _selectedCategoryId = -1; // -1은 전체 카테고리
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
        title: const Text('Milders POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 선택 탭
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              color: Colors.grey[100],
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1, // +1은 전체 카테고리용
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // 전체 카테고리
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
            ),

          // 상품 그리드
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(
              child: Text(
                '등록된 상품이 없습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,  // 한 줄에 2개
                  childAspectRatio: 0.8,  // 원래대로 복원 (높이 조절 가능)
                  crossAxisSpacing: 8,  // 원래대로 복원
                  mainAxisSpacing: 8,   // 원래대로 복원
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
            ),
          ),

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
          ),
        ],
      ),
    );
  }
}