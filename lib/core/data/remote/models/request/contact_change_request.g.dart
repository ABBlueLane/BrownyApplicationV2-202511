// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_change_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactChangeRequest _$ContactChangeRequestFromJson(
  Map<String, dynamic> json,
) => ContactChangeRequest(
  id: json['id'] as String,
  field: json['field'] as String,
  newValue: json['new_value'] as String,
);

Map<String, dynamic> _$ContactChangeRequestToJson(
  ContactChangeRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'field': instance.field,
  'new_value': instance.newValue,
};
