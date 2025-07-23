import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mo_ming_notes/models/note_model.dart';
import 'package:mo_ming_notes/themes/app_theme.dart';
import 'dart:ui';
import 'dart:io'; // Added for File

class NoteCard extends StatefulWidget {
  final String content;
  final DateTime timestamp;
  final List<String> tags;
  final bool isPinned;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final String id; // Add id parameter

  const NoteCard({
    Key? key,
    required this.content,
    required this.timestamp,
    required this.tags,
    required this.id, // Add id to constructor
    this.isPinned = false,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
  }) : super(key: key);

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  static const int _maxLines = 6;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  static const TextStyle _contentStyle = TextStyle(
    fontSize: 14.0,
    height: 1.5,
    letterSpacing: 0.2,
    color: AppTheme.textPrimaryColor,
  );
  
  static const TextStyle _timestampStyle = TextStyle(
    fontSize: 12.0,
    color: AppTheme.textTertiaryColor,
  );
  
  static const TextStyle _actionButtonStyle = TextStyle(
    color: AppTheme.primaryColor,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );

  // 处理标签和Markdown内容
  Widget _buildContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    
    // 提取图片链接
    List<String> imagePaths = [];
    final RegExp imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final imageMatches = imageRegex.allMatches(widget.content);
    for (var match in imageMatches) {
      final path = match.group(1) ?? '';
      if (path.isNotEmpty) {
        imagePaths.add(path);
      }
    }
    
    // 将图片Markdown代码从内容中移除
    String contentWithoutImages = widget.content;
    for (var match in imageMatches) {
      contentWithoutImages = contentWithoutImages.replaceAll(match.group(0) ?? '', '');
    }
    contentWithoutImages = contentWithoutImages.trim();
    
    // 检查是否有文本内容
    bool hasTextContent = contentWithoutImages.isNotEmpty;

