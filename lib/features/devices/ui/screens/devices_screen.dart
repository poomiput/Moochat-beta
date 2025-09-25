import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:easy_localization/easy_localization.dart';

/// Redesigned devices screen with modern card layout
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  // Title and scan button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('nearby_devices'),
                              style: TextStyle(
                                color: ColorsManager.titleText,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              context.tr('discover_and_connect'),
                              style: TextStyle(
                                color: ColorsManager.subtitleText,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 16.w),

                      // Scan button
                      AnimatedBuilder(
                        animation: _refreshAnimation,
                        builder: (context, child) {
                          return GestureDetector(
                            onTap: _toggleScan,
                            child: Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                color: _isScanning
                                    ? ColorsManager.accentColor
                                    : ColorsManager.cardColor,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: ColorsManager.strokeColor,
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    offset: Offset(0, 2.h),
                                    blurRadius: 8.r,
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: _refreshAnimation.value * 2 * 3.14159,
                                child: Icon(
                                  Icons.bluetooth_searching,
                                  color: _isScanning
                                      ? Colors.white
                                      : ColorsManager.bodyText,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Status indicator
                  if (_isScanning)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsManager.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: ColorsManager.accentColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12.w,
                            height: 12.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorsManager.accentColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            context.tr('scanning_for_devices'),
                            style: TextStyle(
                              color: ColorsManager.accentColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Device list
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: _buildDeviceList(),
          ),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    // Mock device data - replace with actual device provider
    final devices = _getMockDevices();

    if (devices.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final device = devices[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildDeviceCard(device),
        );
      }, childCount: devices.length),
    );
  }

  Widget _buildDeviceCard(MockDevice device) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.strokeColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: Offset(0, 2.h),
            blurRadius: 8.r,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Device icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: device.isConnected
                    ? ColorsManager.accentColor.withOpacity(0.1)
                    : ColorsManager.backgroundColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: device.isConnected
                      ? ColorsManager.accentColor.withOpacity(0.3)
                      : ColorsManager.strokeColor,
                  width: 0.5,
                ),
              ),
              child: Icon(
                _getDeviceIcon(device.type),
                color: device.isConnected
                    ? ColorsManager.accentColor
                    : ColorsManager.captionText,
                size: 20.sp,
              ),
            ),

            SizedBox(width: 12.w),

            // Device info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: TextStyle(
                            color: ColorsManager.titleText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Connection status
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: device.isConnected
                              ? Colors.green
                              : ColorsManager.captionText,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  Row(
                    children: [
                      Text(
                        device.address,
                        style: TextStyle(
                          color: ColorsManager.subtitleText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Signal strength
                      ...List.generate(3, (index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 1.w),
                          child: Container(
                            width: 2.w,
                            height: (index + 1) * 3.h,
                            decoration: BoxDecoration(
                              color: index < device.signalStrength
                                  ? ColorsManager.accentColor
                                  : ColorsManager.captionText.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1.r),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // Connect button
            GestureDetector(
              onTap: () => _connectToDevice(device),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: device.isConnected
                      ? ColorsManager.backgroundColor
                      : ColorsManager.accentColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: device.isConnected
                        ? ColorsManager.strokeColor
                        : ColorsManager.accentColor,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  device.isConnected
                      ? context.tr('disconnect')
                      : context.tr('connect'),
                  style: TextStyle(
                    color: device.isConnected
                        ? ColorsManager.bodyText
                        : Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: ColorsManager.cardColor,
                borderRadius: BorderRadius.circular(60.r),
                border: Border.all(color: ColorsManager.strokeColor, width: 1),
              ),
              child: Icon(
                Icons.bluetooth_disabled,
                color: ColorsManager.captionText,
                size: 48.sp,
              ),
            ),

            SizedBox(height: 24.h),

            Text(
              context.tr('no_devices_found'),
              style: TextStyle(
                color: ColorsManager.subtitleText,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              context.tr('tap_scan_to_discover'),
              style: TextStyle(
                color: ColorsManager.captionText,
                fontSize: 14.sp,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'phone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      _refreshController.repeat();
      // Stop scanning after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isScanning) {
          setState(() => _isScanning = false);
          _refreshController.stop();
        }
      });
    } else {
      _refreshController.stop();
    }
  }

  void _connectToDevice(MockDevice device) {
    // Handle device connection
    setState(() {
      device.isConnected = !device.isConnected;
    });
  }

  List<MockDevice> _getMockDevices() {
    // Return mock device data - replace with actual device provider
    return [
      MockDevice(
        name: 'iPhone 14 Pro',
        address: '00:1A:2B:3C:4D:5E',
        type: 'phone',
        signalStrength: 3,
        isConnected: true,
      ),
      MockDevice(
        name: 'MacBook Pro',
        address: '00:1A:2B:3C:4D:5F',
        type: 'laptop',
        signalStrength: 2,
        isConnected: false,
      ),
      MockDevice(
        name: 'Samsung Galaxy',
        address: '00:1A:2B:3C:4D:60',
        type: 'phone',
        signalStrength: 1,
        isConnected: false,
      ),
    ];
  }
}

/// Mock device model for testing
class MockDevice {
  final String name;
  final String address;
  final String type;
  final int signalStrength;
  bool isConnected;

  MockDevice({
    required this.name,
    required this.address,
    required this.type,
    required this.signalStrength,
    required this.isConnected,
  });
}
