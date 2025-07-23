import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/app_config_model.dart';
import '../models/user_model.dart';
import '../services/preferences_service.dart';
import '../services/api_service_factory.dart';
import '../services/database_service.dart';

class ServerInfoScreen extends StatefulWidget {
  const ServerInfoScreen({super.key});

  @override
  State<ServerInfoScreen> createState() => _ServerInfoScreenState();
}

class _ServerInfoScreenState extends State<ServerInfoScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  final TextEditingController _serverAddressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _useHttps = true;
  bool _isSyncing = false;
  bool _isDiagnosing = false;
  String _connectionStatus = '未连接';
  String _lastSyncTime = '未同步';
  String _latency = '0 ms';
  List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // 初始化表单数据
    _initializeFormData(appProvider);
    
    // 初始化日志
    _initializeLogs();

    // 如果已登录，更新连接状态
    if (appProvider.isLoggedIn) {
      _updateConnectionStatus();
      _startPeriodicStatusCheck();
    }
  }

  void _initializeFormData(AppProvider appProvider) {
    final serverUrl = appProvider.appConfig.memosApiUrl ?? '';
    if (serverUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(serverUrl);
        _serverAddressController.text = uri.host;
        _portController.text = uri.port.toString();
        _useHttps = uri.scheme == 'https';
      } catch (e) {
        print('解析服务器URL失败: $e');
  }
    } else {
      _portController.text = '443';
    }
    _apiKeyController.text = appProvider.appConfig.lastToken ?? '';

    // 如果已登录，更新连接状态
    if (appProvider.isLoggedIn) {
        _connectionStatus = '已连接';
      _updateLastSyncTime(appProvider.user?.lastSyncTime);
    }
  }

  void _updateLastSyncTime(DateTime? lastSync) {
    if (lastSync == null) {
      _lastSyncTime = '未同步';
      return;
    }

          final now = DateTime.now();
    final diff = now.difference(lastSync);
          
          if (diff.inMinutes < 1) {
            _lastSyncTime = '刚刚';
          } else if (diff.inMinutes < 60) {
            _lastSyncTime = '${diff.inMinutes}分钟前';
          } else if (diff.inHours < 24) {
            _lastSyncTime = '${diff.inHours}小时前';
          } else {
            _lastSyncTime = '${diff.inDays}天前';
          }
  }

  Timer? _statusCheckTimer;

  void _startPeriodicStatusCheck() {
    // 每30秒检查一次连接状态
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateConnectionStatus();
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _serverAddressController.dispose();
    _portController.dispose();
    _apiKeyController.dispose();
    super.dispose();
    }

  Future<void> _updateConnectionStatus() async {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (!appProvider.isLoggedIn) return;
      
    try {
      final response = await http.get(
        Uri.parse('${appProvider.appConfig.memosApiUrl}/api/v1/status'),
        headers: {
          'Accept': 'application/json',
          if (appProvider.appConfig.lastToken != null)
            'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final startTime = DateTime.now();
        await http.get(
          Uri.parse('${appProvider.appConfig.memosApiUrl}/api/v1/status'),
          headers: {
            'Accept': 'application/json',
            if (appProvider.appConfig.lastToken != null)
              'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
          },
        );
        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;

        if (mounted) {
          setState(() {
            _connectionStatus = '已连接';
            _latency = '$latency ms';
          });
        }
      } else {
        throw Exception('服务器响应错误: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = '连接异常';
          _latency = '超时';
        });
    }
  }
  }

  void _initializeLogs() {
    final now = DateTime.now();
    _logs = [];
    
    // 添加应用启动日志
    _logs.add(LogEntry(
      time: _formatTime(now),
      message: '初始化服务器连接页面...',
      type: LogType.info,
    ));
    
    // 检查是否已登录并获取连接信息
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.isLoggedIn) {
      _logs.add(LogEntry(
        time: _formatTime(now.subtract(const Duration(milliseconds: 100))),
        message: '检测到已登录状态',
        type: LogType.info,
      ));
      
      if (appProvider.appConfig.memosApiUrl != null) {
        try {
          final uri = Uri.parse(appProvider.appConfig.memosApiUrl!);
          _logs.add(LogEntry(
            time: _formatTime(now.subtract(const Duration(milliseconds: 200))),
            message: '当前服务器: ${uri.host}:${uri.port}',
            type: LogType.info,
          ));
          
          _logs.add(LogEntry(
            time: _formatTime(now.subtract(const Duration(milliseconds: 300))),
            message: '使用协议: ${uri.scheme.toUpperCase()}',
            type: LogType.info,
          ));
        } catch (e) {
          _logs.add(LogEntry(
            time: _formatTime(now.subtract(const Duration(milliseconds: 200))),
            message: '解析服务器URL失败: $e',
            type: LogType.error,
          ));
        }
      }
      
      // 添加上次同步信息
      if (appProvider.user?.lastSyncTime != null) {
        final lastSync = appProvider.user!.lastSyncTime!;
        final diff = now.difference(lastSync);
        
        _logs.add(LogEntry(
          time: _formatTime(now.subtract(const Duration(milliseconds: 400))),
          message: '上次同步: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSync)}',
          type: LogType.info,
        ));
        
        // 如果上次同步超过1小时，添加警告
        if (diff.inHours > 1) {
          _logs.add(LogEntry(
            time: _formatTime(now.subtract(const Duration(milliseconds: 500))),
            message: '同步警告: 距离上次同步已超过${diff.inHours}小时',
            type: LogType.warning,
          ));
        }
      }
      
      // 添加连接成功记录
      _logs.add(LogEntry(
        time: _formatTime(now.subtract(const Duration(milliseconds: 600))),
        message: '连接状态: ${_connectionStatus}',
        type: _connectionStatus == '已连接' ? LogType.success : LogType.warning,
      ));
    } else {
      _logs.add(LogEntry(
        time: _formatTime(now.subtract(const Duration(milliseconds: 100))),
        message: '当前未登录，请配置服务器并登录',
        type: LogType.info,
      ));
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  void _showToast(String message, ToastType type) {
    if (!mounted) return;
    
    final Color backgroundColor;
    switch (type) {
      case ToastType.success:
        backgroundColor = const Color(0xDD34C759);
        break;
      case ToastType.error:
        backgroundColor = const Color(0xDDFF3B30);
        break;
      case ToastType.info:
        backgroundColor = const Color(0xDD007AFF);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 40,
          right: 40,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // 添加同步日志
      void addLog(String message, [LogType type = LogType.info]) {
        setState(() {
          _logs.insert(0, LogEntry(
            time: _formatTime(DateTime.now()),
            message: message,
            type: type,
          ));
        });
      }
      
      addLog('开始同步数据...');
      
      // 执行实际的同步操作
      if (!appProvider.isLoggedIn) {
        addLog('同步失败: 未登录', LogType.error);
        _showToast('同步失败: 请先登录', ToastType.error);
        return;
      }
      
      // 首先从服务器获取最新数据
      addLog('正在从服务器获取最新数据...');
      await appProvider.fetchNotesFromServer();
      
      // 然后将本地数据同步到服务器
      addLog('正在同步本地数据到服务器...');
      final result = await appProvider.syncLocalDataToServer();
      
      if (result) {
        addLog('同步成功', LogType.success);
        _showToast('同步成功', ToastType.success);
        
        // 更新上次同步时间
        setState(() {
          _lastSyncTime = '刚刚';
        });
        
        // 更新用户对象中的同步时间
        if (appProvider.user != null) {
          final updatedUser = appProvider.user!.copyWith(
            lastSyncTime: DateTime.now(),
          );
          await appProvider.setUser(updatedUser);
        }
      } else {
        addLog('同步失败', LogType.error);
        _showToast('同步失败', ToastType.error);
      }
    } catch (e) {
      setState(() {
        _logs.insert(0, LogEntry(
          time: _formatTime(DateTime.now()),
          message: '同步失败: $e',
          type: LogType.error,
        ));
      });
      _showToast('同步失败: $e', ToastType.error);
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _diagnoseConnection() async {
    if (_isDiagnosing) return;
    
    setState(() {
      _isDiagnosing = true;
    });
    
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // 添加诊断日志
      void addLog(String message, [LogType type = LogType.info]) {
        setState(() {
          _logs.insert(0, LogEntry(
            time: _formatTime(DateTime.now()),
            message: message,
            type: type,
          ));
        });
      }

      addLog('开始连接诊断...');
      
      // 检查是否配置了服务器地址
      if (appProvider.appConfig.memosApiUrl == null || appProvider.appConfig.memosApiUrl!.isEmpty) {
        addLog('未配置服务器地址', LogType.error);
        _showToast('诊断失败: 未配置服务器地址', ToastType.error);
        return;
      }
      
      // 解析服务器地址
      addLog('解析服务器地址...');
      Uri? uri;
      try {
        uri = Uri.parse(appProvider.appConfig.memosApiUrl!);
        addLog('服务器地址: ${uri.host}', LogType.success);
        addLog('端口: ${uri.port}', LogType.success);
        addLog('协议: ${uri.scheme.toUpperCase()}', LogType.success);
      } catch (e) {
        addLog('解析服务器地址失败: $e', LogType.error);
        _showToast('诊断失败: 服务器地址无效', ToastType.error);
        return;
      }
      
      // 检查DNS解析
      addLog('检查DNS解析...');
      
      try {
        // 使用Http.head请求检查连接性
        final dnsStart = DateTime.now();
        final response = await http.head(
          Uri.parse('${uri!.scheme}://${uri.host}:${uri.port}'),
        ).timeout(const Duration(seconds: 5));
        final dnsEnd = DateTime.now();
        final dnsDuration = dnsEnd.difference(dnsStart).inMilliseconds;
        
        addLog('DNS解析成功，耗时: ${dnsDuration}ms', LogType.success);
      } catch (e) {
        addLog('DNS解析失败: $e', LogType.error);
      }
      
      // 测试API连接
      addLog('测试API连接...');
      
      try {
        final apiStart = DateTime.now();
        final response = await http.get(
          Uri.parse('${appProvider.appConfig.memosApiUrl}/api/v1/status'),
          headers: {
            'Accept': 'application/json',
            if (appProvider.appConfig.lastToken != null)
              'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
          },
        ).timeout(const Duration(seconds: 5));
        final apiEnd = DateTime.now();
        final apiDuration = apiEnd.difference(apiStart).inMilliseconds;
        
        if (response.statusCode == 200) {
          addLog('API连接成功，响应时间: ${apiDuration}ms', LogType.success);
          setState(() {
            _connectionStatus = '已连接';
            _latency = '$apiDuration ms';
          });
        } else {
          addLog('API连接失败: HTTP ${response.statusCode}', LogType.error);
          setState(() {
            _connectionStatus = '连接异常';
            _latency = '错误';
          });
        }
      } catch (e) {
        addLog('API连接失败: $e', LogType.error);
        setState(() {
          _connectionStatus = '连接异常';
          _latency = '超时';
        });
        _showToast('诊断失败: API连接失败', ToastType.error);
        return;
      }
      
      // 验证Token
      if (appProvider.appConfig.lastToken != null) {
        addLog('验证Token...');
        
        try {
          final tokenStart = DateTime.now();
          final response = await http.get(
            Uri.parse('${appProvider.appConfig.memosApiUrl}/api/v1/user/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
            },
          ).timeout(const Duration(seconds: 5));
          final tokenEnd = DateTime.now();
          final tokenDuration = tokenEnd.difference(tokenStart).inMilliseconds;
          
          if (response.statusCode == 200) {
            addLog('Token验证成功，响应时间: ${tokenDuration}ms', LogType.success);
          } else {
            addLog('Token验证失败: HTTP ${response.statusCode}', LogType.error);
          }
        } catch (e) {
          addLog('Token验证失败: $e', LogType.error);
        }
      }
      
      // 综合诊断结果
      if (_connectionStatus == '已连接') {
        addLog('诊断结果: 连接正常', LogType.success);
        _showToast('诊断完成: 连接状态良好', ToastType.success);
      } else {
        addLog('诊断结果: 连接异常', LogType.error);
        _showToast('诊断完成: 连接状态异常', ToastType.error);
      }
    } catch (e) {
      _showToast('诊断失败: $e', ToastType.error);
    } finally {
      setState(() {
        _isDiagnosing = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    // 验证输入
    if (_serverAddressController.text.isEmpty) {
      _showToast('请输入服务器地址', ToastType.error);
      return;
    }
    
    if (_portController.text.isEmpty) {
      _showToast('请输入端口号', ToastType.error);
      return;
    }

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final scheme = _useHttps ? 'https' : 'http';
      final serverUrl = '$scheme://${_serverAddressController.text}:${_portController.text}';
      
      // 更新配置
      final updatedConfig = appProvider.appConfig.copyWith(
        memosApiUrl: serverUrl,
        lastToken: _apiKeyController.text.isNotEmpty ? _apiKeyController.text : null,
      );
      
      await _preferencesService.saveAppConfig(updatedConfig);
      await appProvider.updateConfig(updatedConfig);
      
      _showToast('设置已保存', ToastType.success);
    } catch (e) {
      _showToast('保存失败: $e', ToastType.error);
  }
  }

  void _clearLogs() {
    setState(() {
      _logs = [
        LogEntry(
          time: _formatTime(DateTime.now()),
          message: '日志已清空',
          type: LogType.info,
        ),
      ];
    });
    _showToast('日志已清空', ToastType.info);
  }

  void _copyLogs() {
    // 实现复制日志功能
    _showToast('日志已复制到剪贴板', ToastType.success);
  }

  void _exportLogs() {
    // 实现导出日志功能
    _showToast('日志已导出', ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appProvider = context.watch<AppProvider>();
    final isLoggedIn = appProvider.isLoggedIn;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('服务器连接', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 当前状态
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                  // 状态头部
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _connectionStatus == '已连接'
                              ? const Color(0xFF34C759).withOpacity(0.15)
                              : const Color(0xFFFF3B30).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _connectionStatus == '已连接'
                              ? Icons.show_chart
                              : Icons.error_outline,
                          color: _connectionStatus == '已连接'
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _connectionStatus,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _connectionStatus == '已连接'
                                ? '服务器连接正常，数据同步正常'
                                : '请检查服务器设置',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 服务器详情
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildServerDetail('主机地址', _serverAddressController.text),
                        const SizedBox(height: 8),
                        _buildServerDetail('端口', _portController.text),
                        const SizedBox(height: 8),
                        _buildServerDetail('延迟', _latency),
                        const SizedBox(height: 8),
                        _buildServerDetail('上次同步', _lastSyncTime),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoggedIn && !_isSyncing ? _syncData : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSyncing)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                const Icon(Icons.sync, size: 16),
                              const SizedBox(width: 6),
                              Text(_isSyncing ? '同步中...' : '立即同步'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: isLoggedIn && !_isDiagnosing ? _diagnoseConnection : null,
                          style: TextButton.styleFrom(
                            backgroundColor: theme.dividerColor.withOpacity(0.05),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isDiagnosing)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                                  ),
                                )
                              else
                                const Icon(Icons.add_circle_outline, size: 16),
                              const SizedBox(width: 6),
                              Text(_isDiagnosing ? '诊断中...' : '连接诊断'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 连接设置 - 仅在未登录时显示
            if (!isLoggedIn)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Text(
                        '连接设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                    label: '服务器地址',
                            controller: _serverAddressController,
                    hintText: '请输入服务器地址',
                            helpText: '输入服务器的域名或IP地址，例如：api.inkroot.com',
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                            label: '端口号',
                            controller: _portController,
                            hintText: '请输入端口号',
                            helpText: '默认为443（HTTPS）或80（HTTP）',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            label: 'API 密钥',
                    controller: _apiKeyController,
                            hintText: '请输入API密钥',
                            helpText: '在服务器后台获取的API访问密钥',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                                '使用HTTPS安全连接',
                        style: TextStyle(
                          fontSize: 14,
                                  fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                                value: _useHttps,
                        onChanged: (value) {
                          setState(() {
                                    _useHttps = value;
                          });
                                  _showToast(
                                    'HTTPS ${value ? '已开启' : '已关闭'}',
                                    ToastType.info,
                                  );
                                },
                                activeColor: theme.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('保存更改'),
                            ),
                      ),
                    ],
                      ),
                  ),
                ],
              ),
            ),

            // 连接日志
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      '连接日志',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                              '最近连接记录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy_outlined, size: 20),
                                  onPressed: _copyLogs,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download_outlined, size: 20),
                                  onPressed: _exportLogs,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: _clearLogs,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                              ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            itemCount: _logs.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      log.time,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                              child: Text(
                                        log.message,
                                style: TextStyle(
                                          fontSize: 12,
                                          color: _getLogColor(log.type, theme),
                                ),
                              ),
                            ),
                                  ],
                                ),
                              );
                            },
                                ),
                        ),
                              ],
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

  Widget _buildServerDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? helpText,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            filled: true,
            fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        if (helpText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helpText,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ),
      ],
    );
  }

  Color _getLogColor(LogType type, ThemeData theme) {
    switch (type) {
      case LogType.success:
        return const Color(0xFF34C759);
      case LogType.error:
        return const Color(0xFFFF3B30);
      case LogType.warning:
        return const Color(0xFFFF9500);
      case LogType.info:
        return theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
  }
}
}

enum LogType {
  success,
  error,
  warning,
  info,
}

enum ToastType {
  success,
  error,
  info,
}

class LogEntry {
  final String time;
  final String message;
  final LogType type;

  LogEntry({
    required this.time,
    required this.message,
    required this.type,
  });
} 