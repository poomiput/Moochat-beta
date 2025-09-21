import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/features/chat/ui/widgets/rename_chat.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';

class ChatOption extends ConsumerStatefulWidget {
  const ChatOption({super.key, required this.uuid2P});
  final String uuid2P;

  @override
  ConsumerState<ChatOption> createState() => _ChatOptionState();
}

class _ChatOptionState extends ConsumerState<ChatOption> {
  @override
  Widget build(BuildContext context) {
    final asyncUserData = ref.watch(userDataProvider);

    return asyncUserData.when(
      data: (userData) {
        // Try to find the current chat
        UserChat? userData2P;
        try {
          userData2P = userData.userChats.chats.firstWhere(
            (chat) => chat.uuid2P == widget.uuid2P,
          );
        } catch (e) {
          // Chat not found, close the bottom sheet
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.pop();
            }
          });
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Options
              ListTile(
                leading: Icon(Icons.delete, color: Colors.white, size: 24.sp),

                title: Text(
                  context.tr("clear_chat"),
                  style: CustomTextStyles.font16WhiteRegular,
                ),

                onTap: () {
                  ref
                      .read(userDataProvider.notifier)
                      .clearChatMessages(widget.uuid2P);
                  context.pop(); // Close the bottom sheet after clearing chat
                },
              ),
              ListTile(
                leading: Image.asset(
                  "assets/icons/brush.png",
                  width: 24.w,
                  height: 24.h,
                ),
                title: Text(
                  context.tr("rename_chat"),
                  style: CustomTextStyles.font16WhiteRegular,
                ),
                onTap: () {
                  // Handle rename chat
                  context.pop();
                  showDialog(
                    context: context,
                    barrierDismissible:
                        false, // Prevent dismissing while loading
                    builder: (_) {
                      return RenameChatDialog(
                        initialUsername:
                            userData2P!.username2P, // Pass current username
                        uuid2P: userData2P.uuid2P,
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  userData2P.isFavorite == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: userData2P.isFavorite == true
                      ? Colors.red
                      : Colors.white,
                  size: 24.sp,
                ),
                title: Text(
                  userData2P.isFavorite == true
                      ? context.tr('remove_from_favorites')
                      : context.tr('add_to_favorites'),
                  style: CustomTextStyles.font16WhiteRegular,
                ),
                onTap: () {
                  ref
                      .read(userDataProvider.notifier)
                      .toggleFavoriteStatus(widget.uuid2P);
                },
              ),
              ListTile(
                leading: Icon(
                  userData2P.isBlocked == true
                      ? Icons.block
                      : Icons.block_outlined,
                  color: userData2P.isBlocked == true
                      ? Colors.red
                      : Colors.white,
                  size: 24.sp,
                ),
                title: Text(
                  userData2P.isBlocked == true
                      ? context.tr("unblock_contact")
                      : context.tr('block_contact'),
                  style: CustomTextStyles.font16WhiteRegular,
                ),
                onTap: () {
                  ref
                      .read(userDataProvider.notifier)
                      .toggleBlockedStatus(widget.uuid2P);
                      context.pop(); // Close the bottom sheet after toggling
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.red, size: 24.sp),
                title: Text(
                  context.tr("delete_chat"),
                  style: CustomTextStyles.font16WhiteRegular,
                ),
                onTap: () async {
                  // Close the bottom sheet first
                  context.pop();

                  // Navigate away from chat screen immediately
                  context.pushReplacementNamed(RoutesManager.homeScreen);

                  // Then delete the chat
                  await ref
                      .read(userDataProvider.notifier)
                      .deleteChat(widget.uuid2P);
                },
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: EdgeInsets.all(20.w),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Container(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: Text(
            'Error loading chat options',
            style: CustomTextStyles.font16WhiteRegular,
          ),
        ),
      ),
    );
  }
}
