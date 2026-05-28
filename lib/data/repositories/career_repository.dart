import 'package:hive/hive.dart';
import 'package:dark_trade_app/data/local/models/career.dart';

abstract class CareerRepository {
  Future<List<Career>> loadCareers();
  Future<void> saveCareer(Career career);
  Future<void> deleteCareer(String id);
  Future<void> saveAllCareers(List<Career> careers);
  Future<List<Career>> migrateFromLocal();
}

class HiveCareerRepo implements CareerRepository {
  static const _boxName = 'careers';

  Box<Career> get _box => Hive.box<Career>(_boxName);

  @override
  Future<List<Career>> loadCareers() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveCareer(Career career) async {
    await _box.put(career.id, career);
  }

  @override
  Future<void> deleteCareer(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> saveAllCareers(List<Career> careers) async {
    final map = {for (final c in careers) c.id: c};
    await _box.putAll(map);
  }

  @override
  Future<List<Career>> migrateFromLocal() async {
    return loadCareers();
  }
}
