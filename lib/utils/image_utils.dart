import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/asset_config.dart';

class ImageUtils {
  // 默认缓存管理器
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  // 加载网络图片（带缓存）
  static Widget loadNetworkImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) =>
          errorWidget ?? const Icon(Icons.error),
      cacheManager: _cacheManager,
    );
  }
  
  // 加载主题相关图片
  static Widget loadThemeImage(
    BuildContext context, {
    bool isDarkMode = false,
    bool useLocal = false,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final String imageUrl = AssetConfig.getThemeImageUrl(isDarkMode, useLocal: useLocal);
    
    if (useLocal) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }
    
    return loadNetworkImage(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
    );
  }
  
  // 清除图片缓存
  static Future<void> clearImageCache() async {
    await _cacheManager.emptyCache();
    // 清除Flutter默认图片缓存
    imageCache.clear();
    imageCache.clearLiveImages();
  }
  
  // 预加载图片
  static Future<void> preloadImage(String url) async {
    await _cacheManager.downloadFile(url);
  }
} 