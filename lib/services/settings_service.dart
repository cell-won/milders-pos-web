import 'package:shared_preferences/shared_preferences.dart';

// 앱 설정 관리 서비스
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // 초기화
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // 카드 크기 설정 저장/불러오기
  Future<void> setCardSize(double size) async {
    await initialize();
    await _prefs!.setDouble('card_size', size);
  }

  Future<double> getCardSize() async {
    await initialize();
    return _prefs!.getDouble('card_size') ?? 180.0; // 기본값 180
  }

  // 카드 비율 설정 저장/불러오기
  Future<void> setCardAspectRatio(double ratio) async {
    await initialize();
    await _prefs!.setDouble('card_aspect_ratio', ratio);
  }

  Future<double> getCardAspectRatio() async {
    await initialize();
    return _prefs!.getDouble('card_aspect_ratio') ?? 1.2; // 기본값 1.2
  }
}