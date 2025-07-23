class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime displayTime;
  final List<String> tags;
  final String creator;
  bool isSynced;
  final bool isPinned;
  final String visibility;

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    DateTime? displayTime,
    List<String>? tags,
    String? creator,
    this.isSynced = false,
    this.isPinned = false,
    this.visibility = 'PRIVATE',
  }) : this.displayTime = displayTime ?? updatedAt,
       this.tags = tags ?? [],
       this.creator = creator ?? 'local';

  Note copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? displayTime,
    List<String>? tags,
    String? creator,
    bool? isSynced,
    bool? isPinned,
    String? visibility,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayTime: displayTime ?? this.displayTime,
      tags: tags ?? this.tags,
      creator: creator ?? this.creator,
      isSynced: isSynced ?? this.isSynced,
      isPinned: isPinned ?? this.isPinned,
      visibility: visibility ?? this.visibility,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'displayTime': displayTime.toIso8601String(),
      'tags': tags.join(','),
      'creator': creator,
      'is_synced': isSynced ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'visibility': visibility,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      displayTime: map['displayTime'] != null 
          ? DateTime.parse(map['displayTime'])
          : null,
      tags: map['tags'] != null && map['tags'].isNotEmpty 
          ? map['tags'].split(',') 
          : null,
      creator: map['creator'],
      isSynced: map['is_synced'] == 1,
      isPinned: map['isPinned'] == 1,
      visibility: map['visibility'] ?? 'PRIVATE',
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    // 处理时间戳 - Memos API 返回的是秒级时间戳，需要转换为毫秒
    int createdTsSeconds = json['createdTs'] as int;
    int updatedTsSeconds = json['updatedTs'] as int;
    
    // 转换为毫秒级时间戳
    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(createdTsSeconds * 1000);
    DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedTsSeconds * 1000);
    
    return Note(
      id: json['id'].toString(),
      content: json['content'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      displayTime: json['displayTime'] != null 
          ? DateTime.parse(json['displayTime'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      creator: json['creator']?.toString(),
      isSynced: true,
      isPinned: json['pinned'] ?? false,
      visibility: json['visibility'] ?? 'PRIVATE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdTs': createdAt.millisecondsSinceEpoch,
      'updatedTs': updatedAt.millisecondsSinceEpoch,
      'displayTime': displayTime.toIso8601String(),
      'tags': tags,
      'creator': creator,
      'pinned': isPinned,
      'visibility': visibility,
    };
  }

  // 从笔记内容中提取标签
  static List<String> extractTagsFromContent(String content) {
    final RegExp tagRegex = RegExp(r'#([\p{L}\p{N}_\u4e00-\u9fff]+)', unicode: true);
    final matches = tagRegex.allMatches(content);
    return matches
      .map((match) => match.group(1))
      .where((tag) => tag != null)
      .map((tag) => tag!)
      .toList();
  }

  // 判断可见性
  bool get isPrivate => visibility == 'PRIVATE';
  bool get isProtected => visibility == 'PROTECTED';
  bool get isPublic => visibility == 'PUBLIC';
} 