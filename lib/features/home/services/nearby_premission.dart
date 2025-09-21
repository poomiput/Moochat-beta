import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CorePermissionHandler {
  static Future<void> requestPermissions() async {
    try {
      // Get Android version info for conditional permission handling
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      int androidVersion = androidInfo.version.sdkInt;

      LoggerDebug.logger.t('Android SDK Version: $androidVersion');

      // 1. Location permissions (CRITICAL for Nearby Connections)
      if (await Permission.location.isDenied) {
        await Permission.location.request();
      }
      LoggerDebug.logger.t(
        'Location Permission: ${await Permission.location.status}',
      );

      // 2. Enable location service if disabled
      if (!(await Permission.location.serviceStatus.isEnabled)) {
        await Location.instance.requestService();
      }

      // 3. Storage permissions (for file transfers) - Handle Android 13+ changes
      if (androidVersion >= 33) {
        // Android 13+ (API 33+) - Use new media permissions
        await [
          Permission.photos, // For images
          Permission.videos, // For videos
          Permission.audio, // For audio files
        ].request();

        LoggerDebug.logger.t(
          'Photos Permission: ${await Permission.photos.status}',
        );
        LoggerDebug.logger.t(
          'Videos Permission: ${await Permission.videos.status}',
        );
        LoggerDebug.logger.t(
          'Audio Permission: ${await Permission.audio.status}',
        );

        // If you need full file system access (high-risk permission)
        // Uncomment the following lines only if absolutely necessary
        // await Permission.manageExternalStorage.request();
        // LoggerDebug.logger.t('Manage External Storage: ${await Permission.manageExternalStorage.status}');
      } else {
        // Android 12 and below - Use legacy storage permission
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
        LoggerDebug.logger.t(
          'Storage Permission: ${await Permission.storage.status}',
        );
      }

      // 4. Bluetooth permissions based on Android version
      if (androidVersion >= 31) {
        // Android 12+ permissions
        await [
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ].request();

        LoggerDebug.logger.t(
          'Bluetooth Advertise: ${await Permission.bluetoothAdvertise.status}',
        );
        LoggerDebug.logger.t(
          'Bluetooth Connect: ${await Permission.bluetoothConnect.status}',
        );
        LoggerDebug.logger.t(
          'Bluetooth Scan: ${await Permission.bluetoothScan.status}',
        );

        // Android 12+ (API 32+) also needs nearby WiFi devices
        if (androidVersion >= 32) {
          await Permission.nearbyWifiDevices.request();
          LoggerDebug.logger.t(
            'Nearby WiFi: ${await Permission.nearbyWifiDevices.status}',
          );
        }
      } else {
        // Legacy Android (below 12)
        await Permission.bluetooth.request();
        LoggerDebug.logger.t('Bluetooth: ${await Permission.bluetooth.status}');
      }

      // 5. Check if Bluetooth service is enabled
      bool bluetoothEnabled =
          await Permission.bluetooth.serviceStatus.isEnabled;
      LoggerDebug.logger.t('Bluetooth Service Enabled: $bluetoothEnabled');

      // 6. Log final permission summary
      logPermissionSummary();
    } catch (e) {
      LoggerDebug.logger.e('Permission request error: $e');
    }
  }

  static void logPermissionSummary() async {
    // Get Android version for conditional permission checking
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int androidVersion = androidInfo.version.sdkInt;

    final permissions = <String, bool>{
      'Location': await Permission.location.isGranted,
      'Bluetooth': await Permission.bluetooth.isGranted,
      'Bluetooth Advertise': await Permission.bluetoothAdvertise.isGranted,
      'Bluetooth Connect': await Permission.bluetoothConnect.isGranted,
      'Bluetooth Scan': await Permission.bluetoothScan.isGranted,
      'Nearby WiFi': await Permission.nearbyWifiDevices.isGranted,
    };

    // Add storage permissions based on Android version
    if (androidVersion >= 33) {
      permissions.addAll({
        'Photos': await Permission.photos.isGranted,
        'Videos': await Permission.videos.isGranted,
        'Audio': await Permission.audio.isGranted,
      });
    } else {
      permissions['Storage'] = await Permission.storage.isGranted;
    }

    String summary = '\n=== Permission Summary (Android $androidVersion) ===\n';
    permissions.forEach((name, granted) {
      summary += '$name: ${granted ? '✓ Granted' : '✗ Denied'}\n';
    });
    summary += '========================';

    LoggerDebug.logger.i(summary);
  }

  static Future<void> onBluetoothEnabled() async {
    // first, check if bluetooth is supported by your hardware
    // Note: The platform is initialized on the first call to any FlutterBluePlus method.
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    // handle bluetooth on & off
    // note: for iOS the initial state is typically BluetoothAdapterState.unknown
    // note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    var subscription = FlutterBluePlus.adapterState.listen((
      BluetoothAdapterState state,
    ) {
      print(state);
      if (state == BluetoothAdapterState.on) {
        // usually start scanning, connecting, etc
      } else {
        // show an error to the user, etc
      }
    });

    // turn on bluetooth ourself if we can
    // for iOS, the user controls bluetooth enable/disable
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    // cancel to prevent duplicate listeners
    subscription.cancel();
  }
}
