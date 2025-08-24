import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazachat/core/helpers/extensions.dart';
import 'package:gazachat/core/helpers/shared_prefences.dart';
import 'package:gazachat/core/routing/app_router.dart';
import 'package:gazachat/core/shared/enums/type_of_chats.dart';
import 'package:gazachat/core/shared/models/all_chat_model.dart';
import 'package:gazachat/core/shared/models/user_chat_model.dart';
import 'package:gazachat/features/home/services/nearby_premission.dart';
import 'package:gazachat/features/home/services/notifications_service.dart';
import 'package:gazachat/gazachat_app.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  //WARNING: Ensure that you have the correct screen size before running the app.
  await ScreenUtil.ensureScreenSize();
  await CorePermissionHandler.requestPermissions();
  await NotificationService().requestPermissions();
  await isUserLoggedIn();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('ar')],
      path:
          'assets/translations', // <-- change the path of the translation files
      fallbackLocale: Locale('ar'),
      startLocale: Locale('ar'),
      child: ProviderScope(child: GazachatApp(appRouter: AppRouter())),
    ),
  );
}

Future<void> isUserLoggedIn() async {
  try {
    // Here you would typically check shared preferences or secure storage
    final String? username = await SharedPrefHelper.getString('username');
    final String? uuid = await SharedPrefHelper.getString('uuid');
    final Map<String, dynamic>? userChatsMap = await SharedPrefHelper.getMap(
      "userChats",
    );

    print('Retrieved username: $username');
    print('Retrieved uuid: $uuid');
    print('Retrieved userChatsMap: $userChatsMap');

    if (username.isNullOrEmpty()) {
      // If username is null or empty, generate a new username
      final String newUsername = RandomUsernameGenerator.generateGazaUsername();
      await SharedPrefHelper.setData('username', newUsername);
      print('Generated new username: $newUsername');
    }

    if (uuid.isNullOrEmpty()) {
      // If UUID is null or empty, generate a new UUID using the uuid package
      final String newUuid = const Uuid().v4();
      await SharedPrefHelper.setData('uuid', newUuid);
      print('Generated new UUID: $newUuid');
    }

    // Initialize userChats if null or empty
    if (userChatsMap == null) {
      print('userChatsMap is null, initializing default userChats');
      final defaultAllChat = AllChat(
        policy: "2023-10-07",
        chats: [
          UserChat(
            username2P: "General",
            uuid2P: "loby",
            typeOfChat: TypeOfChats.publicChat,
            isPinned: true,
          ),
        ],
      );
      final Map<String, dynamic> defaultJson = defaultAllChat.toJson();

      // Debug: Print what we're trying to save
      print('Saving default userChats: $defaultJson');

      await SharedPrefHelper.setData('userChats', defaultJson);

      // Verify the data was saved
      final Map<String, dynamic>? verifyData = await SharedPrefHelper.getMap(
        'userChats',
      );
      print('Verification - saved userChats: $verifyData');

      print('Initialized default userChats');
    } else {
      // Validate existing userChats data
      try {
        final allChat = AllChat.fromJson(userChatsMap);
        print(
          'Existing userChats data is valid: ${allChat.chats.length} chats found',
        );
      } catch (e) {
        print('Invalid userChats data, reinitializing: $e');
        final defaultAllChat = AllChat(
          policy: "2023-10-07",
          chats: [
            UserChat(
              username2P: "General",
              uuid2P: "loby",
              typeOfChat: TypeOfChats.publicChat,
              isPinned: true,
            ),
          ],
        );
        await SharedPrefHelper.setData('userChats', defaultAllChat.toJson());

        // Verify the reinitialized data
        final Map<String, dynamic>? verifyData = await SharedPrefHelper.getMap(
          'userChats',
        );
        print('Verification - reinitialized userChats: $verifyData');
      }
    }
  } catch (e) {
    print('Error in isUserLoggedIn: $e');
    // Initialize with defaults if there's any error
    try {
      await SharedPrefHelper.setData(
        'username',
        RandomUsernameGenerator.generateGazaUsername(),
      );
      await SharedPrefHelper.setData('uuid', const Uuid().v4());

      final defaultAllChat = AllChat(
        policy: "2023-10-07",
        chats: [
          UserChat(
            username2P: "General",
            uuid2P: "loby",
            typeOfChat: TypeOfChats.publicChat,
            isPinned: true,
          ),
        ],
      );
      await SharedPrefHelper.setData('userChats', defaultAllChat.toJson());

      // Verify all data was saved correctly
      final String? savedUsername = await SharedPrefHelper.getString(
        'username',
      );
      final String? savedUuid = await SharedPrefHelper.getString('uuid');
      final Map<String, dynamic>? savedUserChats =
          await SharedPrefHelper.getMap('userChats');

      print('Error recovery - saved username: $savedUsername');
      print('Error recovery - saved uuid: $savedUuid');
      print('Error recovery - saved userChats: $savedUserChats');
    } catch (initError) {
      print('Error initializing default data: $initError');
    }
  }
}
