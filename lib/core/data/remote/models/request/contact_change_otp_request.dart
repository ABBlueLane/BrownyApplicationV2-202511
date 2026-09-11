import 'package:json_annotation/json_annotation.dart';

part 'contact_change_otp_request.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

/// Request model สำหรับ verify OTP ช่องทางเดิม / ยืนยัน OTP ช่องทางใหม่
@JsonSerializable()
class ContactChangeOtpRequest {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'change_id')
  final int changeId;

  @JsonKey(name: 'otp')
  final String otp;

  ContactChangeOtpRequest({
    required this.id,
    required this.changeId,
    required this.otp,
  });

  factory ContactChangeOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$ContactChangeOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ContactChangeOtpRequestToJson(this);
}
