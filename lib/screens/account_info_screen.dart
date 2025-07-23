import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../services/preferences_service.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  bool _isEditingNickname = false;
  bool _isEditingEmail = false;
  bool _isEditingBio = false;
  bool _isUpdatingAvatar = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppProvider>(context, listen: false).user;
    _nicknameController = TextEditingController(text: user?.nickname ?? user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: user?.description ?? '');
    
    // 页面加载后自动同步一次用户信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果上次同步时间超过15分钟，或者没有头像，自动同步
      if (user != null && (user.lastSyncTime == null || 
          DateTime.now().difference(user.lastSyncTime!).inMinutes > 15 || 
          user.avatarUrl == null || user.avatarUrl!.isEmpty)) {
        _syncUserInfo(context);
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 格式化创建时间
  String _formatCreationTime(User user) {
    if (user.lastSyncTime != null) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(user.lastSyncTime!);
    }
    return '未知';
  }

  // 从服务器同步用户信息
  Future<void> _syncUserInfo(BuildContext context) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (!appProvider.isLoggedIn || appProvider.memosApiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未登录或API服务未初始化')),
      );
      return;
    }

    try {
      setState(() {
        _isUpdatingAvatar = true; // 使用同一个loading状态
      });

      // 获取最新的用户信息
      final response = await http.get(
        Uri.parse('${appProvider.appConfig.memosApiUrl}/api/v1/user/me'),
        headers: {
          'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('获取用户信息失败: ${response.statusCode}');
      }

      print('用户信息同步响应: ${response.body}');
      final userData = jsonDecode(response.body);
      
      // 更新本地用户信息
      final currentUser = appProvider.user;
      if (currentUser == null) {
        throw Exception('当前用户信息为空');
      }
      
      final updatedUser = User(
        id: userData['id'].toString(),
        username: userData['username'] ?? currentUser.username,
        nickname: userData['nickname'] ?? currentUser.nickname,
        email: userData['email'] ?? currentUser.email,
        description: userData['description'],
        role: userData['role'] ?? currentUser.role,
        avatarUrl: userData['avatarUrl'],
        token: currentUser.token,  // 保留原token
        lastSyncTime: DateTime.now(),
      );
      
      await _preferencesService.saveUser(updatedUser);
      await appProvider.setUser(updatedUser);
      
      // 重新加载控制器的值
      setState(() {
        _nicknameController.text = updatedUser.nickname ?? updatedUser.username ?? '';
        _emailController.text = updatedUser.email ?? '';
        _bioController.text = updatedUser.description ?? '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用户信息同步成功')),
        );
      }
    } catch (e) {
      print('同步用户信息错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAvatar = false;
        });
      }
    }
  }

  // 更新用户信息到服务器
  Future<void> _updateUserInfoToServer({
    String? nickname,
    String? email,
    String? description,
    String? avatarUrl,
  }) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (!appProvider.isLoggedIn || appProvider.memosApiService == null) {
      throw Exception('未登录或API服务未初始化');
    }

    try {
      final response = await http.patch(
        Uri.parse('${appProvider.appConfig.memosApiUrl}/api/v1/users/${appProvider.user?.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
        },
        body: jsonEncode({
          'user': {
            if (nickname != null) 'nickname': nickname,
            if (email != null) 'email': email,
            if (description != null) 'description': description,
            if (avatarUrl != null) 'avatarUrl': avatarUrl,
          },
          'update_mask': {
            'paths': [
              if (nickname != null) 'nickname',
              if (email != null) 'email',
              if (description != null) 'description',
              if (avatarUrl != null) 'avatarUrl',
            ],
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('更新失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('更新失败: $e');
    }
  }

  // 选择头像
  Future<void> _pickImage(User user) async {
    try {
      setState(() {
        _isUpdatingAvatar = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isUpdatingAvatar = false;
        });
        return;
      }

      setState(() {
        _selectedImage = File(image.path);
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.memosApiService != null && appProvider.isLoggedIn) {
        try {
          // 上传图片到服务器
          final bytes = await _selectedImage!.readAsBytes();
          final base64Image = base64Encode(bytes);
          
          // 使用Memos API上传图片
          final apiUrl = '${appProvider.appConfig.memosApiUrl}/api/v1/resource/blob';
          
          // 构建multipart请求
          var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
          request.headers['Authorization'] = 'Bearer ${appProvider.appConfig.lastToken}';
          
          // 添加文件部分
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          
          print('上传头像请求: ${request.url}');
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            print('上传头像响应: ${response.body}');
            final data = jsonDecode(response.body);
            String imageUrl = '';
            
            // 提取资源URL
            if (data['data'] != null && data['data']['resourceId'] != null) {
              // 新版API
              final resourceId = data['data']['resourceId'];
              imageUrl = '${appProvider.appConfig.memosApiUrl}/o/r/${resourceId}';
            } else if (data['id'] != null) {
              // 旧版API
              imageUrl = '${appProvider.appConfig.memosApiUrl}/o/r/${data['id']}';
            } else if (data['resource'] != null && data['resource']['id'] != null) {
              // 另一种格式
              imageUrl = '${appProvider.appConfig.memosApiUrl}/o/r/${data['resource']['id']}';
            }
            
            if (imageUrl.isNotEmpty) {
              print('提取的头像URL: $imageUrl');
              
              // 更新用户信息
              final userUpdateUrl = '${appProvider.appConfig.memosApiUrl}/api/v1/user/${user.id}';
              final updateResponse = await http.patch(
                Uri.parse(userUpdateUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
                },
                body: jsonEncode({
                  'avatarUrl': imageUrl
                }),
              );
              
              print('更新用户头像响应: ${updateResponse.statusCode} - ${updateResponse.body}');
              
              if (updateResponse.statusCode == 200) {
                // 更新本地用户信息
                final updatedUser = user.copyWith(avatarUrl: imageUrl);
                await _preferencesService.saveUser(updatedUser);
                
                // 通知Provider更新
                appProvider.updateUserInfo(avatarUrl: imageUrl);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('头像已更新')),
                  );
                }
                
                // 刷新用户信息
                await _syncUserInfo(context);
              } else {
                throw Exception('更新用户头像失败: ${updateResponse.statusCode}');
              }
            } else {
              throw Exception('无法获取上传的头像URL');
            }
          } else {
            throw Exception('上传头像失败: ${response.statusCode}');
          }
        } catch (e) {
          print('头像上传错误: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('上传头像失败: $e')),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAvatar = false;
        });
      }
    }
  }

  // 显示修改昵称对话框
  void _showNicknameDialog(BuildContext context, User user) {
    final TextEditingController controller = TextEditingController(text: user.nickname);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '昵称',
            hintText: '请输入新的昵称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newNickname = controller.text.trim();
              if (newNickname.isNotEmpty) {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                final result = await appProvider.updateUserInfo(nickname: newNickname);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  
                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('昵称更新成功')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('昵称更新失败'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示修改简介对话框
  void _showBioDialog(BuildContext context, User user) {
    final TextEditingController controller = TextEditingController(text: user.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改简介'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '简介',
            hintText: '请输入新的简介',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newBio = controller.text.trim();
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final result = await appProvider.updateUserInfo(description: newBio);
              
              if (context.mounted) {
                Navigator.pop(context);
                
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('简介更新成功')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('简介更新失败'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示修改邮箱对话框
  void _showEmailDialog(BuildContext context, User user) {
    final TextEditingController controller = TextEditingController(text: user.email);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改邮箱'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '邮箱',
            hintText: '请输入新的邮箱地址',
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isNotEmpty) {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                final result = await appProvider.updateUserInfo(email: newEmail);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  
                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('邮箱更新成功')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('邮箱更新失败'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 构建头像图像，支持URL和base64格式
  Widget _buildAvatarImage(String avatarUrl) {
    if (avatarUrl.startsWith('data:image')) {
      // 处理base64格式的图像
      try {
        // 提取base64数据部分
        final dataStart = avatarUrl.indexOf('base64,') + 'base64,'.length;
        final base64Data = avatarUrl.substring(dataStart);
        final decodedBytes = base64Decode(base64Data);
        return Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('头像加载错误: $error');
            return _buildDefaultAvatar();
          },
        );
      } catch (e) {
        print('处理base64头像错误: $e');
        return _buildDefaultAvatar();
      }
    } else {
      // 处理URL格式的图像
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('头像加载错误: $error');
          return _buildDefaultAvatar();
        },
      );
    }
  }
  
  // 默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 40,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户信息'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.user == null) {
            return const Center(
              child: Text('未登录'),
            );
          }
          
          final user = appProvider.user!;
          
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // 用户基本信息卡片
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(user),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isUpdatingAvatar
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ClipOval(
                                    child: user.avatarUrl != null
                                        ? _buildAvatarImage(user.avatarUrl!)
                                        : Container(
                                            color: theme.primaryColor.withOpacity(0.1),
                                            child: Icon(
                                              Icons.person,
                                              size: 40,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                  ),
                          ),
                        ),
                        if (!_isUpdatingAvatar)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(40),
                                  bottomRight: Radius.circular(40),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nickname ?? user.username ?? '未设置昵称',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '未设置邮箱',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '创建时间：${_formatCreationTime(user)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // 基本信息设置
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        '基本信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF46B696).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF46B696),
                        ),
                      ),
                      title: const Text('修改昵称'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showNicknameDialog(context, user),
                    ),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E9BFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF3E9BFF),
                        ),
                      ),
                      title: const Text('修改邮箱'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showEmailDialog(context, user),
                    ),
                  ],
                ),
              ),
              
              // 添加同步按钮
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _syncUserInfo(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '立即同步个人信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 