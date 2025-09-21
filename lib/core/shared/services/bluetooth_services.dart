import 'dart:async';
import 'dart:typed_data';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/shared/models/nearbay_device_info.dart';
import 'package:nearby_connections/nearby_connections.dart';

class BluetoothServicesmoochat {
  // Streams for device events
  final StreamController<NearbayDeviceInfo> _deviceFoundController =
      StreamController<NearbayDeviceInfo>.broadcast();
  final StreamController<String> _deviceLostController =
      StreamController<String>.broadcast();
  final StreamController<NearbayDeviceInfo> _deviceConnectedController =
      StreamController<NearbayDeviceInfo>.broadcast();
  final StreamController<Map<String, String>> _messageReceivedController =
      StreamController<Map<String, String>>.broadcast();

  // Store discovered devices for UUID lookup
  final Map<String, NearbayDeviceInfo> _discoveredDevices = {};

  // Getters for streams
  Stream<NearbayDeviceInfo> get onDeviceFound => _deviceFoundController.stream;
  Stream<String> get onDeviceLost => _deviceLostController.stream;
  Stream<NearbayDeviceInfo> get onDeviceConnected =>
      _deviceConnectedController.stream;
  Stream<Map<String, String>> get onMessageReceived =>
      _messageReceivedController.stream;

  // Method to get UUID by device ID from discovered devices
  String? getUuidByDeviceId(String deviceId) {
    return _discoveredDevices[deviceId]?.uuid;
  }

  // Method to get discovered device info by device ID
  NearbayDeviceInfo? getDiscoveredDeviceById(String deviceId) {
    return _discoveredDevices[deviceId];
  }

