import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement_model.dart';
import '../themes/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final VersionInfo versionInfo;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    
    return Dialog(
      backgroundColor: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部更新图标
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_outlined,
                    color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '发现新版本 ${versionInfo.versionName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前版本: $currentVersion',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 更新内容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '更新内容',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                // 使用ListView.builder避免列表过长
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: versionInfo.releaseNotes.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              versionInfo.releaseNotes[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 是否强制更新提示
                if (versionInfo.forceUpdate)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode ? Colors.red.shade800.withOpacity(0.3) : Colors.red.shade100,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '此为重要更新，必须更新后才能继续使用',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // 底部按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // 仅当非强制更新时才显示"稍后更新"按钮
                if (!versionInfo.forceUpdate)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '稍后更新',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                if (!versionInfo.forceUpdate)
                  const SizedBox(width: 12),
                  
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 检测平台并打开相应URL
                      final isAndroid = Theme.of(context).platform == TargetPlatform.android;
                      final url = isAndroid
                          ? versionInfo.downloadUrls['android']
                          : versionInfo.downloadUrls['ios'];
                      
                      if (url != null) {
                        launchUrl(Uri.parse(url));
                      }
                      
                      if (!versionInfo.forceUpdate) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '立即更新',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 