// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_programs_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MachineProgramsResponse _$MachineProgramsResponseFromJson(
  Map<String, dynamic> json,
) => MachineProgramsResponse(
  machineId: (json['machine_id'] as num?)?.toInt(),
  machineNo: (json['machine_no'] as num?)?.toInt(),
  capacityKg: (json['capacity_kg'] as num?)?.toInt(),
  machineName: json['machine_name'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['machine_name'] as Map<String, dynamic>,
        ),
  machineType: json['machine_type'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['machine_type'] as Map<String, dynamic>,
        ),
  firebaseRef: json['firebase_ref'] as String?,
  storeName: json['store_name'] == null
      ? null
      : ContentLocalizeData.fromJson(
          json['store_name'] as Map<String, dynamic>,
        ),
  machineImage: json['machine_image'] as String?,
  programs: (json['programs'] as List<dynamic>?)
      ?.map((e) => ProgramData.fromJson(e as Map<String, dynamic>))
      .toList(),
  addTimes: (json['add_time'] as List<dynamic>?)
      ?.map((e) => ProgramData.fromJson(e as Map<String, dynamic>))
      .toList(),
  availableCoupons: (json['available_coupons'] as List<dynamic>?)
      ?.map((e) => AvailableCouponData.fromJson(e as Map<String, dynamic>))
      .toList(),
  paymentMethods: json['payment_methods'] == null
      ? null
      : PaymentMethodsData.fromJson(
          json['payment_methods'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MachineProgramsResponseToJson(
  MachineProgramsResponse instance,
) => <String, dynamic>{
  'machine_id': instance.machineId,
  'machine_no': instance.machineNo,
  'capacity_kg': instance.capacityKg,
  'machine_name': instance.machineName,
  'machine_type': instance.machineType,
  'firebase_ref': instance.firebaseRef,
  'store_name': instance.storeName,
  'machine_image': instance.machineImage,
  'programs': instance.programs,
  'add_time': instance.addTimes,
  'available_coupons': instance.availableCoupons,
  'payment_methods': instance.paymentMethods,
};

ProgramData _$ProgramDataFromJson(Map<String, dynamic> json) => ProgramData(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] == null
      ? null
      : ContentLocalizeData.fromJson(json['name'] as Map<String, dynamic>),
  image: json['image'] as String?,
  price: json['price'] as String?,
  programCode: json['program_code'] as String?,
  discount: json['discount'] == null
      ? null
      : DiscountData.fromJson(json['discount'] as Map<String, dynamic>),
  net: json['net'] as String?,
);

Map<String, dynamic> _$ProgramDataToJson(ProgramData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
      'price': instance.price,
      'program_code': instance.programCode,
      'discount': instance.discount,
      'net': instance.net,
    };

DiscountData _$DiscountDataFromJson(Map<String, dynamic> json) => DiscountData(
  id: json['id'] as String?,
  name: json['name'] == null
      ? null
      : ContentLocalizeData.fromJson(json['name'] as Map<String, dynamic>),
  type: json['type'] as String?,
  value: json['value'] as String?,
  unit: json['unit'] as String?,
  amount: json['amount'] as String?,
);

Map<String, dynamic> _$DiscountDataToJson(DiscountData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'value': instance.value,
      'unit': instance.unit,
      'amount': instance.amount,
    };

AvailableCouponData _$AvailableCouponDataFromJson(Map<String, dynamic> json) =>
    AvailableCouponData(
      id: (json['id'] as num?)?.toInt(),
      icon: json['icon'] as String?,
      type: json['type'] == null
          ? null
          : ContentLocalizeData.fromJson(json['type'] as Map<String, dynamic>),
      name: json['name'] == null
          ? null
          : ContentLocalizeData.fromJson(json['name'] as Map<String, dynamic>),
      description: json['description'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['description'] as Map<String, dynamic>,
            ),
      image: json['image'] == null
          ? null
          : ContentLocalizeData.fromJson(json['image'] as Map<String, dynamic>),
      expire: json['expire'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['expire'] as Map<String, dynamic>,
            ),
      expireDate: json['expire_date'] as String?,
      daysLeft: json['days_left'] as String?,
      daysLeftText: json['days_left_text'] == null
          ? null
          : ContentLocalizeData.fromJson(
              json['days_left_text'] as Map<String, dynamic>,
            ),
      value: json['value'] as String?,
      unit: json['unit'] as String?,
      max: json['max'] as String?,
      min: json['min'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
      remainingTotal: (json['remaining_total'] as num?)?.toInt(),
      remainingShared: (json['remaining_shared'] as num?)?.toInt(),
      remainingWasher: (json['remaining_washer'] as num?)?.toInt(),
      remainingDryer: (json['remaining_dryer'] as num?)?.toInt(),
      appliesTo: json['applies_to'] as String?,
      allowedPaymentMethods: (json['allowed_payment_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      allStores: json['all_stores'] as bool?,
      storeId: (json['store_id'] as num?)?.toInt(),
      storeIds: (json['store_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      excludedStoreIds: (json['excluded_store_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$AvailableCouponDataToJson(
  AvailableCouponData instance,
) => <String, dynamic>{
  'id': instance.id,
  'icon': instance.icon,
  'type': instance.type,
  'name': instance.name,
  'description': instance.description,
  'image': instance.image,
  'expire': instance.expire,
  'expire_date': instance.expireDate,
  'days_left': instance.daysLeft,
  'days_left_text': instance.daysLeftText,
  'value': instance.value,
  'unit': instance.unit,
  'max': instance.max,
  'min': instance.min,
  'quantity': instance.quantity,
  'remaining': instance.remaining,
  'remaining_total': instance.remainingTotal,
  'remaining_shared': instance.remainingShared,
  'remaining_washer': instance.remainingWasher,
  'remaining_dryer': instance.remainingDryer,
  'applies_to': instance.appliesTo,
  'allowed_payment_methods': instance.allowedPaymentMethods,
  'all_stores': instance.allStores,
  'store_id': instance.storeId,
  'store_ids': instance.storeIds,
  'excluded_store_ids': instance.excludedStoreIds,
};
