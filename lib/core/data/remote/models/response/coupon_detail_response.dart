import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/data/remote/models/response/base_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coupon_detail_response.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

@JsonSerializable()
class CouponDetailResponse extends BaseModelResponse {
  @JsonKey(name: 'data')
  final CouponDetailData? data;

  @JsonKey(name: 'payment_methods')
  final PaymentMethodsData? paymentMethods;

  CouponDetailResponse({
    super.message,
    super.errorType,
    super.success,
    this.data,
    this.paymentMethods,
  });

  factory CouponDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$CouponDetailResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      baseToJson(_$CouponDetailResponseToJson(this));
}

@JsonSerializable()
class CouponDetailData {
  @JsonKey(name: 'coupon')
  final CouponData? coupon;

  @JsonKey(name: 'packages')
  final List<PackageDetailData>? packages;

  CouponDetailData({
    this.coupon,
    this.packages,
  });

  factory CouponDetailData.fromJson(Map<String, dynamic> json) =>
      _$CouponDetailDataFromJson(json);

  Map<String, dynamic> toJson() => _$CouponDetailDataToJson(this);
}

@JsonSerializable()
class CouponData {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'value')
  final String? value;

  @JsonKey(name: 'applies_to')
  final String? appliesTo;

  @JsonKey(name: 'usage_duration_days')
  final String? usageDurationDays;

  @JsonKey(name: 'usage_duration_text')
  final ContentLocalizeData? usageDurationText;

  @JsonKey(name: 'coupon_image')
  final ContentLocalizeData? couponImage;

  @JsonKey(name: 'coupon_description')
  final ContentLocalizeData? couponDescription;

  CouponData({
    this.id,
    this.type,
    this.value,
    this.appliesTo,
    this.usageDurationDays,
    this.usageDurationText,
    this.couponImage,
    this.couponDescription,
  });

  factory CouponData.fromJson(Map<String, dynamic> json) =>
      _$CouponDataFromJson(json);

  Map<String, dynamic> toJson() => _$CouponDataToJson(this);

  String dateLeftDisplay(BuildContext context) {
    final locale = context.languageCode;
    if (usageDurationDays != null) {
      switch (locale) {
        case 'en':
          return '$usageDurationDays days';
        case 'zh':
          return '$usageDurationDays 天';
        default:
          return '$usageDurationDays วัน';
      }
    } else {
      return '';
    }
  }
}

@JsonSerializable()
class PackageDetailData {
  @JsonKey(name: 'package_id')
  final int? packageId;

  @JsonKey(name: 'package_name')
  final ContentLocalizeData? packageName;

  @JsonKey(name: 'usage_label')
  final ContentLocalizeData? usageLabel;

  @JsonKey(name: 'group_option')
  final ContentLocalizeData? groupOption;

  @JsonKey(name: 'store')
  final StoreData? store;

  @JsonKey(name: 'price')
  final String? price;

  @JsonKey(name: 'qty_washer')
  final String? qtyWasher;

  @JsonKey(name: 'qty_dryer')
  final String? qtyDryer;

  @JsonKey(name: 'qty_shared')
  final String? qtyShared;

  @JsonKey(name: 'normal_price')
  final String? normalPrice;

  @JsonKey(name: 'discount_percent')
  final String? discountPercent;

  @JsonKey(name: 'browny_coin')
  final String? brownyCoin;

  @JsonKey(name: 'saved')
  final String? saved;

  @JsonKey(name: 'usage_mode')
  final String? usageMode;

  PackageDetailData({
    this.packageId,
    this.packageName,
    this.usageLabel,
    this.groupOption,
    this.store,
    this.price,
    this.qtyWasher,
    this.qtyDryer,
    this.qtyShared,
    this.normalPrice,
    this.discountPercent,
    this.brownyCoin,
    this.saved,
    this.usageMode,
  });

  factory PackageDetailData.fromJson(Map<String, dynamic> json) =>
      _$PackageDetailDataFromJson(json);

