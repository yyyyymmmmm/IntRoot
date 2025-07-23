import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'routes/app_router.dart';
import 'themes/app_theme.dart';
import 'models/app_config_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化timeago库，添加中文支持
  timeago.setLocaleMessages('zh', timeago.ZhCnMessages());
  timeago.setDefaultLocale('zh');
  
  // 设置全局的页面转换配置，使所有动画更平滑
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  // 创建主应用提供器
  final appProvider = AppProvider();
  
  // 运行应用
    runApp(MyApp(appProvider: appProvider));
}

// 创建自定义页面切换动画
class FadeTransitionPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadeTransitionPageRoute({required this.page}) 
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            final tween = Tween(begin: begin, end: end);
            final fadeAnimation = animation.drive(tween);
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}

class MyApp extends StatefulWidget {
  final AppProvider appProvider;
  
  const MyApp({super.key, required this.appProvider});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }
  
  Future<void> _checkForUpdates() async {
    try {
      // 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      log('当前版本: $currentVersion');
      
      // 获取服务器版本
      final response = await http.get(
        Uri.parse('https://gitee.com/yyyyymmmmm/inkroot/raw/master/announcements.json')
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverVersion = data['versionInfo']['versionName'];
        log('服务器版本: $serverVersion');
        
        // 比较版本号
        if (_shouldUpdate(currentVersion, serverVersion)) {
          if (mounted) {
            _showUpdateDialog(data['versionInfo']);
          }
        }
      } else {
        log('获取版本信息失败: ${response.statusCode}');
      }
    } catch (e) {
      log('检查更新异常: $e');
    }
  }
  
  bool _shouldUpdate(String currentVersion, String serverVersion) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final server = serverVersion.split('.').map(int.parse).toList();
      
      // 确保两个列表长度相同
      while (current.length < server.length) current.add(0);
      while (server.length < current.length) server.add(0);
      
      // 比较每个版本号部分
      for (var i = 0; i < current.length; i++) {
        if (server[i] > current[i]) return true;
        if (server[i] < current[i]) return false;
      }
      
      return false;
    } catch (e) {
      log('版本号比较异常: $e');
      return false;
    }
  }
  
  void _showUpdateDialog(Map<String, dynamic> versionInfo) {
    showDialog(
      context: context,
      barrierDismissible: !(versionInfo['forceUpdate'] ?? false),
      builder: (context) => AlertDialog(
        title: const Text('发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('墨鸣笔记有新版本可用，建议立即更新以体验新功能！'),
            const SizedBox(height: 16),
            const Text('更新内容：'),
            ...List<Widget>.from(
              (versionInfo['releaseNotes'] as List<dynamic>).map(
                (note) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $note'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!(versionInfo['forceUpdate'] ?? false))
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后再说'),
            ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = versionInfo['downloadUrls']['android'];
              try {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  log('无法打开下载链接: $url');
                }
              } catch (e) {
                log('启动下载链接异常: $e');
              }
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 创建路由器
    final appRouter = AppRouter(widget.appProvider);
    
    return ChangeNotifierProvider.value(
      value: widget.appProvider,
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // 获取主题选择和深色模式状态
          final isDarkMode = provider.isDarkMode;
          final themeSelection = provider.themeSelection;
          final themeMode = provider.themeMode;
          
          // 设置状态栏颜色 - 根据当前主题调整
          final statusBarColor = isDarkMode 
              ? AppTheme.darkSurfaceColor
              : Colors.white;
          
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: statusBarColor,
              systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
            ),
          );
          
          // 根据配置选择主题
          final theme = AppTheme.getTheme(themeMode, false); // 亮色主题
          final darkTheme = AppTheme.getTheme(themeMode, true); // 深色主题
          
          // 根据主题选择设置ThemeMode
          ThemeMode appThemeMode;
          switch (themeSelection) {
            case AppConfig.THEME_SYSTEM:
              appThemeMode = ThemeMode.system;
              break;
            case AppConfig.THEME_LIGHT:
              appThemeMode = ThemeMode.light;
              break;
            case AppConfig.THEME_DARK:
              appThemeMode = ThemeMode.dark;
              break;
            default:
              appThemeMode = ThemeMode.system;
          }
          
          return MaterialApp.router(
            title: 'InkRoot-墨鸣笔记',
            themeMode: appThemeMode,
            theme: theme,
            darkTheme: darkTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter.router,
            // 添加全局页面切换配置
            builder: (context, child) {
              return MediaQuery(
                // 减少动画延迟
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
