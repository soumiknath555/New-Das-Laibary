import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/shop_models.dart';
import '../shop_repository.dart';

class ShopBloc extends Cubit<List<ShopModel>> {
  final ShopRepository repo;
  bool isSyncing = false;

  ShopBloc(this.repo) : super([]);

  Future<void> loadShops() async {
    await repo.init();
    final data = await repo.getLocalShops();
    emit(data);
  }

  Future<void> addShop(String name, String location) async {
    final newShop = ShopModel(
      id: '',
      name: name,
      location: location,
      createdAt: DateTime.now(),
      synced: false,
    );
    await repo.addShop(newShop);
    await loadShops();
  }

  Future<void> deleteShop(ShopModel shop) async {
    await repo.deleteShop(shop);
    await loadShops();
  }

  Future<void> syncAll() async {
    isSyncing = true;
    await repo.syncData();
    isSyncing = false;
    await loadShops();
  }
}
