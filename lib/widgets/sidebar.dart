import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/stats_view.dart';
import '../widgets/heatmap.dart';
import 'dart:ui';

// 添加一个动画过渡效果组件
class AnimatedMenuWidget extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedMenuWidget({
    Key? key,
    required this.child,
    required this.index,
  }) : super(key: key);

  @override
  State<AnimatedMenuWidget> createState() => _AnimatedMenuWidgetState();
}

class _AnimatedMenuWidgetState extends State<AnimatedMenuWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50), // 添加级联效果
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 自动开始动画
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  // 自定义抽屉关闭方法，添加更平滑的动画
  void _closeDrawerWithAnimation(BuildContext context) {
    Navigator.of(context).pop();
  }

  // 构建菜单项
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String path,
    required bool isSelected,
    required int index, // 添加索引参数
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isSelected 
        ? (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor)
        : (isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor);
    final textColor = isSelected
        ? (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor)
        : (isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor);
    final bgColor = isSelected
        ? (isDarkMode ? AppTheme.primaryLightColor.withOpacity(0.15) : AppTheme.primaryColor.withOpacity(0.1))
        : Colors.transparent;
        
    final menuItem = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? [
          BoxShadow(
            color: (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // 如果不是当前选中项，才执行导航
            if (!isSelected) {
              // 先触发页面切换，使用replace方法
              context.replace(path);
              
              // 延迟关闭侧边栏，让页面先进行切换，时间与打开侧边栏动画保持一致
              // 每个菜单项有级联效果，所以使用跟AnimatedMenuWidget相同的时间计算
              final animationDuration = Duration(milliseconds: 300 + index * 50);
              Future.delayed(animationDuration, () {
                if (context.mounted) {
                  _closeDrawerWithAnimation(context);
                }
              });
            } else {
              // 如果是当前页面，使用带动画的关闭方法
              _closeDrawerWithAnimation(context);
            }
          },
          splashColor: (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor).withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 使用动画包装菜单项
    return AnimatedMenuWidget(
      index: index,
      child: menuItem,
    );
  }

  // 显示退出登录确认对话框
  void _showLogoutDialog(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor;
    
    // 显示选项对话框
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '退出登录时如何处理本地数据？',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
            onPressed: () {
              Navigator.pop(context);
              // 清空本地数据
              _processLogout(context, appProvider, keepLocalData: false);
            },
                      child: const Text(
                        '清空本地数据',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
          ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
            onPressed: () {
              Navigator.pop(context);
              // 保留本地数据
              _processLogout(context, appProvider, keepLocalData: true);
            },
                      child: const Text(
              '保留本地数据',
              style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
              ),
            ),
          ),
        ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _processLogout(BuildContext context, AppProvider appProvider, {required bool keepLocalData}) {
    // 先检查是否有未同步的笔记
    appProvider.logout(keepLocalData: keepLocalData).then((result) {
      final (success, message) = result;
      
      if (!success && message != null) {
        // 有未同步的笔记，显示确认对话框
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '确认退出',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
              ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                onPressed: () {
                  // 用户确认退出，强制退出
                  Navigator.pop(context);
                  // 强制退出登录
                  appProvider.logout(force: true, keepLocalData: keepLocalData).then((_) {
                    context.go('/login');
                  });
                },
                          child: const Text(
                  '确定退出',
                  style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                ),
              ),
            ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (success) {
        // 没有未同步的笔记，直接退出
        context.go('/login');
      } else {
        // 退出失败，显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? '退出登录失败'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isLoggedIn = Provider.of<AppProvider>(context).isLoggedIn;
    final user = Provider.of<AppProvider>(context).user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final dividerColor = isDarkMode ? AppTheme.darkDividerColor : Colors.grey.shade200;
    
    return Drawer(
      backgroundColor: isDarkMode 
        ? AppTheme.darkSurfaceColor.withOpacity(0.97) // 稍微调整不透明度
        : Colors.white.withOpacity(0.97), // 稍微调整不透明度
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 增强模糊效果
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户信息区域
                AnimatedMenuWidget(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 左侧：登录按钮或用户名
                        if (!isLoggedIn)
                          TextButton.icon(
                                icon: const Icon(Icons.login_rounded, color: AppTheme.primaryColor),
                            label: const Text(
                              '登录',
                              style: TextStyle(
                                    color: AppTheme.primaryColor,
                                fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              // 先关闭抽屉
                              Navigator.pop(context);
                              // 使用 pushReplacement 确保动画一致
                              context.pushReplacement('/login');
                            },
                          )
                        else
                          Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        user?.username?.isNotEmpty == true ? user!.username[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.username ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor,
                                ),
                              ),
                                      Row(
                                        children: [
                              Container(
                                            width: 8,
                                            height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Provider.of<AppProvider>(context).isLoggedIn 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Provider.of<AppProvider>(context).isLoggedIn 
                                    ? '在线' 
                                    : '离线',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Provider.of<AppProvider>(context).isLoggedIn 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        
                        // 右侧：设置和通知图标
                        Row(
                          children: [
                                Consumer<AppProvider>(
                                  builder: (context, provider, _) {
                                    return Badge(
                                      isLabelVisible: provider.unreadAnnouncementsCount > 0,
                                      label: Text(
                                        provider.unreadAnnouncementsCount.toString(),
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: backgroundColor == Colors.white ? AppTheme.backgroundColor : AppTheme.darkBackgroundColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.notifications_outlined,
                                            color: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            // 导航到通知页面
                                            Navigator.pop(context);
                                            context.goNamed('notificationsPage');
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: backgroundColor == Colors.white ? AppTheme.backgroundColor : AppTheme.darkBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.settings_outlined,
                                      color: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                                      size: 22,
                                    ),
                              onPressed: () {
                                // 直接导航到设置页面，不等待抽屉关闭
                                Navigator.pop(context);
                                context.go('/settings');
                              },
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
            
                // 热力图
                AnimatedMenuWidget(
                  index: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.neuCardShadow(isDark: isDarkMode),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '活动记录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer<AppProvider>(
                          builder: (context, appProvider, _) => Heatmap(
                            notes: appProvider.notes,
                            cellColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            activeColor: isDarkMode ? AppTheme.primaryLightColor.withOpacity(0.9) : AppTheme.primaryColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 分类标题
                AnimatedMenuWidget(
                  index: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      '功能菜单',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode 
                          ? AppTheme.darkTextPrimaryColor.withOpacity(0.8) // 使用更亮的颜色提高对比度
                          : AppTheme.textSecondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            
                // 功能菜单项
                _buildMenuItem(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  title: '全部笔记',
                  path: '/',
                  isSelected: currentPath == '/',
                  index: 3, // 添加索引
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.shuffle_rounded,
                  title: '随机回顾',
                  path: '/random-review',
                  isSelected: currentPath == '/random-review',
                  index: 4, // 添加索引
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.local_offer_outlined,
                  title: '全部标签',
                  path: '/tags',
                  isSelected: currentPath == '/tags',
                  index: 5, // 添加索引
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: '帮助中心',
                  path: '/help',
                  isSelected: currentPath == '/help',
                  index: 6, // 添加索引
                ),
                
                // 添加伸展空间，使退出登录按钮位于底部
                const Spacer(),
                
                // 退出登录按钮，只在登录模式下显示
                if (isLoggedIn)
                  AnimatedMenuWidget(
                    index: 7,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // 显示退出登录对话框
                            _showLogoutDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: Colors.red.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '退出登录',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 