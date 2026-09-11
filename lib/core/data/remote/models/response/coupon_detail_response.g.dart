// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponDetailResponse _$CouponDetailResponseFromJson(
  Map<String, dynamic> json,
) => CouponDetailResponse(
  message: json['message'] as String?,
  errorType: json['error_type'] as String?,
  success: json['success'] as bool?,
  data: json['data'] == null
      ? null
      : CouponDetailData.fromJson(json['data'] as Map<String, dynamic>),
  paymentMethods: json['payment_methods'] == null
      ? null
      : PaymentMethodsData.fromJson(
          json['payment_methods'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$CouponDetailResponseToJson(
  CouponDetailResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'error_type': instance.errorType,
  'data': instance.data,
  'payment_methods': instance.paymentMethods,
};

CouponDetailData _$CouponDetailDataFromJson(Map<String, dynamic> json) =>
    CouponDetailData(
      coupon: json['coupon'] == null
          ? null
          : CouponData.fromJson(json['coupon'] as Map<String, dynamic>),
      packages: (json['packages'] as List<dynamic>?)
          ?.map((e) => PackageDetailData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CouponDetailDataToJson(CouponDetailData instance) =>
    <String, dynamic>{'coupon': instance.coupon, 'packages': instance.packages};

CouponData _$CouponDataFromJson(Map<String, dynamic> json) => CouponData(
  id: (json['id'] as num?)?.toInt(),
  type: json['type'] as String?,
  value: json['value'] as String?,
  appliesTo: json['applies_to'] as String?,
  usageDurationDays: json['usage_duration_days'] as String?,
  usageDurationText: json['usage_duration_text'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['usage_duration_text'] as Map<String, dynamic>,
        ),
  couponImage: json['coupon_image'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['coupon_image'] as Map<String, dynamic>,
        ),
  couponDescription: json['coupon_description'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['coupon_description'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$CouponDataToJson(CouponData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'value': instance.value,
      'applies_to': instance.appliesTo,
      'usage_duration_days': instance.usageDurationDays,
      'usage_duration_text': instance.usageDurationText,
      'coupon_image': instance.couponImage,
      'coupon_description': instance.couponDescription,
    };

PackageDetailData _$PackageDetailDataFromJson(Map<String, dynamic> json) =>
    PackageDetailData(
      packageId: (json['package_id'] as num?)?.toInt(),
      packageName: json['package_name'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['package_name'] as Map<String, dynamic>,
            ),
      usageLabel: json['usage_label'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['usage_label'] as Map<String, dynamic>,
            ),
      groupOption: json['group_option'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['group_option'] as Map<String, dynamic>,
            ),
      store: json['store'] == null
          ? null
          : StoreData.fromJson(json['store'] as Map<String, dynamic>),
      price: json['price'] as String?,
      qtyWasher: json['qty_washer'] as String?,
      qtyDryer: json['qty_dryer'] as String?,
      qtyShared: json['qty_shared'] as String?,
      normalPrice: json['normal_price'] as String?,
      discountPercent: json['discount_percent'] as String?,
      brownyCoin: json['browny_coin'] as String?,
      saved: json['saved'] as String?,
      usageMode: json['usage_mode'] as String?,
    );

Map<String, dynamic> _$PackageDetailDataToJson(PackageDetailData instance) =>
    <String, dynamic>{
      'package_id': instance.packageId,
      'package_name': instance.packageName,
      'usage_label': instance.usageLabel,
      'group_option': instance.groupOption,
      'store': instance.store,
      'price': instance.price,
      'qty_washer': instance.qtyWasher,
      'qty_dryer': instance.qtyDryer,
      'qty_shared': instance.qtyShared,
      'normal_price': instance.normalPrice,
      'discount_percent': instance.discountPercent,
      'browny_coin': instance.brownyCoin,
      'saved': instance.saved,
      'usage_mode': instance.usageMode,
    };

StoreData _$StoreDataFromJson(Map<String, dynamic> json) => StoreData(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] == null
      ? null
      : ContentLocalizeData.fromJson(json['name'] as Map<String, dynamic>),
  distanceMeters: json['distance_meters'] as String?,
);

Map<String, dynamic> _$StoreDataToJson(StoreData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'distance_meters': instance.distanceMeters,
};

PaymentMethodsData _$PaymentMethodsDataFromJson(Map<String, dynamic> json) =>
    PaymentMethodsData(
      qr: json['qr'] as bool?,
      creditCard: json['credit_card'] as bool?,
      trueMoney: json['true_money'] as bool?,
      shopeePay: json['shopee_pay'] as bool?,
      wechat: json['wechat'] as bool?,
      rabbitLine: json['rabbit_line'] as bool?,
      tpWallet: json['tp_wallet'] as bool?,
      coin: json['coin'] as bool?,
      transfer: json['transfer'] as bool?,
    );

Map<String, dynamic> _$PaymentMethodsDataToJson(PaymentMethodsData instance) =>
    <String, dynamic>{
      'qr': instance.qr,
      'credit_card': instance.creditCard,
      'true_money': instance.trueMoney,
      'shopee_pay': instance.shopeePay,
      'wechat': instance.wechat,
      'rabbit_line': instance.rabbitLine,
      'tp_wallet': instance.tpWallet,
      'coin': instance.coin,
      'transfer': instance.transfer,
    };
