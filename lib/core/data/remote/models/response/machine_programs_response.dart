import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'machine_programs_response.g.dart';

// **************************************************************************
// เมื่อสร้าง class ของ JsonSerializable ใหม่ ให้ run command ใน terminal
// dart run build_runner build --delete-conflicting-outputs
// **************************************************************************

@JsonSerializable()
class MachineProgramsResponse {
  MachineProgramsResponse({
    this.machineId,
    this.machineNo,
    this.capacityKg,
    this.machineName,
    this.machineType,
    this.firebaseRef,
    this.storeName,
    this.machineImage,
    this.programs,
    this.addTimes,
    this.availableCoupons,
    this.paymentMethods,
  });

  @JsonKey(name: 'machine_id')
  final int? machineId;

  @JsonKey(name: 'machine_no')
  final int? machineNo;

  @JsonKey(name: 'capacity_kg')
  final int? capacityKg;

  @JsonKey(name: 'machine_name')
  final ContentLocalizeData? machineName;

  @JsonKey(name: 'machine_type')
  final ContentLocalizeData? machineType;

  @JsonKey(name: 'firebase_ref')
  final String? firebaseRef;

  @JsonKey(name: 'store_name')
  final ContentLocalizeData? storeName;

  @JsonKey(name: 'machine_image')
  final String? machineImage;

  @JsonKey(name: 'programs')
  final List<ProgramData>? programs;

  @JsonKey(name: 'add_time')
  final List<ProgramData>? addTimes;

  @JsonKey(name: 'available_coupons')
  final List<AvailableCouponData>? availableCoupons;

  @JsonKey(name: 'payment_methods')
  final PaymentMethodsData? paymentMethods;

  bool get hasAddTime => addTimes.orEmpty.isNotEmpty;

  /// ดึงชื่อเครื่องตาม locale
  String getMachineNameDisplay(String locale) {
    return machineName?.getByLocaleCode(locale) ?? '';
  }

  /// ดึงประเภทเครื่องตาม locale
  String getMachineTypeDisplay(String locale) {
    return machineType?.getByLocaleCode(locale) ?? '';
  }

  /// ดึงชื่อร้านตาม locale
  String getStoreNameDisplay(String locale) {
    return storeName?.getByLocaleCode(locale) ?? '';
  }

  factory MachineProgramsResponse.fromJson(Map<String, dynamic> json) =>
      _$MachineProgramsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MachineProgramsResponseToJson(this);
}

@JsonSerializable()
class ProgramData {
  ProgramData({
    this.id,
    this.name,
    this.image,
    this.price,
    this.programCode,
    this.discount,
    this.net,
    this.index,
  });

  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'name')
  final ContentLocalizeData? name;

  @JsonKey(name: 'image')
  final String? image;

  @JsonKey(name: 'price')
  final String? price;

  @JsonKey(name: 'program_code')
  final String? programCode;

  @JsonKey(name: 'discount')
  final DiscountData? discount;

  @JsonKey(name: 'net')
  final String? net;

  /// Index ของ ProgramData ใน List (ไม่ได้มาจาก API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? index;

  /// ดึงชื่อโปรแกรมตาม locale
  String getProgramNameDisplay(String locale) {
    return name?.getByLocaleCode(locale) ?? '';
  }

  /// เช็คว่ามีส่วนลดหรือไม่
  bool get hasDiscount => discount != null;

  /// สร้าง copy ของ ProgramData พร้อมอัปเดต index
  ProgramData copyWith({
    int? id,
    ContentLocalizeData? name,
    String? image,
    String? price,
    String? programCode,
    DiscountData? discount,
    String? net,
    int? index,
  }) {
    return ProgramData(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      programCode: programCode ?? this.programCode,
      discount: discount ?? this.discount,
      net: net ?? this.net,
      index: index ?? this.index,
    );
  }

  factory ProgramData.fromJson(Map<String, dynamic> json) =>
      _$ProgramDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramDataToJson(this);
}

@JsonSerializable()
class DiscountData {
  DiscountData({
    this.id,
    this.name,
    this.type,
    this.value,
    this.unit,
    this.amount,
  });

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'name')
  final ContentLocalizeData? name;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'value')
  final String? value;

  @JsonKey(name: 'unit')
  final String? unit;

  @JsonKey(name: 'amount')
  final String? amount;

  /// ดึงชื่อส่วนลดตาม locale
  String getDiscountNameDisplay(String locale) {
    return name?.getByLocaleCode(locale) ?? '';
  }

  /// เช็คว่าเป็นส่วนลดแบบ percent หรือไม่
  bool get isPercentDiscount => type?.toLowerCase() == 'percent';

  /// เช็คว่าเป็นส่วนลดแบบ fixed amount หรือไม่
  bool get isFixedDiscount => type?.toLowerCase() == 'fixed';

  factory DiscountData.fromJson(Map<String, dynamic> json) =>
      _$DiscountDataFromJson(json);

  Map<String, dynamic> toJson() => _$DiscountDataToJson(this);
}

