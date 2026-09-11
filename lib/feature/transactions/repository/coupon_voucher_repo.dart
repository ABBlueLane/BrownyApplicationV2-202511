import 'dart:convert';

import 'package:browny_applications_new/core/data/remote/models/request/coupon_collect_request.dart';
import 'package:browny_applications_new/core/data/remote/models/request/coupon_list_request.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_collect_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_data_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_detail_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_package_list_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_store_list_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/payment_method_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

mixin CouponVoucherDataSourceMixin on CustomerDataSourceMixin {
  /// ฟังก์ชันดึงรายการคูปอง E-Voucher ของ customer ตาม [uuid]
  Future<RepoResult<CouponEVoucherResponse>> fetchCouponEVoucher(
    String uuid, {
    String? storeMachineId,
  });

  /// ฟังก์ชันดึงรายการคูปองส่วนลดของ customer ตาม [uuid]
  Future<RepoResult<CouponDiscountResponse>> fetchCouponDiscount(String uuid);

  /// ฟังก์ชันดึงรายการคูปองแลกซื้อของ customer ตาม [uuid]
  Future<RepoResult<CouponRedemptionResponse>> fetchCouponRedemption(
    String uuid,
  );

  /// ฟังก์ชันดึงรายการสาขาร้านค้าที่ใช้คูปองได้
  Future<RepoResult<CouponStoreListResponse>> fetchCouponStoreList();

  /// ฟังก์ชันดึงรายละเอียดคูปองตาม couponId
  ///
  /// [couponId] - รหัสคูปอง
  /// [request] - ข้อมูล latitude, longitude, customerId
  Future<RepoResult<CouponDetailResponse>> fetchCouponDetail(
    int couponId,
    CouponListRequest request,
  );

  /// ฟังก์ชันดึงรายการแพ็คเกจคูปอง
  ///
  /// [latitude] - ละติจูดของผู้ใช้
  /// [longitude] - ลองจิจูดของผู้ใช้
  /// [customerId] - รหัสลูกค้า
  Future<RepoResult<CouponPackageListResponse>> fetchCouponPackageList({
    String? latitude,
    String? longitude,
    String? customerId,
  });

  /// ฟังก์ชันรับคูปองจาก code หรือ QR
  ///
  /// [type] - ประเภท (code/qr)
  /// [data] - ข้อมูล URL หรือ QR code
  /// [customerId] - รหัสลูกค้า (UUID)
  Future<RepoResult<CouponCollectResponse>> collectCoupon(
    String type,
    String data,
    String customerId,
  );

  /// ฟังก์ชันดึงรายการ Payment Methods ที่รองรับในระบบ
  Future<RepoResult<PaymentMethodResponse>> fetchPaymentMethods();
}

