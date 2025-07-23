import 'package:intl/intl.dart';

/// 时间工具类，用于处理时间戳转换
class TimeUtils {
  /// 将时间戳转换为DateTime对象
  /// 支持多种格式：毫秒时间戳(int)、ISO字符串(String)
  static DateTime parseTimeStamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    
    // 如果是整数，假设是毫秒时间戳
    if (timestamp is int) {
      // 检查时间戳长度，判断是秒还是毫秒
      if (timestamp.toString().length == 10) {
        // 秒级时间戳
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        // 毫秒级时间戳
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    
    // 如果是字符串，尝试解析
    if (timestamp is String) {
      // 尝试解析ISO格式
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        // 尝试解析数字字符串
        try {
          final numTimestamp = int.parse(timestamp);
          return parseTimeStamp(numTimestamp);
        } catch (e) {
          // 无法解析，返回当前时间
          print('无法解析时间戳: $timestamp');
          return DateTime.now();
        }
      }
    }
    
    // 其他情况，返回当前时间
    return DateTime.now();
  }
  
  /// 格式化DateTime为易读字符串
  static String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }
  
  /// 计算相对时间（例如：3分钟前，2小时前）
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 