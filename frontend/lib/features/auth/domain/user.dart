import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole {
  @JsonValue('admin')
  admin,
  @JsonValue('operator')
  operator,
  @JsonValue('viewer')
  viewer,
}

@JsonSerializable()
class User {
  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    this.fullName,
    required this.isActive,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
