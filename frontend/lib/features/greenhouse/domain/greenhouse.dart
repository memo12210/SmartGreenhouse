import 'package:json_annotation/json_annotation.dart';

part 'greenhouse.g.dart';

@JsonSerializable()
class Greenhouse {
  final String id;
  final String name;
  final String? location;
  @JsonKey(name: 'extra_metadata')
  final Map<String, dynamic> extraMetadata;
  @JsonKey(name: 'owner_id')
  final String ownerId;

  Greenhouse({
    required this.id,
    required this.name,
    this.location,
    required this.extraMetadata,
    required this.ownerId,
  });

  factory Greenhouse.fromJson(Map<String, dynamic> json) => _$GreenhouseFromJson(json);
  Map<String, dynamic> toJson() => _$GreenhouseToJson(this);
}
