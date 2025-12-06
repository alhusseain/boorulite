import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_initializer.dart';

class DatabaseProvider {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: DatabaseInitializer.onCreate,
    );

    return _db!;
  }
}
