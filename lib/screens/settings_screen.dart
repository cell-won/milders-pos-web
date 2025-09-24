import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SettingsService _settingsService = SettingsService();

  bool _isLoading = false;
  double _cardSize = 180.0;
  double _cardAspectRatio = 1.2;

  @override
  void initState() {
    super.initState();
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

  // 카드 크기 변경
  Future<void> _updateCardSize(double size) async {
    await _settingsService.setCardSize(size);
    setState(() {
      _cardSize = size;
    });
  }

  // 카드 비율 변경
  Future<void> _updateCardAspectRatio(double ratio) async {
    await _settingsService.setCardAspectRatio(ratio);
    setState(() {
      _cardAspectRatio = ratio;
    });
  }

  // 데이터베이스 초기화 (개발/테스트용)
  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터베이스 초기화'),
        content: const Text(
          '모든 데이터가 삭제되고 기본 설정으로 복원됩니다.\n'
              '이 작업은 되돌릴 수 없습니다.\n'
              '정말 진행하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _dbService.resetDatabase();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('데이터베이스가 초기화되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('초기화 실패: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 앱 정보 다이얼로그
  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milders POS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('버전: 1.0.0'),
            SizedBox(height: 8),
            Text('간단한 포스 시스템'),
            SizedBox(height: 8),
            Text('개발: Flutter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // UI 설정 섹션
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'UI 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카드 크기 조절
                  const Text(
                    '상품 카드 크기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '현재 크기: ${_cardSize.round()}px',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Slider(
                    value: _cardSize,
                    min: 160.0, // 최솟값을 160으로 변경
                    max: 300.0,
                    divisions: 14, // (300-160)/10 = 14 구간으로 조정
                    label: '${_cardSize.round()}px',
                    onChanged: (value) {
                      _updateCardSize(value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // 카드 비율 조절
                  const Text(
                    '상품 카드 비율 (가로:세로)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '현재 비율: ${_cardAspectRatio.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Slider(
                    value: _cardAspectRatio,
                    min: 0.6,
                    max: 2.0,
                    divisions: 14,
                    label: _cardAspectRatio.toStringAsFixed(1),
                    onChanged: (value) {
                      _updateCardAspectRatio(value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // 미리보기 카드
                  const Text(
                    '미리보기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: _cardSize,
                      height: _cardSize / _cardAspectRatio,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag, size: 40),
                          SizedBox(height: 8),
                          Text(
                            '상품명',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('10,000원'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 데이터 관리 섹션
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '데이터 관리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.orange),
                  title: const Text('데이터베이스 초기화'),
                  subtitle: const Text('모든 데이터를 삭제하고 기본 설정으로 복원'),
                  onTap: _resetDatabase,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 앱 정보 섹션
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '앱 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.blue),
                  title: const Text('앱 정보'),
                  subtitle: const Text('버전 및 앱 정보 확인'),
                  onTap: _showAppInfo,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 사용법 안내
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '사용법',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Card(
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주문 화면',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• 상품을 터치하여 장바구니에 추가'),
                  Text('• "-" 버튼으로 수량 감소'),
                  Text('• 주문 확정으로 판매 완료'),
                  SizedBox(height: 12),
                  Text(
                    '상품관리 화면',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• 상품 추가/수정/삭제'),
                  Text('• 카테고리 관리 및 순서 변경'),
                  SizedBox(height: 12),
                  Text(
                    '매출 화면',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• 일별 매출 현황'),
                  Text('• 주문 내역 및 취소'),
                  Text('• 상품별 판매 통계'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}