  Map<String, dynamic> toJson() => _$PackageDetailDataToJson(this);
}

@JsonSerializable()
class StoreData {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'name')
  final ContentLocalizeData? name;

  @JsonKey(name: 'distance_meters')
  final String? distanceMeters;

  StoreData({
    this.id,
    this.name,
    this.distanceMeters,
  });

  factory StoreData.fromJson(Map<String, dynamic> json) =>
      _$StoreDataFromJson(json);

  Map<String, dynamic> toJson() => _$StoreDataToJson(this);

  String getDistaceDisplay(
    String locale, {
    bool needSymbol = false,
  }) {
    double distance = double.parse(
      distanceMeters.ifNullOrEmpty('0.0').replaceAll(',', ''),
    );

    // Unit ที่จะแสดงหน้า UI
    String unit;
    // symbol < > จากการคำนวณระยะห่างแบบ round แล้ว
    String symbol = '';

    switch (locale) {
      case 'zh':
      case 'en':
        unit = 'm';
        break;
      default:
        unit = 'ม.';
    }
    // ดักไว้ถ้าค่าติดลบ(อาจจะไม่เกิด) จะ return 0
    if (distance < 0) {
      return '$distance $unit';
    }

    double distanceRounded = distance.roundToDouble();
    if (needSymbol) {
      if (distanceRounded != distance) {
        if (distanceRounded > distance) {
          symbol = "< ";
        } else {
          symbol = "> ";
        }
      }
    }

    // ถ้าค่าเกิน 1000 เมตร จะคำนวณเป็น กม.
    if (distance > 1000) {
      distanceRounded = (distance / 1000.0);

      switch (locale) {
        case 'zh':
        case 'en':
          unit = 'km';
          break;
        default:
          unit = 'กม.';
      }
    }
    return formatDistance(
      leadingSign: symbol,
      value: distanceRounded,
      trailingSign: ' $unit',
    );
    // return '$symbol${distanceRounded.toInt()} $unit';
  }
}

@JsonSerializable()
class PaymentMethodsData {
  @JsonKey(name: 'qr')
  final bool? qr;

  @JsonKey(name: 'credit_card')
  final bool? creditCard;

  @JsonKey(name: 'true_money')
  final bool? trueMoney;

  @JsonKey(name: 'shopee_pay')
  final bool? shopeePay;

  @JsonKey(name: 'wechat')
  final bool? wechat;

  @JsonKey(name: 'rabbit_line')
  final bool? rabbitLine;

  @JsonKey(name: 'tp_wallet')
  final bool? tpWallet;

  @JsonKey(name: 'coin')
  final bool? coin;

  @JsonKey(name: 'transfer')
  final bool? transfer;

  PaymentMethodsData({
    this.qr,
    this.creditCard,
    this.trueMoney,
    this.shopeePay,
    this.wechat,
    this.rabbitLine,
    this.tpWallet,
    this.coin,
    this.transfer,
  });

  /// ตรวจสอบว่า payment method ตาม [code] ถูก enable อยู่สำหรับ context นี้หรือไม่
  ///
  /// payment methods ใหม่ที่ยังไม่มีใน boolean flags (เช่น coin)
  /// จะถือว่า active เสมอ หากอยู่ใน list จาก /payment-methods API
  bool isMethodActive(String code) {
    switch (code) {
      case 'qr':
        return qr ?? false;
      case 'credit_card':
        return creditCard ?? false;
      case 'true_money':
        return trueMoney ?? false;
      case 'shopee_pay':
        return shopeePay ?? false;
      case 'wechat':
        return wechat ?? false;
      case 'rabbit_line':
        return rabbitLine ?? false;
      case 'tp_wallet':
        return tpWallet ?? false;
      case 'coin':
        return coin ?? false;
      case 'transfer':
        return transfer ?? false;
      default:
        return true;
    }
  }

  factory PaymentMethodsData.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodsDataFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentMethodsDataToJson(this);
}
