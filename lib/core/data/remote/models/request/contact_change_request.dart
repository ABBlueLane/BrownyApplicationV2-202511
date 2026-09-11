import 'package:json_annotation/json_annotation.dart';

part 'contact_change_request.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

/// Request model สำหรับขอเปลี่ยนอีเมล/เบอร์โทร (ส่ง OTP)
@JsonSerializable()
class ContactChangeRequest {
  @JsonKey(name: 'id')
  final String id;

  /// `email` | `phone`
  @JsonKey(name: 'field')
  final String field;

  @JsonKey(name: 'new_value')
  final String newValue;

  ContactChangeRequest({
    required this.id,
    required this.field,
    required this.newValue,
  });

  factory ContactChangeRequest.fromJson(Map<String, dynamic> json) =>
      _$ContactChangeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ContactChangeRequestToJson(this);
}
