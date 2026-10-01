import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'birthday_promo_info_response.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

/// Response จาก GET /profile/birthday-promo-info
///
/// API คืน `null` เมื่อ inactive / ไม่มี config
/// เมื่อ active: { title, description, image } เป็น map th/en/zh
@JsonSerializable()
class BirthdayPromoInfoResponse {
  BirthdayPromoInfoResponse({
    this.title,
    this.description,
    this.image,
  });

  @JsonKey(name: 'title')
  final ContentLocalizeData? title;

  @JsonKey(name: 'description')
  final ContentLocalizeData? description;

  @JsonKey(name: 'image')
  final ContentLocalizeData? image;

  factory BirthdayPromoInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$BirthdayPromoInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BirthdayPromoInfoResponseToJson(this);
}
