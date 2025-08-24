import 'dart:async';
import 'dart:convert'; // Add this import for UTF-8 encoding
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazachat/core/helpers/logger_debug.dart';
import 'package:gazachat/core/helpers/shared_prefences.dart';
import 'package:gazachat/core/shared/models/nearbay_device_info.dart';
import 'package:gazachat/core/shared/services/bluetooth_services.dart';
import 'package:gazachat/features/home/services/notifications_service.dart';

// Provider for managing Bluetooth state with discovered and connected devices
final nearbayStateProvider =
    StateNotifierProvider<BluetoothStateNotifier, BluetoothState>((ref) {
      return BluetoothStateNotifier();
    });

class BluetoothState {
  final List<NearbayDeviceInfo> discoveredDevices;
  final List<NearbayDeviceInfo> connectedDevices;
  final bool isAdvertising;
  final bool isDiscovering;
  final Stream<Map<String, String>>? messageStream;

  const BluetoothState({
    this.discoveredDevices = const [],
    this.connectedDevices = const [],
    this.isAdvertising = false,
    this.isDiscovering = false,
    this.messageStream,
  });

  BluetoothState copyWith({
    List<NearbayDeviceInfo>? discoveredDevices,
    List<NearbayDeviceInfo>? connectedDevices,
    bool? isAdvertising,
    bool? isDiscovering,
    Stream<Map<String, String>>? messageStream,
  }) {
    return BluetoothState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      messageStream: messageStream ?? this.messageStream,
    );
  }
}

class BluetoothStateNotifier extends StateNotifier<BluetoothState> {
  BluetoothStateNotifier() : super(const BluetoothState()) {
    _initializeListeners();
    // Expose message stream
    state = state.copyWith(messageStream: _bluetoothService.onMessageReceived);
  }

  final BluetoothServicesGazachat _bluetoothService =
      BluetoothServicesGazachat();

  StreamSubscription<NearbayDeviceInfo>? _deviceFoundSubscription;
  StreamSubscription<String>? _deviceLostSubscription;
  StreamSubscription<NearbayDeviceInfo>? _deviceConnectedSubscription;
  StreamSubscription<Map<String, String>>? _messageReceivedSubscription;

  // Method to get UUID by device ID - delegates to bluetooth service
  String? getUuidByDeviceId(String deviceId) {
    return _bluetoothService.getUuidByDeviceId(deviceId);
  }

  // Method to get discovered device info by device ID
  NearbayDeviceInfo? getDiscoveredDeviceById(String deviceId) {
    return _bluetoothService.getDiscoveredDeviceById(deviceId);
  }

  void _initializeListeners() {
    // Listen for discovered devices
    _deviceFoundSubscription = _bluetoothService.onDeviceFound.listen((device) {
      LoggerDebug.logger.d('Device found: ${device.id}');
      _addDiscoveredDevice(device);
    });

    // Listen for lost devices
    _deviceLostSubscription = _bluetoothService.onDeviceLost.listen((deviceId) {
      LoggerDebug.logger.d('Device lost: $deviceId');
      _removeDevice(deviceId);
    });

    // Listen for connected devices
    _deviceConnectedSubscription = _bluetoothService.onDeviceConnected.listen((
      device,
    ) {
      LoggerDebug.logger.d(
        'Device connected: ${device.id} with UUID: ${device.uuid}',
      );
      _addConnectedDevice(device);
    });

    // Listen for received messages
    _messageReceivedSubscription = _bluetoothService.onMessageReceived.listen((
      messageData,
    ) {
      LoggerDebug.logger.d(
        'Message received: ${messageData['message']} from ${messageData['senderId']}',
      );
      // You can handle received messages here or expose through another stream
    });
  }

  void _addDiscoveredDevice(NearbayDeviceInfo device) {
    // Check if device already exists in discovered list
    final existingIndex = state.discoveredDevices.indexWhere(
      (d) => d.id == device.id,
    );

    if (existingIndex == -1) {
      // Add new device
      final updatedDiscovered = [...state.discoveredDevices, device];
      state = state.copyWith(discoveredDevices: updatedDiscovered);
      // show notifiication to show user how length of discovered devices
      NotificationService().showNotification(
        id: 1, // Unique ID for the notification
        title: 'device_found_title'.tr(),
        body: '${updatedDiscovered.length} ${'device_found_body'.tr()}',
      );
    }
  }

