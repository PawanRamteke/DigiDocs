import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/document.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'documents.db');

    return await openDatabase(
      fullPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        filePath TEXT NOT NULL,
        thumbnailPath TEXT,
        type TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        fileSize INTEGER NOT NULL,
        appliedFilter TEXT NOT NULL DEFAULT 'original',
        rotation REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Create index for faster searches
    await db.execute('CREATE INDEX idx_documents_name ON documents(name)');
    await db.execute('CREATE INDEX idx_documents_created_at ON documents(createdAt DESC)');
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Document.fromJson(maps[i]);
    });
  }

  Future<Document?> getDocumentById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Document.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Document.fromJson(maps[i]);
    });
  }

  Future<void> insertDocument(Document document) async {
    final db = await database;
    await db.insert(
      'documents',
      document.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDocument(Document document) async {
    final db = await database;
    await db.update(
      'documents',
      document.toJson(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> updateDocumentFields(String id, Map<String, dynamic> fields) async {
    final db = await database;
    fields['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'documents',
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getDocumentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM documents');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalFileSize() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(fileSize) as total FROM documents');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