@JsonSerializable()
class AvailableCouponData {
  AvailableCouponData({
    this.id,
    this.icon,
    this.type,
    this.name,
    this.description,
    this.image,
    this.expire,
    this.expireDate,
    this.daysLeft,
    this.daysLeftText,
    this.value,
    this.unit,
    this.max,
    this.min,
    this.quantity,
    this.remaining,
    this.remainingTotal,
    this.remainingShared,
    this.remainingWasher,
    this.remainingDryer,
    this.appliesTo,
    this.allowedPaymentMethods,
    this.allStores,
    this.storeId,
    this.storeIds,
    this.excludedStoreIds,
  });

  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'icon')
  final String? icon;

  @JsonKey(name: 'type')
  final ContentLocalizeData? type;

  @JsonKey(name: 'name')
  final ContentLocalizeData? name;

  @JsonKey(name: 'description')
  final ContentLocalizeData? description;

  @JsonKey(name: 'image')
  final ContentLocalizeData? image;

  @JsonKey(name: 'expire')
  final ContentLocalizeData? expire;

  @JsonKey(name: 'expire_date')
  final String? expireDate;

  @JsonKey(name: 'days_left')
  final String? daysLeft;

  @JsonKey(name: 'days_left_text')
  final ContentLocalizeData? daysLeftText;

  @JsonKey(name: 'value')
  final String? value;

  @JsonKey(name: 'unit')
  final String? unit;

  @JsonKey(name: 'max')
  final String? max;

  @JsonKey(name: 'min')
  final String? min;

  @JsonKey(name: 'quantity')
  final int? quantity;

  @JsonKey(name: 'remaining')
  final int? remaining;

  @JsonKey(name: 'remaining_total')
  final int? remainingTotal;

  @JsonKey(name: 'remaining_shared')
  final int? remainingShared;

  @JsonKey(name: 'remaining_washer')
  final int? remainingWasher;

  @JsonKey(name: 'remaining_dryer')
  final int? remainingDryer;

  @JsonKey(name: 'applies_to')
  final String? appliesTo;

  @JsonKey(name: 'allowed_payment_methods')
  final List<String>? allowedPaymentMethods;

  @JsonKey(name: 'all_stores')
  final bool? allStores;

  @JsonKey(name: 'store_id')
  final int? storeId;

  @JsonKey(name: 'store_ids')
  final List<int>? storeIds;

  @JsonKey(name: 'excluded_store_ids')
  final List<int>? excludedStoreIds;

  double get minValue =>
      double.tryParse(min.orEmpty.replaceAll(',', ',').ifEmpty('0.0')) ?? 0.0;

  /// ดึงประเภทคูปองตาม locale
  String getCouponTypeDisplay(String locale) {
    if (type?.en == 'E-Voucher') {
      return 'E-Voucher';
    }
    if (type?.en == 'Discount') {
      return ContentLocalizeData(
        zh: '折扣优惠券',
        en: 'Discount Coupons',
        th: 'คูปองส่วนลด',
      ).getTextByLocale(locale);
    }
    return type?.getByLocaleCode(locale) ?? '';
  }

  /// ดึงชื่อคูปองตาม locale
  String getCouponNameDisplay(String locale) {
    return name?.getByLocaleCode(locale) ?? '';
  }

  /// ดึง description ตาม locale
  String getCouponDescriptionDisplay(String locale) {
    return description?.getByLocaleCode(locale) ?? '';
  }

  /// ดึงรูปภาพคูปองตาม locale
  String getCouponImageDisplay(String locale) {
    return image?.getByLocaleCode(locale) ?? '';
  }

  /// ดึงข้อความหมดอายุตาม locale
  String getExpireDisplay(String locale) {
    return expire?.getByLocaleCode(locale) ?? '';
  }

  /// ดึงข้อความวันเหลือตาม locale
  String getDaysLeftDisplay(String locale) {
    return daysLeftText?.getByLocaleCode(locale) ?? '';
  }

  /// เช็คว่าคูปองใกล้หมดอายุหรือไม่ (น้อยกว่า 7 วัน)
  bool get isExpiringSoon {
    if (daysLeft == null) return false;
    final days = int.tryParse(daysLeft!) ?? 0;
    return days > 0 && days <= 7;
  }

  /// เช็คว่าคูปองใช้งานได้หรือไม่
  bool get isAvailable => (remaining ?? 0) > 0;

  factory AvailableCouponData.fromJson(Map<String, dynamic> json) =>
      _$AvailableCouponDataFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableCouponDataToJson(this);
}
