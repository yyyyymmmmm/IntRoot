import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../models/app_config_model.dart';
import '../models/sort_order.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/memos_api_service_fixed.dart'; // 使用修复版API服务
import '../services/preferences_service.dart';
import '../services/api_service_factory.dart';
import 'package:http/http.dart' as http; // 添加http包
import '../services/announcement_service.dart';
import '../models/announcement_model.dart';
import '../widgets/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppProvider with ChangeNotifier {
  User? _user;
  List<Note> _notes = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  ApiService? _apiService; // 保留兼容旧服务
  MemosApiServiceFixed? _memosApiService; // 使用修复版API服务
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferencesService = PreferencesService();
  AppConfig _appConfig = AppConfig();
  bool _mounted = true;
  
  // 同步相关变量
  Timer? _syncTimer;
  bool _isSyncing = false;
  String? _syncMessage;
  
  // 通知相关属性
  final AnnouncementService _announcementService = AnnouncementService();
  int _unreadAnnouncementsCount = 0;
  List<Announcement> _announcements = []; // 新增：用于存储公告列表
  
  // Getters
  User? get user => _user;
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null && _user!.token != null && _user!.token!.isNotEmpty;
  bool get isLocalMode => _appConfig.isLocalMode;
  AppConfig get appConfig => _appConfig;
  ApiService? get apiService => _apiService;
  MemosApiServiceFixed? get memosApiService => _memosApiService;
  DatabaseService get databaseService => _databaseService;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;
  bool get mounted => _mounted;
  
  int get unreadAnnouncementsCount => _unreadAnnouncementsCount;
  List<Announcement> get announcements => _announcements;
  
  // 初始化应用
  Future<void> initializeApp() async {
    if (_isInitialized) return;

    print('AppProvider: 开始初始化应用');
    
    try {
      // 加载应用配置
      print('AppProvider: 加载应用配置');
      _appConfig = await _preferencesService.loadAppConfig();
      print('AppProvider: 应用配置加载完成: $_appConfig');
      
      // 加载用户信息
      print('AppProvider: 加载用户信息');
      _user = await _preferencesService.getUser();
      print('AppProvider: 用户信息加载完成: ${_user != null ? "已登录" : "未登录"}');
      
      // 初始化API服务（这是必要的基础服务，需要在设置初始化标志之前完成）
      if (_user != null && (_user!.serverUrl != null || _appConfig.memosApiUrl != null)) {
        print('AppProvider: 初始化API服务');
        try {
          final baseUrl = _user!.serverUrl ?? _appConfig.memosApiUrl!;
          final token = _user!.token ?? _appConfig.lastToken!;
          _memosApiService = await ApiServiceFactory.createApiService(
            baseUrl: baseUrl,
            token: token,
          ) as MemosApiServiceFixed;
          print('AppProvider: API服务初始化成功');
          
          // 启动自动同步
          startAutoSync();
        } catch (e) {
          print('AppProvider: API服务初始化失败: $e');
        }
      }
      
      // 设置初始化标志为true，让启动页可以继续
      _isInitialized = true;
      notifyListeners();
      
      // 在后台继续加载其他数据
      _loadRemainingData();
    } catch (e) {
      print('AppProvider: 初始化应用异常: $e');
      // 设置初始化标志为true，避免卡在启动页
      _isInitialized = true;
      notifyListeners();
    }
  }

  // 在后台加载剩余数据
  Future<void> _loadRemainingData() async {
    try {
      // 加载笔记
      print('AppProvider: 加载笔记');
      try {
        _notes = await _databaseService.getNotes();
        print('AppProvider: 笔记加载完成，共 ${_notes.length} 条');
        notifyListeners();
        
        // 如果API服务已初始化，尝试同步数据
        if (_memosApiService != null && !_appConfig.isLocalMode) {
          print('AppProvider: 尝试同步数据到服务器');
          await syncLocalDataToServer();
        }
      } catch (e) {
        print('AppProvider: 加载笔记失败: $e');
        _notes = [];
      }
      
      // 加载通知
      print('AppProvider: 加载通知');
      try {
        await refreshAnnouncements();
        await refreshUnreadAnnouncementsCount();
        print('AppProvider: 通知加载完成');
      } catch (e) {
        print('AppProvider: 加载通知失败: $e');
      }
      
      print('AppProvider: 所有数据加载完成');
      notifyListeners();
    } catch (e) {
      print('AppProvider: 加载剩余数据失败: $e');
    }
  }
  
  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // 从本地数据库加载笔记
  Future<void> loadNotesFromLocal() async {
    try {
      print('AppProvider: 从本地加载笔记');
      _notes = await _databaseService.getNotes();
      
      // 重新提取所有笔记的标签
      _refreshAllNoteTags();
      
      notifyListeners();
      print('AppProvider: 本地笔记加载完成');
    } catch (e) {
      print('AppProvider: 从本地加载笔记失败: $e');
      rethrow;
    }
  }
  
  // 重新提取所有笔记的标签
  void _refreshAllNoteTags() {
    print('AppProvider: 开始重新提取所有笔记的标签');
    for (var i = 0; i < _notes.length; i++) {
      var note = _notes[i];
      var tags = extractTags(note.content);
      if (tags.length != note.tags.length || !note.tags.toSet().containsAll(tags)) {
        print('AppProvider: 更新笔记 ${note.id} 的标签: ${note.tags.join(',')} -> ${tags.join(',')}');
        _notes[i] = note.copyWith(tags: tags);
        // 不需要await，批量更新标签只更新内存中的标签，不更新数据库
      }
    }
  }

  // 扫描所有笔记并更新标签（包括数据库更新）
  Future<void> refreshAllNoteTagsWithDatabase() async {
    print('AppProvider: 开始扫描所有笔记并更新标签');
    _setLoading(true);
    try {
      for (var i = 0; i < _notes.length; i++) {
        var note = _notes[i];
        var tags = extractTags(note.content);
        if (tags.length != note.tags.length || !note.tags.toSet().containsAll(tags)) {
          print('AppProvider: 更新笔记 ${note.id} 的标签: ${note.tags.join(',')} -> ${tags.join(',')}');
          var updatedNote = note.copyWith(tags: tags);
          _notes[i] = updatedNote;
          await _databaseService.updateNote(updatedNote);
        }
      }
      notifyListeners();
    } catch (e) {
      print('AppProvider: 更新所有笔记标签失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 计算笔记内容的哈希值
  String _calculateNoteHash(Note note) {
    final content = utf8.encode(note.content);
    final digest = sha256.convert(content);
    return digest.toString();
  }

  // 检查是否存在相同内容的笔记
  Future<bool> _isDuplicateNote(Note note) async {
    final noteHash = _calculateNoteHash(note);
    
    // 检查本地数据库中是否有相同哈希值的笔记
    final allNotes = await _databaseService.getNotes();
    for (var existingNote in allNotes) {
      if (_calculateNoteHash(existingNote) == noteHash) {
        return true;
      }
    }
    
    return false;
  }

  // 检测本地是否有数据
  Future<bool> hasLocalData() async {
    final notes = await _databaseService.getNotes();
    return notes.isNotEmpty;
  }
  
  // 检测云端是否有数据
  Future<bool> hasServerData() async {
    if (!isLoggedIn || _memosApiService == null) return false;
    
    try {
      final response = await _memosApiService!.getMemos();
      final serverNotes = response['memos'] as List<Note>;
      return serverNotes.isNotEmpty;
    } catch (e) {
      print('检查云端数据失败: $e');
      return false;
    }
  }

  // 更新应用配置
  Future<void> updateConfig(AppConfig newConfig) async {
    print('AppProvider: 更新配置');
    print('AppProvider: 新配置: $newConfig');
    
    // 检查API URL是否变化
    final apiUrlChanged = _appConfig.memosApiUrl != newConfig.memosApiUrl;
    
    // 检查暗黑模式是否变化
    final darkModeChanged = _appConfig.isDarkMode != newConfig.isDarkMode;
    
    // 保存新配置
    _appConfig = newConfig;
    await _preferencesService.saveAppConfig(newConfig);
    
    // 如果API URL变化，重新创建API服务
    if (apiUrlChanged) {
      print('AppProvider: API URL已更改，重新创建API服务');
      if (newConfig.memosApiUrl != null && newConfig.lastToken != null) {
        _memosApiService = await ApiServiceFactory.createApiService(
          baseUrl: newConfig.memosApiUrl!,
          token: newConfig.lastToken!,
        ) as MemosApiServiceFixed;
      } else {
        _memosApiService = null;
      }
    }
    
    // 如果暗黑模式变化，需要通知界面刷新主题
    if (darkModeChanged) {
      print('AppProvider: 暗黑模式已${newConfig.isDarkMode ? '开启' : '关闭'}');
    }
    
    print('AppProvider: 配置更新成功');
    notifyListeners();
  }
  
  // 获取当前深色模式状态
  bool get isDarkMode {
    // 如果设置了跟随系统，则返回系统深色模式状态
    if (_appConfig.themeSelection == AppConfig.THEME_SYSTEM) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    // 否则根据主题选择返回
    return _appConfig.themeSelection == AppConfig.THEME_DARK;
  }
  
  // 切换深色模式（兼容旧版本）
  Future<void> toggleDarkMode() async {
    final newTheme = isDarkMode ? AppConfig.THEME_LIGHT : AppConfig.THEME_DARK;
    await setThemeSelection(newTheme);
  }
  
  // 设置深色模式（兼容旧版本）
  Future<void> setDarkMode(bool value) async {
    final newTheme = value ? AppConfig.THEME_DARK : AppConfig.THEME_LIGHT;
    await setThemeSelection(newTheme);
  }
  
  // 设置主题选择
  Future<void> setThemeSelection(String themeSelection) async {
    if (themeSelection == _appConfig.themeSelection) return;
    
    // 同时更新isDarkMode以保持向后兼容
    bool isDarkMode = themeSelection == AppConfig.THEME_DARK;
    // 对于跟随系统，需要获取当前系统设置
    if (themeSelection == AppConfig.THEME_SYSTEM) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
    }
    
    final updatedConfig = _appConfig.copyWith(
      themeSelection: themeSelection,
      isDarkMode: isDarkMode,
    );
    await updateConfig(updatedConfig);
  }
  
  // 获取当前主题选择
  String get themeSelection => _appConfig.themeSelection;
  
  // 设置主题模式
  Future<void> setThemeMode(String mode) async {
    if (mode == _appConfig.themeMode) return;
    
    final updatedConfig = _appConfig.copyWith(
      themeMode: mode
    );
    await updateConfig(updatedConfig);
  }

  // 获取当前主题模式
  String get themeMode => _appConfig.themeMode;

  // 同步本地数据到云端
  Future<bool> syncLocalToServer() async {
    if (!isLoggedIn || _memosApiService == null) return false;
    
    _setLoading(true);
    
    try {
      // 获取本地笔记
      final localNotes = await _databaseService.getNotes();
      if (localNotes.isEmpty) return true;
      
      // 获取服务器笔记以检查重复
      final response = await _memosApiService!.getMemos();
      final serverNotes = response['memos'] as List<Note>;
      
      // 计算所有服务器笔记的哈希值
      final serverHashes = serverNotes.map(_calculateNoteHash).toSet();
      
      // 同步每个本地笔记到服务器
      int syncedCount = 0;
      for (var note in localNotes) {
        // 如果笔记已经同步，跳过
        if (note.isSynced) continue;
        
        // 计算本地笔记的哈希值
        final noteHash = _calculateNoteHash(note);
        
        // 如果服务器上已有相同内容的笔记，跳过
        if (serverHashes.contains(noteHash)) {
          // 标记为已同步
          note.isSynced = true;
          await _databaseService.updateNote(note);
          continue;
        }
        
        try {
          // 创建服务器笔记
          final serverNote = await _memosApiService!.createMemo(
            content: note.content,
            visibility: note.visibility,
          );
          
          // 更新本地笔记的同步状态
          final updatedNote = note.copyWith(
            isSynced: true,
          );
          
          // 更新数据库
          await _databaseService.updateNote(updatedNote);
          
          syncedCount++;
        } catch (e) {
          print('同步笔记失败: ${note.id} - $e');
        }
      }
      
      // 刷新内存中的列表
      await loadNotesFromLocal();
      
      print('成功同步 $syncedCount 条笔记到云端');
      return true;
    } catch (e) {
      print('同步本地数据到云端失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 同步云端数据到本地
  Future<bool> syncServerToLocal() async {
    if (!isLoggedIn || _memosApiService == null) return false;
    
    _setLoading(true);
    
    try {
      // 获取服务器笔记
      final response = await _memosApiService!.getMemos();
      final serverNotes = response['memos'] as List<Note>;
      if (serverNotes.isEmpty) return true;
      
      // 获取本地笔记以检查重复
      final localNotes = await _databaseService.getNotes();
      
      // 计算所有本地笔记的哈希值
      final localHashes = localNotes.map(_calculateNoteHash).toSet();
      
      // 同步每个服务器笔记到本地
      int syncedCount = 0;
      for (var serverNote in serverNotes) {
        // 计算服务器笔记的哈希值
        final noteHash = _calculateNoteHash(serverNote);
        
        // 如果本地已有相同内容的笔记，跳过
        if (localHashes.contains(noteHash)) {
          continue;
        }
        
        // 保存到本地数据库
        await _databaseService.saveNote(serverNote);
        syncedCount++;
      }
      
      // 刷新内存中的列表
      await loadNotesFromLocal();
      
      print('成功同步 $syncedCount 条笔记到本地');
      return true;
    } catch (e) {
      print('同步云端数据到本地失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 使用Token登录
  Future<(bool, String?)> loginWithToken(String serverUrl, String token, {bool remember = false}) async {
    try {
      print('AppProvider: 尝试使用Token登录 - URL: $serverUrl');
      
      // 规范化URL（确保末尾没有斜杠）
      final normalizedUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
      
      print('AppProvider: 规范化后的URL: $normalizedUrl');
      
      // 初始化API服务
      _memosApiService = await ApiServiceFactory.createApiService(
        baseUrl: normalizedUrl,
        token: token,
      ) as MemosApiServiceFixed;
      
      // 验证Token
      try {
        // 先尝试 v1 API
        print('AppProvider: 尝试访问 v1 API: $normalizedUrl/api/v1/user/me');
        final response = await http.get(
          Uri.parse('$normalizedUrl/api/v1/user/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('AppProvider: v1 API响应状态码: ${response.statusCode}');
        print('AppProvider: v1 API响应内容: ${response.body}');
        
        if (response.statusCode == 200) {
          try {
            final userInfo = jsonDecode(response.body);
            print('AppProvider: 解析到的用户信息: $userInfo');
            
            // 检查响应格式
            if (userInfo == null) {
              throw Exception('服务器返回空数据');
            }

            User? user;
            if (userInfo['data'] != null) {
              // 新版API格式
              print('AppProvider: 使用新版API格式解析');
              final userData = userInfo['data'];
              user = User(
                id: userData['id'].toString(),
                username: userData['username'] as String? ?? '',
                nickname: userData['nickname'] as String?,
                email: userData['email'] as String?,
                avatarUrl: userData['avatarUrl'] as String?,
                description: userData['description'] as String?,
                role: (userData['role'] as String?) ?? 'USER',
                token: token,
                lastSyncTime: DateTime.now(),
              );
            } else {
              // 旧版API格式
              print('AppProvider: 使用旧版API格式解析');
              user = User(
                id: userInfo['id'].toString(),
                username: userInfo['username'] as String? ?? '',
                nickname: userInfo['nickname'] as String?,
                email: userInfo['email'] as String?,
                avatarUrl: userInfo['avatarUrl'] as String?,
                description: userInfo['description'] as String?,
                role: (userInfo['role'] as String?) ?? 'USER',
                token: token,
                lastSyncTime: DateTime.now(),
              );
            }
            
            // 保存用户信息
            await _preferencesService.saveUser(user);
            _user = user;
            
            // 更新配置
            final updatedConfig = _appConfig.copyWith(
              memosApiUrl: normalizedUrl,
              lastToken: remember ? token : null,
              rememberLogin: remember,
              isLocalMode: false,
            );
            await updateConfig(updatedConfig);
            
            print('AppProvider: Token登录成功');
            
            // 检查本地是否有未同步笔记
            final hasLocalNotes = await hasLocalData();
            if (hasLocalNotes) {
              print('AppProvider: 检测到本地有笔记数据，需要同步');
            }
            
            return (true, null);
          } catch (e, stackTrace) {
            print('AppProvider: 解析用户信息失败: $e');
            print('AppProvider: 错误堆栈: $stackTrace');
            throw Exception('解析用户信息失败: $e');
          }
        } else if (response.statusCode == 404 || response.statusCode == 401) {
          // 如果v1 API不存在或未授权，尝试旧版API
          print('AppProvider: v1 API返回 ${response.statusCode}，尝试旧版API');
          print('AppProvider: 尝试访问旧版API: $normalizedUrl/api/user/me');
          
          final oldResponse = await http.get(
            Uri.parse('$normalizedUrl/api/user/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          print('AppProvider: 旧版API响应状态码: ${oldResponse.statusCode}');
          print('AppProvider: 旧版API响应内容: ${oldResponse.body}');

          if (oldResponse.statusCode == 200) {
            try {
              final userInfo = jsonDecode(oldResponse.body);
              print('AppProvider: 解析到的用户信息（旧版API）: $userInfo');
              
              final user = User(
                id: userInfo['id'].toString(),
                username: userInfo['username'] as String? ?? '',
                nickname: userInfo['nickname'] as String?,
                email: userInfo['email'] as String?,
                avatarUrl: userInfo['avatarUrl'] as String?,
                description: userInfo['description'] as String?,
                role: (userInfo['role'] as String?) ?? 'USER',
                token: token,
                lastSyncTime: DateTime.now(),
              );
              
              // 保存用户信息
              await _preferencesService.saveUser(user);
              _user = user;
              
              // 更新配置
              final updatedConfig = _appConfig.copyWith(
                memosApiUrl: normalizedUrl,
                lastToken: remember ? token : null,
                rememberLogin: remember,
                isLocalMode: false,
              );
              await updateConfig(updatedConfig);
              
              print('AppProvider: Token登录成功（旧版API）');
              
              // 检查本地是否有未同步笔记
              final hasLocalNotes = await hasLocalData();
              if (hasLocalNotes) {
                print('AppProvider: 检测到本地有笔记数据，需要同步');
              }
              
              return (true, null);
            } catch (e, stackTrace) {
              print('AppProvider: 解析用户信息失败（旧版API）: $e');
              print('AppProvider: 错误堆栈: $stackTrace');
              throw Exception('解析用户信息失败（旧版API）: $e');
            }
          } else {
            throw Exception('获取用户信息失败: ${oldResponse.statusCode}');
          }
        } else {
          throw Exception('获取用户信息失败: ${response.statusCode}');
        }
      } catch (e, stackTrace) {
        print('AppProvider: 验证Token失败: $e');
        print('AppProvider: 错误堆栈: $stackTrace');
        throw Exception('验证Token失败: $e');
      }
    } catch (e, stackTrace) {
      print('AppProvider: Token登录失败: $e');
      print('AppProvider: 错误堆栈: $stackTrace');
      return (false, e.toString());
    }
  }
  
  // 登录后检查本地数据并提示用户是否需要同步
  Future<void> checkAndSyncOnLogin() async {
    try {
      print('AppProvider: 登录后检查本地数据');
      
      // 检查本地和服务器是否有数据
      final hasLocalData = await this.hasLocalData();
      final hasServerData = await this.hasServerData();
      
      if (hasLocalData) {
        print('AppProvider: 检测到本地有数据');
        
        // 本地有数据，从服务器获取数据时会自动保留本地未同步的笔记
        // fetchNotesFromServer方法已经被修改，会处理本地未同步笔记
        await fetchNotesFromServer();
        
        // 这里已经不需要返回状态让UI处理了，因为修改后的同步流程会自动处理
        return;
      } else {
        print('AppProvider: 本地无数据，直接获取服务器数据');
        // 直接获取服务器数据
        await fetchNotesFromServer();
      }
    } catch (e) {
      print('AppProvider: 检查同步状态失败: $e');
      // 出错时，至少确保加载了数据
      await loadNotesFromLocal();
    }
  }
  
  // 同步本地数据到服务器
  Future<bool> syncLocalDataToServer() async {
    // 设置同步状态
    _isSyncing = true;
    _syncMessage = '准备同步本地数据...';
    notifyListeners();
    
    if (!isLoggedIn || _memosApiService == null) {
      print('AppProvider: 未登录或API服务未初始化，无法同步');
      _isSyncing = false;
      _syncMessage = null;
      notifyListeners();
      return false;
    }

    try {
      print('AppProvider: 开始同步本地数据到云端');
      
      // 获取本地未同步的笔记
      _syncMessage = '检查未同步笔记...';
      notifyListeners();
      
      final unsyncedNotes = await _databaseService.getUnsyncedNotes();
      print('AppProvider: 发现 ${unsyncedNotes.length} 条未同步的笔记');

      if (unsyncedNotes.isEmpty) {
        _syncMessage = '所有笔记已同步';
        notifyListeners();
        
        // 延迟一点时间再清除同步状态
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _isSyncing = false;
            _syncMessage = null;
            notifyListeners();
          }
        });
        
        return true;
      }

      int syncedCount = 0;
      for (int i = 0; i < unsyncedNotes.length; i++) {
        final note = unsyncedNotes[i];
        _syncMessage = '正在同步笔记 ${i + 1}/${unsyncedNotes.length}...';
        notifyListeners();
        
        try {
          if (note.id.startsWith('local_')) {
            // 新建笔记
            final createdNote = await _memosApiService!.createMemo(
              content: note.content,
              visibility: note.visibility,
            );
            await _databaseService.updateNoteServerId(
              note.id,
              createdNote.id,
            );
            syncedCount++;
          } else {
            // 更新笔记
            await _memosApiService!.updateMemo(
              note.id,
              content: note.content,
              visibility: note.visibility,
            );
            await _databaseService.markNoteSynced(note.id);
            syncedCount++;
          }
        } catch (e) {
          print('AppProvider: 同步笔记失败: ${note.id}, 错误: $e');
          continue;
        }
      }

      print('AppProvider: 成功同步 $syncedCount 条笔记到云端');
      
      // 从服务器获取最新数据
      _syncMessage = '刷新最新数据...';
      notifyListeners();
      
      await fetchNotesFromServer();
      
      _syncMessage = '同步完成';
      notifyListeners();
      
      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          notifyListeners();
        }
      });
      
      return true;
    } catch (e) {
      print('AppProvider: 同步失败: $e');
      
      _syncMessage = '同步失败: ${e.toString().split('\n')[0]}';
      notifyListeners();
      
      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          notifyListeners();
        }
      });
      
      return false;
    }
  }

  // 从文本内容中提取标签
  List<String> extractTags(String content) {
    final RegExp tagRegex = RegExp(r'#([\p{L}\p{N}_\u4e00-\u9fff]+)', unicode: true);
    final matches = tagRegex.allMatches(content);
    
    return matches
      .map((match) => match.group(1))
      .where((tag) => tag != null)
      .map((tag) => tag!)
      .toList();
  }

  // 获取所有标签
  Set<String> getAllTags() {
    Set<String> tags = {};
    for (var note in _notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }

  // 排序笔记
  void sortNotes(SortOrder order) {
    switch (order) {
      case SortOrder.newest:
        _notes.sort((a, b) {
          // 先按是否置顶排序，置顶的在前面
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          // 再按创建时间排序
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case SortOrder.oldest:
        _notes.sort((a, b) {
          // 先按是否置顶排序，置顶的在前面
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          // 再按创建时间排序
          return a.createdAt.compareTo(b.createdAt);
        });
        break;
      case SortOrder.updated:
        _notes.sort((a, b) {
          // 先按是否置顶排序，置顶的在前面
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          // 再按更新时间排序
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
    }
    notifyListeners();
  }

  // 切换笔记的置顶状态
  Future<bool> togglePinStatus(Note note) async {
    try {
      // 切换置顶状态
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      
      // 更新本地数据库
      await _databaseService.updateNote(updatedNote);
      
      // 如果是在线模式且已登录，尝试同步到服务器
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        try {
          // 这里应该调用相应的API来更新笔记的置顶状态
          final serverNote = await _memosApiService!.updateMemo(
            note.id,
            content: note.content,
            visibility: note.visibility,
          );
          
          // 更新本地数据库
          final syncedNote = serverNote.copyWith(
            isPinned: updatedNote.isPinned,
            isSynced: true,
          );
          await _databaseService.updateNote(syncedNote);
          
          // 更新内存中的列表
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = syncedNote;
          }
        } catch (e) {
          print('同步置顶状态到服务器失败: $e');
        }
      }
      
      // 更新内存中的列表
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }
      
      // 重新排序笔记列表
      final currentOrder = _getCurrentSortOrder();
      sortNotes(currentOrder);
      
      return true;
    } catch (e) {
      print('切换置顶状态失败: $e');
      return false;
    }
  }

  // 获取当前的排序方式
  SortOrder _getCurrentSortOrder() {
    if (_notes.length < 2) return SortOrder.newest;
    
    // 忽略置顶状态，仅根据时间判断排序方式
    List<Note> unpinnedNotes = _notes.where((note) => !note.isPinned).toList();
    if (unpinnedNotes.length < 2) return SortOrder.newest;
    
    if (unpinnedNotes[0].createdAt.isAfter(unpinnedNotes[1].createdAt)) {
      return SortOrder.newest;
    } else if (unpinnedNotes[0].createdAt.isBefore(unpinnedNotes[1].createdAt)) {
      return SortOrder.oldest;
    } else if (unpinnedNotes[0].updatedAt.isAfter(unpinnedNotes[1].updatedAt)) {
      return SortOrder.updated;
    }
    
    return SortOrder.newest; // 默认返回最新排序
  }

  // 切换到本地模式
  Future<void> switchToLocalMode() async {
    _appConfig = _appConfig.copyWith(isLocalMode: true);
    await _preferencesService.saveAppConfig(_appConfig);
    notifyListeners();
  }

  // 退出登录
  Future<(bool, String?)> logout({bool force = false, bool keepLocalData = true}) async {
    if (!force) {
      _setLoading(true);
    } else {
      // 设置同步状态
      _isSyncing = true;
      _syncMessage = '正在处理退出登录...';
      notifyListeners();
    }
    
    try {
      // 检查是否有未同步的笔记
      if (!force && !_appConfig.isLocalMode && isLoggedIn) {
        final unsyncedNotes = await _databaseService.getUnsyncedNotes();
        if (unsyncedNotes.isNotEmpty) {
          _setLoading(false);
          return (false, "有${unsyncedNotes.length}条笔记未同步到云端，退出登录后这些笔记将无法同步。确定要退出吗？");
        }
      }
      
      // 如果不保留本地数据，则清空数据库
      if (!keepLocalData) {
        _syncMessage = '清空本地数据库...';
        notifyListeners();
        
        print('AppProvider: 清空本地数据库');
        await _databaseService.clearAllNotes();
      } else {
        _syncMessage = '保存本地数据...';
        notifyListeners();
        
        print('AppProvider: 保留本地数据');
      }
      
      // 取消同步定时器
      _syncTimer?.cancel();
      _syncTimer = null;
      
      // 清除用户信息
      _user = null;
      await _preferencesService.clearUser();
      
      _syncMessage = '更新配置...';
      notifyListeners();
      
      // 更新配置为本地模式，但保留记住的登录信息
      final bool rememberLogin = _appConfig.rememberLogin;
      final String? lastToken = rememberLogin ? _appConfig.lastToken : null;
      final String? lastServerUrl = rememberLogin ? _appConfig.lastServerUrl : null;
      
      _appConfig = _appConfig.copyWith(
        isLocalMode: true,
        // 如果之前选择了记住登录，则保留这些信息
        rememberLogin: rememberLogin,
        lastToken: lastToken,
        lastServerUrl: lastServerUrl,
      );
      await _preferencesService.saveAppConfig(_appConfig);
      
      // 清除API服务
      _apiService = null;
      _memosApiService = null;
      
      // 重新加载本地笔记
      if (keepLocalData) {
        _syncMessage = '加载本地笔记...';
        notifyListeners();
        
        await loadNotesFromLocal();
      } else {
        _notes = [];
      }
      
      _syncMessage = '退出登录完成';
      notifyListeners();
      
      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          notifyListeners();
        }
      });
      
      return (true, null);
    } catch (e) {
      print('退出登录失败: $e');
      
      _syncMessage = '退出登录失败: ${e.toString().split('\n')[0]}';
      notifyListeners();
      
      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          _setLoading(false);
          notifyListeners();
        }
      });
      
      return (false, "退出登录失败: $e");
    } finally {
      if (!force) {
        _setLoading(false);
      }
    }
  }

  // 仅获取服务器数据
  Future<bool> fetchServerDataOnly() async {
    print('AppProvider: 仅获取服务器数据');
    try {
      // 获取服务器数据
      await fetchNotesFromServer();
      return true;
    } catch (e) {
      print('AppProvider: 获取服务器数据失败: $e');
      return false;
    }
  }

  // 创建笔记
  Future<Note> createNote(String content) async {
    print('AppProvider: 开始创建笔记');
    try {
      // 提取标签
      final tags = extractTags(content);
      print('AppProvider: 提取标签: $tags');
      
      // 当前时间
      final now = DateTime.now();
      
      // 创建笔记对象
      final note = Note(
        id: const Uuid().v4(),
        content: content,
        tags: tags,
        createdAt: now,
        updatedAt: now,
        isSynced: false, // 默认未同步
      );
      
      // 如果是在线模式且已登录，先尝试保存到服务器
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        print('AppProvider: 尝试保存到服务器');
        try {
          final serverNote = await _memosApiService!.createMemo(
            content: content,
            visibility: 'PRIVATE',
          );
          
          // 保存到本地
          await _databaseService.saveNote(serverNote);
          
          // 添加到内存列表
          _notes.insert(0, serverNote); // 添加到列表顶部而不是末尾
          
          print('AppProvider: 笔记已保存到服务器和本地');
          notifyListeners();
          return serverNote;
        } catch (e) {
          print('AppProvider: 保存到服务器失败: $e');
          print('AppProvider: 将改为本地保存');
          
          // 服务器保存失败，尝试重新初始化API服务
          if (_appConfig.memosApiUrl != null && _user?.token != null) {
            _initializeApiService(_appConfig.memosApiUrl!, _user!.token!).then((_) {
              // API服务重新初始化后，尝试同步未同步的笔记
              syncNotesWithServer();
            });
          }
          
          // 继续本地保存流程
        }
      }
      
      // 本地模式或服务器保存失败，保存到本地
      print('AppProvider: 本地保存');
      await _databaseService.saveNote(note);
      
      // 添加到内存列表
      _notes.insert(0, note); // 添加到列表顶部而不是末尾
      
      // 确保置顶笔记仍在最前面
      _applyCurrentSort();
      
      print('AppProvider: 本地保存成功');
      notifyListeners();
      return note;
    } catch (e) {
      print('AppProvider: 创建笔记失败: $e');
      throw Exception('创建笔记失败: $e');
    }
  }
  
  // 应用当前排序规则
  void _applyCurrentSort() {
    final currentOrder = _getCurrentSortOrder();
    sortNotes(currentOrder);
  }

  // 更新笔记
  Future<bool> updateNote(Note note, String newContent) async {
    print('AppProvider: 开始更新笔记 ID: ${note.id}');
    try {
      // 更新内容
      print('AppProvider: 创建更新后的笔记对象');
      final updatedNote = note.copyWith(
        content: newContent,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      
      // 提取标签
      print('AppProvider: 提取标签');
      final tags = extractTags(newContent);
      print('AppProvider: 提取到的标签: ${tags.join(', ')}');
      final noteWithTags = updatedNote.copyWith(tags: tags);
      
      // 更新本地数据库
      print('AppProvider: 更新本地数据库');
      await _databaseService.updateNote(noteWithTags);
      
      // 如果是在线模式且已登录，尝试同步到服务器
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        try {
          print('AppProvider: 尝试同步到服务器，笔记ID: ${noteWithTags.id}');
          // 使用Memos API更新笔记
          final serverNote = await _memosApiService!.updateMemo(
            noteWithTags.id,
            content: newContent,
          );
          
          // 检查返回的笔记ID是否与原笔记ID不同
          if (serverNote.id != noteWithTags.id) {
            print('AppProvider: 服务器返回了新的笔记ID: ${serverNote.id}，原ID: ${noteWithTags.id}');
            // 删除本地旧笔记
            await _databaseService.deleteNote(noteWithTags.id);
            
            // 保存新笔记
            final newSyncedNote = serverNote.copyWith(isSynced: true, tags: tags);
            await _databaseService.saveNote(newSyncedNote);
            
            // 更新内存中的列表 - 删除旧笔记
            _notes.removeWhere((n) => n.id == noteWithTags.id);
            // 添加新笔记
            _notes.insert(0, newSyncedNote); // 添加到列表顶部
            
            _applyCurrentSort();
            notifyListeners();
            print('AppProvider: 笔记已作为新笔记保存（ID已更改）');
            return true;
          }
          
          print('AppProvider: 服务器同步成功，更新同步状态');
          // 更新同步状态
          final syncedNote = serverNote.copyWith(isSynced: true, tags: tags);
          await _databaseService.updateNote(syncedNote);
          
          // 更新内存中的列表
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            print('AppProvider: 更新内存中的笔记');
            _notes[index] = syncedNote;
          }
          
          _applyCurrentSort();
          notifyListeners();
          print('AppProvider: 笔记更新完成（已同步到服务器）');
          return true;
        } catch (e) {
          print('AppProvider: 同步到服务器失败: $e');
          // 如果同步失败，保持本地更新
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = noteWithTags;
          }
          _applyCurrentSort();
          notifyListeners();
          print('AppProvider: 笔记更新完成（仅本地更新）');
          return true;
        }
      } else {
        // 本地模式直接更新内存中的列表
        print('AppProvider: 本地模式更新');
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = noteWithTags;
        }
        _applyCurrentSort();
        notifyListeners();
        print('AppProvider: 笔记本地更新完成');
        return true;
      }
    } catch (e) {
      print('AppProvider: 更新笔记失败: $e');
      return false;
    }
  }

  // 删除笔记（本地和服务器）
  Future<bool> deleteNote(String id) async {
    print('AppProvider: 开始删除笔记 ID: $id');
    try {
      // 如果是在线模式且已登录，先尝试从服务器删除
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        try {
          print('AppProvider: 尝试从服务器删除');
          await deleteNoteFromServer(id);
        } catch (e) {
          print('AppProvider: 从服务器删除笔记失败: $e');
          // 如果是404错误（笔记不存在），继续删除本地笔记
          if (!e.toString().contains('404')) {
            throw e;
          }
        }
      }
      
      // 删除本地数据库中的笔记
      print('AppProvider: 删除本地笔记');
      await deleteNoteLocal(id);
      
      print('AppProvider: 笔记删除完成');
      return true;
    } catch (e) {
      print('AppProvider: 删除笔记失败: $e');
      return false;
    }
  }

  // 仅从本地数据库删除笔记
  Future<bool> deleteNoteLocal(String id) async {
    print('AppProvider: 从本地数据库删除笔记 ID: $id');
    try {
      // 删除本地数据库中的笔记
      await _databaseService.deleteNote(id);
      
      // 从内存中的列表删除
      _notes.removeWhere((note) => note.id == id);
      notifyListeners();
      
      print('AppProvider: 本地笔记删除成功');
      return true;
    } catch (e) {
      print('AppProvider: 从本地删除笔记失败: $e');
      throw Exception('删除本地笔记失败: $e');
    }
  }

  // 仅从服务器删除笔记
  Future<bool> deleteNoteFromServer(String id) async {
    print('AppProvider: 从服务器删除笔记 ID: $id');
    try {
      if (!isLoggedIn || _memosApiService == null) {
        print('AppProvider: 未登录或API服务不可用');
        return false;
      }
      
      // 从服务器删除
      await _memosApiService!.deleteMemo(id);
      print('AppProvider: 服务器笔记删除成功');
      return true;
    } catch (e) {
      print('AppProvider: 从服务器删除笔记失败: $e');
      throw Exception('从服务器删除笔记失败: $e');
    }
  }

  // 从服务器获取笔记
  Future<void> fetchNotesFromServer() async {
    // 设置同步状态
    _isSyncing = true;
    _syncMessage = '正在从服务器获取数据...';
    notifyListeners();
    
    try {
      if (_memosApiService == null) {
        _syncMessage = '初始化API服务...';
        notifyListeners();
        
        print('AppProvider: API服务未初始化，尝试重新初始化');
        
        // 尝试重新初始化API服务
        if (_appConfig.memosApiUrl != null && _user?.token != null) {
          print('AppProvider: 使用当前用户Token初始化API服务');
          _memosApiService = await ApiServiceFactory.createApiService(
            baseUrl: _appConfig.memosApiUrl!,
            token: _user!.token!,
          ) as MemosApiServiceFixed;
        } else if (_appConfig.memosApiUrl != null && _appConfig.lastToken != null) {
          print('AppProvider: 使用上次的Token初始化API服务');
          _memosApiService = await ApiServiceFactory.createApiService(
            baseUrl: _appConfig.memosApiUrl!,
            token: _appConfig.lastToken!,
          ) as MemosApiServiceFixed;
        }
        
        if (_memosApiService == null) {
          throw Exception('API服务初始化失败，无法获取数据');
        }
      }
      
      // 首先获取本地未同步的笔记，稍后将它们与服务器数据合并
      _syncMessage = '保存本地未同步笔记...';
      notifyListeners();
      
      print('AppProvider: 获取本地未同步笔记');
      final unsyncedNotes = await _databaseService.getUnsyncedNotes();
      print('AppProvider: 找到 ${unsyncedNotes.length} 条未同步笔记');
      
      _syncMessage = '获取远程笔记...';
      notifyListeners();
      
      print('AppProvider: 从服务器获取笔记');
      final response = await _memosApiService!.getMemos();
      if (response == null) {
        throw Exception('服务器返回数据为空');
      }
      
      _syncMessage = '处理笔记数据...';
      notifyListeners();
      
      final memosList = response['memos'] as List<dynamic>;
      final serverNotes = memosList.map((memo) => Note.fromJson(memo as Map<String, dynamic>)).toList();
      
      // 为所有服务器笔记重新提取标签
      for (var i = 0; i < serverNotes.length; i++) {
        var note = serverNotes[i];
        var tags = Note.extractTagsFromContent(note.content);
        if (tags.isNotEmpty) {
          print('AppProvider: 为服务器笔记 ${note.id} 提取标签: ${tags.join(',')}');
          serverNotes[i] = note.copyWith(tags: tags);
        }
      }
      
      _syncMessage = '合并数据...';
      notifyListeners();
      
      // 清空本地数据库前确保所有笔记都已保存
      print('AppProvider: 清空本地数据库');
      await _databaseService.clearAllNotes();
      
      // 保存服务器数据到本地
      print('AppProvider: 保存服务器数据到本地');
      await _databaseService.saveNotes(serverNotes);
      
      // 合并本地未同步的笔记
      if (unsyncedNotes.isNotEmpty) {
        print('AppProvider: 合并本地未同步笔记');
        
        // 创建服务器笔记ID集合，用于避免ID冲突
        final serverNoteIds = serverNotes.map((note) => note.id).toSet();
        
        // 创建服务器笔记内容哈希集合，用于避免内容重复
        final serverNoteHashes = serverNotes.map(_calculateNoteHash).toSet();
        
        // 过滤出不在服务器上的未同步笔记
        final notesToMerge = <Note>[];
        for (var note in unsyncedNotes) {
          final noteHash = _calculateNoteHash(note);
          
          // 如果服务器上没有相同内容的笔记，并且ID不冲突，则添加到合并列表
          if (!serverNoteHashes.contains(noteHash) && 
              (!serverNoteIds.contains(note.id) || note.id.startsWith('local_'))) {
            // 如果ID冲突，创建一个新ID
            if (serverNoteIds.contains(note.id)) {
              note = note.copyWith(
                id: 'local_${DateTime.now().millisecondsSinceEpoch}_${notesToMerge.length}',
              );
            }
            notesToMerge.add(note);
          }
        }
        
        // 保存这些笔记到数据库
        if (notesToMerge.isNotEmpty) {
          print('AppProvider: 保存 ${notesToMerge.length} 条本地未同步笔记');
          await _databaseService.saveNotes(notesToMerge);
        }
      }
      
      // 更新内存中的列表
      _notes = await _databaseService.getNotes();
      
      _syncMessage = '同步完成';
      notifyListeners();
      
      print('AppProvider: 笔记同步完成');
    } catch (e, stackTrace) {
      print('AppProvider: 从服务器获取数据失败: $e');
      print('AppProvider: 错误堆栈: $stackTrace');
      
      _syncMessage = '同步失败: ${e.toString().split('\n')[0]}';
      notifyListeners();
      
      // 如果是API服务初始化失败，尝试清除登录状态
      if (e.toString().contains('API服务初始化失败')) {
        await logout(force: true);
      }
      
      print('AppProvider: 保留本地数据');
      // 加载本地数据作为后备
      await loadNotesFromLocal();
      
      rethrow;
    } finally {
      // 延迟一点时间再清除同步状态，让用户有时间看到"同步完成"
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          notifyListeners();
        }
      });
    }
  }

  // 同步本地未同步的笔记到服务器
  Future<void> syncNotesWithServer() async {
    if (!isLoggedIn || _memosApiService == null) return;
    
    try {
      // 获取未同步的笔记
      final unsyncedNotes = await _databaseService.getUnsyncedNotes();
      
      if (unsyncedNotes.isEmpty) return;
      
      // 逐一同步到服务器
      for (var note in unsyncedNotes) {
        try {
          // 创建服务器笔记
          final serverNote = await _memosApiService!.createMemo(
            content: note.content,
            visibility: 'PRIVATE',
          );
          
          // 删除本地笔记（使用临时ID）
          await _databaseService.deleteNote(note.id);
          
          // 保存服务器返回的笔记（带有服务器ID）
          await _databaseService.saveNote(serverNote);
          
          // 更新内存中的列表
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = serverNote;
          }
        } catch (e) {
          print('同步笔记失败: ${note.id} - $e');
        }
      }
      
      // 刷新内存中的列表
      await loadNotesFromLocal();
    } catch (e) {
      print('同步笔记到服务器失败: $e');
    }
  }

  // 创建同步定时器
  void _createSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: _appConfig.syncInterval),
      (_) => syncNotesToServer(),
    );
  }

  // 同步笔记到服务器
  Future<bool> syncNotesToServer() async {
    if (!isLoggedIn || _memosApiService == null) return false;
    
    try {
      // 获取未同步的笔记
      final unsyncedNotes = await _databaseService.getUnsyncedNotes();
      
      // 逐一同步到服务器
      for (var note in unsyncedNotes) {
        try {
          // 创建服务器笔记
          final serverNote = await _memosApiService!.createMemo(
            content: note.content,
            visibility: 'PRIVATE',
          );
          
          // 删除本地笔记（使用临时ID）
          await _databaseService.deleteNote(note.id);
          
          // 保存服务器返回的笔记（带有服务器ID）
          await _databaseService.saveNote(serverNote);
          
          // 更新内存中的列表
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = serverNote;
          }
        } catch (e) {
          print('同步笔记失败: ${note.id} - $e');
        }
      }
      
      // 刷新内存中的列表
      await loadNotesFromLocal();
      return true;
    } catch (e) {
      print('同步笔记到服务器失败: $e');
      return false;
    }
  }

  // 更新用户信息到服务器
  Future<bool> updateUserInfo({
    String? nickname,
    String? email,
    String? avatarUrl,
    String? description,
  }) async {
    if (!isLoggedIn || _memosApiService == null || _user == null) return false;
    
    _setLoading(true);
    
    try {
      // 使用Memos API更新用户信息
      final updatedUser = await _memosApiService!.updateUserInfo(
        nickname: nickname,
        email: email,
        avatarUrl: avatarUrl,
        description: description,
      );

      // 更新本地用户信息
      _user = updatedUser;
      await _preferencesService.saveUser(_user!);

      notifyListeners();
      return true;
    } catch (e) {
      print('更新用户信息失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 保存登录信息
  Future<void> saveLoginInfo(String server, String token) async {
    print('AppProvider: 保存登录信息 - 服务器: $server');
    // 规范化URL（确保末尾没有斜杠）
    final normalizedUrl = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
        
    // 生成一个刷新令牌（这里只是为了满足接口要求）
    final refreshToken = const Uuid().v4();
    
    await _preferencesService.saveLoginInfo(
      token: token,
      refreshToken: refreshToken,
      serverUrl: normalizedUrl,
    );
    
    // 同时更新AppConfig
    final updatedConfig = _appConfig.copyWith(
      memosApiUrl: normalizedUrl,
      lastToken: token,
      lastServerUrl: normalizedUrl,
      rememberLogin: true,
    );
    await updateConfig(updatedConfig);
    
    print('AppProvider: 登录信息保存成功');
  }

  // 清除登录信息
  Future<void> clearLoginInfo() async {
    await _preferencesService.clearLoginInfo();
  }

  // 获取保存的服务器地址
  Future<String?> getSavedServer() async {
    return await _preferencesService.getSavedServer();
  }

  // 获取保存的Token
  Future<String?> getSavedToken() async {
    return await _preferencesService.getSavedToken();
  }

  // 启动自动同步
  void startAutoSync() {
    stopAutoSync();
    if (!_appConfig.isLocalMode && _memosApiService != null) {
      _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
        syncLocalDataToServer();
      });
      print('AppProvider: 自动同步已启动');
    } else {
      print('AppProvider: 本地模式或API服务未初始化，不启动自动同步');
    }
  }

  // 停止自动同步
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('AppProvider: 自动同步已停止');
  }

  // 初始化API服务
  Future<void> _initializeApiService(String baseUrl, String token) async {
    try {
      print('AppProvider: 开始初始化API服务，URL：$baseUrl');
      final normalizedUrl = ApiServiceFactory.normalizeApiUrl(baseUrl);
      print('AppProvider: 规范化后的URL: $normalizedUrl');
      
      _memosApiService = await ApiServiceFactory.createApiService(
        baseUrl: normalizedUrl,
        token: token,
      ) as MemosApiServiceFixed;
      
      // 验证API服务是否正常工作
      final testResponse = await _memosApiService!.getMemos();
      if (testResponse != null) {
        print('AppProvider: API服务初始化成功，验证通过');
        // 更新配置
        final updatedConfig = _appConfig.copyWith(
          memosApiUrl: normalizedUrl,
          lastToken: token,
          isLocalMode: false,
        );
        await updateConfig(updatedConfig);
        
        // 启动自动同步
        startAutoSync();
      } else {
        print('AppProvider: API服务初始化成功，但验证失败');
        _memosApiService = null;
        // 清除保存的凭证
        await _preferencesService.clearLoginInfo();
      }
    } catch (e) {
      print('AppProvider: API服务初始化失败: $e');
      _memosApiService = null;
      // 清除保存的凭证
      await _preferencesService.clearLoginInfo();
      rethrow;
    }
  }

  // 从云端同步数据
  Future<void> syncWithServer() async {
    if (!isLoggedIn || _memosApiService == null) {
      throw Exception('请先登录账号');
    }
    
    // 设置同步状态
    _isSyncing = true;
    _syncMessage = '准备同步...';
    notifyListeners();
    
    try {
      // 1. 先将本地未同步的笔记上传到服务器
      _syncMessage = '上传本地笔记...';
      notifyListeners();
      
      final unsyncedNotes = await _databaseService.getUnsyncedNotes();
      print('AppProvider: 发现 ${unsyncedNotes.length} 条未同步笔记');
      
      for (var note in unsyncedNotes) {
        try {
          final serverNote = await _memosApiService!.createMemo(
            content: note.content,
            visibility: note.visibility,
          );
          
          // 删除本地笔记
          await _databaseService.deleteNote(note.id);
          
          // 保存服务器返回的笔记
          await _databaseService.saveNote(serverNote);
        } catch (e) {
          print('同步笔记到服务器失败: ${note.id} - $e');
        }
      }
      
      // 2. 从服务器获取最新数据
      _syncMessage = '获取服务器数据...';
      notifyListeners();
      
      final response = await _memosApiService!.getMemos();
      if (response == null) {
        throw Exception('服务器返回数据为空');
      }
      
      final memosList = response['memos'] as List<dynamic>;
      final serverNotes = memosList.map((memo) => Note.fromJson(memo as Map<String, dynamic>)).toList();
      
      // 3. 为所有服务器笔记重新提取标签
      _syncMessage = '处理笔记数据...';
      notifyListeners();
      
      for (var i = 0; i < serverNotes.length; i++) {
        var note = serverNotes[i];
        var tags = Note.extractTagsFromContent(note.content);
        if (tags.isNotEmpty) {
          serverNotes[i] = note.copyWith(tags: tags);
        }
      }
      
      // 4. 更新本地数据库
      _syncMessage = '更新本地数据...';
      notifyListeners();
      
      await _databaseService.clearAllNotes();
      await _databaseService.saveNotes(serverNotes);
      
      // 5. 更新内存中的列表
      _notes = await _databaseService.getNotes();
      
      _syncMessage = '同步完成';
      notifyListeners();
      
      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          notifyListeners();
        }
      });
    } catch (e) {
      print('同步失败: $e');
      _syncMessage = '同步失败: ${e.toString().split('\n')[0]}';
      notifyListeners();
      
      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          notifyListeners();
        }
      });
      
      throw e;
    }
  }

  // 初始化通知并检查更新
  Future<void> _initializeAnnouncements() async {
    try {
      // 获取未读通知数量
      final count = await _announcementService.getUnreadAnnouncementsCount();
      _unreadAnnouncementsCount = count;
      notifyListeners();
      
      // 检查是否需要显示更新提示
      final shouldShow = await _announcementService.shouldShowUpdatePrompt();
      if (shouldShow) {
        await checkForUpdatesOnStartup();
      }
    } catch (e) {
      print('初始化通知异常: $e');
    }
  }
  
  // 刷新未读通知数量
  Future<void> refreshUnreadAnnouncementsCount() async {
    try {
      final count = await _announcementService.getUnreadAnnouncementsCount();
      if (_unreadAnnouncementsCount != count) {
        _unreadAnnouncementsCount = count;
        notifyListeners();
      }
    } catch (e) {
      print('刷新未读通知数量异常: $e');
    }
  }
  
  // 启动时检查更新
  Future<void> checkForUpdatesOnStartup() async {
    try {
      // 获取当前版本信息
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // 异步检查更新
      final (versionInfo, hasUpdate) = await _announcementService.checkForUpdates();
      
      if (versionInfo != null && hasUpdate) {
        _pendingVersionInfo = versionInfo;
        _pendingCurrentVersion = currentVersion;
      }
    } catch (e) {
      print('启动时检查更新异常: $e');
    }
  }
  
  // 版本信息暂存
  VersionInfo? _pendingVersionInfo;
  String? _pendingCurrentVersion;
  
  // 显示更新对话框
  void showUpdateDialogIfNeeded(BuildContext context) {
    if (_pendingVersionInfo != null && _pendingCurrentVersion != null) {
      final versionInfo = _pendingVersionInfo!;
      final currentVersion = _pendingCurrentVersion!;
      
      // 清除暂存的版本信息
      _pendingVersionInfo = null;
      _pendingCurrentVersion = null;
      
      // 使用微任务确保对话框在下一帧显示
      Future.microtask(() {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: !versionInfo.forceUpdate,
            builder: (context) => UpdateDialog(
              versionInfo: versionInfo,
              currentVersion: currentVersion,
            ),
          );
        }
      });
    }
  }

  // 通知相关方法
  Future<void> refreshAnnouncements() async {
    final response = await _announcementService.fetchAnnouncements();
    if (response != null) {
      _announcements = response.announcements;
      notifyListeners();
    }
  }

  Future<void> markAnnouncementAsRead(String id) async {
    await _announcementService.markAnnouncementAsRead(id);
    await refreshUnreadAnnouncementsCount();
  }

  Future<void> markAllAnnouncementsAsRead() async {
    await _announcementService.markAllAnnouncementsAsRead();
    await refreshUnreadAnnouncementsCount();
  }

  Future<bool> isAnnouncementRead(String id) async {
    return await _announcementService.isAnnouncementRead(id);
  }

  // 在销毁时清理
  @override
  void dispose() {
    _mounted = false;
    _syncTimer?.cancel();
    super.dispose();
  }

  // 设置当前用户
  Future<void> setUser(User user) async {
    _user = user;
    await _preferencesService.saveUser(user);
    notifyListeners();
  }
} 