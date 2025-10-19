// school_name_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';
import 'package:uuid/uuid.dart';

import '../../ui_helper/ui_colors.dart';

/// Model for a school item stored both locally and remotely.
class SchoolItem {
  String id;
  String name;
  String shortKey;
  int updatedAt;
  bool isDirty;

  SchoolItem({
    required this.id,
    required this.name,
    required this.shortKey,
    required this.updatedAt,
    this.isDirty = false,
  });

  factory SchoolItem.fromMap(Map<String, dynamic> m) {
    return SchoolItem(
      id: m['id'] ?? const Uuid().v4(),
      name: m['name'] ?? '',
      shortKey: m['shortKey'] ?? '',
      updatedAt: m['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      isDirty: m['isDirty'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortKey': shortKey,
      'updatedAt': updatedAt,
      'isDirty': isDirty,
    };
  }
}

/// Repository for handling local + remote sync
class SchoolRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference remoteCollection = FirebaseFirestore.instance
      .collection('laybary')
      .doc('test')
      .collection('new_das_laybary')
      .doc('school_name')
      .collection('items');

  static const String boxName = 'schools_box';
  late Box _box;

  StreamSubscription<QuerySnapshot>? _remoteSub;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  final StreamController<List<SchoolItem>> _itemsController =
  StreamController.broadcast();
  Stream<List<SchoolItem>> get itemsStream => _itemsController.stream;

