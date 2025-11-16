import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  final StreamController<void> _recordsStreamController = StreamController.broadcast();

  Stream<void> get recordsStream => _recordsStreamController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  Future<void> printAllRecords() async {
    final records = await getAllRecords();
    for (var r in records) {
      print(r);
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'majong.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records(
            id INTEGER PRIMARY KEY,
            tiles TEXT,
            win_tile TEXT,
            melds TEXT,
            han INTEGER,
            fu INTEGER,
            yaku TEXT,
            total_score INTEGER,
            created_at TEXT
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await database;
    return await db.query('records', orderBy: 'created_at DESC');
  }

  Future<int> insertRecord(Map<String, dynamic> record) async {
    final db = await database;
    final id = await db.insert('records', record);
    _recordsStreamController.add(null); // 發送事件通知刷新
    return id;
  }

  Future<int> deleteAllRecords() async {
    final db = await database;
    final count = await db.delete('records');
    _recordsStreamController.add(null); // 發送事件通知刷新
    return count;
  }

  void dispose() {
    _recordsStreamController.close();
  }
}
