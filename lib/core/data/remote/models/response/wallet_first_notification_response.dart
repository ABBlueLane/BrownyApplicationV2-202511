import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_first_notification_response.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

/// Response ของ API `/wallet/firstNotification`
///
/// ใช้แสดง popup แจ้งเตือนในหน้า Wallet ก่อนเติมเงิน
/// ถ้า [title] และ [description] เป็น null คือไม่มีประกาศ ไม่ต้องแสดง popup
@JsonSerializable(explicitToJson: true)
class WalletFirstNotificationResponse {
  WalletFirstNotificationResponse({
    this.title,
    this.description,
  });

  @JsonKey(name: 'title')
  final ContentLocalizeData? title;

  @JsonKey(name: 'description')
  final ContentLocalizeData? description;

  /// มีเนื้อหาให้แสดง popup หรือไม่
  bool get hasContent => title != null || description != null;

  factory WalletFirstNotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletFirstNotificationResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$WalletFirstNotificationResponseToJson(this);
}
