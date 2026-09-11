// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_change_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactChangeResponse _$ContactChangeResponseFromJson(
  Map<String, dynamic> json,
) => ContactChangeResponse(
  success: json['success'] as bool?,
  errorType: json['error_type'] as String?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : ContactChangeData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ContactChangeResponseToJson(
  ContactChangeResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'error_type': instance.errorType,
  'data': instance.data?.toJson(),
};

ContactChangeData _$ContactChangeDataFromJson(Map<String, dynamic> json) =>
    ContactChangeData(
      changeId: (json['change_id'] as num?)?.toInt(),
      field: json['field'] as String?,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      step: json['step'] as String?,
      refCode: json['ref_code'] as String?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      debugOtp: json['debug_otp'] as String?,
    );

Map<String, dynamic> _$ContactChangeDataToJson(ContactChangeData instance) =>
    <String, dynamic>{
      'change_id': instance.changeId,
      'field': instance.field,
      'old_value': instance.oldValue,
      'new_value': instance.newValue,
      'step': instance.step,
      'ref_code': instance.refCode,
      'username': instance.username,
      'phone': instance.phone,
      'email': instance.email,
      'debug_otp': instance.debugOtp,
    };
