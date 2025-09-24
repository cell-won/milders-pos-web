import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/order_screen.dart';
import 'screens/product_management_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';
import 'services/platform_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 플랫폼별 데이터 서비스 초기화
  try {
    await PlatformService().initialize();
    print('데이터 서비스 초기화 완료');
  } catch (e) {
    print('데이터 서비스 초기화 오류: $e');
  }

  runApp(const MildersPos());
}

class MildersPos extends StatelessWidget {
  const MildersPos({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milders POS',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          shadowColor: Colors.grey,
          elevation: 2,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 각 탭의 화면들
  final List<Widget> _screens = [
    const OrderScreen(),
    const ProductManagementScreen(),
    const SalesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
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
    );
  }
}