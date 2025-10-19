// class_name_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../ui_helper/ui_colors.dart';

/// Model for a class item stored both locally and remotely.
class ClassItem {
  String id;
  String name;
  int updatedAt;
  bool isDirty;

  ClassItem({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.isDirty = false,
  });

  factory ClassItem.fromMap(Map<String, dynamic> m) {
    return ClassItem(
      id: m['id'] ?? const Uuid().v4(),
      name: m['name'] ?? '',
      updatedAt: m['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      isDirty: m['isDirty'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'updatedAt': updatedAt,
      'isDirty': isDirty,
    };
  }
}

/// Repository for handling local + remote sync
class ClassRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference remoteCollection = FirebaseFirestore.instance
      .collection('laybary')
      .doc('test')
      .collection('new_das_laybary')
      .doc('class')
      .collection('items');

  static const String boxName = 'classes_box';
  late Box _box;

  StreamSubscription<QuerySnapshot>? _remoteSub;
  final StreamController<List<ClassItem>> _itemsController =
  StreamController.broadcast();
  Stream<List<ClassItem>> get itemsStream => _itemsController.stream;

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
    _itemsController.close();
  }

  List<ClassItem> _readLocalItems() {
    final List<String> list =
    List<String>.from(_box.get('items', defaultValue: <String>[]));
    return list.map((s) => ClassItem.fromMap(jsonDecode(s))).toList();
  }

  Future<void> _writeLocalItems(List<ClassItem> items) async {
    final List<String> encoded =
    items.map((i) => jsonEncode(i.toMap())).toList();
    await _box.put('items', encoded);
    _pushLocalToStream();
  }

  Future<void> addOrUpdateLocal(ClassItem item,
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
      final remoteMap = <String, ClassItem>{};
      for (var d in remoteDocs) {
        final m = d.data() as Map<String, dynamic>;
        final id = d.id;
        remoteMap[id] = ClassItem(
          id: id,
          name: (m['name'] ?? '') as String,
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

      for (var l in List<ClassItem>.from(local)) {
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

  Future<void> _pushOneToRemote(ClassItem item) async {
    try {
      await remoteCollection.doc(item.id).set({
        'name': item.name,
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
      return ClassItem(
        id: d.id,
        name: (m['name'] ?? '') as String,
        updatedAt:
        (m['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch) as int,
        isDirty: false,
      );
    }).toList();

    final mergedMap = <String, ClassItem>{};
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

  Future<void> createClass(String name, String shortKey) async {
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = ClassItem(
      id: id,
      name: name,
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

  Future<void> updateClass(ClassItem item,
      {String? name, String? shortKey}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    item.name = name ?? item.name;
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

  Future<void> removeClass(String id) async {
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
class ClassNamePage extends StatefulWidget {
  const ClassNamePage({Key? key}) : super(key: key);

  @override
  State<ClassNamePage> createState() => _ClassNamePageState();
}

class _ClassNamePageState extends State<ClassNamePage> {
  final ClassRepository repo = ClassRepository();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController shortController = TextEditingController();

  bool isSyncing = false;
  List<ClassItem> items = [];
  StreamSubscription<List<ClassItem>>? _itemsSub;

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

  Future<void> _confirmDelete(ClassItem item) async {
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
              child:
              const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await repo.removeClass(item.id);
    }
  }

  void _showEditDialog(ClassItem item) {
    final tcName = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.BLACK_7,
        title: const Text('Edit Class', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tcName,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Class Name',
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

          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              final newName = tcName.text.trim();
              if (newName.isEmpty) return;
              await repo.updateClass(item, name: newName, );
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
        const SnackBar(content: Text('Enter a class name')),
      );
      return;
    }
    setState(() => isSyncing = true);
    try {
      await repo.createClass(name, short);
      nameController.clear();
      shortController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Saved locally (and uploaded if online)')),
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
          content: Text('Sync complete ✅'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sync failed: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isSyncing = false);
    }
  }

  Widget buildClassDataTable(List<ClassItem> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          'No Classes added yet.',
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
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Class Name',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),

            DataColumn(
              label: Text(
                'Last Updated',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  formattedDate,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                )),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.greenAccent),
                      tooltip: 'Edit Class',
                      onPressed: () => _showEditDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete Class',
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
        title:
        const Text('Class Name', style: TextStyle(color: Colors.white)),
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
          const Text('Add Class Name.....',
              style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 12),
          _buildNameField(),
          const SizedBox(height: 12),
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
          Expanded(child: buildClassDataTable(items)),
        ]),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Class Name',
        hintStyle: const TextStyle(color: Colors.white54),
        labelText: 'Class Name',
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
