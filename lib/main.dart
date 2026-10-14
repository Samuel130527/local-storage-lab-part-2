import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'models.dart';
import 'catalogue_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  try {
    await helper.init();
    runApp(DirectoryApp(helper: helper));
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Could not open local storage.\nCheck the console logs and database migration.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
  }
}

class DirectoryApp extends StatelessWidget {
  const DirectoryApp({super.key, required this.helper});
  final DatabaseHelper helper;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Local Storage Lab',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: HomePage(helper: helper),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.helper});
  final DatabaseHelper helper;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Part I · Guest Records' : 'Part II · Folders & Cards'),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          GuestPage(helper: widget.helper),
          CataloguePage(repository: CatalogueRepository(widget.helper)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Guests'),
          NavigationDestination(icon: Icon(Icons.folder_copy_outlined), label: 'Catalogue'),
        ],
      ),
    );
  }
}

// Retains the original Part I guest-table interface.
class GuestPage extends StatefulWidget {
  const GuestPage({super.key, required this.helper});
  final DatabaseHelper helper;

  @override
  State<GuestPage> createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  int _count = 0;
  int? _editingId;
  bool _busy = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();
      if (!mounted) return;
      setState(() { _rows = rows; _count = count; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load guest records: $e'; });
    }
  }

  String? _validateName(String? value) =>
      (value ?? '').trim().isEmpty ? 'Name is required' : null;

  String? _validateAge(String? value) {
    final age = int.tryParse((value ?? '').trim());
    if (age == null) return 'Enter a whole number';
    if (age < 0 || age > 130) return 'Age must be between 0 and 130';
    return null;
  }

