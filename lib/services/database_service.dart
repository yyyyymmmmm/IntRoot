import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import 'dart:convert'; // Added for jsonEncode and jsonDecode

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE notes(
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            displayTime TEXT,
            tags TEXT,
            creator TEXT,
            is_synced INTEGER DEFAULT 0,
            isPinned INTEGER DEFAULT 0,
            visibility TEXT DEFAULT 'PRIVATE'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await db.execute('ALTER TABLE notes ADD COLUMN is_synced INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE notes ADD COLUMN visibility TEXT DEFAULT "PRIVATE"');
        }
      },
    );
  }

  // 保存笔记到数据库
  Future<void> saveNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      {
        'id': note.id,
        'content': note.content,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
        'tags': note.tags.join(','),
        'is_synced': note.isSynced ? 1 : 0,
        'isPinned': note.isPinned ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 更新笔记
  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'content': note.content,
        'updatedAt': note.updatedAt.toIso8601String(),
        'tags': note.tags.join(','),
        'is_synced': note.isSynced ? 1 : 0,
        'isPinned': note.isPinned ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // 删除笔记
  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取所有笔记
  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'createdAt DESC');
    
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        content: maps[i]['content'],
        createdAt: DateTime.parse(maps[i]['createdAt']),
        updatedAt: DateTime.parse(maps[i]['updatedAt']),
        tags: maps[i]['tags'] != null && maps[i]['tags'].isNotEmpty 
            ? maps[i]['tags'].split(',') 
            : [],
        isSynced: maps[i]['is_synced'] == 1,
        isPinned: maps[i]['isPinned'] == 1,
        creator: 'users/local', // 本地笔记使用特殊的creator标识
      );
    });
  }

  // 根据ID获取笔记
  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Note(
      id: maps[0]['id'],
      content: maps[0]['content'],
      createdAt: DateTime.parse(maps[0]['createdAt']),
      updatedAt: DateTime.parse(maps[0]['updatedAt']),
      tags: maps[0]['tags'] != null && maps[0]['tags'].isNotEmpty 
          ? maps[0]['tags'].split(',') 
          : [],
      isSynced: maps[0]['is_synced'] == 1,
      isPinned: maps[0]['isPinned'] == 1,
      creator: 'users/local',
    );
  }

  // 获取未同步的笔记
  Future<List<Note>> getUnsyncedNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
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
    });
  }

  // 更新笔记的服务器ID
  Future<void> updateNoteServerId(String localId, String serverId) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'id': serverId,
        'is_synced': 1,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // 标记笔记为已同步
  Future<void> markNoteSynced(String id) async {
    final db = await database;
    await db.update(
      'notes',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 清空所有笔记
  Future<void> clearAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }

  // 批量保存笔记
  Future<void> saveNotes(List<Note> notes) async {
    final db = await database;
    final batch = db.batch();
    
    for (var note in notes) {
      batch.insert(
        'notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  // 按标签获取笔记
  Future<List<Note>> getNotesByTag(String tag) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
    );
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
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
    });
  }

  // 搜索笔记
  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
    );
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
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
    });
  }

  // 获取笔记总数
  Future<int> getNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM notes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 获取数据库大小（估算值，单位：字节）
  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(LENGTH(content)) FROM notes');
    return (Sqflite.firstIntValue(result) ?? 0) + 1024; // 添加一些额外的元数据大小
  }
  
  // 将笔记导出为JSON
  Future<String> exportNotesToJson() async {
    final notes = await getNotes();
    final jsonList = notes.map((note) => note.toJson()).toList();
    return jsonEncode({
      'version': '1.0',
      'exportTime': DateTime.now().toIso8601String(),
      'notes': jsonList,
    });
  }
  
  // 导入JSON格式的笔记
  Future<int> importNotesFromJson(String jsonData, {bool overwriteExisting = false, bool asNewNotes = true}) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      if (!data.containsKey('notes') || data['notes'] is! List) {
        throw Exception('无效的备份文件格式');
      }
      
      final List<dynamic> jsonNotes = data['notes'];
      final List<Note> notes = [];
      
      for (var item in jsonNotes) {
        if (item is Map<String, dynamic>) {
          try {
            final note = Note.fromJson(item);
            notes.add(note);
          } catch (e) {
            print('解析笔记失败: $e');
          }
        }
      }
      
      return await _importNotes(notes, overwriteExisting: overwriteExisting, asNewNotes: asNewNotes);
    } catch (e) {
      print('导入JSON笔记失败: $e');
      throw Exception('导入JSON笔记失败: $e');
    }
  }
  
  // 导入Markdown格式的笔记
  Future<int> importNotesFromMarkdown(List<String> markdownFiles, List<String> contents) async {
    if (markdownFiles.length != contents.length) {
      throw Exception('文件名和内容数量不匹配');
    }
    
    final List<Note> notes = [];
    final now = DateTime.now();
    
    for (var i = 0; i < markdownFiles.length; i++) {
      final fileName = markdownFiles[i];
      final content = contents[i];
      final tags = Note.extractTagsFromContent(content);
      
      notes.add(Note(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}_${i}',
        content: content,
        createdAt: now,
        updatedAt: now,
        tags: tags,
        isSynced: false,
      ));
    }
    
    return await _importNotes(notes, asNewNotes: true);
  }
  
  // 导入纯文本格式的笔记
  Future<int> importNotesFromText(List<String> textFiles, List<String> contents) async {
    if (textFiles.length != contents.length) {
      throw Exception('文件名和内容数量不匹配');
    }
    
    final List<Note> notes = [];
    final now = DateTime.now();
    
    for (var i = 0; i < textFiles.length; i++) {
      final fileName = textFiles[i];
      final content = contents[i];
      final tags = Note.extractTagsFromContent(content);
      
      notes.add(Note(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}_${i}',
        content: content,
        createdAt: now,
        updatedAt: now,
        tags: tags,
        isSynced: false,
      ));
    }
    
    return await _importNotes(notes, asNewNotes: true);
  }
  
  // 内部方法：导入笔记通用逻辑
  Future<int> _importNotes(List<Note> notes, {bool overwriteExisting = false, bool asNewNotes = true}) async {
    final db = await database;
    int imported = 0;
    
    await db.transaction((txn) async {
      for (var note in notes) {
        try {
          if (asNewNotes) {
            // 作为新笔记导入，使用新ID
            final newNote = note.copyWith(
              id: 'local_${DateTime.now().millisecondsSinceEpoch}_${imported}',
              isSynced: false,
            );
            
            await txn.insert(
              'notes',
              newNote.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            imported++;
          } else if (overwriteExisting) {
            // 检查是否存在相同ID的笔记
            final exists = Sqflite.firstIntValue(await txn.rawQuery(
              'SELECT COUNT(*) FROM notes WHERE id = ?',
              [note.id],
            )) ?? 0;
            
            if (exists > 0) {
              // 存在则更新
              await txn.update(
                'notes',
                note.toMap(),
                where: 'id = ?',
                whereArgs: [note.id],
              );
            } else {
              // 不存在则插入
              await txn.insert(
                'notes',
                note.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            imported++;
          } else {
            // 检查是否存在相同ID的笔记
            final exists = Sqflite.firstIntValue(await txn.rawQuery(
              'SELECT COUNT(*) FROM notes WHERE id = ?',
              [note.id],
            )) ?? 0;
            
            // 只有不存在时才插入
            if (exists == 0) {
              await txn.insert(
                'notes',
                note.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              imported++;
            }
          }
        } catch (e) {
          print('导入单条笔记失败: $e');
        }
      }
    });
    
    return imported;
  }
} 