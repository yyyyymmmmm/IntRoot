import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note_model.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/note_editor.dart';
import 'dart:io'; // Added for File

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  final Note? initialNote;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
    this.initialNote,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note? _note;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('NoteDetailScreen: initState');
    _loadNote();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('NoteDetailScreen: didChangeDependencies');
    if (!_isLoading && _note != null) {
      _refreshNoteFromProvider();
    }
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.initialNote != null) {
        _note = widget.initialNote;
      } else {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final databaseService = appProvider.databaseService;
        _note = await databaseService.getNoteById(widget.noteId);
      }
    } catch (e) {
      print('NoteDetailScreen: 加载笔记失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 从Provider刷新笔记数据
  void _refreshNoteFromProvider() {
    if (_note == null) return;
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentNoteId = _note!.id;
    
    // 从provider中查找最新的笔记数据
    final updatedNote = appProvider.notes.firstWhere(
      (note) => note.id == currentNoteId,
      orElse: () => _note!,
    );
    
    // 如果笔记内容有变化，更新状态
    if (updatedNote.content != _note!.content || 
        updatedNote.tags.toString() != _note!.tags.toString()) {
      print('NoteDetailScreen: 发现笔记内容已更新，刷新UI');
      setState(() {
        _note = updatedNote;
      });
    }
  }

  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // 防止点击外部关闭（由NoteEditor内部处理）
      builder: (context) => NoteEditor(
        initialContent: _note?.content,
        onSave: (content) async {
          if (_note != null) {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            await appProvider.updateNote(_note!, content);
            
            // 确保标签更新
            WidgetsBinding.instance.addPostFrameCallback((_) {
              appProvider.notifyListeners(); // 通知所有监听者，确保标签页更新
            });
            
            // 刷新页面
            setState(() {});
          }
        },
      ),
    );
  }

  Future<void> _deleteNote() async {
    print('NoteDetailScreen: 准备删除笔记 ID: ${_note?.id}');
    
    if (_note != null) {
      print('NoteDetailScreen: 执行删除操作');
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        
        // 先删除本地数据
        await appProvider.deleteNoteLocal(_note!.id);
        
        // 显示正在删除的提示
        if (mounted) {
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
            await appProvider.deleteNoteFromServer(_note!.id);
          }
        } catch (e) {
          print('NoteDetailScreen: 从服务器删除失败，但本地已删除: $e');
        }
        
        print('NoteDetailScreen: 笔记删除成功，返回上一页');
        if (mounted) {
          Navigator.pop(context); // 返回上一页
        }
      } catch (e) {
        print('NoteDetailScreen: 删除笔记失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // 如果应用状态发生变化，尝试获取最新的笔记数据
        if (!_isLoading && _note != null) {
          final currentNoteId = _note!.id;
          final latestNote = appProvider.notes.firstWhere(
            (note) => note.id == currentNoteId,
            orElse: () => _note!
          );
          
          // 如果笔记有更新，更新本地状态
          if (latestNote.content != _note!.content || 
              latestNote.tags.toString() != _note!.tags.toString()) {
            print('NoteDetailScreen: build中检测到笔记更新');
            _note = latestNote;
          }
        }
        
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('笔记详情')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('笔记详情')),
            body: const Center(child: Text('笔记不存在')),
          );
        }

        try {
          // 提取图片链接
          List<String> imagePaths = [];
          final RegExp imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
          final imageMatches = imageRegex.allMatches(_note!.content);
          for (var match in imageMatches) {
            final path = match.group(1) ?? '';
            if (path.isNotEmpty) {
              imagePaths.add(path);
            }
          }
          
          // 将图片Markdown代码从内容中移除以避免重复显示
          String contentWithoutImages = _note!.content;
          for (var match in imageMatches) {
            contentWithoutImages = contentWithoutImages.replaceAll(match.group(0) ?? '', '');
          }
          contentWithoutImages = contentWithoutImages.trim();
          bool hasTextContent = contentWithoutImages.isNotEmpty;

          return Scaffold(
            appBar: AppBar(
              title: const Text('笔记详情'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showEditDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteNote,
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 笔记内容 - Markdown渲染
                  if (hasTextContent)
                    _buildRichContent(contentWithoutImages),
                  
                  // 图片布局 - 统一大小的缩略图网格
                  if (imagePaths.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: hasTextContent ? 16.0 : 0),
                      child: _buildUniformImageGrid(imagePaths),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // 标签列表已经在富文本中显示，不再单独显示
                  // if (_note!.tags.isNotEmpty)
                  //  Wrap(
                  //    spacing: 8,
                  //    runSpacing: 8,
                  //    children: _note!.tags.map((tag) {
                  //      return Chip(
                  //        label: Text('#$tag'),
                  //        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  //        labelStyle: const TextStyle(color: AppTheme.primaryColor),
                  //      );
                  //    }).toList(),
                  //  ),
                    
                  const SizedBox(height: 16),
                  
                  // 日期信息
                  Text(
                    '创建于: ${_formatDate(_note!.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '最后修改: ${_formatDate(_note!.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  // 同步状态
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        _note!.isSynced ? Icons.cloud_done : Icons.cloud_off,
                        size: 16,
                        color: _note!.isSynced ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _note!.isSynced ? '已同步' : '未同步',
                        style: TextStyle(
                          fontSize: 14,
                          color: _note!.isSynced ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          print('Error rendering note detail: $e');
          return Scaffold(
            appBar: AppBar(title: const Text('笔记详情')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('加载笔记内容时出错', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _loadNote();
                    },
                    child: Text('重新加载'),
                  ),
                ],
              ),
            ),
          );
        }
      }
    );
  }
  
  // 处理富文本内容，包括Markdown和标签
  Widget _buildRichContent(String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
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
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
              ),
              h1: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              h3: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              code: TextStyle(
                fontSize: 16,
                backgroundColor: codeBgColor,
                color: textColor,
                fontFamily: 'monospace',
              ),
              blockquote: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
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
                fontSize: 15.0,
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
      runSpacing: 8,
    );
  }
  
  // 构建统一大小的图片网格
  Widget _buildUniformImageGrid(List<String> imagePaths) {
    final int imageCount = imagePaths.length > 9 ? 9 : imagePaths.length;
    final double screenWidth = MediaQuery.of(context).size.width;
    // 详情页面图片宽度稍大一些，为屏幕宽度的32%
    final double imageWidth = screenWidth * 0.32;
    // 图片间距
    const double spacing = 8;
    
    try {
      // 每行最多3张图片
      final int columns = imageCount > 3 ? 3 : imageCount;
      // 计算行数
      final int rows = (imageCount / 3).ceil();
      
      return Container(
        width: columns * imageWidth + (columns - 1) * spacing,
        child: Wrap(
          spacing: spacing, // 水平间距
          runSpacing: spacing, // 垂直间距
          children: List.generate(
            imageCount,
            (index) {
              if (index == 8 && imageCount > 9) {
                // 显示+x
                return Container(
                  width: imageWidth,
                  height: imageWidth,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildUniformImageItem(imagePaths[index], disableTap: true),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showAllImages(imagePaths),
                          splashColor: Colors.black.withOpacity(0.3),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+${imageCount - 8}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                width: imageWidth,
                height: imageWidth,
                child: _buildUniformImageItem(imagePaths[index]),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('Error building image grid: $e');
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('无法显示图片', style: TextStyle(color: Colors.grey[700]))),
      );
    }
  }
  
  // 构建统一大小的单个图片项
  Widget _buildUniformImageItem(String imagePath, {bool disableTap = false}) {
    Widget imageWidget = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image(
          image: _getImageProvider(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Image item error: $error for path: $imagePath');
            return Container(
              color: Colors.grey[300],
              child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600])),
            );
          },
        ),
      ),
    );
    
    return disableTap ? 
      imageWidget : 
      GestureDetector(
        onTap: () => _showFullscreenImage(imagePath),
        child: imageWidget,
      );
  }
  
  // 显示全屏图片
  void _showFullscreenImage(String imagePath) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _ImageViewerScreen(imagePath: imagePath),
        ),
      );
    } catch (e) {
      print('Error showing fullscreen image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法显示图片')),
      );
    }
  }
  
  // 显示所有图片
  void _showAllImages(List<String> imagePaths) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _AllImagesScreen(imagePaths: imagePaths),
        ),
      );
    } catch (e) {
      print('Error showing all images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法显示图片')),
      );
    }
  }
  
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  // 根据URI获取适当的ImageProvider
  ImageProvider _getImageProvider(String uriString) {
    try {
      if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
        // 网络图片
        return NetworkImage(uriString);
      } else if (uriString.startsWith('file://')) {
        // 本地文件
        String filePath = uriString.replaceFirst('file://', '');
        return FileImage(File(filePath));
      } else if (uriString.startsWith('resource:')) {
        // 资源图片
        String assetPath = uriString.replaceFirst('resource:', '');
        return AssetImage(assetPath);
      } else {
        // 尝试作为本地文件处理
        try {
          return FileImage(File(uriString));
        } catch (e) {
          print('Error loading file: $e for $uriString');
          // 默认使用资源图片
          return const AssetImage('assets/images/logo.png');
        }
      }
    } catch (e) {
      print('Error in _getImageProvider: $e');
      return const AssetImage('assets/images/logo.png');
    }
  }
}

