import 'dart:convert';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  @override
  Widget build(BuildContext context) {
    return AiBarcodeScanner(
      controller: MobileScannerController(formats: [BarcodeFormat.qrCode]),

      validator: (value) {
        // Return true to accept all QR codes
        return true;
      },

      onDetect: (BarcodeCapture capture) {
        final String? qrData = capture.barcodes.first.rawValue;

        if (qrData != null && qrData.isNotEmpty) {
          LoggerDebug.logger.d('QR Code detected: $qrData');

          try {
            // Decode the JSON string back to a Map
            final Map<String, dynamic> dataMap = jsonDecode(qrData);

            if (dataMap.containsKey('isme') && dataMap['isme'] == true) {
              // If the QR code contains 'isme' key with value true, return the data
              LoggerDebug.logger.d('Valid QR code with isme=true detected');
              ref
                  .read(userDataProvider.notifier)
                  .addChat(
                    UserChat(
                      username2P: dataMap['username'],
                      uuid2P: dataMap['uuid'],
                    ),
                  );
              final chatData = ref
                  .read(userDataProvider.notifier)
                  .getChatByUuid(dataMap['uuid']);
              Navigator.pop(context, dataMap);
              context.pushNamed(
                RoutesManager.chatScreen,
                arguments: {'userData': chatData},
              );
            } else {
              LoggerDebug.logger.d(
                'QR code does not contain "isme" key or value is not true',
              );
              // Optionally show a message to the user that this isn't a valid contact QR code
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is not a valid contact QR code'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            LoggerDebug.logger.e('Error parsing QR code data: $e');
            // Show error message for invalid QR code format
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid QR code format'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          LoggerDebug.logger.d('Empty QR code detected');
        }
      },

      overlayConfig: const ScannerOverlayConfig(
        scannerAnimation: ScannerAnimation.center,
        scannerBorder: ScannerBorder.corner,
        borderColor: Colors.blue,
        successColor: Colors.green,
        errorColor: Colors.red,
        borderRadius: 24,
        cornerLength: 50,
      ),

      galleryButtonType: GalleryButtonType.filled,
      galleryButtonText: "Choose from Photos",
    );
  }
}