class CouponVoucherRepo extends CustomerDataRepo
    with CouponVoucherDataSourceMixin {
  @override
  Future<RepoResult<CouponEVoucherResponse>> fetchCouponEVoucher(
    String uuid, {
    String? storeMachineId,
  }) async {
    try {
      final response = await requireRemote.fetchCouponEVoucher(
        uuid,
        storeMachineId,
      );
      return RepoResult.dependOn(response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CouponDiscountResponse>> fetchCouponDiscount(
    String uuid,
  ) async {
    try {
      //       if (kDebugMode) {
      //         return RepoResult.success(
      //           data: CouponDiscountResponse.fromJson(
      //             jsonDecode('''
      // {
      //     "data": [
      //         {
      //             "coupon_id": 362,
      //             "customer_coupon_id": 533201,
      //             "discount_type": "baht",
      //             "value": "50.00",
      //             "unit": "baht",
      //             "max": "50.00",
      //             "min": "50.00",
      //             "total_uses": "150",
      //             "assigned_quantity": "1",
      //             "used_quantity": "0",
      //             "remaining": "1",
      //             "expires_at": "2026-05-30 00:00:00",
      //             "is_expired": false,
      //             "is_available": true,
      //             "type_label": {
      //                 "th": "ส่วนลด",
      //                 "en": "Discount",
      //                 "zh": "折扣"
      //             },
      //             "icon": "https://gateway2026.abgroup.co.th/images/coupon-icon/ICON-discount.png",
      //             "name": {
      //                 "th": "Browny Ben - ซักผ้าฟรี",
      //                 "en": "Browny Ben - Free laundry",
      //                 "zh": "Browny Ben - Free laundry"
      //             },
      //             "description": {
      //                 "th": "Browny Ben - ซักผ้าฟรี",
      //                 "en": "Browny Ben - Free laundry",
      //                 "zh": "Browny Ben - Free laundry"
      //             },
      //             "image_url": {
      //                 "th": "https://gateway.abgroup.co.th/upload_file/20250602113022326570.png",
      //                 "en": "https://gateway.abgroup.co.th/upload_file/20250602113022109253.png",
      //                 "zh": "https://gateway.abgroup.co.th/upload_file/20250602113022109253.png"
      //             },
      //             "applies_to": "washer",
      //             "compensation_amount": "50.00",
      //             "code": null,
      //             "is_refund_compensation": false,
      //             "refund_no": null
      //         },
      //         {
      //             "coupon_id": 510,
      //             "customer_coupon_id": 531318,
      //             "discount_type": "baht",
      //             "value": "50.00",
      //             "unit": "baht",
      //             "max": "50.00",
      //             "min": "50.00",
      //             "total_uses": "150",
      //             "assigned_quantity": "1",
      //             "used_quantity": "0",
      //             "remaining": "1",
      //             "expires_at": "2026-05-17 00:00:00",
      //             "is_expired": false,
      //             "is_available": true,
      //             "type_label": {
      //                 "th": "ส่วนลด",
      //                 "en": "Discount",
      //                 "zh": "折扣"
      //             },
      //             "icon": "https://gateway2026.abgroup.co.th/images/coupon-icon/ICON-discount.png",
      //             "name": {
      //                 "th": "Browny Kwangtung - ซักผ้าฟรี ยินดีที่ได้รู้จักฮับ",
      //                 "en": "Browny Kwangtung - Free laundry | Nice to meet you",
      //                 "zh": "Browny Kwangtung - Free laundry | Nice to meet you"
      //             },
      //             "description": {
      //                 "th": "Browny Kwangtung - ซักผ้าฟรี ยินดีที่ได้รู้จักฮับ",
      //                 "en": "Browny Kwangtung - Free laundry | Nice to meet you",
      //                 "zh": "Browny Kwangtung - Free laundry | Nice to meet you"
      //             },
      //             "image_url": {
      //                 "th": "https://gateway.abgroup.co.th/upload_file/20250919135741257336.png",
      //                 "en": "https://gateway.abgroup.co.th/upload_file/20250919135741191339.png",
      //                 "zh": "https://gateway.abgroup.co.th/upload_file/20250919135741191339.png"
      //             },
      //             "applies_to": "washer",
      //             "compensation_amount": "50.00",
      //             "code": null,
      //             "is_refund_compensation": false,
      //             "refund_no": null
      //         },
      //         {
      //             "coupon_id": 679,
      //             "customer_coupon_id": 533451,
      //             "discount_type": "baht",
      //             "value": "50.00",
      //             "unit": "baht",
      //             "max": "50.00",
      //             "min": "30.00",
      //             "total_uses": "700",
      //             "assigned_quantity": "1",
      //             "used_quantity": "0",
      //             "remaining": "1",
      //             "expires_at": "2026-06-01 00:00:00",
      //             "is_expired": false,
      //             "is_available": true,
      //             "type_label": {
      //                 "th": "ส่วนลด",
      //                 "en": "Discount",
      //                 "zh": "折扣"
      //             },
      //             "icon": "https://gateway2026.abgroup.co.th/images/coupon-icon/ICON-discount.png",
      //             "name": {
      //                 "th": "TrueMoney Summer Fresh พฤษภาคม 2026: ซักผ้าเครื่อง 16kg 30 บาท จากปกติ 50 บาท",
      //                 "en": "TrueMoney Summer Fresh May 2026: 30THB Wash discount for 16kg washing machine",
      //                 "zh": "TrueMoney Summer Fresh May 2026: 30THB Wash discount for 16kg washing machine"
      //             },
      //             "description": {
      //                 "th": "TrueMoney",
      //                 "en": "TrueMoney",
      //                 "zh": "TrueMoney"
      //             },
      //             "image_url": {
      //                 "th": "https://gateway.abgroup.co.th/upload_file/20260318142805825496.jpg",
      //                 "en": "https://gateway.abgroup.co.th/upload_file/20260318142805614573.jpg",
      //                 "zh": "https://gateway.abgroup.co.th/upload_file/20260318142805614573.jpg"
      //             },
      //             "applies_to": "washer",
      //             "compensation_amount": "50.00",
      //             "code": "BNTMMjt",
      //             "is_refund_compensation": false,
      //             "refund_no": null
      //         },
      //         {
      //             "coupon_id": 684,
      //             "customer_coupon_id": 531296,
      //             "discount_type": "baht",
      //             "value": "50.00",
      //             "unit": "baht",
      //             "max": "50.00",
      //             "min": "30.00",
      //             "total_uses": "700",
      //             "assigned_quantity": "1",
      //             "used_quantity": "0",
      //             "remaining": "1",
      //             "expires_at": "2026-05-17 00:00:00",
      //             "is_expired": false,
      //             "is_available": true,
      //             "type_label": {
      //                 "th": "ส่วนลด",
      //                 "en": "Discount",
      //                 "zh": "折扣"
      //             },
      //             "icon": "https://gateway2026.abgroup.co.th/images/coupon-icon/ICON-discount.png",
      //             "name": {
      //                 "th": "TrueMoney Summer Fresh เมษายน 2026: ซักผ้าเครื่อง 16kg 30 บาท จากราคาปกติ 50 บาท",
      //                 "en": "TrueMoney Summer Fresh Apr 2026: 30THB Wash discount for 16kg washing machine (normal price 50THB)",
      //                 "zh": "TrueMoney Summer Fresh Apr 2026: 30THB Wash discount for 16kg washing machine (normal price 50THB)"
      //             },
      //             "description": {
      //                 "th": "TrueMoney",
      //                 "en": "TrueMoney",
      //                 "zh": "TrueMoney"
      //             },
      //             "image_url": {
      //                 "th": "https://gateway.abgroup.co.th/upload_file/20260318154209759530.jpg",
      //                 "en": "https://gateway.abgroup.co.th/upload_file/20260318154209873685.jpg",
      //                 "zh": "https://gateway.abgroup.co.th/upload_file/20260318154209873685.jpg"
      //             },
      //             "applies_to": "washer",
      //             "compensation_amount": "50.00",
      //             "code": "BNTMNR9",
      //             "is_refund_compensation": false,
      //             "refund_no": null
      //         },
      //         {
      //             "coupon_id": 692,
      //             "customer_coupon_id": 533203,
      //             "discount_type": "baht",
      //             "value": "50.00",
      //             "unit": "baht",
      //             "max": "50.00",
      //             "min": "40.00",
      //             "total_uses": "300",
      //             "assigned_quantity": "1",
      //             "used_quantity": "0",
      //             "remaining": "1",
      //             "expires_at": "2026-05-30 00:00:00",
      //             "is_expired": false,
      //             "is_available": true,
      //             "type_label": {
      //                 "th": "ส่วนลด",
      //                 "en": "Discount",
      //                 "zh": "折扣"
      //             },
      //             "icon": "https://gateway2026.abgroup.co.th/images/coupon-icon/ICON-discount.png",
      //             "name": {
      //                 "th": "Browny Bell 2026 - ซักผ้าฟรี",
      //                 "en": "Browny Bell 2026 - ซักผ้าฟรี",
      //                 "zh": "Browny Bell 2026 - ซักผ้าฟรี"
      //             },
      //             "description": {
      //                 "th": "<p>Browny Bell 2026 - ซักผ้าฟรี</p>",
      //                 "en": "<p>Browny Bell 2026 - ซักผ้าฟรี</p>",
      //                 "zh": "<p>Browny Bell 2026 - ซักผ้าฟรี</p>"
      //             },
      //             "image_url": {
      //                 "th": "https://gateway.abgroup.co.th/upload_file/20260330184059655944.png",
      //                 "en": "https://gateway.abgroup.co.th/upload_file/20260330184059773887.png",
      //                 "zh": "https://gateway.abgroup.co.th/upload_file/20260330184059773887.png"
      //             },
      //             "applies_to": "washer",
      //             "compensation_amount": "50.00",
      //             "code": null,
      //             "is_refund_compensation": false,
      //             "refund_no": null
      //         },
      //         {
      //             "coupon_id": 694,
      //             "customer_coupon_id": 533216,
      //             "discount_type": "baht",
      //             "value": "50.00",
      //             "unit": "baht",
      //             "max": "50.00",
      //             "min": "40.00",
      //             "total_uses": "300",
      //             "assigned_quantity": "1",
      //             "used_quantity": "0",
      //             "remaining": "1",
      //             "expires_at": "2026-05-30 00:00:00",
      //             "is_expired": false,
      //             "is_available": true,
      //             "type_label": {
      //                 "th": "ส่วนลด",
      //                 "en": "Discount",
      //                 "zh": "折扣"
      //             },
      //             "icon": "https://gateway2026.abgroup.co.th/images/coupon-icon/ICON-discount.png",
      //             "name": {
      //                 "th": "Browny Ohm 2026 - ซักผ้าฟรี",
      //                 "en": "Browny Ohm 2026 - ซักผ้าฟรี",
      //                 "zh": "Browny Ohm 2026 - ซักผ้าฟรี"
      //             },
      //             "description": {
      //                 "th": "<p>Browny Ohm 2026 - ซักผ้าฟรี</p>",
      //                 "en": "<p>Browny Ohm 2026 - ซักผ้าฟรี</p>",
      //                 "zh": "<p>Browny Ohm 2026 - ซักผ้าฟรี</p>"
      //             },
      //             "image_url": {
      //                 "th": "https://gateway.abgroup.co.th/upload_file/20260330184445436385.png",
      //                 "en": "https://gateway.abgroup.co.th/upload_file/20260330184445534820.png",
      //                 "zh": "https://gateway.abgroup.co.th/upload_file/20260330184445534820.png"
      //             },
      //             "applies_to": "washer",
      //             "compensation_amount": "50.00",
      //             "code": null,
      //             "is_refund_compensation": false,
      //             "refund_no": null
      //         },
      //         {
      //             "coupon_id": 695,
      //             "customer_coupon_id": 533217,
      //             "discount_type": "baht",
      //             "value": "50.00",
      //             "unit": "baht",
      //             "max": "50.00",
      //             "min": "40.00",
      //             "total_uses": "300",
      //             "assigned_quantity": "1",
      //             "used_quantity": "0",
      //             "remaining": "1",
      //             "expires_at": "2026-05-30 00:00:00",
      //             "is_expired": false,
      //             "is_available": true,
      //             "type_label": {
      //                 "th": "ส่วนลด",
      //                 "en": "Discount",
      //                 "zh": "折扣"
      //             },
      //             "icon": "https://gateway2026.abgroup.co.th/images/coupon-icon/ICON-discount.png",
      //             "name": {
      //                 "th": "Browny Kluay 2026 - ซักผ้าฟรี",
      //                 "en": "Browny Kluay 2026 - ซักผ้าฟรี",
      //                 "zh": "Browny Kluay 2026 - ซักผ้าฟรี"
      //             },
      //             "description": {
      //                 "th": "<p>Browny Kluay 2026 - ซักผ้าฟรี</p>",
      //                 "en": "<p>Browny Kluay 2026 - ซักผ้าฟรี</p>",
      //                 "zh": "<p>Browny Kluay 2026 - ซักผ้าฟรี</p>"
      //             },
      //             "image_url": {
      //                 "th": "https://gateway.abgroup.co.th/upload_file/20260330184635186146.png",
      //                 "en": "https://gateway.abgroup.co.th/upload_file/20260330184635707825.png",
      //                 "zh": "https://gateway.abgroup.co.th/upload_file/20260330184635707825.png"
      //             },
      //             "applies_to": "washer",
      //             "compensation_amount": "50.00",
      //             "code": null,
      //             "is_refund_compensation": false,
      //             "refund_no": null
      //         }
      //     ]
      // }
      // '''),
      //           ),
      //         );
      //       }
      final response = await requireRemote.fetchCouponDiscount(uuid);
      return RepoResult.dependOn(response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CouponRedemptionResponse>> fetchCouponRedemption(
    String uuid,
  ) async {
    try {
      final response = await requireRemote.fetchCouponRedemption(uuid);
      return RepoResult.dependOn(response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CouponStoreListResponse>> fetchCouponStoreList() async {
    try {
      final response = await requireRemote.fetchCouponStoreList();
      return RepoResult.dependOn(response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CouponDetailResponse>> fetchCouponDetail(
    int couponId,
    CouponListRequest request,
  ) async {
    try {
      final response = await requireRemote.fetchCouponDetail(
        couponId,
        request,
      );
      return RepoResult.dependOn(response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CouponPackageListResponse>> fetchCouponPackageList({
    String? latitude,
    String? longitude,
    String? customerId,
  }) async {
    try {
      final request = CouponListRequest(
        latitude: latitude,
        longitude: longitude,
        customerId: customerId,
      );

      final response = await requireRemote.fetchCouponPackageList(request);

      if (response.data.data.orEmpty.isEmpty) {
        return RepoResult.empty();
      }

      return RepoResult.dependOn(response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CouponCollectResponse>> collectCoupon(
    String type,
    String data,
    String customerId,
  ) async {
    try {
      final request = CouponCollectRequest(
        type: type,
        data: data,
        customerId: customerId,
      );

      final response = await requireRemote.collectCoupon(request);

      if (!response.isSuccessful) {
        return RepoResult.empty(
          error: Exception(response.data.message),
        );
      }

      return RepoResult.success(data: response.data);
    } on DioException catch (dioEx) {
      if (dioEx.response!.isNotFound) {
        return RepoResult.error(error: CollectCouponNotFound());
      }
      if (dioEx.response!.isBadRequest) {
        return RepoResult.error(error: CollectCouponCollected());
      }
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<PaymentMethodResponse>> fetchPaymentMethods() async {
    try {
      final response = await requireRemote.fetchPaymentMethods();
      return RepoResult.dependOn(response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }
}