  // start advertising
  Future<void> startAdvertising(String userName) async {
    final Strategy strategy = Strategy.P2P_STAR;
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          // Called whenever a discoverer requests connection
          LoggerDebug.logger.w(
            'Connection initiated: $id, UserName: ${info.endpointName}',
          );
          // Automatically accept all connections
          acceptConnection(id);
        },
        onConnectionResult: (String id, Status status) {
          // Called when connection is accepted/rejected
          LoggerDebug.logger.w(
            'Connection result: $id, Status: ${status.toString()}',
          );
          //TODO: solve the problem get uuid from discovered devices (create a new method to get uuid by device id)
          if (status == Status.CONNECTED) {
            // Try to get the uuid from discovered devices
            String deviceUuid = getUuidByDeviceId(id) ?? '';

            LoggerDebug.logger.f('Connected device ID: $id, UUID: $deviceUuid');

            // Add connected device to stream
            final device = NearbayDeviceInfo(
              id: id,
              uuid: deviceUuid,
              serviceId: "free.palestine.moochat",
            );

            _deviceConnectedController.add(device);
          }
        },
        onDisconnected: (String id) {
          // Called whenever a discoverer disconnects from advertiser
          LoggerDebug.logger.w('Disconnected from: $id');
          _deviceLostController.add(id);
          // Remove from discovered devices cache
          _discoveredDevices.remove(id);
        },
        serviceId: "free.palestine.moochat", // uniquely identifies your app
      );
    } catch (exception) {
      LoggerDebug.logger.e('Error starting advertising: $exception');
    }
  }

  // start startDiscovery
  Future<void> startDiscovery(String userName) async {
    final Strategy strategy = Strategy.P2P_STAR;

    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) {
          // Called whenever an advertiser is found
          LoggerDebug.logger.w(
            'Endpoint found: $id, UserName: $userName, ServiceId: $serviceId',
          );

          // Create device info and add to stream
          final device = NearbayDeviceInfo(
            id: id,
            uuid: userName, // Using userName as UUID
            serviceId: serviceId,
          );

          // Store in discovered devices cache for later lookup
          _discoveredDevices[id] = device;

          _deviceFoundController.add(device);
        },
        onEndpointLost: (String? id) {
          LoggerDebug.logger.w('Endpoint lost: $id');
          if (id != null) {
            _deviceLostController.add(id);
            // Remove from discovered devices cache
            _discoveredDevices.remove(id);
          }
        },
        serviceId: "free.palestine.moochat",
      );
    } catch (e) {
      LoggerDebug.logger.e('Error starting discovery: $e');
    }
  }

  // Stop advertising
  Future<void> stopAdvertising() async {
    try {
      await Nearby().stopAdvertising();
      LoggerDebug.logger.d('Stopped advertising');
    } catch (e) {
      LoggerDebug.logger.e('Error stopping advertising: $e');
    }
  }

  // Stop discovery
  Future<void> stopDiscovery() async {
    try {
      await Nearby().stopDiscovery();
      // Clear discovered devices cache when stopping discovery
      _discoveredDevices.clear();
      LoggerDebug.logger.d('Stopped discovery');
    } catch (e) {
      LoggerDebug.logger.e('Error stopping discovery: $e');
    }
  }

  // Request connection to a device
  Future<void> requestConnection(String deviceId, String userName) async {
    try {
      await Nearby().requestConnection(
        userName,
        deviceId,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          LoggerDebug.logger.w(
            'Connection initiated to: $id, UserName: ${info.endpointName}',
          );
          // Automatically accept the connection
          acceptConnection(id);
        },
        onConnectionResult: (String id, Status status) {
          LoggerDebug.logger.w('Connection result: $id, Status: $status');
          if (status == Status.CONNECTED) {
            // Try to get the uuid from discovered devices, fallback to userName parameter
            String deviceUuid = getUuidByDeviceId(id) ?? userName;

            final device = NearbayDeviceInfo(
              id: id,
              uuid: deviceUuid,
              serviceId: "free.palestine.moochat",
            );
            _deviceConnectedController.add(device);
          }
        },
        onDisconnected: (String id) {
          LoggerDebug.logger.w('Disconnected from: $id');
          _deviceLostController.add(id);
          // Remove from discovered devices cache
          _discoveredDevices.remove(id);
        },
      );
    } catch (e) {
      LoggerDebug.logger.e('Error requesting connection: $e');
    }
  }

  // Accept connection
  Future<void> acceptConnection(String deviceId) async {
    try {
      await Nearby().acceptConnection(
        deviceId,
        onPayLoadRecieved: (String endpointId, Payload payload) {
          // Handle received messages
          if (payload.type == PayloadType.BYTES) {
            final String message = String.fromCharCodes(payload.bytes!);
            LoggerDebug.logger.d('Message received from $endpointId: $message');

            // Add received message to stream
            _messageReceivedController.add({
              'senderId': endpointId,
              'message': message,
            });
          }
        },
      );
      LoggerDebug.logger.d('Accepted connection from: $deviceId');
    } catch (e) {
      LoggerDebug.logger.e('Error accepting connection: $e');
    }
  }

  // Send message to a specific device
  Future<bool> sendMessage(String deviceId, String message) async {
    try {
      final Uint8List bytes = Uint8List.fromList(message.codeUnits);
      await Nearby().sendBytesPayload(deviceId, bytes);
      LoggerDebug.logger.d('Message sent to $deviceId: $message');
      return true;
    } catch (e) {
      LoggerDebug.logger.e('Error sending message to $deviceId: $e');
      return false;
    }
  }

  // Send message to all connected devices
  Future<void> sendMessageToAll(String message) async {
    try {
      final Uint8List bytes = Uint8List.fromList(message.codeUnits);
      await Nearby().sendBytesPayload('', bytes); // Empty string sends to all
      LoggerDebug.logger.d('Message sent to all connected devices: $message');
    } catch (e) {
      LoggerDebug.logger.e('Error sending message to all devices: $e');
    }
  }

  // Get all discovered devices
  Map<String, NearbayDeviceInfo> get discoveredDevices =>
      Map.from(_discoveredDevices);

  // Clear discovered devices cache
  void clearDiscoveredDevices() {
    _discoveredDevices.clear();
  }

  // Dispose streams
  void dispose() {
    _deviceFoundController.close();
    _deviceLostController.close();
    _deviceConnectedController.close();
    _messageReceivedController.close();
    _discoveredDevices.clear();
  }
}
