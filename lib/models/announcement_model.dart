import 'package:flutter/foundation.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // update, info, event, warning
  final DateTime publishDate;
  final DateTime? expiryDate;
  final String? version;
  final List<String>? updateNotes;
  final Map<String, String>? actionUrls;
  final bool? isForceUpdate;
  final String? imageUrl;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.publishDate,
    this.expiryDate,
    this.version,
    this.updateNotes,
    this.actionUrls,
    this.isForceUpdate,
    this.imageUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      publishDate: DateTime.parse(json['publishDate']),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      version: json['version'],
      updateNotes: json['updateNotes'] != null 
          ? List<String>.from(json['updateNotes']) 
          : null,
      actionUrls: json['actionUrls'] != null 
          ? Map<String, String>.from(json['actionUrls'])
          : null,
      isForceUpdate: json['isForceUpdate'],
      imageUrl: json['imageUrl'],
    );
  }
}

class VersionInfo {
  final String versionName;
  final int versionCode;
  final String minRequiredVersion;
  final Map<String, String> downloadUrls;
  final List<String> releaseNotes;
  final bool forceUpdate;

  VersionInfo({
    required this.versionName,
    required this.versionCode,
    required this.minRequiredVersion,
    required this.downloadUrls,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      versionName: json['versionName'],
      versionCode: json['versionCode'],
      minRequiredVersion: json['minRequiredVersion'],
      downloadUrls: Map<String, String>.from(json['downloadUrls']),
      releaseNotes: List<String>.from(json['releaseNotes']),
      forceUpdate: json['forceUpdate'],
    );
  }

  // 检查是否需要更新
  bool needsUpdate(String currentVersion) {
    // 移除版本号中的任何非数字和点的字符
    final cleanCurrent = currentVersion.replaceAll(RegExp(r'[^\d.]'), '');
    final cleanVersion = versionName.replaceAll(RegExp(r'[^\d.]'), '');
    
    // 比较版本号
    final currentParts = cleanCurrent.split('.').map(int.parse).toList();
    final versionParts = cleanVersion.split('.').map(int.parse).toList();
    
    // 确保两个列表长度相同
    while (currentParts.length < versionParts.length) {
      currentParts.add(0);
    }
    while (versionParts.length < currentParts.length) {
      versionParts.add(0);
    }
    
    // 逐位比较
    for (int i = 0; i < currentParts.length; i++) {
      if (versionParts[i] > currentParts[i]) {
        return true;
      } else if (versionParts[i] < currentParts[i]) {
        return false;
      }
    }
    
    return false; // 版本相同
  }
}

class AnnouncementResponse {
  final List<Announcement> announcements;
  final VersionInfo versionInfo;

  AnnouncementResponse({
    required this.announcements,
    required this.versionInfo,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      announcements: (json['announcements'] as List)
          .map((item) => Announcement.fromJson(item))
          .toList(),
      versionInfo: VersionInfo.fromJson(json['versionInfo']),
    );
  }
} 