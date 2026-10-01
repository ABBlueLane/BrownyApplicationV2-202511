// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'birthday_promo_info_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BirthdayPromoInfoResponse _$BirthdayPromoInfoResponseFromJson(
  Map<String, dynamic> json,
) => BirthdayPromoInfoResponse(
  title: json['title'] == null
      ? null
      : ContentLocalizeData.fromJson(json['title'] as Map<String, dynamic>),
  description: json['description'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['description'] as Map<String, dynamic>,
        ),
  image: json['image'] == null
      ? null
      : ContentLocalizeData.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BirthdayPromoInfoResponseToJson(
  BirthdayPromoInfoResponse instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'image': instance.image,
};
