import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';
import 'package:moochat/core/shared/providers/managing_bluetooth_state_privder.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/features/home/services/nearby_premission.dart';
import 'package:moochat/core/shared/providers/messages_handeler_provider.dart';
import 'package:moochat/features/home/ui/widgets/add_user_with_keyboard.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:moochat/core/routing/routes.dart';

class NewMainPage extends ConsumerStatefulWidget {
  const NewMainPage({super.key});

  @override
  ConsumerState<NewMainPage> createState() => _NewMainPageState();
}

class _NewMainPageState extends ConsumerState<NewMainPage> {
  bool _hasStartedBluetooth = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    CorePermissionHandler.onBluetoothEnabled();
    _initializeBluetooth();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageHandlerInitProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    // Clean up bluetooth services when page is disposed
    if (_hasStartedBluetooth) {
      ref.read(nearbayStateProvider.notifier).stopAdvertising();
      ref.read(nearbayStateProvider.notifier).stopDiscovery();
    }

    super.dispose();
  }

  void _initializeBluetooth() async {
    if (_hasStartedBluetooth) return;

    try {
      await ref.read(nearbayStateProvider.notifier).startAdvertising();
      await ref.read(nearbayStateProvider.notifier).startDiscovery();
      _hasStartedBluetooth = true;
      LoggerDebug.logger.d('Bluetooth services started successfully');
    } catch (e) {
      LoggerDebug.logger.e('Error starting bluetooth services: $e');
    }
  }

  // Helper method to check if a user is online based on discovered devices
  bool _isUserOnline(
    String username,
    List<dynamic> discoveredDevices,
    List<dynamic> connectedDevices,
  ) {
    // Search for the user in the discovered devices or connected devices
    if (connectedDevices.isNotEmpty) {
      return connectedDevices.any(
        (device) => device.uuid == username || device.id == username,
      );
    }
    // If no connected devices, check discovered devices
    if (discoveredDevices.isNotEmpty) {
      return discoveredDevices.any(
        (device) => device.uuid == username || device.id == username,
      );
    }
    return false;
  }

  String _formatTimeString(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return context.tr("just_now");
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${context.tr("minutes_ago")}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${context.tr("hours_ago")}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${context.tr("days_ago")}';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    final bluetoothState = ref.watch(nearbayStateProvider);

    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),

            // Content
            Expanded(
              child: userDataAsync.when(
                data: (userData) => _buildMainContent(userData, bluetoothState),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorsManager.mainColor, ColorsManager.accentColor],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.mainColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            showDialog(context: context, builder: (_) => const AddUserDialog());
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.add_rounded,
            color: ColorsManager.whiteColor,
            size: 28.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          // Info icon
          Icon(Icons.info_outline, color: ColorsManager.grayColor, size: 24.sp),
          SizedBox(width: 12.w),

          // Visibility icon
          Icon(
            Icons.visibility_off_outlined,
            color: ColorsManager.grayColor,
            size: 24.sp,
          ),

          // Title
          Expanded(
            child: Center(
              child: Text(
                'Moochat',
                style: CustomTextStyles.font20WhiteBold.copyWith(
                  color: ColorsManager.grayColor,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),

          // QR Code icon
          Icon(Icons.qr_code, color: ColorsManager.grayColor, size: 24.sp),
          SizedBox(width: 12.w),

          // Favorite icon
          Icon(
            Icons.favorite_outline,
            color: ColorsManager.grayColor,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),

          // Settings icon
          Icon(
            Icons.settings_outlined,
            color: ColorsManager.grayColor,
            size: 24.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(userData, bluetoothState) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          _buildUserProfileCard(userData),

          SizedBox(height: 20.h),

          // Device Count Section
          _buildDeviceCountSection(bluetoothState),

          SizedBox(height: 20.h),

          // Add User Button
          _buildAddUserButton(),

          SizedBox(height: 16.h),

          // QR Code Section
          _buildQRCodeSection(),

          SizedBox(height: 24.h),

          // Chat List
          _buildChatListSection(userData.userChats.chats),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(userData) {
    final userName = userData.userChats.chats.isNotEmpty
        ? userData.userChats.chats.first.username2P
        : 'คุณผู้ใช้';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorsManager.mainColor,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: CustomTextStyles.font20WhiteBold.copyWith(
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: CustomTextStyles.font20WhiteBold.copyWith(
                    color: ColorsManager.grayColor,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ออนไลน์',
                  style: CustomTextStyles.font14GrayRegular.copyWith(
                    color: Colors.green,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),

          // Online indicator
          Container(
            width: 12.w,
            height: 12.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCountSection(bluetoothState) {
    final discoveredCount = bluetoothState.discoveredDevices.length;
    final connectedCount = bluetoothState.connectedDevices.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: Colors.blue, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'อินทราเน็ต: ${discoveredCount + connectedCount}',
                  style: CustomTextStyles.font20WhiteBold.copyWith(
                    color: ColorsManager.grayColor,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'เชื่อมต่อแล้ว: $connectedCount',
                  style: CustomTextStyles.font14GrayRegular.copyWith(
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              connectedCount.toString(),
              style: CustomTextStyles.font14GrayRegular.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddUserButton() {
    return Container(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddUserDialog());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              color: ColorsManager.whiteColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'เพิ่มผู้ใช้',
              style: CustomTextStyles.font18WhiteMedium.copyWith(
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code, color: ColorsManager.grayColor, size: 24.sp),
          SizedBox(width: 12.w),
          Text(
            'QR Code',
            style: CustomTextStyles.font20WhiteBold.copyWith(
              color: ColorsManager.grayColor,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListSection(List<UserChat> chats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with search
        Row(
          children: [
            Text(
              'แชทล่าสุด',
              style: CustomTextStyles.font20WhiteBold.copyWith(
                color: ColorsManager.grayColor,
                fontSize: 18.sp,
              ),
            ),
            const Spacer(),
            Icon(Icons.search, color: ColorsManager.grayColor, size: 24.sp),
          ],
        ),

        SizedBox(height: 16.h),

        // Chat list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final bluetoothState = ref.watch(nearbayStateProvider);
            final isOnline = _isUserOnline(
              chat.uuid2P,
              bluetoothState.discoveredDevices,
              bluetoothState.connectedDevices,
            );
            return _buildChatItem(chat, index, isOnline);
          },
        ),
      ],
    );
  }

  Widget _buildChatItem(UserChat chat, int index, bool isOnline) {
    // Get real chat data
    final lastMessage = chat.messages.isNotEmpty
        ? chat.messages.last.type == MessageType.location
              ? '⟟ ${context.tr("location")}'
              : chat.messages.last.text
        : context.tr("no_messages");

    final timeString = chat.messages.isNotEmpty
        ? _formatTimeString(chat.messages.last.timestamp)
        : '';

    final unreadCount = 0; // TODO: Implement unread count logic
    final userInitial = chat.username2P.isNotEmpty
        ? chat.username2P[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () {
        // Navigate to chat page
        Navigator.pushNamed(context, RoutesManager.chatScreen, arguments: chat);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorsManager.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorsManager.mainColor,
                  ),
                  child: Center(
                    child: Text(
                      userInitial,
                      style: CustomTextStyles.font20WhiteBold.copyWith(
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                ),
                // Online indicator
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(
                          color: ColorsManager.whiteColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 16.w),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        chat.username2P,
                        style: CustomTextStyles.font20WhiteBold.copyWith(
                          color: ColorsManager.grayColor,
                          fontSize: 16.sp,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeString,
                        style: CustomTextStyles.font14GrayRegular.copyWith(
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    lastMessage,
                    style: CustomTextStyles.font14GrayRegular.copyWith(
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // Unread count and menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: ColorsManager.mainColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: CustomTextStyles.font14WhiteMedium.copyWith(
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
                Icon(
                  Icons.more_vert,
                  color: ColorsManager.grayColor,
                  size: 20.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
