import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/note_model.dart';
import '../themes/app_theme.dart';

class Heatmap extends StatelessWidget {
  final List<Note> notes;
  final Color? cellColor;
  final Color activeColor;
  final DateFormat _dateFormat = DateFormat('yyyy年M月');
  final DateFormat _fullDateFormat = DateFormat('yyyy年MM月dd日');
  final DateFormat _keyDateFormat = DateFormat('yyyy-MM-dd');

  // 热力图颜色定义 - 从浅到深
  static const List<Color> lightModeColors = [
    Color(0xFFEBEDF0), // 灰色 - 无活动
    Color(0xFFE3F5E8), // 非常浅的绿色 - 级别1
    Color(0xFFCCECD4), // 浅绿色 - 级别2
    Color(0xFFA8DFBA), // 中浅绿色 - 级别3
    Color(0xFF7ECDA0), // 中绿色 - 级别4
  ];
  
  // 深色模式下的热力图颜色
  static const List<Color> darkModeColors = [
    Color(0xFF2C2C2C), // 深灰色 - 无活动
    Color(0xFF1A3B2D), // 非常深的绿色 - 级别1
    Color(0xFF204836), // 深绿色 - 级别2
    Color(0xFF275C42), // 中深绿色 - 级别3
    Color(0xFF306E4F), // 中绿色 - 级别4
  ];

  Heatmap({
    super.key,
    required this.notes,
    this.cellColor,
    this.activeColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前主题模式
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    
    // 生成一个更可靠的key，同时考虑笔记数量和最近的更新时间
    final latestUpdateTime = notes.isEmpty 
        ? DateTime.now().millisecondsSinceEpoch 
        : notes.map((note) => note.updatedAt.millisecondsSinceEpoch).reduce((max, time) => time > max ? time : max);
    
    final uniqueKey = ValueKey('heatmap-${notes.length}-$latestUpdateTime');
    
    final Map<String, int> dailyCounts = _calculateDailyCounts();
    int maxCount = dailyCounts.values.fold(0, (max, count) => count > max ? count : max);
    final List<DateTime> dates = _generateMonthDates();
    
    // 计算单个格子的大小和间距
    final double cellSize = 12.0; // 更小的格子
    final double spacing = 4.0; // 更大的间距

    return Column(
      key: uniqueKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份标题
        Text(
          _dateFormat.format(DateTime.now()),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        
        // 热力图网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final dateKey = _keyDateFormat.format(date);
            final count = dailyCounts[dateKey] ?? 0;
            final isCurrentMonth = date.month == DateTime.now().month;
            
            return Tooltip(
              message: '${_fullDateFormat.format(date)}: $count条笔记',
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: isCurrentMonth 
                      ? _getHeatmapColor(count, maxCount, isDarkMode)
                      : (cellColor ?? (isDarkMode ? darkModeColors[0] : lightModeColors[0])).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6), // 更圆滑的圆角
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // 星期标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['一', '二', '三', '四', '五', '六', '日'].map((day) => 
            SizedBox(
              width: cellSize,
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 10,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ).toList(),
        ),
        
        // 添加颜色说明
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '活跃度: ',
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
            ...List.generate(4, (index) {
              final colors = isDarkMode ? darkModeColors : lightModeColors;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colors[index + 1],
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
  
  Map<String, int> _calculateDailyCounts() {
    Map<String, int> result = {};
    
    // 预先填充本月的所有日期，确保它们至少有0的值
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      final dateStr = _keyDateFormat.format(date);
      result[dateStr] = 0;
    }
    
    // 同时考虑创建日期和更新日期来计算每天的笔记活动
    for (var note in notes) {
      // 记录创建日期的笔记
      final createDateStr = _keyDateFormat.format(note.createdAt);
      if (note.createdAt.month == now.month && note.createdAt.year == now.year) {
        result[createDateStr] = (result[createDateStr] ?? 0) + 1;
      }
      
      // 如果更新日期与创建日期不同，且在当月，也计入活动
      final updateDateStr = _keyDateFormat.format(note.updatedAt);
      if (note.updatedAt != note.createdAt && 
          note.updatedAt.month == now.month && 
          note.updatedAt.year == now.year) {
        result[updateDateStr] = (result[updateDateStr] ?? 0) + 1;
      }
    }
    
    return result;
  }
  
  List<DateTime> _generateMonthDates() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    // 计算第一天之前需要填充的天数（从周一开始）
    int firstWeekday = firstDayOfMonth.weekday;
    final firstDate = firstDayOfMonth.subtract(Duration(days: firstWeekday - 1));
    
    // 计算最后一天之后需要填充的天数（到周日结束）
    int lastWeekday = lastDayOfMonth.weekday;
    final daysToAdd = 7 - lastWeekday;
    final lastDate = lastDayOfMonth.add(Duration(days: daysToAdd));
    
    final List<DateTime> dates = [];
    DateTime currentDate = firstDate;
    
    // 生成包含完整周的日期列表
    while (!currentDate.isAfter(lastDate)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  Color _getHeatmapColor(int count, int maxCount, bool isDarkMode) {
    final colors = isDarkMode ? darkModeColors : lightModeColors;
    
    // 无活动返回灰色
    if (count == 0) {
      return cellColor ?? colors[0];
    }
    
    // 计算颜色级别
    int level;
    if (maxCount <= 1) {
      // 如果最大值是1，则直接使用第一个颜色
      level = 1;
    } else if (count == maxCount) {
      // 如果是最大值，使用最深的颜色
      level = colors.length - 1;
    } else {
      // 使用线性比例计算颜色级别
      double ratio = count / maxCount;
      level = (ratio * (colors.length - 2)).round() + 1;
    }
    
    // 确保级别在有效范围内
    level = level.clamp(1, colors.length - 1);
    return colors[level];
  }
} 