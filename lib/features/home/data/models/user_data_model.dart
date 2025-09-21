import 'package:moochat/core/shared/models/all_chat_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'user_data_model.g.dart';

@JsonSerializable()
class UserData {
  final String username;
  final String uuid;
  final AllChat userChats;
  final String lang;

  UserData({
    required this.username,
    required this.uuid,
    AllChat? userChats,
    this.lang = "en",
  }) : userChats = userChats ?? AllChat(policy: "2023-10-07", chats: []);
  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
  UserData copyWith({
    String? username,
    String? uuid,
    AllChat? userChats,
    String? lang,
  }) {
    return UserData(
      username: username ?? this.username,
      uuid: uuid ?? this.uuid,
      userChats: userChats ?? this.userChats,
      lang: lang ?? this.lang,
    );
  }
}
