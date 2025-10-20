import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:new_das_laybary/ui_helper/sn_button.dart';
import 'package:new_das_laybary/ui_helper/text_field.dart';
import 'package:new_das_laybary/ui_helper/dropdowon_button.dart';
import 'package:new_das_laybary/ui_helper/ui_colors.dart';

import '../ui_helper/multi_select_dropdown.dart';

class UploadedFile {
  final Uint8List? bytes;
  final File? file;
  final String name;
  final String mime;
  UploadedFile({this.bytes, this.file, required this.name, required this.mime});
  bool get isVideo => mime.toLowerCase().startsWith('video');
}

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final nameCtrl = TextEditingController();
  final authorCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final mrpCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final purchaseCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();

  List<String> classList = ['Class 1', 'Class 2', 'Class 3'];
  List<String> brandList = ['Roy & Martin', 'Chaya', 'Prantik', 'Book India'];
  List<String> stList = ['Textbook', 'Guide', 'Story Book'];

  String? selectedClass;
  String? selectedBrand;
  String? selectedST;

  List<MultiSelectModel> shopName = [
    MultiSelectModel(id: 1, name: "Mukharji Laybary"),
    MultiSelectModel(id: 2, name: "Arnob Laybary"),
    MultiSelectModel(id: 3, name: "Saha Laybary"),
    MultiSelectModel(id: 4, name: "Netaji Laybary"),
    MultiSelectModel(id: 5, name: "Janoprio Laybary"),
  ];
  List<MultiSelectModel> selectedShopName = [];

  List<UploadedFile> _uploadedFiles = [];
  late DropzoneViewController dropzoneController;

  Future<void> _pickImagesMobile() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null) {
      for (var img in images) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: img.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [AndroidUiSettings(toolbarTitle: 'Crop Image')],
        );
        if (cropped != null) {
          setState(() {
            _uploadedFiles.add(UploadedFile(
              file: File(cropped.path),
              name: cropped.path.split('/').last,
              mime: 'image/*',
            ));
          });
        }
      }
    }
  }

  Future<void> _pickVideoMobile() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _uploadedFiles.add(UploadedFile(
          file: File(picked.path),
          name: picked.path.split('/').last,
          mime: 'video/*',
        ));
      });
    }
  }

  Future<void> _handleDrop(dynamic event) async {
    final name = await dropzoneController.getFilename(event);
    final mime = await dropzoneController.getFileMIME(event);
    final bytes = await dropzoneController.getFileData(event);
    setState(() {
      _uploadedFiles.add(UploadedFile(bytes: bytes, name: name, mime: mime));
    });
  }

  Future<void> _pickFilesWeb() async {
    final events = await dropzoneController.pickFiles(multiple: true);
    for (var ev in events) {
      await _handleDrop(ev);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final orientation = MediaQuery.of(context).orientation;
    final shopDropDown =
    shopName.map((shop) => MultiSelectItem(shop, shop.name)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.BLACK_9,
        title: const Text('Books Add Page', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: AppColors.BLACK_9,
      body: Container(
        padding: const EdgeInsets.all(12),
        child: isWide && orientation == Orientation.landscape
            ? Row(
          children: [
            Expanded(flex: 3, child: SingleChildScrollView(child: _buildForm(shopDropDown))),
            const SizedBox(width: 12),
            Container(width: 350, child: _buildPreviewCard()),
          ],
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildForm(shopDropDown),
              const SizedBox(height: 20),
              _buildPreviewCard(),
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
        _bookInfoCard(),
        const SizedBox(height: 10),
        _dropdownCard(),
        const SizedBox(height: 10),
        _priceCard(),
        const SizedBox(height: 10),
        _shopCard(shopDropDown),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SnButton(text: "Save",buttonColor: AppColors.GREEN_9,textColor: AppColors.WHITE_9, onPressed: () {}),
              const SizedBox(width: 30),
              SnButton(text: "Cancel",buttonColor: AppColors.RED_9,textColor: AppColors.WHITE_9, onPressed: () {}),
            ],
          ),
        )
      ],
    );
  }

  Widget _bookInfoCard() => Card(
    color: AppColors.BLACK_7,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        snTextField(hint: "Book Name", label: "Book Name", controller: nameCtrl),
        const SizedBox(height: 10),
        snTextField(hint: "Author", label: "Author", controller: authorCtrl),
        const SizedBox(height: 10),
        snTextField(hint: "Description", label: "Description", controller: descCtrl, maxLines: 3),
      ]),
    ),
  );

  Widget _dropdownCard() => Card(
    color: AppColors.BLACK_7,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SnDropdown(items: brandList,
              value: selectedBrand,
              hintText: "Publication",
              onChanged: (v) => setState(() => selectedBrand = v)),

          SnDropdown(items: stList,
              value: selectedST,
              hintText: "Book Type",
              onChanged: (v) => setState(() => selectedST = v)),
          SnDropdown(items: classList,
              value: selectedClass,
              hintText: "Class",
              onChanged: (v) => setState(() => selectedClass = v)),
        ],
      ),
    ),
  );

  Widget _priceCard() => Card(
    color: AppColors.BLACK_7,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          snTextField(hint: "MRP", label: "MRP", controller: mrpCtrl),
          const SizedBox(height: 10),
          snTextField(hint: "Sell Discount", label: "Sell Discount", controller: discountCtrl),
          const SizedBox(height: 10),
          snTextField(hint: "Purchase Discount", label: "Purchase Discount", controller: purchaseCtrl),
          const SizedBox(height: 10),
          snTextField(hint: "Quantity", label: "Quantity", controller: quantityCtrl),
        ],
      ),
    ),
  );

  Widget _shopCard(List<MultiSelectItem<MultiSelectModel>> items) => Card(
    color: AppColors.BLACK_7,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: MultiSelectDialogField<MultiSelectModel>(
        items: items,
        itemsTextStyle: const TextStyle(color: Colors.white),
        selectedItemsTextStyle: const TextStyle(color: AppColors.GREEN_9),
        initialValue: selectedShopName,
        title: const Text(
          "Select Shops",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        selectedColor: Colors.green, // Selected items highlight
        decoration: BoxDecoration(
          color: AppColors.BLACK_7,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white),
        ),
        dialogHeight: 700,
        dialogWidth: 500,
        cancelText: const Text(
          "Cancel",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        confirmText: const Text(
          "OK",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        searchable: true, // search bar enable
        barrierColor: Colors.black87, // dark background behind dialog
        listType: MultiSelectListType.LIST,
        chipDisplay: MultiSelectChipDisplay(
          chipColor: Colors.green.withOpacity(0.7),
          textStyle: const TextStyle(color: Colors.white),
          onTap: (value) {
            setState(() {
              selectedShopName.remove(value);
            });
          },
        ),
        onConfirm: (values) {
          setState(() {
            selectedShopName = values.cast<MultiSelectModel>();
          });
        },
      ),
    ),
  );

  Widget _buildImageUploader(double size) {
    return Card(
      color: AppColors.BLACK_7,
      child: Container(
        height: size,
        width: double.infinity,
        child: Stack(
          children: [
            if (kIsWeb)
              DropzoneView(onCreated: (ctrl) => dropzoneController = ctrl, onDrop: (event) async => await _handleDrop(event)),
            Center(
              child: _uploadedFiles.isEmpty
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload, color: AppColors.WHITE_9, size: 50),
                  TextButton.icon(
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text("Choose Files"),
                    onPressed: () async {
                      if (kIsWeb) {
                        await _pickFilesWeb();
                      } else {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo),
                                  title: const Text('Pick images'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImagesMobile();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.videocam),
                                  title: const Text('Pick video'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickVideoMobile();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  Text("You can drag & drop files here", style: TextStyle(color: AppColors.WHITE_9)),
                ],
              )
                  : _previewFiles(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewFiles() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final f = _uploadedFiles[i];
          return Stack(
            children: [
              Container(
                width: 140,
                height: 140,
                child: f.isVideo
                    ? const Icon(Icons.videocam, color: Colors.white)
                    : (f.bytes != null
                    ? Image.memory(f.bytes!, fit: BoxFit.cover)
                    : Image.file(f.file!, fit: BoxFit.cover)),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => _uploadedFiles.removeAt(i)),
                ),
              )
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _uploadedFiles.length,
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      color: AppColors.BLACK_7,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _uploadedFiles.isNotEmpty
                ? (_uploadedFiles.first.isVideo
                ? const Icon(Icons.videocam, color: Colors.white, size: 100)
                : (kIsWeb
                ? Image.memory(_uploadedFiles.first.bytes!, height: 150, fit: BoxFit.cover)
                : Image.file(_uploadedFiles.first.file!, height: 150, fit: BoxFit.cover)))
                : Container(
              height: 150,
              color: Colors.grey[800],
              child: const Center(child: Text("No Media", style: TextStyle(color: Colors.white))),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _previewRow("📖 Book Name", nameCtrl.text),
                    _previewRow("✍️ Author", authorCtrl.text),
                    _previewRow("🏷 Brand", selectedBrand ?? '-'),
                    _previewRow("📚 Book Type", selectedST ?? '-'),
                    _previewRow("📚 Class", selectedClass ?? '-'),
                    const Divider(color: Colors.white38),
                    _previewRow("💰 MRP", mrpCtrl.text),
                    _previewRow("💸 Sell Discount", discountCtrl.text),
                    _previewRow("🧾 Purchase Discount", purchaseCtrl.text),
                    _previewRow("📦 Quantity", quantityCtrl.text),
                    const Divider(color: Colors.white38),
                    _previewRow(
                        "🏪 Shops",
                        selectedShopName.isEmpty
                            ? '-'
                            : selectedShopName.map((e) => e.name).join(', ')
                    ),
                  ],
                ),
              ),
            )

          ],
        ),
      ),
    );
  }

  Widget _previewRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Flexible(
            child: Text(
              value.isEmpty ? "-" : value,
              textAlign: TextAlign.right,
              style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
