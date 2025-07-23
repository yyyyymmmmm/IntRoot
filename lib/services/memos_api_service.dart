import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../utils/time_utils.dart';
import 'memos_api_service_fix.dart';

/// Memos API服务类
class MemosApiService {
  final String baseUrl;
  final String? token;
  
  MemosApiService({required this.baseUrl, this.token});
  
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
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/memo'),
      headers: _getHeaders(),
      body: jsonEncode({
        'content': content,
        'visibility': visibility,
      }),
    );
    
    if (response.statusCode == 200) {
      return MemosApiServiceFix.convertMemoToNote(jsonDecode(response.body));
    } else {
      throw Exception('创建备忘录失败: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// 获取备忘录列表
  Future<Map<String, dynamic>> getMemos({
    int? limit,
    int? offset,
    String? rowStatus,
  }) async {
    String url = '$baseUrl/api/v1/memo';
    
    // 构建查询参数
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    if (rowStatus != null) queryParams['rowStatus'] = rowStatus;
    
    if (queryParams.isNotEmpty) {
      url += '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return {
        'memos': data.map((json) => MemosApiServiceFix.convertMemoToNote(json)).toList(),
        'nextPageToken': null, // V1 API没有分页标记
      };
    } else {
      throw Exception('获取备忘录失败: ${response.statusCode}');
    }
  }
  
  /// 搜索备忘录
  Future<List<Note>> searchMemos(String content) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/memo?content=$content'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MemosApiServiceFix.convertMemoToNote(json)).toList();
    } else {
      throw Exception('搜索备忘录失败: ${response.statusCode}');
    }
  }
  
  /// 获取单个备忘录
  Future<Note> getMemo(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/memo/$id'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return MemosApiServiceFix.convertMemoToNote(jsonDecode(response.body));
    } else {
      throw Exception('获取备忘录失败: ${response.statusCode}');
    }
  }
  
  /// 更新备忘录
  Future<Note> updateMemo(String id, {
    String? content,
    String? visibility,
  }) async {
    try {
      print('MemosApiService: 开始更新备忘录 ID: $id');
      
      // 确保至少有一个字段需要更新
      if (content == null && visibility == null) {
        throw Exception('没有提供要更新的内容');
      }

      // 构建请求体，按照API文档格式
      final Map<String, dynamic> body = {
        "memo": {
          "name": "memos/$id",
          "content": content,
          "visibility": visibility ?? "PRIVATE"
        },
        "update_mask": {
          "paths": []
        }
      };
      
      // 添加需要更新的字段到 update_mask
      if (content != null) body["update_mask"]["paths"].add("content");
      if (visibility != null) body["update_mask"]["paths"].add("visibility");
      
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/memos/$id'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      print('MemosApiService: 收到响应，状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('MemosApiService: 解析响应数据成功');
        return MemosApiServiceFix.convertMemoToNote(responseData);
      } else if (response.statusCode == 404) {
        print('MemosApiService: 备忘录不存在 (404)');
        throw Exception('备忘录不存在');
      } else if (response.statusCode == 401) {
        print('MemosApiService: 未授权 (401)');
        throw Exception('未授权，请重新登录');
      } else {
        print('MemosApiService: 更新备忘录失败: ${response.statusCode} - ${response.body}');
        throw Exception('更新备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      print('MemosApiService: 更新备忘录时发生错误: $e');
      throw Exception('更新备忘录失败: $e');
    }
  }
  

  
  /// 删除备忘录
  Future<void> deleteMemo(String id) async {
    try {
      print('MemosApiService: 开始删除备忘录 ID: $id');
      
      // 从ID中提取第一组数字作为memoId
      final match = RegExp(r'(\d+)').firstMatch(id);
      if (match == null) {
        throw Exception('无效的备忘录ID格式');
      }
      final memoId = match.group(1);
      print('MemosApiService: 提取到的数字ID: $memoId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/memo/$memoId'),
        headers: _getHeaders(),
      );
    
      print('MemosApiService: 收到响应，状态码: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('MemosApiService: 删除成功');
        return;
      } else if (response.statusCode == 404) {
        print('MemosApiService: 备忘录不存在 (404)');
        throw Exception('备忘录不存在');
      } else if (response.statusCode == 401) {
        print('MemosApiService: 未授权 (401)');
        throw Exception('未授权，请重新登录');
      } else {
        print('MemosApiService: 删除备忘录失败: ${response.statusCode} - ${response.body}');
        throw Exception('删除备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      print('MemosApiService: 删除备忘录时发生错误: $e');
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
      throw Exception('获取用户信息失败: ${response.statusCode}');
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
      
      // 构建请求体
      final Map<String, dynamic> body = {};
      
      if (nickname != null) {
        if (nickname.length > 64) {
          throw Exception('昵称长度不能超过64个字符');
        }
        body['nickname'] = nickname;
      }
      
      if (email != null) {
        if (email.length > 256) {
          throw Exception('邮箱长度不能超过256个字符');
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
          throw Exception('邮箱格式不正确');
        }
        body['email'] = email;
      }
      
      if (avatarUrl != null) {
        body['avatarUrl'] = avatarUrl;
      }
      
      if (description != null) {
        body['description'] = description;
      }
      
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/user/me'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      
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
        print('更新用户信息失败: ${response.statusCode} - ${response.body}');
        throw Exception('更新用户信息失败: ${response.statusCode}');
      }
    } catch (e) {
      print('更新用户信息时发生错误: $e');
      throw Exception('更新用户信息失败: $e');
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
      throw Exception('登录失败: ${response.statusCode}');
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
} 