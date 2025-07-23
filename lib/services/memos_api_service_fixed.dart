import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../utils/time_utils.dart';

/// 修复版本的Memos API服务类 - 基于Memos 0.21.0 API
class MemosApiServiceFixed {
  final String baseUrl;
  final String? token;
  
  MemosApiServiceFixed({required this.baseUrl, this.token});
  
  /// 创建请求头，包含授权信息
  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // ==================== 备忘录 API ====================
  
  /// 创建备忘录
  Future<Note> createMemo({
    required String content,
    String visibility = 'PRIVATE',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/memo'),
        headers: _getHeaders(),
        body: json.encode({
          'content': content,
          'visibility': visibility,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Note.fromJson(data);
      } else {
        print('创建备忘录失败: ${response.statusCode}, ${response.body}');
        throw Exception('创建备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      print('V1 API创建备忘录失败: $e');
      throw Exception('创建备忘录失败: $e');
    }
  }
  
  /// 获取备忘录列表
  Future<Map<String, dynamic>> getMemos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/memo'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> memos = data.map((item) => item as Map<String, dynamic>).toList();
        return {'memos': memos};
      } else {
        print('获取备忘录列表失败: ${response.statusCode}, ${response.body}');
        throw Exception('获取备忘录列表失败: ${response.statusCode}');
      }
    } catch (e) {
      print('V1 API获取备忘录列表失败: $e');
      throw Exception('获取备忘录列表失败: $e');
    }
  }
  
  /// 获取单个备忘录
  Future<Note> getMemo(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/memo/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _convertToNote(responseData);
      } else {
        print('获取备忘录失败: ${response.statusCode}, ${response.body}');
        throw Exception('获取备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      print('V1 API获取备忘录失败: $e');
      throw Exception('获取备忘录失败: $e');
    }
  }
  
  /// 更新备忘录
  Future<Note> updateMemo(
    String id, {
    required String content,
    String? visibility,
  }) async {
    try {
      // 如果是本地ID，需要创建而不是更新
      if (id.startsWith('local_') || id.contains('-')) {
        print('本地ID，需要创建新备忘录: $id');
        return createMemo(content: content, visibility: visibility ?? 'PRIVATE');
      }
      
      // 构建请求体
      final Map<String, dynamic> body = {
        'content': content,
      };
      
      if (visibility != null) {
        body['visibility'] = visibility;
      }

      print('尝试更新备忘录: $baseUrl/api/v1/memo/$id');
      print('请求体: ${json.encode(body)}');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/memo/$id'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      print('更新备忘录响应状态码: ${response.statusCode}');
      print('更新备忘录响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Note.fromJson(data);
      } else {
        throw Exception('更新备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      print('V1 API更新备忘录失败: $e');
      throw Exception('更新备忘录失败: $e');
    }
  }
  
  /// 删除备忘录
  Future<void> deleteMemo(String id) async {
    try {
      // 如果是本地ID，不需要从服务器删除
      if (id.startsWith('local_') || id.contains('-')) {
        print('本地ID，不需要从服务器删除: $id');
        return;
      }
      
      print('MemosApiServiceFixed: 开始删除备忘录 ID: $id');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/memo/$id'),
        headers: _getHeaders(),
      );

      print('MemosApiServiceFixed: 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('MemosApiServiceFixed: 删除成功');
      } else {
        print('V1 API删除备忘录失败: ${response.statusCode}, ${response.body}');
        throw Exception('删除备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      print('MemosApiServiceFixed: 删除备忘录时发生错误: $e');
      throw Exception('删除备忘录失败: $e');
    }
  }
  
  // ==================== 用户 API ====================
  
  /// 获取当前用户信息
  Future<User> getUserInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/user/me'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return _convertApiUserToUser(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Token无效或已过期，请重新登录');
    } else {
      print('获取用户信息失败: ${response.statusCode}, ${response.body}');
      throw Exception('获取用户信息失败: ${response.statusCode}');
    }
  }
  
  /// 创建访问令牌
  Future<String> createAccessToken(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      print('登录失败: ${response.statusCode}, ${response.body}');
      throw Exception('登录失败: ${response.statusCode}');
    }
  }

  /// 更新用户信息
  Future<User> updateUserInfo({
    String? nickname,
    String? email,
    String? avatarUrl,
    String? description,
  }) async {
    try {
      if (token == null || token!.isEmpty) {
        throw Exception('未登录，无法更新用户信息');
      }
      
      // 获取当前用户信息
      final currentUser = await getUserInfo();
      
      // 构建请求体
      final Map<String, dynamic> body = {};
      
      if (nickname != null) body['nickname'] = nickname;
      if (email != null) body['email'] = email;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
      if (description != null) body['description'] = description;
      
      final userId = currentUser.id;
      final apiUrl = '$baseUrl/api/v1/user/$userId';
      
      print('尝试更新用户信息: $apiUrl');
      print('请求体: ${json.encode(body)}');
      
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      
      print('更新用户信息响应状态码: ${response.statusCode}');
      print('更新用户信息响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson({
          ...data,
          'token': token, // 保持token不变
        });
      } else if (response.statusCode == 401) {
        throw Exception('Token无效或已过期，请重新登录');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('更新用户信息失败: ${error['message'] ?? '请求参数错误'}');
      } else {
        print('更新用户信息失败: ${response.statusCode}, ${response.body}');
        throw Exception('更新用户信息失败: ${response.statusCode}');
      }
    } catch (e) {
      print('更新用户信息时发生错误: $e');
      throw Exception('更新用户信息失败: $e');
    }
  }
  
  // ==================== 工具方法 ====================
  
  /// 将API返回的用户数据转换为User模型
  User _convertApiUserToUser(Map<String, dynamic> apiUser) {
    return User(
      id: apiUser['id'].toString(),
      username: apiUser['username'] ?? '',
      email: apiUser['email'],
      nickname: apiUser['nickname'] ?? apiUser['username'],
      token: token,
      role: apiUser['role'] ?? 'USER',
    );
  }
  
  /// 将API返回的备忘录数据转换为Note模型
  Note _convertToNote(Map<String, dynamic> memo) {
    // 提取ID
    String id = memo['id'].toString();
    
    // 处理时间戳 - Memos API 返回的是秒级时间戳，需要转换为毫秒
    int createdTsSeconds = memo['createdTs'] as int;
    int updatedTsSeconds = memo['updatedTs'] as int;
    
    // 转换为毫秒级时间戳
    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(createdTsSeconds * 1000);
    DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedTsSeconds * 1000);
    
    // 提取内容和可见性
    String content = memo['content'] ?? '';
    String visibility = memo['visibility'] ?? 'PRIVATE';
    
    // 提取创建者
    String creator = memo['creatorId']?.toString() ?? '';
    
    // 创建Note对象
    return Note(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      displayTime: updatedAt,
      creator: creator,
      visibility: visibility,
      tags: Note.extractTagsFromContent(content),
      isSynced: true,
      isPinned: memo['pinned'] ?? false,
    );
  }
} 