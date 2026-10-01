// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_first_notification_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletFirstNotificationResponse _$WalletFirstNotificationResponseFromJson(
  Map<String, dynamic> json,
) => WalletFirstNotificationResponse(
  title: json['title'] == null
      ? null
      : ContentLocalizeData.fromJson(json['title'] as Map<String, dynamic>),
  description: json['description'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['description'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$WalletFirstNotificationResponseToJson(
  WalletFirstNotificationResponse instance,
) => <String, dynamic>{
  'title': instance.title?.toJson(),
  'description': instance.description?.toJson(),
};
