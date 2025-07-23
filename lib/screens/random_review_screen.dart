import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/app_provider.dart';
import '../models/note_model.dart';
import '../themes/app_theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/note_editor.dart';

class RandomReviewScreen extends StatefulWidget {
  const RandomReviewScreen({super.key});

  @override
  State<RandomReviewScreen> createState() => _RandomReviewScreenState();
}

class _RandomReviewScreenState extends State<RandomReviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final Random _random = Random();
  
  List<Note> _reviewNotes = [];
  int _currentIndex = 0;
  
  // 回顾设置
  int _reviewDays = 30; // 默认回顾最近30天的笔记
  int _reviewCount = 10; // 默认回顾10条笔记

  @override
  void initState() {
    super.initState();
    
    // 初始化时获取笔记
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviewNotes();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // 加载回顾笔记
  void _loadReviewNotes() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final allNotes = appProvider.notes;
    
    if (allNotes.isEmpty) {
      setState(() {
        _reviewNotes = [];
        _currentIndex = 0;
      });
      return;
    }
    
    // 根据时间范围筛选笔记
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: _reviewDays));
    final filteredNotes = allNotes.where((note) => note.createdAt.isAfter(cutoffDate)).toList();
    
    // 如果筛选后的笔记不足，则使用全部笔记
    List<Note> availableNotes = filteredNotes.isEmpty ? allNotes : filteredNotes;
    
    // 随机选择指定数量的笔记
    List<Note> selectedNotes = [];
    if (availableNotes.length <= _reviewCount) {
      // 如果可用笔记少于请求的数量，全部使用
      selectedNotes = List.from(availableNotes);
    } else {
      // 随机选择笔记
      availableNotes.shuffle(_random);
      selectedNotes = availableNotes.take(_reviewCount).toList();
    }
    
    // 保持当前笔记的位置
    String currentNoteId = _currentIndex < _reviewNotes.length ? _reviewNotes[_currentIndex].id : '';
    int newIndex = selectedNotes.indexWhere((note) => note.id == currentNoteId);
    
    setState(() {
      _reviewNotes = selectedNotes;
      _currentIndex = newIndex != -1 ? newIndex : 0;
    });
  }

  // 显示编辑笔记表单
  void _showEditNoteForm(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: note.content,
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              await appProvider.updateNote(note, content);
              _loadReviewNotes(); // 重新加载笔记
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('更新失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
  
  // 显示设置对话框
  void _showSettingsDialog() {
    int tempDays = _reviewDays;
    int tempCount = _reviewCount;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final accentColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text(
          '回顾设置',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 时间范围设置
            Row(
              children: [
                Text(
                  '回顾时间范围：',
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(width: 8),
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: dialogBgColor,
                  ),
                  child: DropdownButton<int>(
                  value: tempDays,
                  items: [7, 14, 30, 60, 90, 180, 365, 999999]
                      .map((days) => DropdownMenuItem<int>(
                            value: days,
                              child: Text(
                                days == 999999 ? '全部' : '$days天',
                                style: TextStyle(color: textColor),
                              ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      tempDays = value;
                    }
                  },
                    dropdownColor: dialogBgColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 回顾数量设置
            Row(
              children: [
                Text(
                  '回顾笔记数量：',
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(width: 8),
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: dialogBgColor,
                  ),
                  child: DropdownButton<int>(
                  value: tempCount,
                  items: [5, 10, 20, 30, 50, 100]
                      .map((count) => DropdownMenuItem<int>(
                            value: count,
                              child: Text(
                                '$count条',
                                style: TextStyle(color: textColor),
                              ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      tempCount = value;
                    }
                  },
                    dropdownColor: dialogBgColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: accentColor),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _reviewDays = tempDays;
                _reviewCount = tempCount;
              });
              Navigator.pop(context);
              _loadReviewNotes(); // 重新加载笔记
            },
            child: Text(
              '确定',
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  // 处理页面变化
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  // 打开侧边栏
  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
  
  // 处理标签和Markdown内容
  Widget _buildContent(String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Color(0xFF333333);
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Color(0xFF666666);
    final codeBgColor = isDarkMode ? Color(0xFF2C2C2C) : Color(0xFFF5F5F5);
    
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
              p: TextStyle(
                fontSize: 14.0,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
              ),
              h1: TextStyle(
                fontSize: 20.0,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              h2: TextStyle(
                fontSize: 18.0,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              h3: TextStyle(
                fontSize: 16.0,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              code: TextStyle(
                fontSize: 14.0,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                backgroundColor: codeBgColor,
                fontFamily: 'monospace',
              ),
              blockquote: TextStyle(
                fontSize: 14.0,
                height: 1.5,
                letterSpacing: 0.2,
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }
      
      // 添加标签 - 更新为与主页一致的样式
      if (matchIndex < matches.length && i < parts.length - 1) {
        final tag = matches.elementAt(matchIndex).group(1)!;
        contentWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                color: AppTheme.primaryColor,
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
  
  // 显示笔记操作菜单
  void _showNoteOptions(Note note) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final infoBgColor = isDarkMode ? Colors.grey[850] : Colors.grey.shade100;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 80.0),
        backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 编辑选项
            _buildMenuOption(
              title: "编辑",
              onTap: () {
                Navigator.pop(context);
                // 显示编辑器
                _showEditNoteForm(note);
              },
            ),
            
            // 删除选项
            _buildMenuOption(
              title: "删除",
              textColor: Colors.red,
              onTap: () async {
                print('RandomReviewScreen: 准备删除笔记 ID: ${note.id}');
                          Navigator.pop(context); // 关闭菜单对话框
                          
                          try {
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                  
                            // 先删除本地数据
                            print('RandomReviewScreen: 删除本地笔记');
                            await appProvider.deleteNoteLocal(note.id);
                            
                            // 显示正在删除的提示
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('正在删除笔记...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            
                            // 尝试从服务器删除
                            try {
                              if (!appProvider.isLocalMode && appProvider.isLoggedIn) {
                                print('RandomReviewScreen: 从服务器删除笔记');
                                await appProvider.deleteNoteFromServer(note.id);
                              }
                            } catch (e) {
                              print('RandomReviewScreen: 从服务器删除失败，但本地已删除: $e');
                            }
                            
                            print('RandomReviewScreen: 笔记删除成功，刷新列表');
                            // 刷新笔记列表
                            _loadReviewNotes();
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('笔记已删除'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          } catch (e) {
                            print('RandomReviewScreen: 删除笔记失败: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('删除失败: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
              },
            ),
            
            // 底部信息区域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: infoBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "字数统计: ${note.content.length}",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "创建时间: ${DateFormat('yyyy-MM-dd HH:mm').format(note.createdAt)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "最后编辑: ${DateFormat('yyyy-MM-dd HH:mm').format(note.updatedAt)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建菜单选项
  Widget _buildMenuOption({
    required String title, 
    IconData? icon, 
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? defaultTextColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    final bottomInfoBgColor = isDarkMode ? Colors.grey[850] : Colors.grey.shade100;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: const Sidebar(), // 添加侧边栏
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 2,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          onPressed: _openDrawer,
        ),
        centerTitle: true,
        title: Text(
          '随机回顾',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.settings,
                size: 20,
                color: iconColor,
              ),
            ),
            onPressed: _showSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          if (appProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_reviewNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 80,
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有可回顾的笔记',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            itemCount: _reviewNotes.length,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final note = _reviewNotes[index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  color: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 时间显示
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm:ss').format(note.createdAt),
                              style: TextStyle(
                                fontSize: 14.0,
                                color: secondaryTextColor,
                              ),
                            ),
                            InkWell(
                              onTap: () => _showNoteOptions(note),
                              child: Icon(
                                Icons.more_horiz,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 笔记内容
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: _buildContent(note.content),
                          ),
                        ),
                      ),
                      
                      // 底部导航 - 只显示笔记计数
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 当前笔记索引/总数
                            Text(
                              '${index + 1}/${_reviewNotes.length}条笔记',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 