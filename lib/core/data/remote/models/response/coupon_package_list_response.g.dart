// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_package_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponPackageListResponse _$CouponPackageListResponseFromJson(
  Map<String, dynamic> json,
) => CouponPackageListResponse(
  success: json['success'] as bool?,
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => CouponPackageData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CouponPackageListResponseToJson(
  CouponPackageListResponse instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

CouponPackageData _$CouponPackageDataFromJson(Map<String, dynamic> json) =>
    CouponPackageData(
      packageId: (json['package_id'] as num?)?.toInt(),
      couponId: (json['coupon_id'] as num?)?.toInt(),
      allowedPaymentMethods: (json['allowed_payment_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      storeId: (json['store_id'] as num?)?.toInt(),
      quantityPerPackage: json['quantity_per_package'] as String?,
      qtyTotal: json['qty_total'] as String?,
      price: json['price'] as String?,
      normalPrice: json['normal_price'] as String?,
      discountPercent: json['discount_percent'] as String?,
      brownyCoin: json['browny_coin'] as String?,
      saved: json['saved'] as String?,
      qtyWasher: json['qty_washer'] as String?,
      qtyDryer: json['qty_dryer'] as String?,
      qtyShared: json['qty_shared'] as String?,
      usageMode: json['usage_mode'] as String?,
      distanceMeters: json['distance_meters'] as String?,
      couponName: json['coupon_name'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['coupon_name'] as Map<String, dynamic>,
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
      usageLabel: json['usage_label'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['usage_label'] as Map<String, dynamic>,
            ),
      storeName: json['store_name'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['store_name'] as Map<String, dynamic>,
            ),
      usageDurationText: json['usage_duration_text'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['usage_duration_text'] as Map<String, dynamic>,
            ),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );

Map<String, dynamic> _$CouponPackageDataToJson(CouponPackageData instance) =>
    <String, dynamic>{
      'package_id': instance.packageId,
      'coupon_id': instance.couponId,
      'allowed_payment_methods': instance.allowedPaymentMethods,
      'store_id': instance.storeId,
      'quantity_per_package': instance.quantityPerPackage,
      'qty_total': instance.qtyTotal,
      'price': instance.price,
      'normal_price': instance.normalPrice,
      'discount_percent': instance.discountPercent,
      'browny_coin': instance.brownyCoin,
      'saved': instance.saved,
      'qty_washer': instance.qtyWasher,
      'qty_dryer': instance.qtyDryer,
      'qty_shared': instance.qtyShared,
      'usage_mode': instance.usageMode,
      'distance_meters': instance.distanceMeters,
      'coupon_name': instance.couponName,
      'coupon_image': instance.couponImage,
      'coupon_description': instance.couponDescription,
      'usage_label': instance.usageLabel,
      'store_name': instance.storeName,
      'usage_duration_text': instance.usageDurationText,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
    };
