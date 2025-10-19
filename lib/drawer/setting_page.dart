import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';
import 'package:new_das_laybary/ui_helper/ui_colors.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? selectedPublication;
  String selectedFilter = 'All';

  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController purchaseCtrl = TextEditingController();
  final TextEditingController sellCtrl = TextEditingController();

  bool _isSyncing = false;

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

  Box? _localBox;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    _localBox = await Hive.openBox('booksTypeLocal');
    setState(() {});
  }

  Map<String, dynamic> _normalizeDiscountValue(dynamic value) {
    try {
      if (value is Map) {
        return {
          'purchase': value['purchase'] ?? 0,
          'sell': value['sell'] ?? 0,
        };
      } else if (value is String || value is num) {
        return {'purchase': value, 'sell': value};
      }
    } catch (_) {}
    return {'purchase': 0, 'sell': 0};
  }

  Future<void> addCategory(String pubName) async {
    final category = categoryCtrl.text.trim();
    final purchase = double.tryParse(purchaseCtrl.text.trim()) ?? 0;
    final sell = double.tryParse(sellCtrl.text.trim()) ?? 0;

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Category name required")),
      );
      return;
    }

    await _saveToLocal(pubName, category, purchase, sell);
    await _trySyncToFirebase();

    categoryCtrl.clear();
    purchaseCtrl.clear();
    sellCtrl.clear();
    setState(() {});
  }

  Future<void> _saveToLocal(String pubName, String category, double purchase, double sell) async {
    final data = _localBox?.get(pubName, defaultValue: {
      'categories': [],
      'discounts': {}
    }) ??
        {
          'categories': [],
          'discounts': {}
        };

    final categories = List<String>.from(data['categories']);
    final discounts = Map<String, dynamic>.from(data['discounts']);

    if (!categories.contains(category)) {
      categories.add(category);
    }
    discounts[category] = {'purchase': purchase, 'sell': sell};

    await _localBox?.put(pubName, {
      'categories': categories,
      'discounts': discounts,
    });
  }

  Future<void> _trySyncToFirebase() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    setState(() => _isSyncing = true);

    final allKeys = _localBox?.keys ?? [];
    for (var key in allKeys) {
      final localData = _localBox?.get(key);
      if (localData != null) {
        await booksType.doc(key).set({
          'categories': localData['categories'],
          'discounts': localData['discounts'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Synced with Firebase")),
    );
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Books Type", style: snTextStyle20Bold(color: AppColors.WHITE_9)),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : _trySyncToFirebase,
              icon: const Icon(Icons.sync),
              label: Text(_isSyncing ? "Syncing..." : "Sync"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _localBox == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: publications.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final docs = snapshot.data!.docs;
                  final publicationNames = docs.map((e) => e['name'] as String).toList();

                  return Column(
                    children: [
                      DropdownButton<String>(
                        value: selectedPublication,
                        hint: const Text("Select Publication", style: TextStyle(color: Colors.white70)),
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        items: publicationNames
                            .map((pub) => DropdownMenuItem(value: pub, child: Text(pub)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedPublication = val),
                      ),
                      const SizedBox(height: 12),

                      // 🔹 Responsive Input Fields
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 600;
                          final categoryField = TextField(
                            controller: categoryCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration("Category Name"),
                          );

                          final purchaseField = TextField(
                            controller: purchaseCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration("Purchase Discount"),
                          );

                          final sellField = TextField(
                            controller: sellCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration("Sell Discount"),
                            onSubmitted: (_) {
                              if (selectedPublication != null) {
                                addCategory(selectedPublication!);
                              }
                            },
                          );

                          final addButton = ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                              const MaterialStatePropertyAll(Colors.green),
                              foregroundColor:
                              const MaterialStatePropertyAll(Colors.white),
                              padding: const MaterialStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              shape: MaterialStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            onPressed: selectedPublication == null
                                ? null
                                : () => addCategory(selectedPublication!),
                            child: const Padding(
                              padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text("Add"),
                            ),
                          );

                          return isWide
                              ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: categoryField),
                              const SizedBox(width: 10),
                              Expanded(flex: 2, child: purchaseField),
                              const SizedBox(width: 10),
                              Expanded(flex: 2, child: sellField),
                              const SizedBox(width: 10),
                              addButton,
                            ],
                          )
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              categoryField,
                              const SizedBox(height: 10),
                              purchaseField,
                              const SizedBox(height: 10),
                              sellField,
                              const SizedBox(height: 15),
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(width: 120, child: addButton),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 25),
                      Text("Categories (Local + Cloud)", style: snTextStyle20Bold(color: AppColors.WHITE_9)),

                      const SizedBox(height: 15),
                      ValueListenableBuilder(
                        valueListenable: _localBox!.listenable(),
                        builder: (context, box, _) {
                          final allKeys = box.keys.toList();
                          if (allKeys.isEmpty) {
                            return const Text("No data found", style: TextStyle(color: Colors.white70));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: allKeys.length,
                            itemBuilder: (context, index) {
                              final pub = allKeys[index];
                              final data = box.get(pub);
                              final categories = List<String>.from(data['categories']);
                              final discounts = Map<String, dynamic>.from(data['discounts']);

                              return Card(
                                color: Colors.grey[850],
                                child: ExpansionTile(
                                  title: Text(pub, style: const TextStyle(color: Colors.white)),
                                  children: categories.map((cat) {
                                    final d = discounts[cat] ?? {'purchase': 0, 'sell': 0};
                                    return ListTile(
                                      title: Text(cat, style: const TextStyle(color: Colors.white)),
                                      subtitle: Text(
                                        "Purchase: ${d['purchase']} | Sell: ${d['sell']}",
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    );
                                  }).toList(),
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
            ],
          ),
        ),
      ),
    );
  }
}
