import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'MyDatabase.db';
  static const int databaseVersion = 2;

  // Part I table: preserve this table and all existing rows.
  static const String tableName = 'my_table';
  static const String columnId = '_id';
  static const String columnName = 'name';
  static const String columnAge = 'age';

  static const String foldersTable = 'folders';
  static const String cardsTable = 'cards';

  Database? _db;
  Database get database {
    final db = _db;
    if (db == null) {
      throw StateError('DatabaseHelper.init() must complete before use.');
    }
    return db;
  }

  Future<void> init() async {
    if (_db != null) return;

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, databaseName);

    _db = await openDatabase(
      path,
      version: databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createPartOneTable(db);
        await _createCatalogueTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add only the new schema. Never drop or recreate my_table.
          await _createCatalogueTables(db);
        }
      },
    );
  }

  Future<void> _createPartOneTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createCatalogueTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        suit TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_cards_folder_id ON cards(folder_id)',
    );
  }

  // Part I guest operations.
  Future<int> insert(Map<String, dynamic> row) =>
      database.insert(tableName, row);

  Future<List<Map<String, dynamic>>> queryAllRows() =>
      database.query(tableName, orderBy: '$columnId ASC');

  Future<int> queryRowCount() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final id = row[columnId] as int;
    return database.update(
      tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) => database.delete(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );

  // Read-only diagnostics for the lab. Run against this open connection.
  Future<int> schemaVersion() async {
    final rows = await database.rawQuery('PRAGMA user_version');
    return (rows.first['user_version'] as int?) ?? 0;
  }

  Future<int> foreignKeysEnabled() async {
    final rows = await database.rawQuery('PRAGMA foreign_keys');
    return (rows.first['foreign_keys'] as int?) ?? 0;
  }

  Future<List<Map<String, Object?>>> foreignKeyList() =>
      database.rawQuery('PRAGMA foreign_key_list(cards)');

  Future<List<Map<String, Object?>>> cardIndexes() =>
      database.rawQuery('PRAGMA index_list(cards)');

  Future<List<Map<String, Object?>>> partOneRowsForEvidence() =>
      database.query(tableName, orderBy: '$columnId ASC');

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
