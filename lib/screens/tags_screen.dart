import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/app_provider.dart';
import '../models/note_model.dart';
import '../themes/app_theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/note_editor.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  String? _selectedTag;
  List<Note> _notesWithTag = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    print('TagsScreen: initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('TagsScreen: 开始刷新笔记');
      _refreshNotes();
      
      // 进入标签页时自动扫描标签，解决首次进入无标签的问题
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.getAllTags().isEmpty) {
        _scanAllNoteTags();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听AppProvider的变化
    final appProvider = Provider.of<AppProvider>(context);
    print('TagsScreen: didChangeDependencies - 笔记总数: ${appProvider.notes.length}, 标签总数: ${appProvider.getAllTags().length}');
    
    // 每次AppProvider变化时都重新加载标签
    _refreshNotes();
  }

  void _refreshNotes() {
    print('TagsScreen: _refreshNotes');
    // 如果有选中的标签，重新过滤
    if (_selectedTag != null) {
      print('TagsScreen: 刷新标签: $_selectedTag');
      _filterNotesByTag(_selectedTag!);
    }
  }
  
  // 扫描笔记并更新所有标签
  Future<void> _scanAllNoteTags() async {
    print('TagsScreen: 开始扫描并更新所有笔记标签');
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // 显示加载中对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('正在扫描所有笔记中的标签...'),
          ],
        ),
      ),
    );
    
    try {
      // 调用AppProvider的方法扫描所有笔记的标签
      await appProvider.refreshAllNoteTagsWithDatabase();
      
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        
        // 重新加载标签
        _refreshNotes();
        
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('标签扫描完成'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('标签扫描失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _selectTag(String tag) {
    print('TagsScreen: 选择标签: $tag');
    setState(() {
      _selectedTag = tag;
    });
    _filterNotesByTag(tag);
  }
  
  void _filterNotesByTag(String tag) {
    print('TagsScreen: 过滤笔记 - 标签: $tag');
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final allNotes = appProvider.notes;
    print('TagsScreen: 全部笔记数量: ${allNotes.length}');
    
    final filteredNotes = allNotes.where((note) {
      print('TagsScreen: 检查笔记 ${note.id} - 标签: ${note.tags.join(', ')}');
      return note.tags.contains(tag);
    }).toList();
    
    print('TagsScreen: 过滤后笔记数量: ${filteredNotes.length}');
    setState(() {
      _notesWithTag = filteredNotes;
    });
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
  
  // 显示编辑笔记表单
  void _showEditNoteForm(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => NoteEditor(
        initialContent: note.content,
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              await appProvider.updateNote(note, content);
              print('TagsScreen: 笔记更新成功');
              
              // 确保所有监听者都收到更新通知
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appProvider.notifyListeners();
              });
              
              // 如果当前有选中的标签，重新过滤笔记
              if (_selectedTag != null) {
                _filterNotesByTag(_selectedTag!);
              }
            } catch (e) {
              print('TagsScreen: 更新笔记失败: $e');
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
    ).then((_) {
      print('TagsScreen: 编辑笔记表单已关闭');
    });
  }
  
  // 显示笔记操作菜单
  void _showNoteOptions(Note note) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 编辑选项
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: Text('编辑笔记', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              _showEditNoteForm(note);
            },
          ),
          
          // 查看详情选项
          ListTile(
            leading: const Icon(Icons.visibility, color: Colors.green),
            title: Text('查看详情', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              context.push('/note/${note.id}', extra: note);
            },
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    print('TagsScreen: build开始');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final tagSelectedBgColor = isDarkMode ? Color(0xFF1E3A5F) : const Color(0xFFEDF3FF);
    final tagSelectedTextColor = isDarkMode ? Color(0xFF82B1FF) : Colors.blue;
    final tagBorderColor = isDarkMode ? Colors.blue.withOpacity(0.3) : Colors.grey.shade300;
    final tagUnselectedBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final tags = appProvider.getAllTags().toList()..sort();
        print('TagsScreen: 标签数量: ${tags.length}, 标签列表: ${tags.join(', ')}');
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: backgroundColor,
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
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Text(
              '全部标签',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 18.0,
              ),
            ),
            centerTitle: true,
            actions: [
              // 用刷新图标替换标签图标
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                tooltip: '扫描所有笔记的标签',
                onPressed: _scanAllNoteTags,
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: const Sidebar(),
          body: Column(
            children: [
              // 标签列表
              Container(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final isSelected = tag == _selectedTag;
                    return InkWell(
                      onTap: () {
                        if (isSelected) {
                          setState(() {
                            _selectedTag = null;
                            _notesWithTag = [];
                          });
                        } else {
                          _selectTag(tag);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : (isDarkMode ? AppTheme.darkCardColor : Colors.white),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : tagBorderColor,
                            width: isSelected ? 1 : 0.5,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : textColor,
                            fontSize: 13.0,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // 笔记列表
              Expanded(
                child: _selectedTag == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '选择一个标签以查看相关笔记',
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _notesWithTag.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '没有找到带有 #$_selectedTag 标签的笔记',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _notesWithTag.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final note = _notesWithTag[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: cardColor,
                                  elevation: 1.0,
                                  child: InkWell(
                                    onTap: () => context.push('/note/${note.id}', extra: note),
                                    onLongPress: () => _showNoteOptions(note),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 时间显示和操作按钮
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${note.createdAt.year}年${note.createdAt.month}月${note.createdAt.day}日 ${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                              // 添加编辑按钮
                                              IconButton(
                                                icon: Icon(Icons.edit, size: 18, color: iconColor),
                                                onPressed: () => _showEditNoteForm(note),
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          
                                          // 笔记内容
                                          _buildContent(note.content),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
} 