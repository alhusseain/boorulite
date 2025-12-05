import 'package:sqflite/sqflite.dart';

class DatabaseInitializer {
  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts(
        id INTEGER PRIMARY KEY,
        preview_url TEXT NOT NULL,
        file_url TEXT NOT NULL,
        tags TEXT NOT NULL,
        file_ext TEXT NOT NULL,
        score INTEGER NOT NULL
      );
    ''');
  }
}
