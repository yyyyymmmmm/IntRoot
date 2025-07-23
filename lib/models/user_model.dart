class User {
  final String id;
  final String username;
  final String? email;
  final String? nickname;
  final String? avatarUrl;
  final String? token; // 用于API身份验证的令牌
  final String role; // 用户角色: HOST, ADMIN, USER
  final String? description; // 个人简介
  final DateTime? lastSyncTime; // 最后同步时间
  final String? serverUrl; // 服务器地址

  User({
    required this.id,
    required this.username,
    this.email,
    this.nickname,
    this.avatarUrl,
    this.token,
    this.role = 'USER',
    this.description,
    this.lastSyncTime,
    this.serverUrl,
  });

  // 从JSON构建用户对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'],
      nickname: json['nickname'],
      avatarUrl: json['avatarUrl'],
      token: json['token'],
      role: json['role'] ?? 'USER',
      description: json['description'],
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'])
          : null,
      serverUrl: json['serverUrl'],
    );
  }

  // 将用户对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'token': token,
      'role': role,
      'description': description,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'serverUrl': serverUrl,
    };
  }

  // 创建User对象的副本
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? nickname,
    String? avatarUrl,
    String? token,
    String? role,
    String? description,
    DateTime? lastSyncTime,
    String? serverUrl,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      token: token ?? this.token,
      role: role ?? this.role,
      description: description ?? this.description,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  // 判断用户是否已登录
  bool get isLoggedIn => token != null && token!.isNotEmpty;
  
  // 判断用户角色
  bool get isHost => role == 'HOST';
  bool get isAdmin => role == 'ADMIN';
  bool get isUser => role == 'USER';
} 