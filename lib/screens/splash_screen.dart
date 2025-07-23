import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/preferences_service.dart';
import '../themes/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final PreferencesService _preferencesService = PreferencesService();
  late AnimationController _animationController;
  late Animation<double> _dotAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 加载点动画
    _dotAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
    
    // 启动动画并循环
    _animationController.repeat();
    
    // 在UI渲染完成后初始化应用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 初始化应用
  Future<void> _initializeApp() async {
    if (!mounted) return;
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // 初始化应用
    try {
      if (!appProvider.isInitialized) {
        await appProvider.initializeApp();
      }
    } catch (e) {
      print('初始化应用失败: $e');
    }
    
    // 延迟一小段时间以显示启动页
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // 检查是否首次启动
    bool isFirstLaunch = true;
    try {
      isFirstLaunch = await _preferencesService.isFirstLaunch();
    } catch (e) {
      print('检查是否首次启动失败: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
    
    // 导航到适当的页面
    if (isFirstLaunch) {
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              isDarkMode ? 'assets/images/black2logo.png' : 'assets/images/logo.png',
              width: 100,
              height: 100,
            ),
            
            const SizedBox(height: 24),
            
            // 应用名称
            Text(
              'InkRoot',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 加载指示器
            if (_isLoading)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLoadingDot(0, textColor),
                  _buildLoadingDot(1, textColor),
                  _buildLoadingDot(2, textColor),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  // 构建加载动画点
  Widget _buildLoadingDot(int index, Color color) {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        final double t = _dotAnimation.value;
        final int currentDot = (t * 3).floor() % 3;
        final bool isActive = currentDot == index;
        
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(isActive ? 1.0 : 0.3),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 