import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AnnouncementService {
  static const String _baseUrl = 'https://gitee.com/yyyyymmmmm/inkroot/raw/master';
  static const String _announcementsUrl = '$_baseUrl/announcements.json';
  static const String _lastViewedKey = 'last_viewed_announcements';
  static const String _lastCheckedKey = 'last_checked_version';

  // 获取公告和版本信息
  Future<AnnouncementResponse?> fetchAnnouncements() async {
    try {
      final response = await http.get(Uri.parse(_announcementsUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnnouncementResponse.fromJson(data);
      } else {
        print('获取公告失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取公告异常: $e');
      return null;
    }
  }

  // 检查是否有新版本
  Future<(VersionInfo?, bool)> checkForUpdates() async {
    try {
      // 获取当前应用版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final announcementResponse = await fetchAnnouncements();
      if (announcementResponse == null) {
        return (null, false);
      }
      
      final versionInfo = announcementResponse.versionInfo;
      final hasUpdate = versionInfo.needsUpdate(currentVersion);
      
      return (versionInfo, hasUpdate);
    } catch (e) {
      print('检查更新异常: $e');
      return (null, false);
    }
  }
  
  // 标记公告为已读
  Future<void> markAnnouncementAsRead(String announcementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedAnnouncements = prefs.getStringList(_lastViewedKey) ?? [];
      
      if (!viewedAnnouncements.contains(announcementId)) {
        viewedAnnouncements.add(announcementId);
        await prefs.setStringList(_lastViewedKey, viewedAnnouncements);
      }
    } catch (e) {
      print('标记公告已读异常: $e');
    }
  }
  
  // 检查公告是否已读
  Future<bool> isAnnouncementRead(String announcementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedAnnouncements = prefs.getStringList(_lastViewedKey) ?? [];
      
      return viewedAnnouncements.contains(announcementId);
    } catch (e) {
      print('检查公告是否已读异常: $e');
      return false;
    }
  }
  
  // 获取未读通知数量
  Future<int> getUnreadAnnouncementsCount() async {
    try {
      final announcementResponse = await fetchAnnouncements();
      if (announcementResponse == null) {
        return 0;
      }
      
      int unreadCount = 0;
      for (final announcement in announcementResponse.announcements) {
        // 只统计通知类型的消息
        if (announcement.type != 'update' && !await isAnnouncementRead(announcement.id)) {
          unreadCount++;
        }
      }
      
      return unreadCount;
    } catch (e) {
      print('获取未读通知数量异常: $e');
      return 0;
    }
  }

  // 标记所有通知为已读
  Future<void> markAllAnnouncementsAsRead() async {
    try {
      final announcementResponse = await fetchAnnouncements();
      if (announcementResponse == null) {
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final viewedAnnouncements = prefs.getStringList(_lastViewedKey) ?? [];
      
      for (final announcement in announcementResponse.announcements) {
        if (!viewedAnnouncements.contains(announcement.id)) {
          viewedAnnouncements.add(announcement.id);
        }
      }
      
      await prefs.setStringList(_lastViewedKey, viewedAnnouncements);
    } catch (e) {
      print('标记所有通知已读异常: $e');
    }
  }

  // 判断是否显示更新提示
  Future<bool> shouldShowUpdatePrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckedString = prefs.getString(_lastCheckedKey);
      
      // 如果从未检查过，显示更新提示
      if (lastCheckedString == null) {
        await prefs.setString(_lastCheckedKey, DateTime.now().toIso8601String());
        return true;
      }
      
      final lastChecked = DateTime.parse(lastCheckedString);
      final difference = DateTime.now().difference(lastChecked);
      
      // 如果距离上次检查超过12小时，则显示更新提示
      if (difference.inHours >= 12) {
        // 获取当前版本信息
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        
        // 获取最新版本信息
        final announcementResponse = await fetchAnnouncements();
        if (announcementResponse == null) {
          return false;
        }
        
        final versionInfo = announcementResponse.versionInfo;
        
        // 检查是否需要更新
        final hasUpdate = versionInfo.needsUpdate(currentVersion);
        
        // 如果有更新或强制更新，就显示提示
        if (hasUpdate || versionInfo.forceUpdate) {
          // 更新最后检查时间
          await prefs.setString(_lastCheckedKey, DateTime.now().toIso8601String());
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('判断是否显示更新提示异常: $e');
      return false;
    }
  }
} 