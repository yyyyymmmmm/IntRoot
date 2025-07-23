import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import '../models/app_config_model.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final appConfig = appProvider.appConfig;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkSurfaceColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : null),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('偏好设置', 
            style: TextStyle(
              fontSize: 17, 
              fontWeight: FontWeight.w500,
              color: textColor,
            )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: ListView(
        children: [
          // 外观设置
          _buildSectionHeader(context, '外观'),
          
          // 主题选择
          _buildThemeSelector(context, appProvider, appConfig),
          
          const Divider(),
          
          // 同步设置
          _buildSectionHeader(context, '同步'),
          
          // 自动同步设置
          _buildSwitchItem(
            context, 
            icon: Icons.sync, 
            title: '自动同步', 
            subtitle: '定期自动同步笔记',
            value: appConfig.autoSyncEnabled,
            onChanged: (value) => _updateAutoSync(appProvider, value),
          ),
          
          // 同步间隔设置 (仅当自动同步开启时显示)
          if (appConfig.autoSyncEnabled)
            _buildSyncIntervalSetting(context, appProvider, appConfig),
          
          const Divider(),
          
          // 其他设置
          _buildSectionHeader(context, '其他'),
          
          // 记住登录设置
          _buildSwitchItem(
            context, 
            icon: Icons.login, 
            title: '记住登录', 
            subtitle: '下次启动时自动登录',
            value: appConfig.rememberLogin,
            onChanged: (value) => _updateRememberLogin(appProvider, value),
          ),
        ],
      ),
    );
  }
  
  // 构建主题选择器
  Widget _buildThemeSelector(BuildContext context, AppProvider appProvider, AppConfig appConfig) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    final dropdownColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        children: [
          // 图标容器
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode 
                ? AppTheme.primaryColor.withOpacity(0.2) 
                : primaryColorWithOpacity,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.palette_outlined,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // 标题和描述
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主题选择',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '选择应用的外观主题',
                  style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                // 下拉选择框
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor!, width: 1),
                  ),
                  child: DropdownButton<String>(
                    value: appConfig.themeSelection,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: iconColor),
                    underline: Container(), // 移除下划线
                    dropdownColor: dropdownColor,
                    items: [
                      _buildDropdownItem('跟随系统', AppConfig.THEME_SYSTEM, isDarkMode, iconColor),
                      _buildDropdownItem('纸白', AppConfig.THEME_LIGHT, isDarkMode, iconColor),
                      _buildDropdownItem('幽谷', AppConfig.THEME_DARK, isDarkMode, iconColor),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateThemeSelection(appProvider, value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建下拉项
  DropdownMenuItem<String> _buildDropdownItem(String label, String value, bool isDarkMode, Color iconColor) {
    final selectedColor = isDarkMode ? Colors.white : AppTheme.primaryColor;
    final isSelected = value == Provider.of<AppProvider>(context).appConfig.themeSelection;
    
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (value == AppConfig.THEME_SYSTEM)
            Icon(Icons.brightness_auto, size: 20, color: isSelected ? iconColor : null)
          else if (value == AppConfig.THEME_LIGHT)
            Icon(Icons.wb_sunny_outlined, size: 20, color: isSelected ? iconColor : null)
          else
            Icon(Icons.nights_stay_outlined, size: 20, color: isSelected ? iconColor : null),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : null,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建分区标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
  
  // 构建开关设置项
  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode 
                ? AppTheme.primaryColor.withOpacity(0.2) 
                : primaryColorWithOpacity,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
          ),
        ],
      ),
    );
  }
  
  // 构建同步间隔设置
  Widget _buildSyncIntervalSetting(BuildContext context, AppProvider appProvider, AppConfig appConfig) {
    // 定义可选的同步间隔（分钟）
    final syncIntervals = [5, 15, 30, 60, 120];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final primaryColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 56), // 与图标对齐
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '同步间隔',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: syncIntervals.map((interval) {
                    final isSelected = appConfig.syncInterval == interval * 60; // 转换为秒
                    return ChoiceChip(
                      label: Text('${interval}分钟'),
                      selected: isSelected,
                      selectedColor: primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? primaryColor : (isDarkMode ? Colors.grey[300] : Colors.black),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          _updateSyncInterval(appProvider, interval * 60); // 转换为秒
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 更新主题选择
  void _updateThemeSelection(AppProvider appProvider, String value) async {
    await appProvider.setThemeSelection(value);
    
    if (mounted) {
      String themeName;
      switch (value) {
        case AppConfig.THEME_SYSTEM:
          themeName = '跟随系统';
          break;
        case AppConfig.THEME_LIGHT:
          themeName = '纸白';
          break;
        case AppConfig.THEME_DARK:
          themeName = '幽谷';
          break;
        default:
          themeName = '未知';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('主题已切换为$themeName'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 更新自动同步设置
  void _updateAutoSync(AppProvider appProvider, bool value) async {
    final updatedConfig = appProvider.appConfig.copyWith(autoSyncEnabled: value);
    await appProvider.updateConfig(updatedConfig);
    setState(() {});
    
    // 根据设置启动或停止自动同步
    if (value) {
      appProvider.startAutoSync();
    } else {
      appProvider.stopAutoSync();
    }
  }
  
  // 更新同步间隔
  void _updateSyncInterval(AppProvider appProvider, int seconds) async {
    final updatedConfig = appProvider.appConfig.copyWith(syncInterval: seconds);
    await appProvider.updateConfig(updatedConfig);
    
    // 重启自动同步
    if (updatedConfig.autoSyncEnabled) {
      appProvider.stopAutoSync();
      appProvider.startAutoSync();
    }
  }
  
  // 更新记住登录设置
  void _updateRememberLogin(AppProvider appProvider, bool value) async {
    final updatedConfig = appProvider.appConfig.copyWith(rememberLogin: value);
    await appProvider.updateConfig(updatedConfig);
    
    // 如果关闭记住登录，清除保存的登录信息
    if (!value) {
      await appProvider.clearLoginInfo();
    }
  }
} 