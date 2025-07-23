import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final bool showBackButton;
  
  const LoginScreen({
    super.key,
    this.showBackButton = false, // 默认不显示返回按钮
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _rememberLogin = true; // 记住登录信息

  @override
  void initState() {
    super.initState();
    print('LoginScreen: initState');
    _loadSavedLoginInfo();
    
    // 默认记住登录
    _rememberLogin = true;
  }

  Future<void> _loadSavedLoginInfo() async {
    print('LoginScreen: 加载保存的登录信息');
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final savedServer = await appProvider.getSavedServer();
    final savedToken = await appProvider.getSavedToken();
    
    if (savedServer != null && savedToken != null) {
      print('LoginScreen: 发现保存的登录信息');
      setState(() {
        _serverController.text = savedServer;
        _tokenController.text = savedToken;
      });
    } else {
      print('LoginScreen: 未找到保存的登录信息');
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final serverUrl = _serverController.text.trim();
      final token = _tokenController.text.trim();
      
      print('LoginScreen: 尝试登录，记住登录: $_rememberLogin');
      
      // 如果选择记住登录，保存登录信息
      if (_rememberLogin) {
        print('LoginScreen: 保存登录信息');
        await appProvider.saveLoginInfo(serverUrl, token);
      } else {
        print('LoginScreen: 清除登录信息');
        await appProvider.clearLoginInfo();
      }
      
      // 使用Token登录
      final result = await appProvider.loginWithToken(
        serverUrl, 
        token,
        remember: _rememberLogin,
      );

      if (result.$1 && mounted) {
        print('LoginScreen: 登录成功，检查同步状态');
        
        // 确保API服务已初始化
        await appProvider.fetchNotesFromServer().catchError((e) {
          print('LoginScreen: 初始同步失败，继续流程: $e');
        });
        
        // 检查是否需要同步本地数据
        final hasLocalData = await appProvider.hasLocalData();
        if (hasLocalData) {
          // 显示确认对话框，询问是否同步本地数据到云端
          if (mounted) {
            final shouldSync = await _showSyncConfirmDialog();
            if (shouldSync == true) {
              // 用户选择同步本地数据到云端
              await appProvider.syncLocalDataToServer();
            } else {
              // 用户选择不同步，仅获取服务器数据
              await appProvider.fetchServerDataOnly();
            }
          }
        } else {
          // 本地无数据，直接获取服务器数据
          await appProvider.fetchServerDataOnly();
        }
        
        // 完成登录流程，跳转到主页
        if (mounted) {
          context.go('/');
        }
      } else if (mounted) {
        print('LoginScreen: 登录失败: ${result.$2}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.$2 ?? '登录失败，请检查服务器地址和Token是否正确'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('LoginScreen: 登录异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // 显示同步确认对话框
  Future<bool?> _showSyncConfirmDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final accentColor = isDarkMode ? AppTheme.primaryLightColor : Colors.teal;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogColor,
        title: Text('数据同步', style: TextStyle(color: textColor)),
        content: Text('检测到本地已有笔记数据，是否将本地数据同步到云端？', 
                    style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('不同步', style: TextStyle(color: accentColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('同步到云端', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  void _handleLoginSuccess() {
    print('LoginScreen: 登录成功，检查同步状态');
    
    // 启动自动同步
    context.read<AppProvider>().startAutoSync();
    
    // 导航到主页
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey.shade50;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final accentColor = isDarkMode ? AppTheme.primaryLightColor : Colors.teal;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.showBackButton 
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () {
                  // 使用 go_router 的 context.go() 而不是 Navigator.pop()
                  // 这样可以确保不会弹出最后一个页面
                  context.go('/');
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题部分 - 更大的标题
                      const SizedBox(height: 40),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '静待沉淀',
                              style: TextStyle(
                                fontSize: 30, // 增大字体
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '蓄势鸣响',
                              style: TextStyle(
                                fontSize: 30, // 增大字体
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '记录每一个值得铭记的瞬间',
                          style: TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      
                      // 服务器地址输入 - 更小的输入框
                      Container(
                        width: screenSize.width * 0.8, // 控制宽度
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _serverController,
                          decoration: InputDecoration(
                            labelText: '服务器地址',
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: TextStyle(fontSize: 14, color: textColor),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入服务器地址';
                            }
                            // 移除前后空格
                            value = value.trim();
                            
                            // 检查是否包含协议
                            if (!value.startsWith('http://') && !value.startsWith('https://')) {
                              value = 'https://$value';
                            }
                            
                            try {
                              final uri = Uri.parse(value);
                              if (!uri.hasAuthority) {
                                return '无效的服务器地址';
                              }
                            } catch (e) {
                              return '无效的服务器地址格式';
                            }
                            
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Token输入 - 更小的输入框
                      Container(
                        width: screenSize.width * 0.8, // 控制宽度
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _tokenController,
                          decoration: InputDecoration(
                            labelText: 'Token',
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: TextStyle(fontSize: 14, color: textColor),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入访问令牌';
                            }
                            // 移除前后空格
                            value = value.trim();
                            
                            // 检查最小长度
                            if (value.length < 32) {
                              return '访问令牌长度不足';
                            }
                            
                            // 检查是否包含非法字符
                            if (value.contains(' ')) {
                              return '访问令牌不能包含空格';
                            }
                            
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 记住登录状态选项
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberLogin,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberLogin = value ?? true;
                                  });
                                },
                                activeColor: accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '记住登录',
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                            const Spacer(),
                            Text(
                              '下次将自动登录',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // 登录按钮
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('立即连接'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 获取Token提示
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // 显示获取Token的帮助信息
                            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                            final dialogColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
                            final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
                            final accentColor = isDarkMode ? AppTheme.primaryLightColor : Colors.teal;
                            
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: dialogColor,
                                title: Text('如何获取Token?', style: TextStyle(color: textColor)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('1. 登录您的Memos服务器', style: TextStyle(color: textColor)),
                                    SizedBox(height: 8),
                                    Text('2. 进入设置 > Access Tokens', style: TextStyle(color: textColor)),
                                    SizedBox(height: 8),
                                    Text('3. 点击"Create Token"创建新的访问令牌', style: TextStyle(color: textColor)),
                                    SizedBox(height: 8),
                                    Text('4. 复制生成的令牌并粘贴到上方输入框', style: TextStyle(color: textColor)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('明白了', style: TextStyle(color: accentColor)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            '如何获取Token?',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 底部InkRoot标识
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Text(
                    'InkRoot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0',
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
} 