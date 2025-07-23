import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config_model.dart';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  static const String _configKey = 'app_config';
  static const String _userKey = 'user_info';
  static const String _firstLaunchKey = 'first_launch';
  
  // 安全存储相关的key
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _serverUrlKey = 'server_url';
  
  factory PreferencesService() {
    return _instance;
  }
  
  PreferencesService._internal();
  
  final _storage = const FlutterSecureStorage();
  
  // 保存应用配置
  Future<void> saveAppConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = jsonEncode(config.toJson());
    await prefs.setString(_configKey, configJson);
  }
  
  /// 加载应用配置
  Future<AppConfig> loadAppConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 尝试从JSON中加载完整配置
    final configJson = prefs.getString(_configKey);
    if (configJson != null && configJson.isNotEmpty) {
      try {
        return AppConfig.fromJson(jsonDecode(configJson));
      } catch (e) {
        print('解析配置JSON失败: $e');
        // 如果解析失败，继续使用单独的键
      }
    }
    
    // 回退到使用单独的键
    return AppConfig(
      isLocalMode: prefs.getBool('isLocalMode') ?? false,
      memosApiUrl: prefs.getString('memosApiUrl'),
      lastToken: prefs.getString('lastToken'),
      lastServerUrl: prefs.getString('lastServerUrl'),
      rememberLogin: prefs.getBool('rememberLogin') ?? false,
      autoSyncEnabled: prefs.getBool('autoSyncEnabled') ?? false,
      syncInterval: prefs.getInt('syncInterval') ?? 300,
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      themeMode: prefs.getString('themeMode') ?? 'default',
    );
  }
  
  // 保存用户信息
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }
  
  // 获取用户信息
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    
    return null;
  }
  
  // 清除用户信息（退出登录时使用）
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
  
  // 检查是否是第一次启动应用
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }
  
  // 设置非首次启动
  Future<void> setNotFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }
  
  // 更新主题模式
  Future<void> updateThemeMode(bool isDarkMode) async {
    AppConfig config = await loadAppConfig(); // Changed from getAppConfig to loadAppConfig
    config = config.copyWith(isDarkMode: isDarkMode);
    await saveAppConfig(config);
  }
  
  // 更新使用模式（本地/云端）
  Future<void> updateUseMode(bool isLocalMode) async {
    AppConfig config = await loadAppConfig(); // Changed from getAppConfig to loadAppConfig
    config = config.copyWith(isLocalMode: isLocalMode);
    await saveAppConfig(config);
  }
  
  // 更新API URL
  Future<void> updateApiUrl(String apiUrl) async {
    AppConfig config = await loadAppConfig(); // Changed from getAppConfig to loadAppConfig
    config = config.copyWith(memosApiUrl: apiUrl);
    await saveAppConfig(config);
  }
  
  // 更新自动同步设置
  Future<void> updateAutoSync(bool enabled, [int? interval]) async {
    final config = await loadAppConfig();
    final updatedConfig = config.copyWith(
      autoSyncEnabled: enabled,
      syncInterval: interval ?? config.syncInterval,
    );
    await saveAppConfig(updatedConfig);
  }

  // 保存登录信息
  Future<void> saveLoginInfo({
    required String token,
    required String refreshToken,
    required String serverUrl,
  }) async {
    await Future.wait([
      _storage.write(key: _authTokenKey, value: token),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _serverUrlKey, value: serverUrl),
    ]);
  }
  
  // 获取保存的登录信息
  Future<Map<String, String?>> getLoginInfo() async {
    final results = await Future.wait([
      _storage.read(key: _authTokenKey),
      _storage.read(key: _refreshTokenKey),
      _storage.read(key: _serverUrlKey),
    ]);
    
    return {
      'token': results[0],
      'refreshToken': results[1],
      'serverUrl': results[2],
    };
  }
  
  // 清除登录信息
  Future<void> clearLoginInfo() async {
    await Future.wait([
      _storage.delete(key: _authTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _serverUrlKey),
    ]);
  }
  
  // 检查是否有保存的登录信息
  Future<bool> hasLoginInfo() async {
    final token = await _storage.read(key: _authTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    return token != null && refreshToken != null;
  }

  // 获取保存的服务器地址
  Future<String?> getSavedServer() async {
    return await _storage.read(key: _serverUrlKey);
  }

  // 获取保存的Token
  Future<String?> getSavedToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  // 保存导出历史
  Future<void> saveExportHistory(String fileName, int count, String format) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getExportHistory();
    
    // 添加新记录
    history.insert(0, {
      'date': DateTime.now().toIso8601String(),
      'fileName': fileName,
      'count': count,
      'format': format,
    });
    
    // 保留最近50条记录
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    // 保存历史记录
    await prefs.setString('export_history', jsonEncode(history));
  }

  // 获取导出历史
  Future<List<Map<String, dynamic>>> getExportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString('export_history');
    
    if (historyStr == null || historyStr.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(historyStr);
      return List<Map<String, dynamic>>.from(
        decoded.map((item) => Map<String, dynamic>.from(item))
      );
    } catch (e) {
      print('解析导出历史失败: $e');
      return [];
    }
  }

  // 保存导入历史
  Future<void> saveImportHistory(String source, int count, String format) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getImportHistory();
    
    // 添加新记录
    history.insert(0, {
      'date': DateTime.now().toIso8601String(),
      'source': source,
      'count': count,
      'format': format,
    });
    
    // 保留最近50条记录
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    // 保存历史记录
    await prefs.setString('import_history', jsonEncode(history));
  }

  // 获取导入历史
  Future<List<Map<String, dynamic>>> getImportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString('import_history');
    
    if (historyStr == null || historyStr.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(historyStr);
      return List<Map<String, dynamic>>.from(
        decoded.map((item) => Map<String, dynamic>.from(item))
      );
    } catch (e) {
      print('解析导入历史失败: $e');
      return [];
    }
  }

  // 获取上次备份时间
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_backup_time');
    
    if (timeStr == null || timeStr.isEmpty) {
      return null;
    }
    
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      print('解析上次备份时间失败: $e');
      return null;
    }
  }

  // 保存备份时间
  Future<void> saveLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
  }

  // 清除导入导出历史记录
  Future<void> clearImportExportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('import_history');
    await prefs.remove('export_history');
    await prefs.remove('last_backup_time');
  }
  
  // 清除所有应用设置（保留登录信息）
  Future<void> clearAllSettings({bool keepLoginInfo = true}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 如果需要保留登录信息，先保存它们
    String? token;
    String? refreshToken;
    String? serverUrl;
    if (keepLoginInfo) {
      token = await getSavedToken();
      refreshToken = await prefs.getString('refresh_token');
      serverUrl = await getSavedServer();
    }
    
    // 获取所有键
    final keys = prefs.getKeys();
    
    // 保留的键列表（不清除这些键）
    final reservedKeys = [
      'first_launch',
      if (keepLoginInfo) ...[
        'auth_token',
        'refresh_token',
        'server_url',
      ]
    ];
    
    // 清除所有不在保留列表中的键
    for (var key in keys) {
      if (!reservedKeys.contains(key)) {
        await prefs.remove(key);
      }
    }
    
    // 如果需要保留登录信息，恢复它们
    if (keepLoginInfo && token != null && serverUrl != null) {
      await saveLoginInfo(
        token: token, 
        refreshToken: refreshToken ?? '', 
        serverUrl: serverUrl
      );
    }
  }
} 