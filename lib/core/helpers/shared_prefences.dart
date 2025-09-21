import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  // private constructor as I don't want to allow creating an instance of this class itself.
  SharedPrefHelper._();

  /// Removes a value from SharedPreferences with given [key].
  static removeData(String key) async {
    LoggerDebug.logger.d(
      'SharedPrefHelper : data with key : $key has been removed',
    );
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove(key);
  }

  /// Removes all keys and values in the SharedPreferences
  static clearAllData() async {
    LoggerDebug.logger.d('SharedPrefHelper : all data has been cleared');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
  }

  /// Saves a [value] with a [key] in the SharedPreferences.
  static setData(String key, value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    LoggerDebug.logger.d(
      'SharedPrefHelper : setData with key : $key and value : $value, with type : ${value.runtimeType}',
    );

    switch (value.runtimeType) {
      case String:
        await sharedPreferences.setString(key, value);
        LoggerDebug.logger.d('SharedPrefHelper : setString With Key : $key');
        break;
      case int:
        await sharedPreferences.setInt(key, value);
        LoggerDebug.logger.d('SharedPrefHelper : setInt With Key : $key');
        break;
      case bool:
        await sharedPreferences.setBool(key, value);
        LoggerDebug.logger.d('SharedPrefHelper : setBool With Key : $key');
        break;
      case double:
        await sharedPreferences.setDouble(key, value);
        LoggerDebug.logger.d('SharedPrefHelper : setDouble With Key : $key');
        break;
      // set json data - Fixed to handle both Map and List types
      default:
        if (value is Map || value is List) {
          LoggerDebug.logger.d(
            'SharedPrefHelper : setMap/List With Key : $key',
          );
          try {
            String jsonString = jsonEncode(value);
            await sharedPreferences.setString(key, jsonString);
            LoggerDebug.logger.d(
              'SharedPrefHelper : Successfully stored JSON for key : $key',
            );
          } catch (e) {
            LoggerDebug.logger.e(
              'SharedPrefHelper : Error encoding JSON for key $key: $e',
            );
          }
        } else {
          LoggerDebug.logger.e(
            'SharedPrefHelper : Unsupported type for key $key: ${value.runtimeType}',
          );
          return null;
        }
        break;
    }
  }

  /// Gets a bool value from SharedPreferences with given [key].
  static getBool(String key) async {
    LoggerDebug.logger.d('SharedPrefHelper : getBool with key : $key');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(key) ?? false;
  }

  /// Gets a double value from SharedPreferences with given [key].
  static getDouble(String key) async {
    LoggerDebug.logger.d('SharedPrefHelper : getDouble with key : $key');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getDouble(key) ?? 0.0;
  }

  /// Gets an int value from SharedPreferences with given [key].
  static getInt(String key) async {
    LoggerDebug.logger.d('SharedPrefHelper : getInt with key : $key');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getInt(key) ?? 0;
  }

  /// Gets an String value from SharedPreferences with given [key].
  static getString(String key) async {
    LoggerDebug.logger.d('SharedPrefHelper : getString with key : $key');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(key) ?? '';
  }

  /// Gets a Map value from SharedPreferences with given [key].
  static Future<Map<String, dynamic>?> getMap(String key) async {
    LoggerDebug.logger.d('SharedPrefHelper : getMap with key : $key');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? jsonString = sharedPreferences.getString(key);

    LoggerDebug.logger.d(
      'SharedPrefHelper : getMap with key : $key and jsonString : $jsonString',
    );

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        // Decode the JSON
        final decoded = jsonDecode(jsonString);

        // Check if decoded is a Map
        if (decoded is Map<String, dynamic>) {
          LoggerDebug.logger.d(
            'SharedPrefHelper : Successfully decoded Map for key : $key',
          );
          return decoded;
        } else if (decoded is Map) {
          // Convert Map to Map<String, dynamic>
          LoggerDebug.logger.d(
            'SharedPrefHelper : Converting Map to Map<String, dynamic> for key : $key',
          );
          return Map<String, dynamic>.from(decoded);
        } else {
          LoggerDebug.logger.e(
            'SharedPrefHelper : Decoded value is not a Map for key : $key, type: ${decoded.runtimeType}',
          );
          return null;
        }
      } catch (e) {
        LoggerDebug.logger.e(
          'SharedPrefHelper : Error decoding JSON for key $key: $e',
        );
        return null;
      }
    }

    LoggerDebug.logger.d('SharedPrefHelper : No data found for key : $key');
    return null;
  }

  /// Gets a List value from SharedPreferences with given [key].
  static Future<List<dynamic>?> getList(String key) async {
    LoggerDebug.logger.d('SharedPrefHelper : getList with key : $key');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? jsonString = sharedPreferences.getString(key);

    LoggerDebug.logger.d(
      'SharedPrefHelper : getList with key : $key and jsonString : $jsonString',
    );

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          LoggerDebug.logger.d(
            'SharedPrefHelper : Successfully decoded List for key : $key',
          );
          return decoded;
        } else {
          LoggerDebug.logger.e(
            'SharedPrefHelper : Decoded value is not a List for key : $key, type: ${decoded.runtimeType}',
          );
          return null;
        }
      } catch (e) {
        LoggerDebug.logger.e(
          'SharedPrefHelper : Error decoding JSON for key $key: $e',
        );
        return null;
      }
    }

    LoggerDebug.logger.d('SharedPrefHelper : No data found for key : $key');
    return null;
  }

  /// Saves a [value] with a [key] in the FlutterSecureStorage.
  static setSecuredString(String key, String value) async {
    const flutterSecureStorage = FlutterSecureStorage();
    debugPrint(
      "FlutterSecureStorage : setSecuredString with key : $key and value : $value",
    );
    await flutterSecureStorage.write(key: key, value: value);
  }

  /// Gets an String value from FlutterSecureStorage with given [key].
  static getSecuredString(String key) async {
    const flutterSecureStorage = FlutterSecureStorage();
    debugPrint('FlutterSecureStorage : getSecuredString with key : $key');
    return await flutterSecureStorage.read(key: key) ?? '';
  }

  /// Removes all keys and values in the FlutterSecureStorage
  static clearAllSecuredData() async {
    debugPrint('FlutterSecureStorage : all data has been cleared');

    const flutterSecureStorage = FlutterSecureStorage();
    await flutterSecureStorage.deleteAll();
  }
}

