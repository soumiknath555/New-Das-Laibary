import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';
import 'package:path_provider/path_provider.dart';
import 'package:new_das_laybary/ui_helper/ui_colors.dart';

class BooksType extends StatefulWidget {
  const BooksType({super.key});

  @override
  State<BooksType> createState() => _BooksTypeState();
}

class _BooksTypeState extends State<BooksType> {
  String? selectedPublication;
  String selectedFilter = 'All';
  bool isSyncing = false;

  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController purchaseCtrl = TextEditingController();
  final TextEditingController sellCtrl = TextEditingController();

  final CollectionReference publications = FirebaseFirestore.instance
      .collection('laybary')
      .doc('test')
      .collection('new_das_laybary')
      .doc('publication')
      .collection('items');

  final CollectionReference booksType = FirebaseFirestore.instance
      .collection('laybary')
      .doc('test')
      .collection('new_das_laybary')
      .doc('books-type')
      .collection('items');

  late Box localBox;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    if (kIsWeb) {
      localBox = await Hive.openBox('books_type_cache');
    } else {
      Directory dir;
      if (Platform.isAndroid || Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = Directory.current;
      }
      Hive.init(dir.path);
      localBox = await Hive.openBox('books_type_cache');
    }
  }

  Map<String, dynamic> _normalizeDiscountValue(dynamic value) {
    if (value is Map) {
      return {'purchase': value['purchase'] ?? 0, 'sell': value['sell'] ?? 0};
    } else if (value is String || value is num) {
      return {'purchase': value, 'sell': value};
    }
    return {'purchase': 0, 'sell': 0};
  }

  Future<void> addCategory(String pubName) async {
    final category = categoryCtrl.text.trim();
    final purchase = double.tryParse(purchaseCtrl.text.trim()) ?? 0;
    final sell = double.tryParse(sellCtrl.text.trim()) ?? 0;

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ Category name required")));
      return;
    }

    final data = {
      'publication': pubName,
      'category': category,
      'discounts': {'purchase': purchase, 'sell': sell},
      'createdAt': DateTime.now().toIso8601String(),
      'synced': false,
    };

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      await _saveToFirebase(data);
      data['synced'] = true;
    }

    await _saveToLocal(data);

    categoryCtrl.clear();
    purchaseCtrl.clear();
    sellCtrl.clear();
    setState(() {});
  }

  Future<void> _saveToLocal(Map<String, dynamic> data) async {
    final localList = localBox.get('items', defaultValue: <String>[]);
    final List<String> newList = List<String>.from(localList);
    newList.add(jsonEncode(data));
    await localBox.put('items', newList);
  }

  Future<void> _saveToFirebase(Map<String, dynamic> data) async {
    final docRef = booksType.doc(data['publication']);
    final docSnap = await docRef.get();

    List categories = [];
    Map<String, dynamic> discounts = {};

    if (docSnap.exists) {
      final existing = docSnap.data() as Map<String, dynamic>;
      categories = List.from(existing['categories'] ?? []);
      discounts = Map<String, dynamic>.from(existing['discounts'] ?? {});
    }

    final category = data['category'];
    if (!categories.contains(category)) {
      categories.add(category);
    }
    discounts[category] = data['discounts'];

    await docRef.set({
      'categories': categories,
      'discounts': discounts,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCategory(String pubName, String oldCategory, String newCategory,
      double newPurchase, double newSell) async {
    final docRef = booksType.doc(pubName);
    final docSnap = await docRef.get();
    if (!docSnap.exists) return;

    final data = docSnap.data() as Map<String, dynamic>;
    List categories = List.from(data['categories'] ?? []);
    Map<String, dynamic> discounts = Map<String, dynamic>.from(data['discounts'] ?? {});

    if (oldCategory != newCategory) {
      categories.remove(oldCategory);
      categories.add(newCategory);
      discounts.remove(oldCategory);
    }

    discounts[newCategory] = {'purchase': newPurchase, 'sell': newSell};

    await docRef.update({
      'categories': categories,
      'discounts': discounts,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String pubName, String category) async {
    final docRef = booksType.doc(pubName);
    final docSnap = await docRef.get();
    if (!docSnap.exists) return;

    final data = docSnap.data() as Map<String, dynamic>;
    List categories = List.from(data['categories'] ?? []);
    Map<String, dynamic> discounts = Map<String, dynamic>.from(data['discounts'] ?? {});

    categories.remove(category);
    discounts.remove(category);

    await docRef.update({
      'categories': categories,
      'discounts': discounts,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncAllData() async {
    setState(() => isSyncing = true);

    try {
      final QuerySnapshot snapshot = await booksType.get();
      List<Map<String, dynamic>> allData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final publication = doc.id;
        final categories = List<String>.from(data['categories'] ?? []);
        final discountsRaw = Map<String, dynamic>.from(data['discounts'] ?? {});

        for (var cat in categories) {
          allData.add({
            'publication': publication,
            'category': cat,
            'discounts': discountsRaw[cat] ?? {'purchase': 0, 'sell': 0},
            'createdAt': DateTime.now().toIso8601String(),
            'synced': true,
          });
        }
      }

      await localBox.put('items', allData.map((e) => jsonEncode(e)).toList());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Sync complete!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Sync failed: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => isSyncing = false);
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white54),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BLACK_9,
      appBar: AppBar(
        backgroundColor: AppColors.BLACK_9,
        title: const Text("Books Type", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextButton.icon(
              onPressed: isSyncing ? null : syncAllData,
              icon: isSyncing
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, color: Colors.white),
              label: Text(
                isSyncing ? "Syncing..." : "Sync",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green, // ✅ এখানে background color
               // padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(width: 25,)
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: StreamBuilder<QuerySnapshot>(
              stream: publications.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pubs = snapshot.data!.docs;
                final pubNames = pubs.map((e) => e['name'] as String).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // 🔽 Publication Select
                    DropdownButton<String>(
                      value: selectedPublication,
                      hint: const Text("Select Publication",
                          style: TextStyle(color: Colors.white70)),
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      items: pubNames
                          .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedPublication = val),
                    ),
                    const SizedBox(height: 10),

                    // 📝 Input Fields + Add
                    TextField(
                      controller: categoryCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Category Name"),
                      onSubmitted: (_) {
                        if (selectedPublication != null) {
                          addCategory(selectedPublication!);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: purchaseCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Purchase Discount"),
                      onSubmitted: (_) {
                        if (selectedPublication != null) {
                          addCategory(selectedPublication!);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: sellCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Sell Discount"),
                      onSubmitted: (_) {
                        if (selectedPublication != null) {
                          addCategory(selectedPublication!);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                   /* ElevatedButton.icon(
                      onPressed: selectedPublication == null
                          ? null
                          : () => addCategory(selectedPublication!),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Category"),
                    ),*/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: selectedPublication == null
                              ? null
                              : () async {
                            await addCategory(selectedPublication!); // 👉 অনলাইন ও অফলাইন দুই জায়গায় save হবে
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Category saved successfully!"),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            "Add Category",
                            style: snTextStyle20(color: AppColors.WHITE_9),
                          ),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.green),
                            foregroundColor: MaterialStateProperty.all(Colors.white),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            elevation: MaterialStateProperty.all(4),
                          ),

                        ),
                      ],
                    ),


                    const Divider(height: 30, color: Colors.white30),

                    // 🔽 Filter Dropdown

                    DropdownButton<String>(
                      value: selectedFilter,
                      hint: const Text("Filter by Publisher",
                          style: TextStyle(color: Colors.white70)),
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text('All'),
                        ),
                        ...pubNames.map((p) =>
                            DropdownMenuItem(value: p, child: Text(p))),
                      ],
                      onChanged: (val) =>
                          setState(() => selectedFilter = val ?? 'All'),
                    ),

                    // 📘 List of Categories
                    StreamBuilder<QuerySnapshot>(
                      stream: booksType.snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snap.data!.docs;
                        final filtered = selectedFilter == 'All'
                            ? docs
                            : docs.where((d) => d.id == selectedFilter).toList();

                        List<Map<String, dynamic>> allCats = [];
                        for (var doc in filtered) {
                          final data = doc.data() as Map<String, dynamic>;
                          final categories =
                          List<String>.from(data['categories'] ?? []);
                          final discounts =
                          Map<String, dynamic>.from(data['discounts'] ?? {});
                          for (var cat in categories) {
                            final d = _normalizeDiscountValue(discounts[cat]);
                            allCats.add({
                              'pub': doc.id,
                              'cat': cat,
                              'p': d['purchase'],
                              's': d['sell'],
                            });
                          }
                        }

                        if (allCats.isEmpty) {
                          return const Center(
                              child: Text("No Categories Found",
                                  style: TextStyle(color: Colors.white70)));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allCats.length,
                          itemBuilder: (_, i) {
                            final item = allCats[i];
                            return Card(
                              color: Colors.grey[850],
                              child: ListTile(
                                title: Text(item['cat'],
                                    style:
                                    const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  "Publication: ${item['pub']}\nPurchase: ${item['p']} | Sell: ${item['s']}",
                                  style:
                                  const TextStyle(color: Colors.white70),
                                ),
                                trailing: Wrap(
                                  spacing: 12,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.greenAccent),
                                      onPressed: () => _showEditDialog(
                                          item['pub'],
                                          item['cat'],
                                          item['p'],
                                          item['s']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _confirmDelete(
                                          item['pub'], item['cat']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }),
    );
  }

  void _showEditDialog(
      String pubName, String oldCategory, double purchase, double sell) {
    final TextEditingController editCategoryCtrl =
    TextEditingController(text: oldCategory);
    final TextEditingController editPurchaseCtrl =
    TextEditingController(text: purchase.toString());
    final TextEditingController editSellCtrl =
    TextEditingController(text: sell.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
        const Text("Edit Category", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pubName, style: const TextStyle(color: Colors.greenAccent)),
            const SizedBox(height: 10),
            TextField(
              controller: editCategoryCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Category Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: editPurchaseCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Purchase Discount"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: editSellCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Sell Discount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () async {
              await updateCategory(
                pubName,
                oldCategory,
                editCategoryCtrl.text.trim(),
                double.tryParse(editPurchaseCtrl.text) ?? 0,
                double.tryParse(editSellCtrl.text) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text("Save",
                style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String pubName, String category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Confirm Delete",
            style: TextStyle(color: Colors.redAccent)),
        content: Text(
          "Are you sure you want to delete '$category'?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("Cancel", style: TextStyle(color: Colors.greenAccent)),
          ),
          TextButton(
            onPressed: () async {
              await deleteCategory(pubName, category);
              Navigator.pop(context);
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
