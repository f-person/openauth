import 'package:hive/hive.dart';
import 'package:openauth/core/entry.dart';

abstract class Repository<T> {
  Future put(T data);
  Future remove(T data);
  List<T> fetch();
}

class EntryRepository extends Repository<Entry> {
  static const _boxName = "entries";
  final box = Hive.box<Entry>(_boxName);

  static Future open(key) async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Entry>(_boxName, encryptionCipher: HiveAesCipher(key));
    }
  }

  @override
  Future put(Entry data) async {
    return await box.put(data.entryId, data);
  }

  @override
  Future remove(Entry data) async {
    return await box.delete(data.entryId);
  }

  @override
  List<Entry> fetch() {
    return List.castFrom(box.values.toList());
  }
}
