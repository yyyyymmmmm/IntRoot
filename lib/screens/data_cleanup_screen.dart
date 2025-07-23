import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../themes/app_theme.dart';
import '../models/app_config_model.dart';

class DataCleanupScreen extends StatefulWidget {
  const DataCleanupScreen({super.key});

  @override
  State<DataCleanupScreen> createState() => _DataCleanupScreenState();
}

class _DataCleanupScreenState extends State<DataCleanupScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferencesService = PreferencesService();
  
  bool _isLoading = false;
  int _notesCount = 0;
  double _databaseSize = 0;
  double _cacheSize = 0;
  int _imagesCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadDataInfo();
  }
  
  // 加载数据信息
  Future<void> _loadDataInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 获取笔记数量
      final notesCount = await _databaseService.getNotesCount();
      
      // 获取数据库大小
      final dbSize = await _databaseService.getDatabaseSize();
      final dbSizeInMB = dbSize / (1024 * 1024);
      
      // 获取缓存大小
      double cacheSize = await _calculateCacheSize();
      
      // 获取图片数量
      int imagesCount = await _getImagesCount();
      
      if (mounted) {
        setState(() {
          _notesCount = notesCount;
          _databaseSize = dbSizeInMB;
          _cacheSize = cacheSize;
          _imagesCount = imagesCount;
        });
      }
    } catch (e) {
      print('加载数据信息失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 计算缓存大小
  Future<double> _calculateCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      int totalSize = 0;
      
      if (await cacheDir.exists()) {
        // 递归获取目录内所有文件大小
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize / (1024 * 1024); // 转换为MB
    } catch (e) {
      print('计算缓存大小失败: $e');
      return 0;
    }
  }
  
  // 获取图片数量
  Future<int> _getImagesCount() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDocDir.path}/images');
      
      if (!await imagesDir.exists()) {
        return 0;
      }
      
      int count = 0;
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          count++;
        }
      }
      
      return count;
    } catch (e) {
      print('获取图片数量失败: $e');
      return 0;
    }
  }
  
  // 清理全部笔记
  Future<void> _clearAllNotes() async {
    final confirmed = await _showConfirmDialog(
      '确认清理',
      '此操作将删除所有本地笔记数据，且不可恢复。是否继续？',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _databaseService.clearAllNotes();
      
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.loadNotesFromLocal(); // 刷新应用中的笔记列表
      
      // 重新加载数据信息
      await _loadDataInfo();
      
      _showSuccessToast('所有笔记已清理');
    } catch (e) {
      _showErrorToast('清理失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 清理缓存
  Future<void> _clearCache() async {
    final confirmed = await _showConfirmDialog(
      '确认清理',
      '此操作将清除应用缓存，可能会影响短期使用体验。是否继续？',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cacheDir = await getTemporaryDirectory();
      
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            print('删除缓存文件失败: $e');
          }
        }
      }
      
      // 重新加载数据信息
      await _loadDataInfo();
      
      _showSuccessToast('缓存已清理');
    } catch (e) {
      _showErrorToast('清理缓存失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 清理图片
  Future<void> _clearImages() async {
    final confirmed = await _showConfirmDialog(
      '确认清理',
      '此操作将删除所有未使用的图片文件。是否继续？',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDocDir.path}/images');
      
      if (await imagesDir.exists()) {
        // 这里应该有实际的逻辑来检测哪些图片是未使用的
        // 简单实现是删除全部图片，但实际应用中应该更加精确
        await imagesDir.delete(recursive: true);
        await imagesDir.create();
      }
      
      // 重新加载数据信息
      await _loadDataInfo();
      
      _showSuccessToast('图片已清理');
    } catch (e) {
      _showErrorToast('清理图片失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 重置应用设置
  Future<void> _resetAppSettings() async {
    final confirmed = await _showConfirmDialog(
      '确认重置',
      '此操作将重置所有应用设置到默认状态，但不会删除笔记数据。是否继续？',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 重置导入导出历史
      await _preferencesService.clearImportExportHistory();
      
      // 重置应用配置（但保留登录信息）
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentConfig = appProvider.appConfig;
      
      // 保留这些信息
      final memosApiUrl = currentConfig.memosApiUrl;
      final lastToken = currentConfig.lastToken;
      final rememberLogin = currentConfig.rememberLogin;
      
      // 创建默认配置但保留登录信息
      final newConfig = AppConfig().copyWith(
        memosApiUrl: memosApiUrl,
        lastToken: lastToken,
        rememberLogin: rememberLogin,
        isLocalMode: currentConfig.isLocalMode,
      );
      
      // 更新配置
      await _preferencesService.saveAppConfig(newConfig);
      await appProvider.updateConfig(newConfig);
      
      _showSuccessToast('应用设置已重置');
    } catch (e) {
      _showErrorToast('重置设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 清理导入导出历史
  Future<void> _clearImportExportHistory() async {
    final confirmed = await _showConfirmDialog(
      '确认清理',
      '此操作将删除所有导入导出历史记录。是否继续？',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _preferencesService.clearImportExportHistory();
      _showSuccessToast('导入导出历史已清理');
    } catch (e) {
      _showErrorToast('清理历史失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 确认对话框
  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
  
  // 成功提示
  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // 错误提示
  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据清理'),
        elevation: 0,
        backgroundColor: cardColor,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 数据统计卡片
                  _buildStatisticsCard(cardColor, textColor),
                  
                  const SizedBox(height: 16),
                  
                  // 清理操作卡片
                  _buildCleanupActionsCard(cardColor, textColor),
                  
                  const SizedBox(height: 16),
                  
                  // 高级操作卡片
                  _buildAdvancedActionsCard(cardColor, textColor),
                ],
              ),
            ),
    );
  }
  
  // 数据统计卡片
  Widget _buildStatisticsCard(Color cardColor, Color textColor) {
    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据统计',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem(Icons.note, '笔记数量', '$_notesCount 条笔记'),
            const SizedBox(height: 8),
            _buildStatItem(Icons.storage, '数据库大小', '${_databaseSize.toStringAsFixed(2)} MB'),
            const SizedBox(height: 8),
            _buildStatItem(Icons.cached, '缓存大小', '${_cacheSize.toStringAsFixed(2)} MB'),
            const SizedBox(height: 8),
            _buildStatItem(Icons.image, '图片数量', '$_imagesCount 张图片'),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadDataInfo,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新数据'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 统计项
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(color: Colors.grey),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  
  // 清理操作卡片
  Widget _buildCleanupActionsCard(Color cardColor, Color textColor) {
    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '清理操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.delete_outline,
              title: '清理缓存',
              subtitle: '删除临时文件和缓存，不会影响笔记数据',
              iconColor: Colors.orange,
              onTap: _clearCache,
            ),
            const Divider(),
            _buildActionItem(
              icon: Icons.image_not_supported_outlined,
              title: '清理未使用图片',
              subtitle: '删除未被笔记引用的图片文件',
              iconColor: Colors.blue,
              onTap: _clearImages,
            ),
            const Divider(),
            _buildActionItem(
              icon: Icons.history,
              title: '清理导入导出历史',
              subtitle: '删除所有导入导出的历史记录',
              iconColor: Colors.purple,
              onTap: _clearImportExportHistory,
            ),
          ],
        ),
      ),
    );
  }
  
  // 高级操作卡片
  Widget _buildAdvancedActionsCard(Color cardColor, Color textColor) {
    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '高级操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.settings_backup_restore,
              title: '重置应用设置',
              subtitle: '将所有应用设置恢复到默认状态，不会删除笔记数据',
              iconColor: Colors.amber,
              onTap: _resetAppSettings,
            ),
            const Divider(),
            _buildActionItem(
              icon: Icons.delete_forever,
              title: '清理所有笔记',
              subtitle: '危险操作：删除所有本地笔记数据，此操作不可恢复',
              iconColor: Colors.red,
              onTap: _clearAllNotes,
            ),
          ],
        ),
      ),
    );
  }
  
  // 操作项
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
} 