  void _addConnectedDevice(NearbayDeviceInfo device) {
    // Check if device already exists in connected list
    final existingIndex = state.connectedDevices.indexWhere(
      (d) => d.id == device.id,
    );

    if (existingIndex == -1) {
      // Add to connected devices
      final updatedConnected = [...state.connectedDevices, device];
      // Remove from discovered devices if it exists there
      final updatedDiscovered = state.discoveredDevices
          .where((d) => d.id != device.id)
          .toList();

      state = state.copyWith(
        connectedDevices: updatedConnected,
        discoveredDevices: updatedDiscovered,
      );
    }
  }

  void _removeDevice(String deviceId) {
    // Remove from both discovered and connected lists
    final updatedDiscovered = state.discoveredDevices
        .where((d) => d.id != deviceId)
        .toList();
    final updatedConnected = state.connectedDevices
        .where((d) => d.id != deviceId)
        .toList();

    state = state.copyWith(
      discoveredDevices: updatedDiscovered,
      connectedDevices: updatedConnected,
    );
  }

  Future<void> startAdvertising() async {
    // Check if already advertising to prevent multiple calls
    if (state.isAdvertising) {
      LoggerDebug.logger.w('Advertising already in progress');
      return;
    }

    try {
      final String username = await SharedPrefHelper.getString('uuid');
      await _bluetoothService.startAdvertising(username);

      state = state.copyWith(isAdvertising: true);
      LoggerDebug.logger.d('Started advertising');
    } catch (e) {
      LoggerDebug.logger.e('Error starting advertising: $e');
      // Reset advertising state if it failed
      state = state.copyWith(isAdvertising: false);
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _bluetoothService.stopAdvertising();
      state = state.copyWith(isAdvertising: false);
      LoggerDebug.logger.d('Stopped advertising');
    } catch (e) {
      LoggerDebug.logger.e('Error stopping advertising: $e');
    }
  }

  Future<void> startDiscovery() async {
    // Check if already discovering to prevent multiple calls
    if (state.isDiscovering) {
      LoggerDebug.logger.w('Discovery already in progress');
      return;
    }

    try {
      final String username = await SharedPrefHelper.getString('uuid');
      await _bluetoothService.startDiscovery(username);

      state = state.copyWith(isDiscovering: true);
      LoggerDebug.logger.d('Started discovery');
    } catch (e) {
      LoggerDebug.logger.e('Error starting discovery: $e');
      // Reset discovery state if it failed
      state = state.copyWith(isDiscovering: false);
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _bluetoothService.stopDiscovery();
      state = state.copyWith(isDiscovering: false);
      LoggerDebug.logger.d('Stopped discovery');
    } catch (e) {
      LoggerDebug.logger.e('Error stopping discovery: $e');
    }
  }

  Future<void> connectToDevice(String deviceId, String uuid) async {
    try {
      // Find the device in discovered devices to get its username
      final device = state.discoveredDevices
          .where((d) => d.id == deviceId)
          .firstOrNull;
      if (device == null) {
        LoggerDebug.logger.e(
          'Device not found in discovered devices: $deviceId',
        );
        return;
      }

      await _bluetoothService.requestConnection(deviceId, uuid);
      LoggerDebug.logger.d('Requesting connection to: $deviceId');
    } catch (e) {
      LoggerDebug.logger.e('Error connecting to device: $e');
    }
  }

