import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'models/shop_models.dart';

class ShopRepository {
  final _firestore = FirebaseFirestore.instance;
  late Box localBox;

  final shopRef = FirebaseFirestore.instance
      .collection('laybary')
      .doc('test')
      .collection('new_das_laybary')
      .doc('shop_name')
      .collection('items');

  Future<void> init() async {
    if (kIsWeb) {
      localBox = await Hive.openBox('shop_cache');
    } else {
      Directory dir;
      if (Platform.isAndroid || Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = Directory.current;
      }
      Hive.init(dir.path);
      localBox = await Hive.openBox('shop_cache');
    }
  }

  Future<List<ShopModel>> getLocalShops() async {
    final data = localBox.get('shops', defaultValue: <String>[]);
    return List<ShopModel>.from(
      data.map((e) => ShopModel.fromJson(jsonDecode(e))),
    );
  }

  Future<void> saveToLocal(List<ShopModel> shops) async {
    final list = shops.map((e) => jsonEncode(e.toJson())).toList();
    await localBox.put('shops', list);
  }

  Future<void> addShop(ShopModel shop) async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      final docRef = await shopRef.add({
        'name': shop.name,
        'location': shop.location,
        'createdAt': FieldValue.serverTimestamp(),
      });
      shop = ShopModel(
        id: docRef.id,
        name: shop.name,
        location: shop.location,
        createdAt: shop.createdAt,
        synced: true,
      );
    }

    final shops = await getLocalShops();
    shops.add(shop);
    await saveToLocal(shops);
  }

  Future<void> deleteShop(ShopModel shop) async {
    final connectivity = await Connectivity().checkConnectivity();
    final shops = await getLocalShops();

    if (connectivity != ConnectivityResult.none && shop.id.isNotEmpty) {
      await shopRef.doc(shop.id).delete();
    }

    shops.removeWhere((s) =>
    s.name == shop.name && s.location == shop.location);
    await saveToLocal(shops);
  }

  Future<void> syncData() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final localShops = await getLocalShops();

    // 🔼 Upload unsynced
    for (var shop in localShops) {
      if (!shop.synced) {
        final docRef = await shopRef.add({
          'name': shop.name,
          'location': shop.location,
          'createdAt': FieldValue.serverTimestamp(),
        });
        shop.synced = true;
        shop = ShopModel(
          id: docRef.id,
          name: shop.name,
          location: shop.location,
          createdAt: shop.createdAt,
          synced: true,
        );
      }
    }

    // 🔽 Download fresh
    final snapshot = await shopRef.get();
    final firebaseData = snapshot.docs.map((d) {
      final data = d.data();
      return ShopModel(
        id: d.id,
        name: data['name'],
        location: data['location'],
        createdAt: DateTime.now(),
        synced: true,
      );
    }).toList();

    await saveToLocal(firebaseData);
  }
}