  bool _isListeningRemote = false;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
    if (!_box.containsKey('items')) {
      await _box.put('items', <String>[]);
    }
    _startRemoteListener();
    _pushLocalToStream();
  }

  void dispose() {
    _remoteSub?.cancel();
    _connectivitySub?.cancel();
    _itemsController.close();
  }

  List<SchoolItem> _readLocalItems() {
    final List<String> list =
    List<String>.from(_box.get('items', defaultValue: <String>[]));
    return list.map((s) => SchoolItem.fromMap(jsonDecode(s))).toList();
  }

  Future<void> _writeLocalItems(List<SchoolItem> items) async {
    final List<String> encoded =
    items.map((i) => jsonEncode(i.toMap())).toList();
    await _box.put('items', encoded);
    _pushLocalToStream();
  }

  Future<void> addOrUpdateLocal(SchoolItem item,
      {bool markDirty = true}) async {
    final items = _readLocalItems();
    final idx = items.indexWhere((i) => i.id == item.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    item.updatedAt = now;
    if (markDirty) item.isDirty = true;

    if (idx == -1) {
      items.add(item);
    } else {
      items[idx] = item;
    }
    await _writeLocalItems(items);
  }

  Future<void> deleteLocal(String id) async {
    final items = _readLocalItems();
    items.removeWhere((i) => i.id == id);
    await _writeLocalItems(items);
  }

  void _pushLocalToStream() {
    final items = _readLocalItems();
    items.sort((a, b) => a.name.compareTo(b.name));
    _itemsController.add(items);
  }

  void _startRemoteListener() {
    if (_isListeningRemote) return;
    _isListeningRemote = true;

    _remoteSub = remoteCollection.snapshots().listen((snapshot) async {
      final remoteDocs = snapshot.docs;
      final remoteMap = <String, SchoolItem>{};
      for (var d in remoteDocs) {
        final m = d.data() as Map<String, dynamic>;
        final id = d.id;
        remoteMap[id] = SchoolItem(
          id: id,
          name: (m['name'] ?? '') as String,
          shortKey: (m['shortKey'] ?? '') as String,
          updatedAt:
          (m['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch) as int,
          isDirty: false,
        );
      }

      final local = _readLocalItems();
      final localMap = {for (var l in local) l.id: l};

      bool localChanged = false;

      for (var r in remoteMap.values) {
        final l = localMap[r.id];
        if (l == null) {
          local.add(r);
          localChanged = true;
        } else {
          if (l.isDirty) {
            if (r.updatedAt > l.updatedAt) {
              localMap[r.id] = r;
              localChanged = true;
            } else {
              await _pushOneToRemote(l);
              l.isDirty = false;
              localChanged = true;
            }
          } else {
            if (r.updatedAt > l.updatedAt) {
              localMap[r.id] = r;
              localChanged = true;
            }
          }
        }
      }

      for (var l in List<SchoolItem>.from(local)) {
        if (!remoteMap.containsKey(l.id)) {
          if (l.isDirty) {
            await _pushOneToRemote(l);
            l.isDirty = false;
            localChanged = true;
          }
        }
      }

      final merged = localMap.values.toList();
      if (localChanged) {
        await _writeLocalItems(merged);
      } else {
        _pushLocalToStream();
      }
    }, onError: (err) {});
  }

  Future<void> _pushOneToRemote(SchoolItem item) async {
    try {
      await remoteCollection.doc(item.id).set({
        'name': item.name,
        'shortKey': item.shortKey,
        'updatedAt': item.updatedAt,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to push remote: $e');
      rethrow;
    }
  }

  Future<void> syncLocalToRemote() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      throw Exception('No internet');
    }

    final local = _readLocalItems();
    for (var item in local) {
      if (item.isDirty) {
        try {
          await _pushOneToRemote(item);
          item.isDirty = false;
        } catch (e) {
          debugPrint('upload error for ${item.id}: $e');
        }
      }
    }

    await _writeLocalItems(local);

    final snapshot = await remoteCollection.get();
    final remoteItems = snapshot.docs.map((d) {
      final m = d.data() as Map<String, dynamic>;
      return SchoolItem(
        id: d.id,
        name: (m['name'] ?? '') as String,
        shortKey: (m['shortKey'] ?? '') as String,
        updatedAt:
        (m['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch) as int,
        isDirty: false,
      );
    }).toList();

    final mergedMap = <String, SchoolItem>{};
    for (var r in remoteItems) mergedMap[r.id] = r;
    for (var l in local) {
      final r = mergedMap[l.id];
      if (r == null) {
        mergedMap[l.id] = l;
      } else {
        mergedMap[l.id] = (l.updatedAt >= r.updatedAt) ? l : r;
      }
    }

    final merged = mergedMap.values.toList();
    await _writeLocalItems(merged);
  }

  Future<void> createSchool(String name, String shortKey) async {
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = SchoolItem(
      id: id,
      name: name,
      shortKey: shortKey,
      updatedAt: now,
      isDirty: true,
    );
    await addOrUpdateLocal(item, markDirty: true);

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      try {
        await _pushOneToRemote(item);
        item.isDirty = false;
        await addOrUpdateLocal(item, markDirty: false);
      } catch (e) {}
    }
  }

  Future<void> updateSchool(SchoolItem item,
      {String? name, String? shortKey}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    item.name = name ?? item.name;
    item.shortKey = shortKey ?? item.shortKey;
    item.updatedAt = now;
    item.isDirty = true;
    await addOrUpdateLocal(item, markDirty: true);

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      try {
        await _pushOneToRemote(item);
        item.isDirty = false;
        await addOrUpdateLocal(item, markDirty: false);
      } catch (e) {}
    }
  }

  Future<void> removeSchool(String id) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      try {
        await remoteCollection.doc(id).delete();
      } catch (e) {}
    }
    await deleteLocal(id);
  }
}

/// --- UI Page
class SchoolNamePage extends StatefulWidget {
  const SchoolNamePage({Key? key}) : super(key: key);

  @override
  State<SchoolNamePage> createState() => _SchoolNamePageState();
}

class _SchoolNamePageState extends State<SchoolNamePage> {
  final SchoolRepository repo = SchoolRepository();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController shortController = TextEditingController();

  bool isSyncing = false;
  bool isWide = false;

