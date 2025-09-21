import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/helpers/shared_prefences.dart';
import 'package:moochat/core/shared/models/all_chat_model.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/features/home/data/models/user_data_model.dart';

// User data provider to manage user information
final userDataProvider =
    StateNotifierProvider<UserDataNotifier, AsyncValue<UserData>>(
      (ref) => UserDataNotifier(),
    );

class UserDataNotifier extends StateNotifier<AsyncValue<UserData>> {
  UserDataNotifier() : super(const AsyncValue.loading()) {
    // Load user data immediately when the notifier is created
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    await loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      // Set loading state
      state = const AsyncValue.loading();

      final String username =
          await SharedPrefHelper.getString('username') ?? 'unknown-username';
      final String uuid =
          await SharedPrefHelper.getString('uuid') ?? 'unknown-uuid';

      // Get userChats Map and handle null/empty cases
      final Map<String, dynamic>? userChatsMap = await SharedPrefHelper.getMap(
        "userChats",
      );
      LoggerDebug.logger.f('Loaded userChatsMap: $userChatsMap');

      AllChat userChats;
      if (userChatsMap == null || userChatsMap.isEmpty) {
        // If no data exists, create default AllChat
        userChats = AllChat(policy: "2023-10-07", chats: []);
        // Save the default to SharedPreferences for future use
        await SharedPrefHelper.setData('userChats', userChats.toJson());
      } else {
        // Try to parse the existing data
        try {
          userChats = AllChat.fromJson(userChatsMap);
        } catch (parseError) {
          LoggerDebug.logger.w(
            'Error parsing userChats, using default: $parseError',
          );
          // If parsing fails, use default and save it
          userChats = AllChat(policy: "2023-10-07", chats: []);
          await SharedPrefHelper.setData('userChats', userChats.toJson());
        }
      }

      final userData = UserData(
        username: username,
        uuid: uuid,
        userChats: userChats,
      );

      // Set success state
      state = AsyncValue.data(userData);
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error loading user data: $error');
      // Set error state
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void updateUserData(String username, String uuid) {
    state.whenData((currentData) {
      final updatedData = currentData.copyWith(username: username, uuid: uuid);
      state = AsyncValue.data(updatedData);
    });
  }

  // Method to save user data to SharedPreferences
  Future<void> saveUserData(String username, String uuid) async {
    try {
      // Don't set loading for simple updates like this
      await SharedPrefHelper.setData('username', username);
      await SharedPrefHelper.setData('uuid', uuid);

      // Update the state without loading
      state.whenData((currentData) {
        final updatedData = currentData.copyWith(
          username: username,
          uuid: uuid,
        );
        state = AsyncValue.data(updatedData);
      });
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error saving user data: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Method to get get uuid by deivceId
  String? getUuidByDeviceId(String deviceId) {
    return state.when(
      data: (currentData) {
        try {
          return currentData.userChats.chats
              .firstWhere(
                (chat) => chat.uuid2P == deviceId,
                orElse: () => throw StateError('No element'),
              )
              .uuid2P;
        } catch (e) {
          return null; // Return null if chat not found
        }
      },
      loading: () => null,
      error: (error, stackTrace) => null,
    );
  }

  // update deivceId by uuid2P
  Future<void> updateDeviceIdByUuid(String uuid2P, String newDeviceId) async {
    try {
      await state.when(
        data: (currentData) async {
          // Find the chat by uuid2P and update its deviceId
          final updatedChats = currentData.userChats.chats.map((chat) {
            if (chat.uuid2P == uuid2P) {
              return chat.copyWith(uuid2P: newDeviceId);
            }
            return chat;
          }).toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w(
            'Cannot update device ID while loading user data',
          );
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot update device ID due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error updating device ID: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // get username by uuid2P
  String? getUsernameByUuid(String uuid2P) {
    return state.when(
      data: (currentData) {
        try {
          return currentData.userChats.chats
              .firstWhere(
                (chat) => chat.uuid2P == uuid2P,
                orElse: () => throw StateError('No element'),
              )
              .username2P;
        } catch (e) {
          return null; // Return null if chat not found
        }
      },
      loading: () => null,
      error: (error, stackTrace) => null,
    );
  }

  // Method to add a new chat to userChats
  Future<void> addChat(UserChat chat) async {
    try {
      await state.when(
        data: (currentData) async {
          // add the new chat to the existing chats in the head of the list after cheching if it already exists
          final updatedChats = List<UserChat>.from(currentData.userChats.chats);
          if (!updatedChats.any(
            (existingChat) => existingChat.uuid2P == chat.uuid2P,
          )) {
            updatedChats.insert(0, chat); // Add to the head of the list
          } else {
            LoggerDebug.logger.w(
              'Chat with id ${chat.uuid2P} already exists, not adding again.',
            );
          }
          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w('Cannot add chat while loading user data');
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot add chat due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error adding chat: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // delete user chat by uuid2P
  Future<void> deleteChat(String uuid2P) async {
    try {
      await state.when(
        data: (currentData) async {
          // Filter out the chat with the given uuid2P
          final updatedChats = currentData.userChats.chats
              .where((chat) => chat.uuid2P != uuid2P)
              .toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w('Cannot delete chat while loading user data');
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot delete chat due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error deleting chat: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // clear all message from chat by uuid2P
  Future<void> clearChatMessages(String uuid2P) async {
    try {
      await state.when(
        data: (currentData) async {
          // Verify the chat exists before clearing
          final chatExists = currentData.userChats.chats.any(
            (chat) => chat.uuid2P == uuid2P,
          );

          if (!chatExists) {
            LoggerDebug.logger.w(
              'Chat with uuid $uuid2P not found for clearing',
            );
            return;
          }

          // Find the chat by uuid2P and clear its messages
          final updatedChats = currentData.userChats.chats.map((chat) {
            if (chat.uuid2P == uuid2P) {
              return chat.copyWith(messages: []);
            }
            return chat;
          }).toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w('Cannot clear chat while loading user data');
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot clear chat due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error clearing chat messages: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // add message to chat by uuid2P
  Future<void> addMessageToChat(String uuid2P, ChatMessage message) async {
    try {
      await state.when(
        data: (currentData) async {
          // Find the chat by uuid2P safely
          final updatedChats = currentData.userChats.chats.map((chat) {
            if (chat.uuid2P == uuid2P) {
              // Add the new message to the existing messages
              final updatedMessages = List<ChatMessage>.from(chat.messages)
                ..add(message);
              return chat.copyWith(messages: updatedMessages);
            }
            return chat;
          }).toList();

          // Verify the chat exists
          final chatExists = currentData.userChats.chats.any(
            (chat) => chat.uuid2P == uuid2P,
          );

          if (!chatExists) {
            LoggerDebug.logger.w('Chat with uuid $uuid2P not found');
            return;
          }

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w('Cannot add message while loading user data');
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot add message due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error adding message to chat: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Method to remove a chat by uuid2P
  Future<void> removeChatByUuid(String uuid2P) async {
    try {
      await state.when(
        data: (currentData) async {
          // Filter out the chat with the given uuid2P
          final updatedChats = currentData.userChats.chats
              .where((chat) => chat.uuid2P != uuid2P)
              .toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w('Cannot remove chat while loading user data');
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot remove chat due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error removing chat: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // getFavoriteChats
  Future<List<UserChat>> getFavoriteChats() async {
    try {
      return state.when(
        data: (currentData) {
          // Filter favorite chats
          return currentData.userChats.chats
              .where((chat) => chat.isFavorite)
              .toList();
        },
        loading: () => [],
        error: (error, stackTrace) => [],
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error getting favorite chats: $error');
      return [];
    }
  }

  // get blocked chats
  Future<List<UserChat>> getBlockedChats() async {
    try {
      return state.when(
        data: (currentData) {
          // Filter blocked chats
          return currentData.userChats.chats
              .where((chat) => chat.isBlocked)
              .toList();
        },
        loading: () => [],
        error: (error, stackTrace) => [],
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error getting blocked chats: $error');
      return [];
    }
  }

  // filter blocked chats
  Future<void> filterBlockedChats() async {
    try {
      await state.when(
        data: (currentData) async {
          final blockedChats = currentData.userChats.chats
              .where((chat) => chat.isBlocked)
              .toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: blockedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);
        },
        loading: () async {
          LoggerDebug.logger.w(
            'Cannot filter blocked chats while loading user data',
          );
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot filter blocked chats due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error filtering blocked chats: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // update the provider to fileter chates by isFavorite status but don"t return anything just  update the state
  Future<void> filterFavoriteChats() async {
    try {
      await state.when(
        data: (currentData) async {
          final favoriteChats = currentData.userChats.chats
              .where((chat) => chat.isFavorite)
              .toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: favoriteChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);
        },
        loading: () async {
          LoggerDebug.logger.w(
            'Cannot filter favorite chats while loading user data',
          );
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot filter favorite chats due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error filtering favorite chats: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  UserChat? getChatByUuid(String uuid2P) {
    return state.when(
      data: (currentData) {
        try {
          return currentData.userChats.chats.firstWhere(
            (chat) => chat.uuid2P == uuid2P,
            orElse: () => throw StateError('No element'),
          );
        } catch (e) {
          return null; // Return null if chat not found
        }
      },
      loading: () => null,
      error: (error, stackTrace) => null,
    );
  }

  // change username
  Future<void> changeUsername(String newUsername) async {
    try {
      await state.when(
        data: (currentData) async {
          // Update the username in the current data
          final updatedData = currentData.copyWith(username: newUsername);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData('username', newUsername);
        },
        loading: () async {
          LoggerDebug.logger.w(
            'Cannot change username while loading user data',
          );
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot change username due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error changing username: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // rename chat by uuid2P
  Future<void> renameChat(String uuid2P, String newName) async {
    try {
      await state.when(
        data: (currentData) async {
          // Verify the chat exists before renaming
          final chatExists = currentData.userChats.chats.any(
            (chat) => chat.uuid2P == uuid2P,
          );

          if (!chatExists) {
            LoggerDebug.logger.w(
              'Chat with uuid $uuid2P not found for renaming',
            );
            return;
          }

          final updatedChats = currentData.userChats.chats.map((chat) {
            if (chat.uuid2P == uuid2P) {
              return chat.copyWith(username2P: newName);
            }
            return chat;
          }).toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w('Cannot rename chat while loading user data');
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot rename chat due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error renaming chat: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // toogle  blocked status and dave in SharedPreferences
  Future<void> toggleFavoriteStatus(String uuid2P) async {
    try {
      await state.when(
        data: (currentData) async {
          // Verify the chat exists before toggling
          final chatExists = currentData.userChats.chats.any(
            (chat) => chat.uuid2P == uuid2P,
          );

          if (!chatExists) {
            LoggerDebug.logger.w(
              'Chat with uuid $uuid2P not found for toggling favorite',
            );
            return;
          }

          final updatedChats = currentData.userChats.chats.map((chat) {
            if (chat.uuid2P == uuid2P) {
              return chat.copyWith(isFavorite: !chat.isFavorite);
            }
            return chat;
          }).toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w(
            'Cannot toggle favorite status while loading user data',
          );
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot toggle favorite status due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error toggling favorite status: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Safe method to toggle blocked status
  Future<void> toggleBlockedStatus(String uuid2P) async {
    try {
      await state.when(
        data: (currentData) async {
          // Verify the chat exists before toggling
          final chatExists = currentData.userChats.chats.any(
            (chat) => chat.uuid2P == uuid2P,
          );

          if (!chatExists) {
            LoggerDebug.logger.w(
              'Chat with uuid $uuid2P not found for toggling block',
            );
            return;
          }

          final updatedChats = currentData.userChats.chats.map((chat) {
            if (chat.uuid2P == uuid2P) {
              return chat.copyWith(isBlocked: !chat.isBlocked);
            }
            return chat;
          }).toList();

          final updatedUserChats = AllChat(
            policy: currentData.userChats.policy,
            chats: updatedChats,
          );

          // Update the state
          final updatedData = currentData.copyWith(userChats: updatedUserChats);
          state = AsyncValue.data(updatedData);

          // Save to SharedPreferences
          await SharedPrefHelper.setData(
            'userChats',
            updatedUserChats.toJson(),
          );
        },
        loading: () async {
          LoggerDebug.logger.w(
            'Cannot toggle blocked status while loading user data',
          );
        },
        error: (error, stackTrace) async {
          LoggerDebug.logger.e(
            'Cannot toggle blocked status due to error in user data: $error',
          );
        },
      );
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error toggling blocked status: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Method to refresh user data
  Future<void> refresh() async {
    await loadUserData();
  }

  // Method to clear all user data
  Future<void> clearUserData() async {
    try {
      await SharedPrefHelper.removeData('username');
      await SharedPrefHelper.removeData('uuid');
      await SharedPrefHelper.removeData('userChats');

      // Reset to initial state
      final defaultData = UserData(
        username: 'unknown-username',
        uuid: 'unknown-uuid',
        userChats: AllChat(policy: "2023-10-07", chats: []),
      );

      state = AsyncValue.data(defaultData);
    } catch (error, stackTrace) {
      LoggerDebug.logger.e('Error clearing user data: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
