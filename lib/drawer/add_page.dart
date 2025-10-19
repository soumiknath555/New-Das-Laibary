import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:new_das_laybary/ui_helper/multi_select_dropdown.dart';
import 'package:new_das_laybary/ui_helper/sn_button.dart';
import 'package:new_das_laybary/ui_helper/text_field.dart';
import 'package:new_das_laybary/ui_helper/dropdowon_button.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController authorCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController();

  final MultiSelectController<String> shopNameCtrl = MultiSelectController();

  List<String> brandList = ["Unknown", "Roy Martin", "Chaya", "Prantik"];
  String? selectedBrand;

  List<String> classList = ["10", "9", "8", "7", "6", "5", "4", "3", "2", "1"];
  String? selectedClass;

  List<String> st = ["Text Book", "Sohaika", "Project", "Khata"];
  String? selectedST;

  final List<MultiSelectModel> shopName = [
    MultiSelectModel(id: 1, name: "Mukharji Laybary"),
    MultiSelectModel(id: 2, name: "Arnob Laybary"),
    MultiSelectModel(id: 3, name: "Saha Laybary"),
    MultiSelectModel(id: 4, name: "Netaji Laybary"),
    MultiSelectModel(id: 5, name: "Janoprio Laybary"),
    MultiSelectModel(id: 6, name: "School Laybary"),
  ];

  List<MultiSelectModel> selectedShopName = [];

  File? _selectedImage;
  Uint8List? _webImage;
  late DropzoneViewController _dropzoneController;

  /// Pick from gallery (mobile & desktop)
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      } else {
        _cropImage(picked.path);
      }
    }
  }

  /// Crop image (mobile only)
  Future<void> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedImage = File(croppedFile.path);
      });
    }
  }

  /// Image uploader widget
  Widget _buildImageUploader(double size) {
    final color = Theme.of(context).colorScheme.surfaceVariant;
    return Card(
      elevation: 4,
      child: Container(
        height: size,
        width: size,
        color: color,
        child: Stack(
          children: [
            if (kIsWeb)
              DropzoneView(
                onCreated: (ctrl) => _dropzoneController = ctrl,
                onDrop: (event) async {
                  final bytes = await _dropzoneController.getFileData(event);
                  setState(() => _webImage = bytes);
                },
              ),
            Center(
              child: _selectedImage == null && _webImage == null
                  ? TextButton.icon(
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Upload Image"),
                onPressed: _pickImageFromGallery,
              )
                  : _webImage != null
                  ? Image.memory(
                _webImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              )
                  : Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            if (_selectedImage != null || _webImage != null)
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    if (_selectedImage != null && !kIsWeb)
                      IconButton(
                        icon: const Icon(Icons.crop, color: Colors.orange),
                        onPressed: () {
                          if (_selectedImage != null) {
                            _cropImage(_selectedImage!.path);
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _webImage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String get finalPrice {
    double mrp = double.tryParse(mrpCtrl.text) ?? 0;
    double discount = double.tryParse(discountCtrl.text) ?? 0;
    double price = mrp - discount;
    return price > 0 ? price.toStringAsFixed(2) : "-";
  }

  @override
  Widget build(BuildContext context) {
    final shopDropDown =
    shopName.map((shop) => MultiSelectItem(shop, shop.name)).toList();
    final isWide = MediaQuery.of(context).size.width > 900;
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      appBar: AppBar(title: const Text("Add Book"), centerTitle: true),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        padding: const EdgeInsets.all(12),
        child: isWide && orientation == Orientation.landscape
            ? Row(
          children: [
            /// LEFT — scrollable form
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 12),
                child: _buildForm(shopDropDown),
              ),
            ),

            /// RIGHT — fixed preview
            Container(
              width: MediaQuery.of(context).size.width * 0.35,
              child: _buildPreviewCard(),
            ),
          ],
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildForm(shopDropDown),
              const SizedBox(height: 20),
              _buildPreviewCard(), // portrait: below form
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<MultiSelectItem<MultiSelectModel>> shopDropDown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageUploader(250),
        const SizedBox(height: 10),
        _buildBookInfoCard(),
        const SizedBox(height: 10),
        _buildDropdowns(),
        const SizedBox(height: 10),
        _buildPriceCard(),
        const SizedBox(height: 10),
        _buildShopSelect(shopDropDown),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SnButton(text: "Save", onPressed: () {}),
            const SizedBox(width: 40),
            SnButton(text: "Cancel", onPressed: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildBookInfoCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            snTextField(
              hint: "Book Name",
              label: "Book Name",
              controller: nameCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            snTextField(
              hint: "Author Name",
              label: "Author Name",
              controller: authorCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            snTextField(
              hint: "Description",
              label: "Description",
              controller: descCtrl,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdowns() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SnDropdown(
              items: st,
              value: selectedST,
              hintText: "Book Type",
              onChanged: (v) => setState(() => selectedST = v),
            ),
            SnDropdown(
              items: brandList,
              value: selectedBrand,
              hintText: "Brand",
              onChanged: (v) => setState(() => selectedBrand = v),
            ),
            SnDropdown(
              items: classList,
              value: selectedClass,
              hintText: "Class",
              onChanged: (v) => setState(() => selectedClass = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            snTextField(
              hint: "MRP",
              label: "MRP",
              controller: mrpCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            snTextField(
              hint: "Discount",
              label: "Discount",
              controller: discountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            snTextField(
              hint: "Quantity",
              label: "Quantity",
              controller: quantityCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopSelect(List<MultiSelectItem<MultiSelectModel>> items) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SnMultiSelectDropdown<MultiSelectModel>(
          title: "Shop Name",
          items: items,
          onConfirm: (value) {
            setState(() {
              selectedShopName = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 300,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : _webImage != null
                  ? Image.memory(_webImage!, fit: BoxFit.cover)
                  : Container(
                color: Colors.grey[800],
                child:
                const Center(child: Text("No Image Selected")),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: DefaultTextStyle(
                  style: TextStyle(color: textColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📖 ${nameCtrl.text}"),
                      Text("✍️ ${authorCtrl.text}"),
                      Text("🏷 Brand: ${selectedBrand ?? "-"}"),
                      Text("📚 Class: ${selectedClass ?? "-"}"),
                      Text("📂 Type: ${selectedST ?? "-"}"),
                      Text("💰 MRP: ${mrpCtrl.text}"),
                      Text("💸 Discount: ${discountCtrl.text}"),
                      Text("💰 Final Price: $finalPrice"),
                      Text(
                          "📦 Quantity: ${quantityCtrl.text.isEmpty ? "-" : quantityCtrl.text}"),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selectedShopName
                            .map((shop) => Chip(label: Text(shop.name)))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text("📝 ${descCtrl.text}"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
