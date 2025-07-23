class AppConfig {
  final bool isLocalMode;
  final String? memosApiUrl;
  final String? lastToken;
  final String? lastServerUrl;
  final bool rememberLogin;
  final bool autoSyncEnabled;
  final int syncInterval;
  final bool isDarkMode; // 保留此字段以兼容旧版本
  final String themeMode; // 主题模式：default(默认), fenglan(凤蓝)
  final String themeSelection; // 主题选择：system(跟随系统)、light(纸白)、dark(幽谷)

  static const String THEME_SYSTEM = 'system';
  static const String THEME_LIGHT = 'light';
  static const String THEME_DARK = 'dark';

  AppConfig({
    this.isLocalMode = false,
    this.memosApiUrl,
    this.lastToken,
    this.lastServerUrl,
    this.rememberLogin = false,
    this.autoSyncEnabled = false,
    this.syncInterval = 300,
    this.isDarkMode = false,
    this.themeMode = 'default',
    this.themeSelection = THEME_SYSTEM, // 默认跟随系统
  });

  AppConfig copyWith({
    bool? isLocalMode,
    String? memosApiUrl,
    String? lastToken,
    String? lastServerUrl,
    bool? rememberLogin,
    bool? autoSyncEnabled,
    int? syncInterval,
    bool? isDarkMode,
    String? themeMode,
    String? themeSelection,
  }) {
    return AppConfig(
      isLocalMode: isLocalMode ?? this.isLocalMode,
      memosApiUrl: memosApiUrl ?? this.memosApiUrl,
      lastToken: lastToken ?? this.lastToken,
      lastServerUrl: lastServerUrl ?? this.lastServerUrl,
      rememberLogin: rememberLogin ?? this.rememberLogin,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncInterval: syncInterval ?? this.syncInterval,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeMode: themeMode ?? this.themeMode,
      themeSelection: themeSelection ?? this.themeSelection,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isLocalMode': isLocalMode,
      'memosApiUrl': memosApiUrl,
      'lastToken': lastToken,
      'lastServerUrl': lastServerUrl,
      'rememberLogin': rememberLogin,
      'autoSyncEnabled': autoSyncEnabled,
      'syncInterval': syncInterval,
      'isDarkMode': isDarkMode,
      'themeMode': themeMode,
      'themeSelection': themeSelection,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      isLocalMode: json['isLocalMode'] ?? false,
      memosApiUrl: json['memosApiUrl'],
      lastToken: json['lastToken'],
      lastServerUrl: json['lastServerUrl'],
      rememberLogin: json['rememberLogin'] ?? false,
      autoSyncEnabled: json['autoSyncEnabled'] ?? false,
      syncInterval: json['syncInterval'] ?? 300,
      isDarkMode: json['isDarkMode'] ?? false,
      themeMode: json['themeMode'] ?? 'default',
      themeSelection: json['themeSelection'] ?? THEME_SYSTEM,
    );
  }
} 