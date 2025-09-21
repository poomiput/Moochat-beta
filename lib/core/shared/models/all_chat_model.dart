import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'all_chat_model.g.dart';

@JsonSerializable()
class AllChat {
  final String policy;
  final List<UserChat> chats;

  AllChat({required this.policy, required this.chats});
  factory AllChat.fromJson(Map<String, dynamic> json) =>
      _$AllChatFromJson(json);
  Map<String, dynamic> toJson() => _$AllChatToJson(this);
}
