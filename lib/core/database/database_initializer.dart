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
        score INTEGER NOT NULL,
        source TEXT NOT NULL,
        rating TEXT NOT NULL
      );
    ''');
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE posts ADD COLUMN source TEXT NOT NULL DEFAULT "Unknown"');
      await db.execute('ALTER TABLE posts ADD COLUMN rating TEXT NOT NULL DEFAULT "s"');
    }
  }
}