  StreamSubscription<List<SchoolItem>>? _itemsSub;
  List<SchoolItem> items = [];

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    await repo.init();
    _itemsSub = repo.itemsStream.listen((list) {
      setState(() => items = list);
    });
    setState(() {});
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    repo.dispose();
    nameController.dispose();
    shortController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(SchoolItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.BLACK_7,
        title: const Text('Delete Confirmation',
            style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${item.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await repo.removeSchool(item.id);
    }
  }

  void _showEditDialog(SchoolItem item) {
    final tcName = TextEditingController(text: item.name);
    final tcShort = TextEditingController(text: item.shortKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.BLACK_7,
        title: const Text('Edit School', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tcName,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'School Name',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white38),
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(10)),
              ),

            ),
            const SizedBox(height: 10),
            TextField(
              controller: tcShort,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Short Key',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white38),
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              final newName = tcName.text.trim();
              final newShort = tcShort.text.trim();
              if (newName.isEmpty) return;
              await repo.updateSchool(item,
                  name: newName, shortKey: newShort);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> saveFromInputs() async {
    final name = nameController.text.trim();
    final short = shortController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a school name')),
      );
      return;
    }
    setState(() => isSyncing = true);
    try {
      await repo.createSchool(name, short);
      nameController.clear();
      shortController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Saved locally (and uploaded if online)')),
      );
    } finally {
      setState(() => isSyncing = false);
    }
  }

  Future<void> doSync() async {
    setState(() => isSyncing = true);
    try {
      await repo.syncLocalToRemote();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sync complete ✅'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.red));
    } finally {
      setState(() => isSyncing = false);
    }
  }

  Widget buildSchoolDataTable(List<SchoolItem> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          'No School Name added yet.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.BLACK_7,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: DataTable(
          columnSpacing: 100,
          headingRowColor: MaterialStateProperty.all(Colors.grey[850]),
          dataRowColor:
          MaterialStateProperty.all(AppColors.BLACK_7.withOpacity(0.4)),
          dividerThickness: 0.4,
          columns: const [
            DataColumn(
              label: Text(
                'SL',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'School Name',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Short Key',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Last Updated',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: docs.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final date = DateTime.fromMillisecondsSinceEpoch(item.updatedAt);
            final formattedDate =
                "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

            return DataRow(
              cells: [
                DataCell(Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white70),
                )),
                DataCell(Text(
                  item.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                )),
                DataCell(Text(
                  item.shortKey,
                  style: const TextStyle(
                      color: Colors.white70, fontStyle: FontStyle.italic),
                )),
                DataCell(Text(
                  formattedDate,
                  style:
                  const TextStyle(color: Colors.white54, fontSize: 12),
                )),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.greenAccent),
                      tooltip: 'Edit School',
                      onPressed: () => _showEditDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete School',
                      onPressed: () => _confirmDelete(item),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BLACK_9,
      appBar: AppBar(
        backgroundColor: AppColors.BLACK_9,
        centerTitle: true,
        title: const Text('School Name',
            style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 16),
            child: TextButton.icon(
              onPressed: isSyncing ? null : doSync,
              icon: isSyncing
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, color: Colors.white),
              label: Text(isSyncing ? 'Syncing...' : 'Sync',
                  style: const TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
          const Text('Add School Name.....',
              style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 12),
          _buildNameField(),
          const SizedBox(height: 12),
          _buildShortField(),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: isSyncing ? null : saveFromInputs,
              child:
              const Text('Save', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                nameController.clear();
                shortController.clear();
              },
              child:
              const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 18),
          Expanded(child: buildSchoolDataTable(items)),
        ]),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'School Name',
        hintStyle: const TextStyle(color: Colors.white54),
        labelText: 'School Name',
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.white38)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.white)),
      ),
    );
  }

  Widget _buildShortField() {
    return TextField(
      controller: shortController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Short Key e.g. B.H.S',
        hintStyle: const TextStyle(color: Colors.white54),
        labelText: 'Short Key',
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.white38)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.white)),
      ),
      onSubmitted: (_)async {
        await saveFromInputs();
      },
    );
  }
}