  void _clear() {
    _name.clear();
    _age.clear();
    setState(() => _editingId = null);
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final age = int.parse(_age.text.trim());
    setState(() => _busy = true);
    try {
      if (_editingId == null) {
        final id = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });
        if (mounted) _message('Guest saved. ID: $id');
      } else {
        final affected = await widget.helper.update({
          DatabaseHelper.columnId: _editingId,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });
        if (mounted) _message('Update affected rows: $affected');
      }
      if (mounted) _clear();
    } catch (e) {
      if (mounted) _message('Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _refresh();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row[DatabaseHelper.columnId] as int;
    final name = row[DatabaseHelper.columnName] as String;
    final yes = await _confirm('Delete guest?', 'Delete "$name" (ID $id)?');
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final affected = await widget.helper.delete(id);
      if (mounted) _message('Delete affected rows: $affected');
      if (_editingId == id && mounted) _clear();
    } catch (e) {
      if (mounted) _message('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _refresh();
  }

  Future<bool?> _confirm(String title, String message) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
          ],
        ),
      );

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'Guest name', border: OutlineInputBorder()),
                  validator: _validateName,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _age,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                  validator: _validateAge,
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(_editingId == null ? 'Add Guest' : 'Save Guest'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _busy || _editingId == null ? null : _clear,
                    child: const Text('Cancel Edit'),
                  ),
                  IconButton(onPressed: _busy ? null : _refresh, icon: const Icon(Icons.refresh)),
                ]),
              ]),
            ),
          ),
          ListTile(
            title: Text('Existing Part I records: $_count'),
            subtitle: const Text('Keep this table and its rows during migration.'),
            trailing: _busy || _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('No guest records yet. Save a fictional guest before migration if this is still Part I.'))
                    : ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          final id = row[DatabaseHelper.columnId] as int;
                          final name = row[DatabaseHelper.columnName] as String;
                          final age = row[DatabaseHelper.columnAge] as int;
                          return ListTile(
                            leading: CircleAvatar(child: Text('$id')),
                            title: Text(name),
                            subtitle: Text('ID: $id · Age: $age'),
                            trailing: Wrap(children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: _busy ? null : () => setState(() {
                                  _editingId = id; _name.text = name; _age.text = '$age';
                                }),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: _busy ? null : () => _delete(row),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ]),
                          );
                        },
                      ),
          ),
        ],
      );
}

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key, required this.repository});
  final CatalogueRepository repository;

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  List<Folder> _folders = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final folders = await widget.repository.getFoldersWithCounts();
      if (!mounted) return;
      setState(() { _folders = folders; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load folders: $e'; });
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<String?> _textDialog({
    required String title,
    required String label,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _addFolder() async {
    if (_busy) return;
    final name = await _textDialog(title: 'Create folder', label: 'Folder name');
    if (name == null || !mounted) return;
    if (name.trim().isEmpty) { _message('Folder name cannot be blank.'); return; }
    setState(() => _busy = true);
    try {
      final id = await widget.repository.insertFolder(name);
      if (mounted) _message('Folder created. ID: $id');
    } catch (e) {
      if (mounted) _message('Could not create folder. Use a different name. Details: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _loadFolders();
  }

  Future<void> _deleteFolder(Folder folder) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text('Delete "${folder.name}" (ID ${folder.id}) and all ${folder.cardCount} card(s) inside it?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete folder')),
        ],
      ),
    );
    if (yes != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final affected = await widget.repository.deleteFolder(folder.id);
      if (mounted) _message('Folder delete affected rows: $affected');
    } catch (e) {
      if (mounted) _message('Could not delete folder: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _loadFolders();
  }

  Future<void> _openFolder(Folder folder) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CardsPage(repository: widget.repository, folder: folder),
      ),
    );
    if (mounted) await _loadFolders();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
                : _folders.isEmpty
                    ? const Center(child: Text('No folders yet. Tap + to create Atlas and Harbor.'))
                    : RefreshIndicator(
                        onRefresh: _loadFolders,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: _folders.length,
                          itemBuilder: (context, index) {
                            final folder = _folders[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              child: ListTile(
                                leading: const Icon(Icons.folder_outlined, size: 32),
                                title: Text(folder.name),
                                subtitle: Text('Folder ID: ${folder.id} · Cards: ${folder.cardCount}'),
                                onTap: () => _openFolder(folder),
                                trailing: IconButton(
                                  tooltip: 'Delete folder',
                                  onPressed: _busy ? null : () => _deleteFolder(folder),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _busy ? null : _addFolder,
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('Add folder'),
        ),
      );
}

class CardsPage extends StatefulWidget {
  const CardsPage({super.key, required this.repository, required this.folder});
  final CatalogueRepository repository;
  final Folder folder;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  List<CardRecord> _cards = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cards = await widget.repository.getCards(widget.folder.id);
      if (!mounted) return;
      setState(() { _cards = cards; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load cards: $e'; });
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _symbol(String suit) {
    switch (suit) {
      case 'Hearts': return '♥';
      case 'Diamonds': return '♦';
      case 'Clubs': return '♣';
      default: return '♠';
    }
  }

  Future<void> _editCard([CardRecord? card]) async {
    if (_busy) return;
    final result = await showDialog<_CardFormResult>(
      context: context,
      builder: (context) => _CardFormDialog(card: card, folderId: widget.folder.id),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (card == null) {
        final id = await widget.repository.insertCard(
          title: result.title,
          suit: result.suit,
          folderId: result.folderId,
          notes: result.notes,
          imageRef: result.imageRef,
        );
        if (mounted) _message('Card saved. ID: $id');
      } else {
        final affected = await widget.repository.updateCard(
          id: card.id,
          title: result.title,
          suit: result.suit,
          folderId: result.folderId,
          notes: result.notes,
          imageRef: result.imageRef,
        );
        if (mounted) _message('Card update affected rows: $affected');
      }
    } catch (e) {
      if (mounted) _message('Could not save card: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _loadCards();
  }

  Future<void> _deleteCard(CardRecord card) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Delete "${card.title}" (ID ${card.id})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final affected = await widget.repository.deleteCard(card.id);
      if (mounted) _message('Card delete affected rows: $affected');
    } catch (e) {
      if (mounted) _message('Could not delete card: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _loadCards();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.folder.name),
          actions: [IconButton(onPressed: _busy ? null : _loadCards, icon: const Icon(Icons.refresh))],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
                : _cards.isEmpty
                    ? const Center(child: Text('This folder is empty. Tap + to add a card.'))
                    : RefreshIndicator(
                        onRefresh: _loadCards,
                        child: ListView.builder(
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(_symbol(card.suit), style: const TextStyle(fontSize: 22)),
                                ),
                                title: Text(card.title),
                                subtitle: Text('ID: ${card.id} · ${card.suit}${card.notes.isEmpty ? '' : '\n${card.notes}'}\nImage: ${card.imageRef ?? 'null (suit fallback)'}'),
                                isThreeLine: card.notes.isNotEmpty,
                                trailing: Wrap(
                                  spacing: 0,
                                  children: [
                                  IconButton(tooltip: 'Edit', onPressed: _busy ? null : () => _editCard(card), icon: const Icon(Icons.edit_outlined)),
                                  IconButton(tooltip: 'Delete', onPressed: _busy ? null : () => _deleteCard(card), icon: const Icon(Icons.delete_outline)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _busy ? null : () => _editCard(),
          icon: const Icon(Icons.add),
          label: const Text('Add card'),
        ),
      );
}

class _CardFormResult {
  const _CardFormResult({
    required this.title,
    required this.suit,
    required this.folderId,
    required this.notes,
    required this.imageRef,
  });
  final String title;
  final String suit;
  final int folderId;
  final String notes;
  final String? imageRef;
}

class _CardFormDialog extends StatefulWidget {
  const _CardFormDialog({required this.card, required this.folderId});
  final CardRecord? card;
  final int folderId;

  @override
  State<_CardFormDialog> createState() => _CardFormDialogState();
}

class _CardFormDialogState extends State<_CardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _image;
  late String _suit;

  static const suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.card?.title ?? '');
    _notes = TextEditingController(text: widget.card?.notes ?? '');
    _image = TextEditingController(text: widget.card?.imageRef ?? '');
    _suit = widget.card?.suit ?? 'Hearts';
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.card == null ? 'Add card' : 'Edit card · ID ${widget.card!.id}'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _suit,
                decoration: const InputDecoration(labelText: 'Suit', border: OutlineInputBorder()),
                items: suits.map((suit) => DropdownMenuItem(value: suit, child: Text(suit))).toList(),
                onChanged: (value) { if (value != null) setState(() => _suit = value); },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _image,
                decoration: const InputDecoration(labelText: 'Image reference (optional)', hintText: 'Leave blank for suit fallback', border: OutlineInputBorder()),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, _CardFormResult(
                title: _title.text.trim(),
                suit: _suit,
                folderId: widget.folderId,
                notes: _notes.text.trim(),
                imageRef: _image.text.trim().isEmpty ? null : _image.text.trim(),
              ));
            },
            child: const Text('Save'),
          ),
        ],
      );
}
