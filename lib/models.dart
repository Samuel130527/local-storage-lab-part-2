class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.cardCount = 0,
  });

  final int id;
  final String name;
  final String createdAt;
  final int cardCount;

  factory Folder.fromMap(Map<String, Object?> map) => Folder(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['created_at'] as String,
        cardCount: (map['card_count'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt,
      };
}

class CardRecord {
  const CardRecord({
    required this.id,
    required this.title,
    required this.suit,
    required this.notes,
    required this.folderId,
    this.imageRef,
  });

  final int id;
  final String title;
  final String suit;
  final String notes;
  final String? imageRef;
  final int folderId;

  factory CardRecord.fromMap(Map<String, Object?> map) => CardRecord(
        id: map['id'] as int,
        title: map['title'] as String,
        suit: map['suit'] as String,
        notes: (map['notes'] as String?) ?? '',
        imageRef: map['image_ref'] as String?,
        folderId: map['folder_id'] as int,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'suit': suit,
        'notes': notes,
        'image_ref': imageRef,
        'folder_id': folderId,
      };
}
