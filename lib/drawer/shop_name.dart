import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_das_laybary/drawer/shop_page/bloc/shop_bloc.dart';
import 'package:new_das_laybary/drawer/shop_page/models/shop_models.dart';
import '../ui_helper/ui_colors.dart';


class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().loadShops();
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white30),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.greenAccent),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ShopBloc>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("🛒 Shop List", style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: bloc.isSyncing ? null : () => bloc.syncAll(),
              icon: bloc.isSyncing
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.sync, color: Colors.white),
              label: const Text("Sync", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final isPortrait = constraints.maxWidth < 600;
                if (isPortrait) {
                  return Column(
                    children: [
                      _buildTextField(nameCtrl, "Shop Name"),
                      const SizedBox(height: 10),
                      _buildTextField(locationCtrl, "Location"),
                      const SizedBox(height: 10),
                      _saveButton(context),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: _buildTextField(nameCtrl, "Shop Name")),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField(locationCtrl, "Location")),
                      const SizedBox(width: 10),
                      _saveButton(context),
                    ],
                  );
                }
              }),
              const SizedBox(height: 25),
              _buildDataTable(bloc.state, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      onSubmitted: (_) => _save(context),
    );
  }

  Widget _saveButton(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    onPressed: () => _save(context),
    child: const Text("Save"),
  );

  void _save(BuildContext context) {
    final name = nameCtrl.text.trim();
    final loc = locationCtrl.text.trim();
    if (name.isEmpty || loc.isEmpty) return;
    context.read<ShopBloc>().addShop(name, loc);
    nameCtrl.clear();
    locationCtrl.clear();
  }

  Widget _buildDataTable(List<ShopModel> shops, BuildContext context) {
    if (shops.isEmpty) {
      return const Text("No shops yet.", style: TextStyle(color: Colors.white70));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
        WidgetStateProperty.all(Colors.green.withOpacity(0.2)),
        border: TableBorder.all(color: Colors.white30),
        columns: const [
          DataColumn(label: Text("No.", style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text("Shop Name", style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text("Location", style: TextStyle(color: Colors.white))),
          DataColumn(label: Text("Action", style: TextStyle(color: Colors.white))),
        ],
        rows: List.generate(shops.length, (index) {
          final item = shops[index];
          return DataRow(cells: [
            DataCell(Text("${index + 1}",
                style: const TextStyle(color: Colors.white))),
            DataCell(Text(item.name,
                style: const TextStyle(color: Colors.white))),
            DataCell(Text(item.location,
                style: const TextStyle(color: Colors.white))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, item),
                ),
              ],
            )),
          ]);
        }),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ShopModel shop) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.BLACK_7,
        title:
        const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
        content: const Text("Delete this shop?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<ShopBloc>().deleteShop(shop);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
