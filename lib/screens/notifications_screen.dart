import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/announcement_model.dart';
import '../themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 页面加载后立即刷新未读通知数量
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AppProvider>(context, listen: false).refreshUnreadAnnouncementsCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
        actions: [
          // 将刷新按钮改为全部已读按钮
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _isLoading ? null : () => _markAllAsRead(context),
            tooltip: '全部已读',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final announcements = appProvider.announcements;
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无通知',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshAnnouncements(context),
            child: ListView.builder(
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return FutureBuilder<bool>(
                  future: appProvider.isAnnouncementRead(announcement.id),
                  builder: (context, snapshot) {
                    final isRead = snapshot.data ?? false;
                    return _buildAnnouncementCard(
                      context,
                      announcement,
                      isRead,
                      isDarkMode,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Announcement announcement,
    bool isRead,
    bool isDarkMode,
  ) {
    final backgroundColor = isDarkMode
        ? isRead
            ? AppTheme.darkCardColor
            : AppTheme.darkCardColor.withOpacity(0.8)
        : isRead
            ? Colors.white
            : Colors.blue.shade50;

    final titleColor = isDarkMode
        ? isRead
            ? AppTheme.darkTextPrimaryColor
            : Colors.blue.shade200
        : isRead
            ? AppTheme.textPrimaryColor
            : Colors.blue.shade700;

    final contentColor = isDarkMode
        ? isRead
            ? AppTheme.darkTextSecondaryColor
            : AppTheme.darkTextPrimaryColor
        : isRead
            ? AppTheme.textSecondaryColor
            : AppTheme.textPrimaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      elevation: isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead
            ? BorderSide.none
            : BorderSide(
                color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200,
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: () => _showAnnouncementDetails(context, announcement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAnnouncementIcon(announcement.type),
                    color: titleColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue.shade900
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '未读',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 14,
                  color: contentColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(announcement.publishDate),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? Colors.white38
                      : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAnnouncementIcon(String type) {
    switch (type) {
      case 'update':
        return Icons.system_update_outlined;
      case 'info':
        return Icons.info_outline;
      case 'event':
        return Icons.event_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshAnnouncements(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.refreshAnnouncements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('刷新通知失败，请检查网络连接'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.markAllAnnouncementsAsRead();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已将所有通知标记为已读'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('操作失败，请稍后重试'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAnnouncementDetails(BuildContext context, Announcement announcement) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getAnnouncementIcon(announcement.type),
                    color: isDarkMode
                        ? AppTheme.darkTextPrimaryColor
                        : AppTheme.textPrimaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? AppTheme.darkTextSecondaryColor
                      : AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDate(announcement.publishDate),
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
              if (announcement.actionUrls != null &&
                  announcement.actionUrls!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? AppTheme.primaryLightColor
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final isAndroid =
                            Theme.of(context).platform == TargetPlatform.android;
                        final url = isAndroid
                            ? announcement.actionUrls!['android']
                            : announcement.actionUrls!['ios'];

                        if (url != null) {
                          launchUrl(Uri.parse(url));
                        }

                        Navigator.pop(context);
                      },
                      child: Text(
                        announcement.type == 'update' ? '立即更新' : '查看详情',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // 标记为已读
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.markAnnouncementAsRead(announcement.id);
  }
} 