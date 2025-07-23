import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _selectedIndex = 0;
  final List<String> _categories = [
    '开始使用',
    '笔记功能',
    '标签功能',
    '数据同步',
    'Markdown语法',
    '常见问题'
  ];

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final contentBgColor = isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5);
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    
    // 处理返回按钮的逻辑函数
    Future<bool> _onWillPop() async {
      // 如果是从设置页面进入，返回设置页面
      if (GoRouterState.of(context).matchedLocation.startsWith('/settings')) {
        context.pop();
      } else {
        // 如果是从侧边栏进入，返回主页
        context.go('/');
      }
      return false; // 返回false阻止默认返回行为，因为我们已经手动处理了
    }
    
    return PopScope(
      canPop: false, // 禁止默认返回行为
      onPopInvoked: (didPop) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : null),
            onPressed: () {
              // 如果是从设置页面进入，返回设置页面
              if (GoRouterState.of(context).matchedLocation.startsWith('/settings')) {
                context.pop();
              } else {
                // 如果是从侧边栏进入，返回主页
                context.go('/');
              }
            },
          ),
          title: Text('帮助中心', 
                     style: TextStyle(
                       fontWeight: FontWeight.w500,
                       color: textColor,
                     )),
          centerTitle: true,
          elevation: 0,
          backgroundColor: backgroundColor,
        ),
        body: Column(
          children: [
            // 分类导航条
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? iconColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? (isDarkMode ? Colors.black : Colors.white) : textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 内容区域
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _categories.map((category) => 
                  Container(
                    color: contentBgColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildContent(_categories.indexOf(category)),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 根据选中的索引构建相应的内容
  Widget _buildContent(int index) {
    switch (index) {
      case 0: return _buildGettingStarted();
      case 1: return _buildNotesFeatures();
      case 2: return _buildTagsFeatures();
      case 3: return _buildDataSync();
      case 4: return _buildMarkdownGuide();
      case 5: return _buildFAQ();
      default: return _buildGettingStarted();
    }
  }
  
  // 开始使用
  Widget _buildGettingStarted() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: '开始使用',
          icon: Icons.start,
          description: '快速了解InkRoot-墨鸣笔记的基本功能和使用方式'
        ),
        
        _buildSection(
          title: '欢迎使用InkRoot-墨鸣笔记',
          content: '''
InkRoot-墨鸣笔记是一款简洁高效的笔记应用，支持本地使用和连接到Memos服务器。无论是随手记录灵感、整理工作笔记，还是建立个人知识库，InkRoot-墨鸣笔记都能满足您的需求。

### 主要功能
- **笔记创建与管理**：快速记录、编辑和管理您的笔记
- **标签系统**：使用标签对笔记进行分类和组织
- **双端同步**：在本地和云端之间自由切换，数据随时同步
- **随机回顾**：定期回顾过去的笔记，加深记忆与思考
- **Markdown支持**：使用Markdown语法丰富笔记格式

### 应用界面
- **主页**：显示全部笔记，支持创建和管理笔记
- **标签页**：按标签分类查看笔记
- **随机回顾**：随机展示历史笔记，帮助回顾
- **设置**：个性化设置和账户管理
          ''',
        ),
        
        _buildSection(
          title: '快速入门',
          content: '''
### 创建第一条笔记
1. 在主页点击右下角的"+"按钮
2. 在编辑器中输入笔记内容
3. 点击发送按钮保存笔记

### 添加标签
在笔记中使用"#标签名"的格式添加标签，例如：
```
今天的工作计划 #工作 #计划
```

### 查看笔记
- 在主页可以查看所有笔记
- 点击任意笔记可查看详情
- 在标签页可按标签分类查看

### 连接到Memos服务器
1. 点击侧边栏，进入"设置"
2. 点击"连接"按钮
3. 输入服务器地址和Token
4. 点击"登录"按钮
          ''',
        ),
      ],
    );
  }
  
  // 笔记功能
  Widget _buildNotesFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: '笔记功能',
          icon: Icons.note_alt,
          description: '全面了解InkRoot-墨鸣笔记的核心笔记功能'
        ),
        
        _buildSection(
          title: '创建和编辑笔记',
          content: '''
### 创建新笔记
- 在主页点击右下角的"+"按钮
- 输入笔记内容（支持Markdown格式）
- 使用"#标签名"添加标签
- 点击发送按钮保存笔记

### 编辑笔记
- 在笔记列表中点击笔记进入详情页
- 点击右上角的编辑图标进入编辑模式
- 或在笔记列表中点击笔记右上角的编辑图标
- 修改内容后点击发送按钮保存

### 删除笔记
- 在笔记详情页点击右上角的删除图标
- 或在笔记列表中左滑笔记，点击删除图标
- 注意：删除操作无需确认，直接执行
          ''',
        ),
        
        _buildSection(
          title: '笔记排序与过滤',
          content: '''
### 笔记排序方式
- **最新优先**：最新创建的笔记显示在顶部（默认）
- **最早优先**：最早创建的笔记显示在顶部
- **最近更新**：最近编辑过的笔记显示在顶部

### 笔记过滤
- 通过标签页筛选显示特定标签的笔记
- 使用搜索功能查找特定内容的笔记
          ''',
        ),
        
        _buildSection(
          title: '随机回顾功能',
          content: '''
### 什么是随机回顾？
随机回顾功能会从您的笔记库中随机选取一些笔记展示给您，帮助您回顾过去的想法和记录，激发新的思考。

### 如何使用？
1. 从侧边栏进入"随机回顾"页面
2. 系统会自动展示随机选取的笔记
3. 左右滑动切换不同的笔记
4. 点击编辑按钮可以直接编辑回顾中的笔记

### 自定义回顾设置
- 点击右上角设置图标
- 可设置回顾时间范围（如7天、30天、全部）
- 可设置回顾笔记数量（如5条、10条、20条）
          ''',
        ),
      ],
    );
  }
  
  // 标签功能
  Widget _buildTagsFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: '标签功能',
          icon: Icons.tag,
          description: '了解如何使用标签组织和管理您的笔记'
        ),
        
        _buildSection(
          title: '标签基础',
          content: '''
### 什么是标签？
标签是一种灵活的分类方式，帮助您组织和查找笔记。一条笔记可以添加多个标签，一个标签也可以应用于多条笔记。

### 标签格式
- 标准格式为：`#标签名`
- 标签名可以包含中文、英文、数字和下划线
- 例如：`#工作`、`#读书笔记`、`#2023目标`

### 标签优势
- 比传统文件夹更灵活
- 一条笔记可以同时属于多个分类
- 快速筛选和组织相关内容
          ''',
        ),
        
        _buildSection(
          title: '添加和使用标签',
          content: '''
### 如何添加标签
- 在创建或编辑笔记时，直接在内容中使用`#标签名`格式
- 可以在一条笔记中添加多个标签
- 例如：`今天完成了项目方案 #工作 #项目 #完成`

### 查看标签笔记
1. 从侧边栏进入"标签"页面
2. 查看所有已使用的标签列表
3. 点击任意标签，查看包含该标签的所有笔记
4. 点击笔记可查看详情或进行编辑

### 标签管理技巧
- 使用一致的命名方式，便于记忆和查找
- 适当使用多级标签，如`#工作_会议`、`#工作_报告`
- 定期整理标签，保持系统的清晰和高效
          ''',
        ),
        
        _buildSection(
          title: '标签页功能',
          content: '''
### 标签页功能介绍
- 展示所有已使用的标签
- 点击标签筛选相关笔记
- 可直接在标签页中编辑笔记
- 支持刷新和重新扫描标签

### 标签页操作指南
- **查看标签笔记**：点击标签查看相关笔记
- **编辑笔记**：点击笔记右上角的编辑图标
- **查看笔记详情**：点击笔记内容区域
- **刷新标签**：点击刷新按钮更新标签列表
- **扫描标签**：点击标签图标重新扫描所有笔记中的标签
          ''',
        ),
      ],
    );
  }
  
  // 数据同步
  Widget _buildDataSync() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: '数据同步',
          icon: Icons.sync,
          description: '了解InkRoot-墨鸣笔记的双端同步功能和使用方法'
        ),
        
        _buildSection(
          title: '双端同步概述',
          content: '''
### 什么是双端同步？
InkRoot-墨鸣笔记支持在本地模式和云端模式之间无缝切换，并能够智能同步两端的数据，确保您的笔记随时随地可用。

### 同步模式
- **本地模式**：笔记保存在本地设备，无需网络连接
- **云端模式**：笔记同步到Memos服务器，支持多设备访问

### 同步特点
- **双向同步**：本地到云端、云端到本地的双向数据传输
- **智能去重**：基于内容哈希值，避免数据重复
- **用户可控**：在关键节点提供同步选择，用户掌握数据流向
          ''',
        ),
        
        _buildSection(
          title: '从本地到云端（登录时同步）',
          content: '''
### 登录流程中的数据同步
当您从本地模式登录到Memos服务器时，系统会检测本地数据并提供同步选择：

1. **检测数据**：系统自动检查本地是否有笔记数据
2. **同步选择**：如有本地数据，会弹出提示询问是否同步到云端
   - 选择"同步到云端"：将本地笔记上传至服务器
   - 选择"不同步"：仅获取服务器数据，不上传本地数据
3. **自动处理**：如本地无数据，会直接获取服务器数据

### 同步过程中的重复处理
- 系统会计算每条笔记的内容哈希值
- 对比云端是否存在相同内容的笔记
- 跳过已存在的重复内容，避免数据冗余
          ''',
        ),
        
        _buildSection(
          title: '从云端到本地（退出登录时同步）',
          content: '''
### 退出登录流程中的数据同步
当您从云端模式退出登录时，系统同样提供数据同步选择：

1. **同步询问**：弹出对话框询问是否将云端数据同步到本地
   - 选择"同步到本地"：将服务器笔记下载到本地
   - 选择"不同步"：直接退出登录，保持本地数据不变
2. **同步进度**：选择同步时会显示进度指示器
3. **完成退出**：同步完成后自动退出登录

### 同步结果通知
- 同步成功会显示成功通知
- 同步过程中如遇错误，会显示错误提示
          ''',
        ),
        
        _buildSection(
          title: '自动同步设置',
          content: '''
### 配置自动同步
在登录模式下，您可以在设置页面配置自动同步：

1. 进入设置页面
2. 开启/关闭"自动同步"开关
3. 设置"同步间隔"时间（如5分钟、15分钟、30分钟等）

### 自动同步优势
- 定时自动同步，无需手动操作
- 确保本地和云端数据的及时更新
- 减少数据丢失风险

### 手动同步
即使启用了自动同步，您仍可以随时手动触发同步：
- 在主页下拉刷新可触发同步
- 登录或退出登录时选择同步选项
          ''',
        ),
      ],
    );
  }
  
  // Markdown语法指南
  Widget _buildMarkdownGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: 'Markdown语法指南',
          icon: Icons.code,
          description: '学习在笔记中使用Markdown格式化文本'
        ),
        
        _buildSection(
          title: 'Markdown基础',
          content: '''
### 什么是Markdown？
Markdown是一种轻量级标记语言，让您使用纯文本格式编写文档，并转换成结构化的HTML显示。InkRoot-墨鸣笔记支持Markdown语法，让您的笔记更加丰富多彩。

### Markdown优势
- 简单易学，使用纯文本
- 专注于内容而非排版
- 可读性强，即使不转换也易于阅读
- 跨平台兼容性好
          ''',
        ),
        
        _buildSection(
          title: '常用Markdown语法',
          content: '''
### 标题
```
# 一级标题
## 二级标题
### 三级标题
```

### 文本格式
```
**粗体文本**
*斜体文本*
~~删除线文本~~
`行内代码`
```

### 列表
```
- 无序列表项1
- 无序列表项2
  - 嵌套列表项

1. 有序列表项1
2. 有序列表项2
```

### 引用
```
> 这是一段引用文本
> 可以跨多行
```

### 链接和图片
```
[链接文字](https://example.com)
![图片描述](图片URL)
```

### 代码块
\```
这里是代码块
可以包含多行代码
\```

### 表格
```
| 表头1 | 表头2 |
| ----- | ----- |
| 单元格1 | 单元格2 |
| 单元格3 | 单元格4 |
```
          ''',
        ),
        
        _buildSection(
          title: 'Markdown在InkRoot-墨鸣笔记中的应用',
          content: '''
### 为什么在InkRoot-墨鸣笔记中使用Markdown？
- 结构化笔记内容，提高可读性
- 统一格式，美观整洁
- 实现更复杂的文本排版效果

### 使用建议
- 使用标题层级组织笔记结构
- 使用列表整理条目和步骤
- 使用引用突出重要信息
- 使用代码块保存代码或格式化文本
- 结合标签系统，进一步提高笔记管理效率

### InkRoot-墨鸣笔记中的特殊语法
- 标签格式：`#标签名`
- 使用三个反引号(```)创建代码块
- 支持表格和大部分常用Markdown语法
          ''',
        ),
      ],
    );
  }
  
  // 常见问题
  Widget _buildFAQ() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: '常见问题',
          icon: Icons.help_outline,
          description: '解答使用InkRoot-墨鸣笔记时可能遇到的问题'
        ),
        
        _buildSection(
          title: '数据同步问题',
          content: '''
### 笔记无法同步到云端？
- 检查网络连接是否正常
- 确认Memos服务器地址是否正确
- 验证Token是否有效或已过期
- 尝试退出登录后重新登录
- 检查服务器是否有空间限制

### 同步后发现数据重复？
- InkRoot-墨鸣笔记使用内容哈希检测重复，一般不会出现重复
- 如遇极少数情况，可尝试手动删除重复笔记
- 检查笔记内容是否完全一致，轻微差异也会被视为不同笔记

### 退出登录时无法同步到本地？
- 检查本地存储空间是否充足
- 确认网络连接状态
- 尝试先同步少量数据，再同步全部
          ''',
        ),
        
        _buildSection(
          title: '标签相关问题',
          content: '''
### 标签未被正确识别？
- 确保标签格式为"#标签名"，无空格
- 检查标签名是否包含特殊字符
- 标签名支持中文、英文、数字和下划线
- 多个标签之间需要用空格分隔

### 标签页不显示任何内容？
- 尝试点击刷新按钮更新标签列表
- 点击标签图标重新扫描所有笔记中的标签
- 检查是否有包含标签的笔记
- 确认当前登录状态与笔记存储位置一致

### 编辑笔记后标签失效？
- 确保保存笔记时标签格式正确
- 编辑后点击刷新按钮更新标签列表
- 如持续出现问题，尝试重启应用
          ''',
        ),
        
        _buildSection(
          title: '其他常见问题',
          content: '''
### 如何备份我的笔记？
- 连接到Memos服务器可自动备份笔记
- 退出登录时选择"同步到本地"可保留本地副本
- 在设置中找到"导入导出"功能进行手动备份

### 应用打开速度慢？
- 检查笔记数量，过多笔记可能影响加载速度
- 确保设备存储空间充足
- 尝试清理应用缓存
- 重启设备后再次尝试

### 如何彻底删除数据？
- 本地数据：在设置页面使用"清理数据"功能
- 云端数据：需登录Memos服务器后台进行操作
- 注意：数据删除后无法恢复，请谨慎操作

### 如何联系开发团队？
如有其他问题或建议，请通过以下方式联系我们：
- 电子邮件：support@momingnotes.com
- 官方网站：www.momingnotes.com
- 在应用内的"设置 > 反馈与建议"提交反馈
          ''',
        ),
      ],
    );
  }
  
  // 内容头部
  Widget _buildContentHeader({
    required String title,
    required IconData icon,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final iconBgColor = isDarkMode 
        ? AppTheme.primaryColor.withOpacity(0.2) 
        : AppTheme.primaryColor.withOpacity(0.1);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 内容区块
  Widget _buildSection({required String title, required String content}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final headerBgColor = isDarkMode 
        ? AppTheme.primaryColor.withOpacity(0.2) 
        : AppTheme.primaryColor.withOpacity(0.1);
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final codeBgColor = isDarkMode ? Color(0xFF2C2C2C) : Color(0xFFF5F5F5);
    final codeBlockBgColor = isDarkMode ? Colors.grey[900] : Colors.grey[200];
    final codeBlockBorderColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                h3: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.8,
                ),
                p: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: textColor,
                ),
                code: TextStyle(
                  backgroundColor: codeBgColor,
                  fontFamily: 'monospace',
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
                codeblockDecoration: BoxDecoration(
                  color: codeBlockBgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: codeBlockBorderColor!),
                ),
                listBullet: TextStyle(
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }
} 