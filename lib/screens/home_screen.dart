import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../models/note_model.dart';
import '../models/sort_order.dart';
import '../themes/app_theme.dart';
import '../widgets/note_editor.dart';
import '../widgets/sidebar.dart';
import '../widgets/note_card.dart';
import '../widgets/progress_overlay.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  List<Note> _searchResults = [];
  bool _isRefreshing = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    
    // 在页面加载完成后异步检查更新和通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _refreshNotifications();
    });
  }
  
  // 异步检查更新
  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // 异步检查更新，不阻塞UI
    appProvider.checkForUpdatesOnStartup().then((_) {
      if (mounted) {
        appProvider.showUpdateDialogIfNeeded(context);
      }
    });
  }
  
  // 刷新通知数据
  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // 异步刷新通知数量，不阻塞UI
    appProvider.refreshUnreadAnnouncementsCount();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeApp() async {
    if (!mounted) return;
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (!appProvider.isInitialized) {
      await appProvider.initializeApp();
    }
  }
  
  // 刷新笔记数据
  Future<void> _refreshNotes() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // 如果已登录且不是本地模式，从服务器获取笔记
      if (appProvider.isLoggedIn && !appProvider.isLocalMode) {
        await appProvider.fetchNotesFromServer();
      } else {
        // 本地模式下只重新加载本地数据
        await appProvider.loadNotesFromLocal();
      }
      
      // 显示刷新成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('刷新成功'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('HomeScreen: 刷新失败: $e');
      // 显示刷新失败提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  
  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
  
  // 显示添加笔记表单
  void _showAddNoteForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => NoteEditor(
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final note = await appProvider.createNote(content);
              print('HomeScreen: 笔记创建成功');
              
              // 如果用户已登录但笔记未同步，尝试再次同步
              if (appProvider.isLoggedIn && !note.isSynced) {
                appProvider.syncNotesWithServer();
              }
            } catch (e) {
              print('HomeScreen: 创建笔记失败: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('创建失败: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        },
      ),
    ).then((_) {
      print('HomeScreen: 创建笔记表单已关闭');
    });
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
              print('HomeScreen: 笔记更新成功');
              
              // 确保标签更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appProvider.notifyListeners(); // 通知所有监听者，确保标签页更新
              });
            } catch (e) {
              print('HomeScreen: 更新笔记失败: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('更新失败: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        },
      ),
    ).then((_) {
      print('HomeScreen: 编辑笔记表单已关闭');
    });
  }

  // 构建通知提示框
  Widget _buildNotificationBanner() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context);
    
    // 如果没有未读通知，则不显示通知栏
    if (appProvider.unreadAnnouncementsCount <= 0) {
      return const SizedBox.shrink();
    }
    
    // 设置颜色
    final backgroundColor = isDarkMode 
        ? AppTheme.primaryColor.withOpacity(0.15) 
        : AppTheme.primaryColor.withOpacity(0.08);
    final borderColor = isDarkMode
        ? AppTheme.primaryLightColor.withOpacity(0.3)
        : AppTheme.primaryColor.withOpacity(0.2);
    final textColor = isDarkMode
        ? AppTheme.primaryLightColor
        : AppTheme.primaryColor;
    final iconColor = isDarkMode
        ? AppTheme.primaryLightColor
        : AppTheme.primaryColor;
        
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // 标记所有通知为已读
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            await appProvider.markAllAnnouncementsAsRead();
            
            // 跳转到通知页面
            if (context.mounted) {
              context.pushNamed('notifications');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.black).withOpacity(isDarkMode ? 0.2 : 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '您有${appProvider.unreadAnnouncementsCount}条通知，请及时查看',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: iconColor,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final cardShadow = AppTheme.neuCardShadow(isDark: isDarkMode);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(60),
              boxShadow: cardShadow,
            ),
            child: Center(
              child: Icon(
                Icons.note_add_rounded,
                size: 48,
                color: iconColor.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有笔记',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右下角的按钮开始创建',
            style: TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSortOrderOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final headerBgColor = isDarkMode 
        ? AppTheme.primaryColor.withOpacity(0.15) 
        : AppTheme.primaryColor.withOpacity(0.05);
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // 获取当前排序方式
    SortOrder currentSortOrder = SortOrder.newest;
    
    // 检查当前排序方式
    if (appProvider.notes.length > 1) {
      if (appProvider.notes[0].createdAt.isAfter(appProvider.notes[1].createdAt)) {
        currentSortOrder = SortOrder.newest;
      } else if (appProvider.notes[0].createdAt.isBefore(appProvider.notes[1].createdAt)) {
        currentSortOrder = SortOrder.oldest;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: headerBgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    '排序方式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              RadioListTile<SortOrder>(
                title: Text(
                  '从新到旧',
                  style: TextStyle(color: textColor),
                ),
                value: SortOrder.newest,
                groupValue: currentSortOrder,
                activeColor: iconColor,
                onChanged: (SortOrder? value) {
                  if (value != null) {
                    appProvider.sortNotes(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<SortOrder>(
                title: Text(
                  '从旧到新',
                  style: TextStyle(color: textColor),
            ),
                value: SortOrder.oldest,
                groupValue: currentSortOrder,
                activeColor: iconColor,
                onChanged: (SortOrder? value) {
                  if (value != null) {
                    appProvider.sortNotes(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
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
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final hintColor = isDarkMode ? Colors.grey[500] : Colors.grey[400];
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Sidebar(),
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
          onPressed: _openDrawer,
        ),
        title: _isSearchActive
          ? Container(
              height: 40,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索笔记...',
                  hintStyle: TextStyle(
                    color: hintColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: iconColor,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: TextStyle(
                  color: textColor,
                ),
                onChanged: (query) {
                  if (query.isEmpty) {
                    setState(() {
                      _searchResults.clear();
                    });
                    return;
                  }
                  
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                  final results = appProvider.notes.where((note) {
                    return note.content.toLowerCase().contains(query.toLowerCase());
                  }).toList();
                  
                  setState(() {
                    _searchResults = results;
                  });
                },
              ),
            )
          : Text(
              '全部笔记',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 18.0,
              ),
            ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isSearchActive ? Icons.close : Icons.search,
                size: 20,
                color: iconColor,
              ),
            ),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _searchResults.clear();
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: iconColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '加载中...',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final notes = _isSearchActive ? _searchResults : appProvider.notes;
          
          return Column(
            children: [
              // 添加通知提示框
              _buildNotificationBanner(),
              
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshNotes,
                      color: AppTheme.primaryColor,
                      child: notes.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height - 200,
                                  child: _buildEmptyState(),
                                ),
                              ],
                            )
                          : ListView.builder(
                        itemCount: notes.length + 1,
                        padding: EdgeInsets.zero,
                        cacheExtent: 500,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        itemBuilder: (context, index) {
                          if (index == notes.length) {
                                  return const SizedBox(height: 120);
                          }
                          
                          final note = notes[index];
                          return RepaintBoundary(
                            child: NoteCard(
                              content: note.content,
                              timestamp: note.updatedAt,
                              tags: note.tags,
                              isPinned: note.isPinned,

                              id: note.id, // Add note ID
                              onEdit: () {
                                print('HomeScreen: 开始编辑笔记 ID: ${note.id}');
                                _showEditNoteForm(note);
                              },
                              onDelete: () async {
                                print('HomeScreen: 准备删除笔记 ID: ${note.id}');
                                try {
                                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                                  await appProvider.deleteNote(note.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('笔记已删除'),
                                        duration: Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('HomeScreen: 删除笔记失败: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('删除失败: $e'),
                                        duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              onPin: () async {
                                final appProvider = Provider.of<AppProvider>(context, listen: false);
                                await appProvider.togglePinStatus(note);
                                      if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                            content: Text(note.isPinned ? '笔记已置顶' : '笔记已取消置顶'),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                      }
                              },
                            ),
                          );
                        },
                      ),
              ),
              
              // 同步进度覆盖层
              ProgressOverlay(
                isVisible: appProvider.isSyncing,
                message: appProvider.syncMessage,
                color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabAnimationController.forward(),
        onTapUp: (_) => _fabAnimationController.reverse(),
        onTapCancel: () => _fabAnimationController.reverse(),
        child: ScaleTransition(
          scale: _fabScaleAnimation,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryLightColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAddNoteForm,
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.white.withOpacity(0.2),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 