import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coupon_package_list_response.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

@JsonSerializable()
class CouponPackageListResponse {
  @JsonKey(name: 'success')
  final bool? success;

  @JsonKey(name: 'data')
  final List<CouponPackageData>? data;

  CouponPackageListResponse({
    this.success,
    this.data,
  });

  factory CouponPackageListResponse.fromJson(Map<String, dynamic> json) =>
      _$CouponPackageListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CouponPackageListResponseToJson(this);
}

@JsonSerializable()
class CouponPackageData {
  @JsonKey(name: 'package_id')
  final int? packageId;

  @JsonKey(name: 'coupon_id')
  final int? couponId;

  @JsonKey(name: 'allowed_payment_methods')
  final List<String>? allowedPaymentMethods;

  @JsonKey(name: 'store_id')
  final int? storeId;

  @JsonKey(name: 'quantity_per_package')
  final String? quantityPerPackage;

  @JsonKey(name: 'qty_total')
  final String? qtyTotal;

  @JsonKey(name: 'price')
  final String? price;

  @JsonKey(name: 'normal_price')
  final String? normalPrice;

  @JsonKey(name: 'discount_percent')
  final String? discountPercent;

  @JsonKey(name: 'browny_coin')
  final String? brownyCoin;

  @JsonKey(name: 'saved')
  final String? saved;

  @JsonKey(name: 'qty_washer')
  final String? qtyWasher;

  @JsonKey(name: 'qty_dryer')
  final String? qtyDryer;

  @JsonKey(name: 'qty_shared')
  final String? qtyShared;

  @JsonKey(name: 'usage_mode')
  final String? usageMode;

  @JsonKey(name: 'distance_meters')
  final String? distanceMeters;

  @JsonKey(name: 'coupon_name')
  final ContentLocalizeData? couponName;

  @JsonKey(name: 'coupon_image')
  final ContentLocalizeData? couponImage;

  @JsonKey(name: 'coupon_description')
  final ContentLocalizeData? couponDescription;

  @JsonKey(name: 'usage_label')
  final ContentLocalizeData? usageLabel;

  @JsonKey(name: 'store_name')
  final ContentLocalizeData? storeName;

  @JsonKey(name: 'usage_duration_text')
  final ContentLocalizeData? usageDurationText;

  @JsonKey(name: 'start_date')
  final String? startDate;

  @JsonKey(name: 'end_date')
  final String? endDate;

  CouponPackageData({
    this.packageId,
    this.couponId,
    this.allowedPaymentMethods,
    this.storeId,
    this.quantityPerPackage,
    this.qtyTotal,
    this.price,
    this.normalPrice,
    this.discountPercent,
    this.brownyCoin,
    this.saved,
    this.qtyWasher,
    this.qtyDryer,
    this.qtyShared,
    this.usageMode,
    this.distanceMeters,
    this.couponName,
    this.couponImage,
    this.couponDescription,
    this.usageLabel,
    this.storeName,
    this.usageDurationText,
    this.startDate,
    this.endDate,
  });

  factory CouponPackageData.fromJson(Map<String, dynamic> json) =>
      _$CouponPackageDataFromJson(json);

  Map<String, dynamic> toJson() => _$CouponPackageDataToJson(this);
}
