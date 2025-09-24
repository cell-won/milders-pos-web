import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/platform_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final PlatformService _platformService = PlatformService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final products = await _platformService.getAllProducts();
      final categories = await _platformService.getAllCategories();

      setState(() {
        _products = products;
        _categories = categories;
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

  // 카테고리명으로 찾기
  String _getCategoryName(int categoryId) {
    final category = _categories.firstWhere(
          (c) => c.id == categoryId,
      orElse: () => Category(
        id: -1,
        name: '알 수 없음',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  // 상품 추가/수정 다이얼로그
  Future<void> _showProductDialog({Product? product}) async {
    final TextEditingController nameController =
    TextEditingController(text: product?.name ?? '');
    final TextEditingController priceController =
    TextEditingController(text: product?.price.toString() ?? '');

    int selectedCategoryId = product?.categoryId ?? (_categories.isNotEmpty ? _categories.first.id! : 0);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(product == null ? '상품 추가' : '상품 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상품명 입력
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '상품명',
                        hintText: '상품명을 입력하세요',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 가격 입력
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: '가격 (원)',
                        hintText: '가격을 입력하세요',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 카테고리 선택
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: '카테고리',
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id!,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedCategoryId = value;
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();

                    if (name.isEmpty || priceText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모든 필드를 입력해주세요')),
                      );
                      return;
                    }

                    final price = int.tryParse(priceText);
                    if (price == null || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('올바른 가격을 입력해주세요')),
                      );
                      return;
                    }

                    bool success;
                    if (product == null) {
                      // 새 상품 추가
                      final productId = await _platformService.addProduct(
                          name, price, selectedCategoryId
                      );
                      success = productId > 0;
                    } else {
                      // 기존 상품 수정
                      success = await _platformService.updateProduct(
                          product.id!, name, price, selectedCategoryId
                      );
                    }

                    if (success) {
                      Navigator.of(context).pop();
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(product == null ? '상품이 추가되었습니다' : '상품이 수정되었습니다'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(product == null ? '상품 추가에 실패했습니다' : '상품 수정에 실패했습니다'),
                        ),
                      );
                    }
                  },
                  child: Text(product == null ? '추가' : '수정'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 카테고리 추가/수정 다이얼로그
  Future<void> _showCategoryDialog({Category? category}) async {
    final TextEditingController nameController =
    TextEditingController(text: category?.name ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category == null ? '카테고리 추가' : '카테고리 수정'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '카테고리명',
              hintText: '카테고리명을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('카테고리명을 입력해주세요')),
                  );
                  return;
                }

                bool success;
                if (category == null) {
                  // 새 카테고리 추가
                  final categoryId = await _platformService.addCategory(name);
                  success = categoryId > 0;
                } else {
                  // 기존 카테고리 수정
                  success = await _platformService.updateCategory(category.id!, name);
                }

                if (success) {
                  Navigator.of(context).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(category == null ? '카테고리가 추가되었습니다' : '카테고리가 수정되었습니다'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(category == null ? '카테고리 추가에 실패했습니다' : '카테고리 수정에 실패했습니다'),
                    ),
                  );
                }
              },
              child: Text(category == null ? '추가' : '수정'),
            ),
          ],
        );
      },
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '상품'),
            Tab(text: '카테고리'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 상품 관리 탭
          _buildProductTab(),
          // 카테고리 관리 탭
          _buildCategoryTab(),
        ],
      ),
    );
  }

  // 상품 관리 탭
  Widget _buildProductTab() {
    return Column(
      children: [
        Expanded(
          child: _products.isEmpty
              ? const Center(
            child: Text(
              '등록된 상품이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ReorderableListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _products.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;

              final product = _products[oldIndex];
              final success = await _platformService.updateProductOrder(
                  product.id!,
                  newIndex + 1
              );

              if (success) {
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('상품 순서 변경에 실패했습니다')),
                );
              }
            },
            itemBuilder: (context, index) {
              final product = _products[index];
              return Card(
                key: ValueKey(product.id),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: product.isActive ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('가격: ${product.formattedPrice}'),
                      Text('카테고리: ${_getCategoryName(product.categoryId)}'),
                      Text('순서: ${product.order}'),
                      Text(
                        '상태: ${product.isActive ? "활성" : "비활성"}',
                        style: TextStyle(
                          color: product.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          _showProductDialog(product: product);
                          break;
                        case 'toggle':
                          final success = await _platformService.toggleProductStatus(product.id!);
                          if (success) {
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(product.isActive ? '상품이 비활성화되었습니다' : '상품이 활성화되었습니다'),
                              ),
                            );
                          }
                          break;
                        case 'delete':
                          final success = await _platformService.deleteProduct(product.id!);
                          if (success) {
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('상품이 삭제되었습니다')),
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('수정'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(product.isActive ? '비활성화' : '활성화'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // 상품 추가 버튼
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _categories.isEmpty
                  ? null
                  : () => _showProductDialog(),
              child: const Text('새 상품 추가'),
            ),
          ),
        ),
      ],
    );
  }

  // 카테고리 관리 탭
  Widget _buildCategoryTab() {
    return Column(
      children: [
        Expanded(
          child: _categories.isEmpty
              ? const Center(
            child: Text(
              '등록된 카테고리가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ReorderableListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _categories.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;

              final category = _categories[oldIndex];
              final success = await _platformService.updateCategoryOrder(
                  category.id!,
                  newIndex + 1
              );

              if (success) {
                _loadData();
              }
            },
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Card(
                key: ValueKey(category.id),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('순서: ${category.order}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          _showCategoryDialog(category: category);
                          break;
                        case 'delete':
                          final success = await _platformService.deleteCategory(category.id!);
                          if (success) {
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('카테고리가 삭제되었습니다')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('해당 카테고리에 상품이 있어 삭제할 수 없습니다')),
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('수정'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // 카테고리 추가 버튼
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCategoryDialog(),
              child: const Text('새 카테고리 추가'),
            ),
          ),
        ),
      ],
    );
  }
}