    // 检查文本是否需要展开按钮
    bool needsExpansion = _contentMightOverflow(contentWithoutImages);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        // 计算图片网格尺寸
        final double spacing = 4.0;
        final double imageWidth = (availableWidth - spacing * 2) / 3;
        final int imageCount = imagePaths.length > 9 ? 9 : imagePaths.length;
        final int rowsNeeded = ((imageCount - 1) ~/ 3 + 1).clamp(0, 3);
        final double gridHeight = rowsNeeded * imageWidth + (rowsNeeded - 1) * spacing;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTextContent)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: _isExpanded ? double.infinity : (6 * _contentStyle.height! * 14.0),
                    ),
                    child: _buildRichContent(contentWithoutImages),
                  ),
                  if (needsExpansion)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isExpanded ? '收起' : '展开',
                              style: TextStyle(
                                color: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
            if (imagePaths.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: hasTextContent ? 8.0 : 0),
                child: SizedBox(
                  width: availableWidth,
                  height: gridHeight,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: imageCount,
                    itemBuilder: (context, index) {
                      if (index == 8 && imagePaths.length > 9) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildUniformImageItem(imagePaths[index]),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showAllImages(imagePaths),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+${imagePaths.length - 8}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _buildUniformImageItem(imagePaths[index]);
                    },
                  ),
                ),
              ),
          ],
        );
      }
    );
  }

  // 检查文本是否可能超过最大行数
  bool _contentMightOverflow(String content) {
    // 根据内容长度和换行符数量估算可能超过的行数
    int newlineCount = '\n'.allMatches(content).length;
    int estimatedLines = (content.length / 40).ceil() + newlineCount; // 假设每行平均40个字符
    return estimatedLines > 6;
  }

  // 构建富文本内容
  Widget _buildRichContent(String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Color(0xFF666666);
    final codeBgColor = isDarkMode ? Color(0xFF2C2C2C) : Color(0xFFF5F5F5);
    
    // 处理标签
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
              p: _contentStyle.copyWith(color: textColor),
              h1: _contentStyle.copyWith(fontSize: 20.0, fontWeight: FontWeight.bold, color: textColor),
              h2: _contentStyle.copyWith(fontSize: 18.0, fontWeight: FontWeight.bold, color: textColor),
              h3: _contentStyle.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: textColor),
              code: _contentStyle.copyWith(
                backgroundColor: codeBgColor,
                color: textColor,
                fontFamily: 'monospace',
              ),
              blockquote: _contentStyle.copyWith(
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            shrinkWrap: true,
            softLineBreak: true,
          ),
        );
      }
      
      // 添加标签
      if (matchIndex < matches.length && i < parts.length - 1) {
        final tag = matches.elementAt(matchIndex).group(1)!;
        contentWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: contentWidgets,
            ),
          ),
        );
      },
    );
  }
  
  // 构建统一大小的图片网格
  Widget _buildUniformImageGrid(List<String> imagePaths) {
    final int imageCount = imagePaths.length > 9 ? 9 : imagePaths.length;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double gridWidth = screenWidth * 0.7;
    
    return SizedBox(
      width: gridWidth,
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: imageCount,
        itemBuilder: (context, index) {
          if (index == 8 && imagePaths.length > 9) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildUniformImageItem(imagePaths[index]),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAllImages(imagePaths),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+${imagePaths.length - 8}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _buildUniformImageItem(imagePaths[index]);
        },
      ),
    );
  }
  
  // 构建统一大小的单个图片项
  Widget _buildUniformImageItem(String imagePath) {
    try {
      return GestureDetector(
        onTap: () => _showFullscreenImage(imagePath),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image(
              image: _getImageProvider(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Image item error: $error for path $imagePath');
                return Center(child: Icon(Icons.broken_image, color: Colors.grey[600]));
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error building image item: $e for path $imagePath');
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600])),
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

  // 显示更多选项菜单
  void _showMoreOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final headerBgColor = isDarkMode 
      ? AppTheme.primaryColor.withOpacity(0.15) 
      : AppTheme.primaryColor.withOpacity(0.05);
    final footerBgColor = isDarkMode ? AppTheme.darkSurfaceColor : Colors.grey.shade50;
    final footerTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : Colors.grey.shade600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 80.0),
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Center(
                child: Text(
                  "笔记选项",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text(
                "置顶",
                style: TextStyle(),
              ),
              leading: Icon(
                widget.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: AppTheme.primaryColor,
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onPin();
              },
            ),
            ListTile(
              title: const Text(
                "编辑",
                style: TextStyle(),
              ),
              leading: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
            ListTile(
              title: const Text(
                "删除",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: footerBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "字数统计: ${widget.content.length}",
                    style: TextStyle(
                      fontSize: 12,
                      color: footerTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "创建时间: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.timestamp)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: footerTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "最后编辑: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.timestamp)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: footerTextColor,
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final List<BoxShadow>? cardShadow = isDarkMode ? null : [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(
        left: 8.0,    // 左边距8px
        right: 8.0,   // 右边距8px
        bottom: 5.0,  // 底部间距5px，这样两个卡片之间的间距就是5px
      ),
      child: Dismissible(
        key: ValueKey(widget.id), // Use id instead of content
        direction: DismissDirection.endToStart,
        background: Container(color: cardColor),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          child: const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            widget.onDelete();
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 - (_scaleAnimation.value * 0.03),
              child: GestureDetector(
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) => _controller.reverse(),
                onTapCancel: () => _controller.reverse(),
                onTap: widget.onEdit,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: cardShadow,
                      border: widget.isPinned 
                        ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5)
                      : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 顶部栏：时间和更多按钮
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm').format(widget.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: (isDarkMode 
                                          ? AppTheme.darkBackgroundColor 
                                          : AppTheme.backgroundColor).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.more_horiz,
                                        color: isDarkMode ? AppTheme.darkTextSecondaryColor : Colors.grey[600],
                                        size: 14,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _showMoreOptions(context),
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // 减小顶部和内容之间的间距
                              _buildContent(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
          padding: EdgeInsets.all(4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
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
      borderRadius: BorderRadius.circular(4),
      child: Container(
        color: Colors.grey[800],
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Grid image error: $error for $path');
            return Container(
              color: Colors.grey[800],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            );
          },
        ),
      ),
    );
  }
} 