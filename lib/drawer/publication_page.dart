import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';
import 'package:new_das_laybary/ui_helper/ui_colors.dart';

class Publication_Page extends StatefulWidget {
  const Publication_Page({super.key});

  @override
  State<Publication_Page> createState() => _PublicationPageState();
}

class _PublicationPageState extends State<Publication_Page> {
  final TextEditingController pubController = TextEditingController();

  // 🔥 Firestore collection
  final CollectionReference publications = FirebaseFirestore.instance
      .collection('laybary').doc('test')
      .collection('new_das_laybary')
      .doc('publication')
      .collection('items');

  // ✅ Save new publication
  Future<void> savePublication() async {
    final name = pubController.text.trim();
    if (name.isEmpty) return;

    await publications.add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    pubController.clear();
  }

  void cancelInput() => pubController.clear();

  // ✅ Edit publication dialog
  void editPublication(String id, String currentName) {
    pubController.text = currentName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.BLACK_7,
          title: Text("Edit Publication",
              style: snTextStyle20Bold(color: AppColors.WHITE_9)),
          content: TextField(
            controller: pubController,
            style: TextStyle(color: AppColors.WHITE_9),
            decoration: InputDecoration(
              labelText: "Publication Name",
              labelStyle: TextStyle(color: AppColors.WHITE_9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.white60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
            // ✅ Enter চাপলে update হবে
            onSubmitted: (value) async {
              final newName = pubController.text.trim();
              if (newName.isNotEmpty) {
                await publications.doc(id).update({'name': newName});
                pubController.clear();
                Navigator.pop(context); // dialog close
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () async {
                final newName = pubController.text.trim();
                if (newName.isNotEmpty) {
                  await publications.doc(id).update({'name': newName});
                  pubController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("Update", style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deletePublication(String id) async {
    await publications.doc(id).delete();
  }

  // ✅ Build method
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700; // Web or desktop view

    return Scaffold(
      backgroundColor: AppColors.BLACK_9,
      appBar: AppBar(
        title: Text("Publication", style: snTextStyle20Bold(color: AppColors.WHITE_9)),
        centerTitle: true,
        backgroundColor: AppColors.BLACK_9,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Publication Name.....",
                style: snTextStyle20(color: AppColors.WHITE_9)),
            const SizedBox(height: 20),

            // ✅ Input Field
            TextField(
              controller: pubController,
              style: TextStyle(color: AppColors.WHITE_9),
              decoration: InputDecoration(
                hintText: "Publication Name",
                labelText: "Publication Name",
                hintStyle: TextStyle(color: AppColors.WHITE_9),
                labelStyle: TextStyle(color: AppColors.WHITE_9),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: Colors.white60),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  await savePublication();
                  FocusScope.of(context).unfocus(); // keyboard hide
                }
              },
            ),
            const SizedBox(height: 15),

            // ✅ Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: savePublication,
                  child: const Text("Save",
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: cancelInput,
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ Firestore data
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: publications
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No publications added yet.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // ✅ Responsive switch
                  return isWide
                      ? buildWebTable(docs)
                      : buildMobileList(docs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Mobile view (ListTile)
  Widget buildMobileList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? '';

        return Card(
          color: Colors.grey[850],
          child: ListTile(
            leading: Text(
              '${index + 1}.',
              style: const TextStyle(color: Colors.white),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.greenAccent),
                  onPressed: () => editPublication(doc.id, name),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => deletePublication(doc.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Web/Desktop view (DataTable)
  Widget buildWebTable(List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[850]),
        columns: const [
          DataColumn(
              label: Text("SL",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text("Publication Name",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text("Actions",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
        rows: docs.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] ?? '';

          return DataRow(cells: [
            DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.white))),
            DataCell(Text(name, style: const TextStyle(color: Colors.white))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.greenAccent),
                  onPressed: () => editPublication(doc.id, name),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => deletePublication(doc.id),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}