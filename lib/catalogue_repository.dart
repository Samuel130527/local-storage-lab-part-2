import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'models.dart';

class CatalogueRepository {
  CatalogueRepository(this.helper);

  final DatabaseHelper helper;
  Database get _db => helper.database;

  Future<int> insertFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Folder name is required.');
    return _db.insert('folders', {
      'name': trimmed,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Folder>> getFoldersWithCounts() async {
    final rows = await _db.rawQuery('''
      SELECT folders.id, folders.name, folders.created_at,
             COUNT(cards.id) AS card_count
      FROM folders
      LEFT JOIN cards ON cards.folder_id = folders.id
      GROUP BY folders.id, folders.name, folders.created_at
      ORDER BY folders.name COLLATE NOCASE ASC
    ''');
    return rows.map(Folder.fromMap).toList();
  }

  Future<int> deleteFolder(int id) => _db.delete(
        'folders',
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<CardRecord>> getCards(int folderId) async {
    final rows = await _db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title COLLATE NOCASE ASC, id ASC',
    );
    return rows.map(CardRecord.fromMap).toList();
  }

  Future<int> insertCard({
    required String title,
    required String suit,
    required int folderId,
    String notes = '',
    String? imageRef,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError('Card title is required.');
    if (!const ['Hearts', 'Diamonds', 'Clubs', 'Spades'].contains(suit)) {
      throw ArgumentError('Choose a valid suit.');
    }
    return _db.insert('cards', {
      'title': trimmed,
      'suit': suit,
      'notes': notes.trim(),
      'image_ref': imageRef?.trim().isEmpty == true ? null : imageRef?.trim(),
      'folder_id': folderId,
    });
  }

  Future<int> updateCard({
    required int id,
    required String title,
    required String suit,
    required int folderId,
    String notes = '',
    String? imageRef,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError('Card title is required.');
    if (!const ['Hearts', 'Diamonds', 'Clubs', 'Spades'].contains(suit)) {
      throw ArgumentError('Choose a valid suit.');
    }
    return _db.update(
      'cards',
      {
        'title': trimmed,
        'suit': suit,
        'notes': notes.trim(),
        'image_ref': imageRef?.trim().isEmpty == true ? null : imageRef?.trim(),
        'folder_id': folderId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCard(int id) => _db.delete(
        'cards',
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<int> cardCountForFolder(int folderId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
