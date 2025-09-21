import 'package:moochat/core/shared/enums/type_of_chats.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'user_chat_model.g.dart';

@JsonSerializable()
class UserChat {
  final String username2P;
  final String uuid2P;
  final bool isFavorite;
  final bool isBlocked;
  final TypeOfChats typeOfChat;
  final bool isPinned;
  final List<ChatMessage> messages;

  UserChat({
    required this.username2P,
    required this.uuid2P,
    this.isFavorite = false,
    this.isBlocked = false,
    this.isPinned = false,
    this.messages = const [],
    this.typeOfChat = TypeOfChats.privateChatP2P,
  });

  factory UserChat.fromJson(Map<String, dynamic> json) =>
      _$UserChatFromJson(json);

  Map<String, dynamic> toJson() => _$UserChatToJson(this);
  // copuWith Method
  UserChat copyWith({
    String? username2P,
    String? uuid2P,
    bool? isFavorite,
    bool? isBlocked,
    bool? isPinned,
    TypeOfChats? typeOfChat,
    List<ChatMessage>? messages,
  }) {
    return UserChat(
      username2P: username2P ?? this.username2P,
      uuid2P: uuid2P ?? this.uuid2P,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
      typeOfChat: typeOfChat ?? this.typeOfChat,
    );
  }
}
