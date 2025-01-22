import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  static final SharedPrefsUtil _instance = SharedPrefsUtil._internal();

  factory SharedPrefsUtil() => _instance;

  SharedPrefsUtil._internal();

  late SharedPreferences _prefs;

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save a value (String, int, double, bool, List<String>, or Object) to SharedPreferences
  Future<void> save(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      // For objects, convert to JSON and store as String
      final jsonString = jsonEncode(value);
      await _prefs.setString(key, jsonString);
    }
  }

  /// Retrieve a value (String, int, double, bool, List<String>, or Object) from SharedPreferences
  T? get<T>(String key, {T Function(Map<String, dynamic>)? fromJson}) {
    if (!_prefs.containsKey(key)) return null;

    if (T == String) {
      return _prefs.getString(key) as T?;
    } else if (T == int) {
      return _prefs.getInt(key) as T?;
    } else if (T == double) {
      return _prefs.getDouble(key) as T?;
    } else if (T == bool) {
      return _prefs.getBool(key) as T?;
    } else if (T == List<String>) {
      return _prefs.getStringList(key) as T?;
    } else if (fromJson != null) {
      // For objects, decode JSON and map to object
      final jsonString = _prefs.getString(key);
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString);
        return fromJson(jsonData);
      }
    }

    return null;
  }

  /// Remove a value from SharedPreferences
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Clear all values from SharedPreferences
  Future<void> clear() async {
    await _prefs.clear();
  }
}

// Example usage:
// class User {
//   final String name;
//   final int age;

//   User({required this.name, required this.age});

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'age': age,
//       };

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       name: json['name'],
//       age: json['age'],
//     );
//   }
// }

// void main() async {
//   final sharedPrefs = SharedPrefsUtil();
//   await sharedPrefs.init();

//   // Storing simple data types
//   await sharedPrefs.save('username', 'JohnDoe');
//   await sharedPrefs.save('isLoggedIn', true);
//   await sharedPrefs.save('age', 30);

//   // Storing an object
//   final user = User(name: 'John Doe', age: 25);
//   await sharedPrefs.save('user', user);

//   // Retrieving simple data types
//   final username = sharedPrefs.get<String>('username');
//   final isLoggedIn = sharedPrefs.get<bool>('isLoggedIn');
//   final age = sharedPrefs.get<int>('age');

//   // Retrieving an object
//   final retrievedUser = sharedPrefs.get<User>('user', fromJson: (json) => User.fromJson(json));

//   print('Username: $username');
//   print('Is Logged In: $isLoggedIn');
//   print('Age: $age');
//   if (retrievedUser != null) {
//     print('User: ${retrievedUser.name}, Age: ${retrievedUser.age}');
//   }
// }
