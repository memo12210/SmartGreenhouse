// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'greenhouse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Greenhouse _$GreenhouseFromJson(Map<String, dynamic> json) => Greenhouse(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String?,
  extraMetadata: json['extra_metadata'] as Map<String, dynamic>,
  ownerId: json['owner_id'] as String,
);

Map<String, dynamic> _$GreenhouseToJson(Greenhouse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'extra_metadata': instance.extraMetadata,
      'owner_id': instance.ownerId,
    };
