// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_change_otp_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactChangeOtpRequest _$ContactChangeOtpRequestFromJson(
  Map<String, dynamic> json,
) => ContactChangeOtpRequest(
  id: json['id'] as String,
  changeId: (json['change_id'] as num).toInt(),
  otp: json['otp'] as String,
);

Map<String, dynamic> _$ContactChangeOtpRequestToJson(
  ContactChangeOtpRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'change_id': instance.changeId,
  'otp': instance.otp,
};
