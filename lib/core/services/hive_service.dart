import 'package:hive/hive.dart';

class HiveService {
  static const String boxName = 'seekrBox';
  static const String lastSavedDevice = 'last_connected_id';

  Future<void> saveString(String key, String value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  String? getString(String key) {
    final box = Hive.box(boxName);
    return box.get(key) as String?;
  }

  void removeData(String key) {
    final box = Hive.box(boxName);
    box.delete(key);
  }

  Future<void> saveMap(String key, Map value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  Map? getMap(String key) {
    final box = Hive.box(boxName);
    return box.get(key) as Map?;
  }
}
