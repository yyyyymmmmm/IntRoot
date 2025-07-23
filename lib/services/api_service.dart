import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note_model.dart';
import '../models/user_model.dart';

class ApiService {
  final String baseUrl;
  final String? token;
  
  ApiService({required this.baseUrl, this.token});
  
  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // 用户登录
  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signin'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('登录失败: ${response.statusCode} - ${response.body}');
    }
  }
  
  // 获取所有笔记
  Future<List<Note>> getNotes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/memo'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('获取笔记失败: ${response.statusCode}');
    }
  }
  
  // 创建笔记
  Future<Note> createNote(Note note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/memo'),
      headers: _getHeaders(),
      body: jsonEncode({
        'content': note.content,
        'tags': note.tags,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Note.fromJson(data);
    } else {
      throw Exception('创建笔记失败: ${response.statusCode}');
    }
  }
  
  // 更新笔记
  Future<Note> updateNote(Note note) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/memo/${note.id}'),
      headers: _getHeaders(),
      body: jsonEncode({
        'content': note.content,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Note.fromJson(data);
    } else {
      throw Exception('更新笔记失败: ${response.statusCode}');
    }
  }
  
  // 删除笔记
  Future<void> deleteNote(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/memo/$id'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode != 200) {
      throw Exception('删除笔记失败: ${response.statusCode}');
    }
  }
  
  // 获取用户信息
  Future<User> getUserInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/me'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('获取用户信息失败: ${response.statusCode}');
    }
  }
  
  // 检查服务器连接
  Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
        headers: _getHeaders(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // 同步本地数据到服务器
  Future<List<Note>> syncNotesToServer(List<Note> notes) async {
    List<Note> syncedNotes = [];
    
    for (var note in notes) {
      try {
        final syncedNote = await createNote(note);
        syncedNotes.add(syncedNote);
      } catch (e) {
        print('同步笔记失败: ${note.id} - $e');
      }
    }
    
    return syncedNotes;
  }
} 