// 图片查看器页面
class _ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  
  const _ImageViewerScreen({required this.imagePath});
  
  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    try {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        imageProvider = NetworkImage(imagePath);
      } else if (imagePath.startsWith('file://')) {
        String filePath = imagePath.replaceFirst('file://', '');
        imageProvider = FileImage(File(filePath));
      } else if (imagePath.startsWith('resource:')) {
        String assetPath = imagePath.replaceFirst('resource:', '');
        imageProvider = AssetImage(assetPath);
      } else {
        imageProvider = FileImage(File(imagePath));
      }
    } catch (e) {
      print('Error creating image provider: $e');
      imageProvider = AssetImage('assets/images/logo.png');
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image(
              image: imageProvider,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print('Full screen image error: $error');
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    SizedBox(height: 16),
                    Text('无法加载图片', style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(height: 8),
                    Text(imagePath, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// 全部图片页面
class _AllImagesScreen extends StatelessWidget {
  final List<String> imagePaths;
  
  const _AllImagesScreen({required this.imagePaths});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('全部图片 (${imagePaths.length})', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => _ImageViewerScreen(imagePath: imagePaths[index]),
                  ),
                );
              },
              child: _buildGridItem(imagePaths[index]),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildGridItem(String path) {
    ImageProvider imageProvider;
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        imageProvider = NetworkImage(path);
      } else if (path.startsWith('file://')) {
        String filePath = path.replaceFirst('file://', '');
        imageProvider = FileImage(File(filePath));
      } else if (path.startsWith('resource:')) {
        String assetPath = path.replaceFirst('resource:', '');
        imageProvider = AssetImage(assetPath);
      } else {
        imageProvider = FileImage(File(path));
      }
    } catch (e) {
      print('Error creating image provider: $e');
      imageProvider = AssetImage('assets/images/logo.png');
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.grey[800],
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Grid image error: $error for $path');
            return Container(
              color: Colors.grey[800],
              child: Center(child: Icon(Icons.broken_image, color: Colors.grey[400])),
            );
          },
        ),
      ),
    );
  }
} 