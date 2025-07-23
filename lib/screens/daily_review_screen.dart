import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/app_provider.dart';
import '../models/note_model.dart';
import '../themes/app_theme.dart';
import '../widgets/sidebar.dart';

class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Note> _notesForSelectedDate = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    _filterNotesByDate();
  }
  
  void _filterNotesByDate() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final allNotes = appProvider.notes;
    
    // 找出选定日期的笔记
    final filteredNotes = allNotes.where((note) {
      final noteDate = note.createdAt;
      return noteDate.year == _selectedDate.year &&
             noteDate.month == _selectedDate.month &&
             noteDate.day == _selectedDate.day;
    }).toList();
    
    setState(() {
      _notesForSelectedDate = filteredNotes;
    });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _filterNotesByDate();
    }
  }
  
  // 处理标签和Markdown内容
  Widget _buildContent(String content) {
    // 首先处理标签
    final RegExp tagRegex = RegExp(r'#([\p{L}\p{N}_\u4e00-\u9fff]+)', unicode: true);
    final List<String> parts = content.split(tagRegex);
    final matches = tagRegex.allMatches(content);
    
    List<Widget> contentWidgets = [];
    int matchIndex = 0;

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        // 非标签部分用Markdown渲染
        contentWidgets.add(
          MarkdownBody(
            data: parts[i],
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
              ),
              h1: const TextStyle(
                fontSize: 22,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
              h2: const TextStyle(
                fontSize: 20,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
              h3: const TextStyle(
                fontSize: 18,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
              // 使用monospace字体渲染代码块
              code: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
                backgroundColor: Color(0xFFF5F5F5),
                fontFamily: 'monospace',
              ),
              blockquote: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }
      
      // 添加标签
      if (matchIndex < matches.length && i < parts.length - 1) {
        final tag = matches.elementAt(matchIndex).group(1)!;
        contentWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF3FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        matchIndex++;
      }
    }

    return Wrap(
      children: contentWidgets,
      spacing: 2,
      runSpacing: 4,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 2,
                  color: textColor,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: 2,
                  color: textColor,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 2,
                  color: textColor,
                ),
              ],
            ),
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () => _selectDate(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateFormat.format(_selectedDate),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.calendar_today,
                color: textColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
      drawer: const Sidebar(),
      body: _notesForSelectedDate.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  '这一天还没有笔记',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _notesForSelectedDate.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final note = _notesForSelectedDate[index];
              final timeFormat = DateFormat('HH:mm');
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push('/note/${note.id}', extra: note),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContent(note.content),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(note.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
} 