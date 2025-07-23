import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/preferences_service.dart';
import '../themes/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final PreferencesService _preferencesService = PreferencesService();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'InkRoot • InkRoot-墨鸣笔记',
      description: '记录每一个值得铭记的瞬间',
      image: 'assets/images/onboarding_1.png',
      iconData: Icons.edit_note,
    ),
    OnboardingPage(
      title: 'InkRoot • InkRoot-墨鸣笔记',
      description: '使用#标签整理你的笔记，轻松分类和查找',
      image: 'assets/images/onboarding_2.png',
      iconData: Icons.tag,
    ),
    OnboardingPage(
      title: 'InkRoot • InkRoot-墨鸣笔记',
      description: '随机回顾功能，激发新的思考，加深记忆',
      image: 'assets/images/onboarding_3.png',
      iconData: Icons.refresh,
    ),
    OnboardingPage(
      title: 'InkRoot • InkRoot-墨鸣笔记',
      description: '多端同步，随时随地记录你的想法',
      image: 'assets/images/onboarding_4.png',
      iconData: Icons.devices,
    ),
    OnboardingPage(
      title: 'InkRoot • InkRoot-墨鸣笔记',
      description: '选择你的使用方式',
      image: 'assets/images/onboarding_5.png',
      iconData: Icons.cloud_sync,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _markOnboardingComplete() async {
    await _preferencesService.setNotFirstLaunch();
  }

  void _navigateToLogin() {
    _markOnboardingComplete();
    context.go('/login');
  }

  void _continueToLocalMode() async {
    setState(() {
      _isLoading = true;
    });

    _markOnboardingComplete();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.switchToLocalMode();

    setState(() {
      _isLoading = false;
    });

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 标题区域
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Text(
                    'InkRoot • InkRoot-墨鸣笔记',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '你的每一次落笔，都是未来成长的源泉！',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3DD598),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 图片滑动区域
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 图片区域
                        Expanded(
                          flex: 3,
                          child: Image.asset(
                            page.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                page.iconData,
                                size: 180,
                                color: Colors.teal,
                              );
                            },
                          ),
                        ),
                        
                        // 描述文本
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            page.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 页面指示器
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.teal
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            
            // 底部按钮区域 - 始终显示
            Column(
              children: [
                // 立即接入按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _navigateToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3DD598),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '立即接入',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 或
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '或',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // 本地运行按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continueToLocalMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3DD598),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '本地运行',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final IconData iconData;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.iconData,
  });
} 