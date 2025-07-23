class AssetConfig {
  // 本地资源
  static const String localLogo = 'assets/images/logo.png';
  
  // CDN资源URL - 这里需要替换成你的实际CDN地址
  static const String cdnBaseUrl = 'https://your-cdn-url.com/assets';
  
  // 获取图片URL
  static String getImageUrl(String imageName, {bool useLocal = false}) {
    if (useLocal) {
      return 'assets/images/$imageName';
    }
    return '$cdnBaseUrl/images/$imageName';
  }
  
  // 主题相关图片
  static const String lightThemeImage = 'baise.png';
  static const String darkThemeImage = 'heise.png';
  
  // 获取主题图片URL
  static String getThemeImageUrl(bool isDarkMode, {bool useLocal = false}) {
    final String imageName = isDarkMode ? darkThemeImage : lightThemeImage;
    return getImageUrl(imageName, useLocal: useLocal);
  }
} 