  // Connect to all discovered devices
  Future<void> connectToAllDiscoveredDevices() async {
    for (final device in state.discoveredDevices) {
      // Check if already connected
      final isAlreadyConnected = state.connectedDevices.any(
        (conn) => conn.id == device.id,
      );
      if (!isAlreadyConnected) {
        await connectToDevice(device.id, device.uuid);
        // Add small delay between connection attempts
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// Enhanced message sending with UTF-8 encoding support
  Future<bool> sendMessageToDevice(String deviceId, String message) async {
    try {
      // Encode message to handle Arabic characters properly
      final encodedMessage = _encodeMessage(message);

      LoggerDebug.logger.d('Sending message to $deviceId: $message');
      LoggerDebug.logger.d('Encoded message length: ${encodedMessage.length}');

      final result = await _bluetoothService.sendMessage(
        deviceId,
        encodedMessage,
      );
      LoggerDebug.logger.d('Message send result to $deviceId: $result');
      return result;
    } catch (e) {
      LoggerDebug.logger.e('Error sending message to device: $e');
      return false;
    }
  }

  /// Enhanced message broadcasting with UTF-8 encoding support
  Future<void> sendMessageToAll(String message) async {
    try {
      // Encode message to handle Arabic characters properly
      final encodedMessage = _encodeMessage(message);

      LoggerDebug.logger.d('Broadcasting message: $message');
      LoggerDebug.logger.d('Encoded message length: ${encodedMessage.length}');

      await _bluetoothService.sendMessageToAll(encodedMessage);
      LoggerDebug.logger.d('Message sent to all connected devices');
    } catch (e) {
      LoggerDebug.logger.e('Error sending message to all devices: $e');
    }
  }

  /// Encodes message for proper UTF-8 transmission over Bluetooth
  String _encodeMessage(String message) {
    try {
      // Method 1: Base64 encoding (recommended for Bluetooth)
      final utf8Bytes = utf8.encode(message);
      final base64Encoded = base64Encode(utf8Bytes);

      LoggerDebug.logger.d('Original message: $message');
      LoggerDebug.logger.d('UTF-8 bytes: $utf8Bytes');
      LoggerDebug.logger.d('Base64 encoded: $base64Encoded');

      return base64Encoded;
    } catch (e) {
      LoggerDebug.logger.e('Error encoding message: $e');
      // Fallback to original message
      return message;
    }
  }

  /// Alternative encoding method if base64 doesn't work with your Bluetooth service
  String _encodeMessageAlternative(String message) {
    try {
      final encoded = Uri.encodeComponent(message);
      LoggerDebug.logger.d('URL encoded message: $encoded');
      return encoded;
    } catch (e) {
      LoggerDebug.logger.e('Error encoding message with URI: $e');
      return message;
    }
  }

  /// Send a structured message (for chat messages with metadata)
  Future<bool> sendChatMessage(
    String deviceId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      // Convert message data to JSON
      final jsonString = jsonEncode(messageData);

      // Encode the JSON string for safe transmission
      final encodedMessage = _encodeMessage(jsonString);

      LoggerDebug.logger.d('Sending chat message to $deviceId');
      LoggerDebug.logger.d('Message data: $messageData');

      return await sendMessageToDevice(deviceId, encodedMessage);
    } catch (e) {
      LoggerDebug.logger.e('Error sending chat message: $e');
      return false;
    }
  }

  /// Broadcast a structured message to all connected devices
  Future<void> broadcastChatMessage(Map<String, dynamic> messageData) async {
    try {
      // Convert message data to JSON
      final jsonString = jsonEncode(messageData);

      // Encode the JSON string for safe transmission
      final encodedMessage = _encodeMessage(jsonString);

      LoggerDebug.logger.d('Broadcasting chat message');
      LoggerDebug.logger.d('Message data: $messageData');

      await sendMessageToAll(encodedMessage);
    } catch (e) {
      LoggerDebug.logger.e('Error broadcasting chat message: $e');
    }
  }

  // Get connected device by username
  NearbayDeviceInfo? getConnectedDeviceByUsername(String username) {
    try {
      return state.connectedDevices.firstWhere(
        (device) => device.uuid == username,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if a specific user is connected
  bool isUserConnected(String username) {
    return state.connectedDevices.any((device) => device.uuid == username);
  }

  void clearAllDevices() {
    state = state.copyWith(discoveredDevices: [], connectedDevices: []);
    // Also clear the bluetooth service cache
    _bluetoothService.clearDiscoveredDevices();
  }

  @override
  void dispose() {
    _deviceFoundSubscription?.cancel();
    _deviceLostSubscription?.cancel();
    _deviceConnectedSubscription?.cancel();
    _messageReceivedSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }
}
