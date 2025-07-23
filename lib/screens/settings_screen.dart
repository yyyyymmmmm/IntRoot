import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import '../routes/app_router.dart'; // 导入自定义路由
import '../screens/home_screen.dart'; // 导入首页
import '../services/announcement_service.dart'; // 导入公告服务
import '../widgets/update_dialog.dart'; // 导入更新对话框

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : Colors.grey[600];
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // 返回首页而不是退出应用
        if (didPop == false) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.close, color: isDarkMode ? Colors.white : null),
            onPressed: () {
              // 返回主页
              context.go('/');
            },
          ),
          title: Text('设置', 
                    style: TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    )),
          centerTitle: true,
          elevation: 0,
          backgroundColor: backgroundColor,
        ),
        body: Column(
          children: [
            // 顶部标语
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
              children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Text(
                        '静待沉淀',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '蓄势鸣响',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '你的每一次落笔，都是未来生长的根源。',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                            ),
                    ),
                  ],
                ),
            ),
                
            // 设置列表
            Expanded(
              child: ListView(
                  children: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.account_circle,
                      title: '账户信息',
                      onTap: () {
                        final appProvider = Provider.of<AppProvider>(context, listen: false);
                        if (appProvider.isLoggedIn) {
                          // 已登录，直接前往账户信息页面
                          context.push('/account-info');
                        } else {
                          // 未登录，显示提示对话框
                          _showLoginPromptDialog(context);
                        }
                      },
                    ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.cloud,
                    title: '服务器连接',
                    onTap: () => context.push('/server-info'),
                    ),
                    _buildSettingsItem(
                      context,
                    icon: Icons.settings,
                    title: '偏好设置',
                    onTap: () => context.push('/preferences'),
                    ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.import_export,
                    title: '导入导出',
                    onTap: () => context.push('/import-export'),
                      ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.cleaning_services,
                    title: '数据清理',
                    onTap: () => context.push('/data-cleanup'),
                    ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.science,
                    title: '实验室',
                    onTap: () => _showLabDialog(context),
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.system_update_outlined,
                    title: '检查更新',
                    onTap: () => _checkForUpdates(context),
                  ),
                    _buildSettingsItem(
                      context,
                    icon: Icons.feedback,
                    title: '反馈建议',
                    onTap: () => _showFeedbackDialog(context),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.help_outline,
                      title: '帮助中心',
                      onTap: () => context.push('/settings/help'),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline,
                      title: '关于我们',
                      onTap: () => context.push('/settings/about'),
                    ),
                  ],
                ),
            ),
                
            // 底部区域
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                return Column(
                  children: [
                    // 只在非本地模式下显示退出登录按钮
                    if (!appProvider.isLocalMode)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextButton(
                          onPressed: () => _confirmLogout(context),
                          child: const Text(
                            '退出登录',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'InkRoot-1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : null;
    final arrowColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
                icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: arrowColor,
            ),
          ],
        ),
      ),
    );
  }
  
  // 显示未登录提示对话框
  void _showLoginPromptDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              Text(
                '未登录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              // 内容
              Text(
                '您当前未登录，无法查看账户信息。是否前往登录页面？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 登录按钮
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
                        context.push('/login');
                      },
                      child: const Text(
                        '去登录',
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
  
  void _showLabDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.science,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              '实验室暂无新功能，敬请期待！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '知道了',
              style: TextStyle(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFeedbackDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final emailAddress = 'sdwxgzh@126.com';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.feedback_outlined,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              Text(
                '问题反馈',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              // 内容
              Text(
                '感谢您使用InkRoot-墨鸣笔记！\n如有任何问题或建议，请发送邮件至：',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // 邮箱
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: emailAddress));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('邮箱已复制到剪贴板'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emailAddress,
                        style: TextStyle(
                          color: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 按钮
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: isDarkMode ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '关闭',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 检查更新
  Future<void> _checkForUpdates(BuildContext context) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // 获取当前版本信息
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    
    // 检查更新
    final announcementService = AnnouncementService();
    final (versionInfo, hasUpdate) = await announcementService.checkForUpdates();
    
    // 关闭加载对话框
    if (context.mounted) {
      Navigator.pop(context);
      
      if (versionInfo == null) {
        // 检查更新失败
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('检查更新失败，请检查网络连接'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (!hasUpdate) {
        // 已是最新版本
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('您当前已是最新版本'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // 显示更新对话框
        showDialog(
          context: context,
          barrierDismissible: !versionInfo.forceUpdate,
          builder: (context) => UpdateDialog(
            versionInfo: versionInfo,
            currentVersion: currentVersion,
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'InkRoot',
        applicationVersion: '1.0.0',
        applicationIcon: const FlutterLogo(size: 32),
        children: const [
          Text('InkRoot 是一个简洁高效的笔记应用。'),
          SizedBox(height: 8),
          Text('© 2025 InkRoot Team'),
        ],
      ),
    );
  }
  
  void _confirmLogout(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // 显示选项对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出登录时如何处理云端数据？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 清空本地数据
              _processLogout(context, appProvider, keepLocalData: false);
            },
            child: const Text('清空云端数据'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 保留本地数据
              _processLogout(context, appProvider, keepLocalData: true);
            },
            child: Text(
              '保留云端数据',
              style: TextStyle(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
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
          builder: (context) => AlertDialog(
            title: const Text('确认退出'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  // 用户确认退出，强制退出
                  Navigator.pop(context);
                  // 强制退出登录
                  appProvider.logout(force: true, keepLocalData: keepLocalData).then((_) {
                    context.go('/login');
                  });
                },
                child: Text(
                  '确定退出',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (success) {
        // 没有未同步的笔记，直接退出
        context.go('/login');
      } else {
        // 退出失败，显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message ?? '退出登录失败')),
        );
      }
    });
  }
} 