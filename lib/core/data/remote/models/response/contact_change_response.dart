import 'package:json_annotation/json_annotation.dart';
import 'package:browny_applications_new/core/data/remote/models/response/base_response.dart';

part 'contact_change_response.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class ContactChangeResponse extends BaseModelResponse {
  ContactChangeResponse({
    super.success,
    super.errorType,
    super.message,
    this.data,
  });

  @JsonKey(name: 'data')
  final ContactChangeData? data;

  factory ContactChangeResponse.fromJson(Map<String, dynamic> json) =>
      _$ContactChangeResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      baseToJson(_$ContactChangeResponseToJson(this));
}

@JsonSerializable()
class ContactChangeData {
  ContactChangeData({
    this.changeId,
    this.field,
    this.oldValue,
    this.newValue,
    this.step,
    this.refCode,
    this.username,
    this.phone,
    this.email,
    this.debugOtp,
  });

  @JsonKey(name: 'change_id')
  final int? changeId;

  /// `email` | `phone`
  @JsonKey(name: 'field')
  final String? field;

  @JsonKey(name: 'old_value')
  final String? oldValue;

  @JsonKey(name: 'new_value')
  final String? newValue;

  /// `verify_old` | `verify_new`
  @JsonKey(name: 'step')
  final String? step;

  @JsonKey(name: 'ref_code')
  final String? refCode;

  /// ปลายทางที่ระบบส่ง OTP ไป
  @JsonKey(name: 'username')
  final String? username;

  @JsonKey(name: 'phone')
  final String? phone;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'debug_otp')
  final String? debugOtp;

  factory ContactChangeData.fromJson(Map<String, dynamic> json) =>
      _$ContactChangeDataFromJson(json);

  Map<String, dynamic> toJson() => _$ContactChangeDataToJson(this);
}
