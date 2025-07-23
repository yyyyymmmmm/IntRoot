import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:math' as math;

class NoteEditor extends StatefulWidget {
  final Function(String content) onSave;
  final String? initialContent;
  
  const NoteEditor({
    super.key,
    required this.onSave,
    this.initialContent,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _textController;
  bool _canSave = false;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  // 单行文本的估计高度
  final double _singleLineHeight = 22.0; // 字体大小 * 行高
  
  // 最大显示的行数
  final int _maxLines = 10;
  
  // 文本内容行数
  int _lineCount = 0;
  
  // 文本样式
  static const TextStyle _textStyle = TextStyle(
    fontSize: 16.0,
    height: 1.375, // 行高是字体大小的1.375倍
    letterSpacing: 0.1,
    color: Color(0xFF333333),
  );
  
  // 提示文本样式
  late final TextStyle _hintStyle = _textStyle.copyWith(
    color: Colors.grey.shade400,
  );

  // 添加一个标志来防止多次保存
  bool _isSaving = false;
  
  // 添加图片列表和Markdown代码
  List<_ImageItem> _imageList = [];
  List<String> _mdCodes = [];
  final ScrollController _imageScrollController = ScrollController();

  // 从Markdown中提取图片路径
  void _extractImagesFromMarkdown() {
    final RegExp imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final matches = imageRegex.allMatches(_textController.text);
    
    // 提取所有图片链接和描述
    List<_ImageItem> newImageList = [];
    List<String> markdownCodes = [];
    
    for (var match in matches) {
      final alt = match.group(1) ?? '图片';
      final path = match.group(2) ?? '';
      final fullMatch = match.group(0) ?? '';
      
      if (path.isNotEmpty) {
        newImageList.add(_ImageItem(path: path, alt: alt));
        markdownCodes.add(fullMatch);
      }
    }
    
    setState(() {
      _imageList = newImageList;
      _mdCodes = markdownCodes;
      
      // 从文本中移除所有图片Markdown代码
      String newText = _textController.text;
      for (var code in markdownCodes) {
        newText = newText.replaceAll(code, '');
      }
      
      // 更新文本，但不触发监听器
      _textController.removeListener(_updateLineCount);
      _textController.text = newText;
      _textController.addListener(_updateLineCount);
    });
  }

  // 更新内容行数
  void _updateLineCount() {
    setState(() {
      _lineCount = '\n'.allMatches(_textController.text).length + 1;
    });
  }
  
  // 检查是否可以保存
  bool _checkCanSave() {
    return _textController.text.trim().isNotEmpty || _imageList.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialContent);
    _canSave = _checkCanSave();
    
    // 初始化内容行数
    _updateLineCount();
    
    // 解析现有内容中的图片
    _extractImagesFromMarkdown();
    
    // 监听输入变化，更新保存按钮状态和行数
    _textController.addListener(() {
      final canSave = _checkCanSave();
      if (canSave != _canSave) {
        setState(() {
          _canSave = canSave;
        });
      }
      _updateLineCount();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _imageScrollController.dispose();
    super.dispose();
  }

  // 从设备选择图片并插入
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        // 显示加载指示器
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          // 获取应用文档目录
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory('${appDir.path}/images');
          
          // 确保图片目录存在
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          
          // 创建唯一文件名
          final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
          final localImagePath = '${imagesDir.path}/$fileName';
          
          // 复制图片到应用目录
          final File newImage = File(localImagePath);
          await File(pickedFile.path).copy(localImagePath);
          
          // 关闭加载指示器
          Navigator.pop(context);
          
          // 添加图片到列表，但不在文本中显示Markdown代码
          final mdCode = '![图片](file://$localImagePath)';
          
          setState(() {
            _imageList.add(_ImageItem(path: 'file://$localImagePath', alt: '图片'));
            _mdCodes.add(mdCode);
            // 确保添加图片后可以保存
            _canSave = true;
          });
          
          // 移除图片添加提示
        } catch (e) {
          // 关闭加载指示器
          Navigator.pop(context);
          
          print('保存图片失败: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('添加图片失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('选择图片失败: $e');
    }
  }

  // 用于保存笔记前的最终内容准备
  String _prepareFinalContent() {
    // 保存前将隐藏的图片Markdown添加回文本
    String finalContent = _textController.text.trim();
    
    // 如果有图片，添加到内容末尾
    if (_imageList.isNotEmpty) {
      // 如果文本非空且没有以换行符结尾，添加换行符
      if (finalContent.isNotEmpty && !finalContent.endsWith('\n')) {
        finalContent += '\n';
      }
      
      // 添加所有图片的Markdown代码
      for (var i = 0; i < _imageList.length; i++) {
        var img = _imageList[i];
        var mdCode = i < _mdCodes.length ? 
            _mdCodes[i] : 
            '![${img.alt}](${img.path})';
        finalContent += mdCode + '\n';
      }
    }
    
    return finalContent.trim();
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸和键盘高度
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    // 基础编辑框高度 - 屏幕高度的35%或300像素，取较大值
    final baseEditorHeight = math.max(screenSize.height * 0.35, 300.0);
    
    // 计算编辑区域的自适应高度（根据行数）
    final contentHeight = math.min(
      _lineCount * _singleLineHeight, // 根据行数计算高度
      _maxLines * _singleLineHeight,  // 最大高度（10行）
    );
    
    // 底部工具栏高度
    const toolbarHeight = 50.0;
    
    // 顶部指示器和内边距高度
    const topElementsHeight = 20.0;
    
    // 图片预览区域高度
    final imagePreviewHeight = _imageList.isEmpty ? 0.0 : 120.0;
    
    // 编辑器总高度 = 内容高度 + 工具栏高度 + 顶部元素高度 + 图片预览高度
    final editorHeight = math.max(
      contentHeight + toolbarHeight + topElementsHeight + imagePreviewHeight + 32, // 添加额外padding空间
      baseEditorHeight
    );
    
    // 获取当前主题模式
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? Colors.grey[600] : Colors.grey[800];
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final dividerColor = isDarkMode ? Colors.grey[800] ?? Colors.grey.shade800 : Colors.grey[200] ?? Colors.grey.shade200;
    final hintTextColor = isDarkMode ? Colors.grey[600] : Colors.grey[400];
    
    // 确保即使只有图片也能保存
    bool canSave = _textController.text.trim().isNotEmpty || _imageList.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      // 点击空白区域关闭编辑框
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // 确保内容位于底部
            children: [
              // 编辑器主体 - 使用GestureDetector拦截点击事件
              GestureDetector(
                onTap: () {}, // 空的onTap阻止点击事件冒泡
                child: Container(
                  height: editorHeight,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 顶部灰条 - 类似于iOS的拖动指示器
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // 编辑区域 - 高度自适应，支持滚动
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                          child: TextField(
                            controller: _textController,
                            scrollController: _scrollController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null, // 允许无限行
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '现在的想法是...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: hintTextColor,
                                height: 1.5,
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                            cursorColor: iconColor,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      
                      // 图片预览区域 - 水平滚动
                      if (_imageList.isNotEmpty)
                        Container(
                          height: 110,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: dividerColor, width: 0.5),
                            ),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            controller: _imageScrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _imageList.length,
                            itemBuilder: (context, index) {
                              return _buildImagePreviewItem(_imageList[index], index);
                            },
                          ),
                        ),
                      
                      // 底部功能栏和发送按钮
                      Container(
                        height: toolbarHeight,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border(
                            top: BorderSide(color: dividerColor, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            // 功能按钮容器
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 12),
                                    
                                    // # 标签按钮
                                    IconButton(
                                      icon: Text(
                                        '#',
                                        style: TextStyle(
                                          fontSize: 20, 
                                          fontWeight: FontWeight.bold,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      onPressed: () => _insertText('#'),
                                      iconSize: 20,
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    
                                    // 图片按钮
                                    IconButton(
                                      icon: Icon(Icons.photo_outlined, 
                                          size: 20, 
                                          color: secondaryTextColor),
                                      onPressed: _pickImage,
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    
                                    // B 粗体按钮
                                    IconButton(
                                      icon: Text(
                                        'B',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      onPressed: () => _wrapSelectedText('**', '**'),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    
                                    // 列表按钮
                                    IconButton(
                                      icon: Icon(Icons.format_list_bulleted, 
                                          size: 20, 
                                          color: secondaryTextColor),
                                      onPressed: () => _insertText('\n- '),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    
                                    // 更多按钮
                                    IconButton(
                                      icon: Icon(Icons.more_horiz, 
                                          size: 20, 
                                          color: secondaryTextColor),
                                      onPressed: _showMoreOptions,
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 发送按钮
                            Container(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 70,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: canSave 
                                    ? (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor) 
                                    : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: (canSave && !_isSaving)
                                      ? () async {
                                          if (_isSaving) return;
                                          
                                          setState(() {
                                            _isSaving = true;
                                          });
                                          
                                          try {
                                            print('NoteEditor: 开始保存笔记...');
                                            
                                            // 准备最终内容
                                            String finalContent = _prepareFinalContent();
                                            
                                            // 如果内容为空且没有图片，不保存
                                            if (finalContent.isEmpty && _imageList.isEmpty) {
                                              setState(() {
                                                _isSaving = false;
                                              });
                                              return;
                                            }
                                            
                                            await widget.onSave(finalContent);
                                            print('NoteEditor: 笔记保存成功，准备关闭编辑器');
                                            
                                            // 使用安全的方式关闭编辑器
                                            if (mounted) {
                                              try {
                                                Navigator.pop(context);
                                                print('NoteEditor: 编辑器已关闭');
                                              } catch (e) {
                                                print('NoteEditor: 关闭编辑器失败: $e');
                                              }
                                            }
                                          } catch (e) {
                                            print('NoteEditor: 保存笔记时出错: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('保存失败: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                _isSaving = false;
                                              });
                                            }
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建单个图片预览项
  Widget _buildImagePreviewItem(_ImageItem image, int index) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 图片
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image(
              image: _getImageProvider(image.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
          
          // 删除按钮
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 删除图片
  void _removeImage(int index) {
    setState(() {
      if (index < _imageList.length) {
        _imageList.removeAt(index);
        
        if (index < _mdCodes.length) {
          _mdCodes.removeAt(index);
        }
      }
    });
  }
  
  // 在当前光标位置插入文本
  void _insertText(String text) {
    final currentText = _textController.text;
    final selection = _textController.selection;
    final newText = currentText.substring(0, selection.start) + 
                    text + 
                    currentText.substring(selection.end);
    
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + text.length,
      ),
    );
  }
  
  // 用指定的标记包裹所选文本
  void _wrapSelectedText(String prefix, String suffix) {
    final currentText = _textController.text;
    final selection = _textController.selection;
    
    // 如果没有选择文本，插入标记并将光标放在中间
    if (selection.start == selection.end) {
      final newText = currentText.substring(0, selection.start) + 
                      prefix + suffix + 
                      currentText.substring(selection.end);
      
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length,
        ),
      );
    } else {
      // 如果选择了文本，用标记包裹它
      final selectedText = currentText.substring(selection.start, selection.end);
      final newText = currentText.substring(0, selection.start) + 
                      prefix + selectedText + suffix + 
                      currentText.substring(selection.end);
      
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
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
          print('Error loading image: $e for $uriString');
          // 默认使用资源图片
          return const AssetImage('assets/images/logo.png');
        }
      }
    } catch (e) {
      print('Error in _getImageProvider: $e');
      return const AssetImage('assets/images/logo.png');
    }
  }
  
  // 显示更多Markdown选项
  void _showMoreOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : null; // 使用系统图标颜色
    
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.format_quote, color: iconColor),
              title: Text('引用', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _insertText('\n> ');
              },
            ),
            ListTile(
              leading: Icon(Icons.code, color: iconColor),
              title: Text('代码', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _wrapSelectedText('`', '`');
              },
            ),
            ListTile(
              leading: Icon(Icons.title, color: iconColor),
              title: Text('标题', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _insertText('\n# ');
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: iconColor),
              title: Text('链接', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _insertText('[链接文本](链接地址)');
              },
            ),
            ListTile(
              leading: Icon(Icons.format_underlined, color: iconColor),
              title: Text('下划线', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _wrapSelectedText('<u>', '</u>');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 图片项类
class _ImageItem {
  final String path;
  final String alt;
  
  _ImageItem({required this.path, required this.alt});
} 