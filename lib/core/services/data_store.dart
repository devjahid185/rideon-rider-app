import 'package:hive/hive.dart';

final box = Hive.box('appBox');
final lanBox = Hive.box('lanBox');

class UserData {
  saveLoginData(String key, String value) {
    box.put(key, value);
  }
}
