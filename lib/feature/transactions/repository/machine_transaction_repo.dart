// ignore: unused_import for debug mode
import 'dart:convert';

import 'package:browny_applications_new/core/data/repo/app_repository.dart';
import 'package:browny_applications_new/core/data/remote/models/request/machine_order_request.dart';
import 'package:browny_applications_new/core/data/remote/models/request/machine_order_review_request.dart';
import 'package:browny_applications_new/core/data/remote/models/response/base_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_detail_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_order_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_programs_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_status_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:dio/dio.dart';
// ignore: unused_import for debug mode
import 'package:flutter/foundation.dart';

mixin MachineTransactionDataSourceMixin {
  /// API fetch รายละเอียดเครื่อง (machine detail)
  Future<RepoResult<MachineDetailResponse>> fetchMachineDetail(
    String machineId,
  );

  /// API fetch โปรแกรมของเครื่อง (machine programs)
  Future<RepoResult<MachineProgramsResponse>> fetchMachinePrograms(
    String machineId,
    String customerId,
  );

  /// API สร้างคำสั่งซื้อเครื่องซัก/อบ (machine order)
  Future<RepoResult<MachineOrderResponse>> createMachineOrder(
    MachineOrderRequest request,
  );

  /// API ส่งคะแนนรีวิวคำสั่งซื้อเครื่องซัก/อบ
  Future<RepoResult<BaseResponse>> submitMachineOrderReview(
    String orderId,
    MachineOrderReviewRequest request,
  );

  /// API ตรวจสอบสถานะเครื่องจาก QR code
  Future<RepoResult<MachineStatusResponse>> checkMachineStatus(
    String qrCode,
  );
}

class MachineRepo extends AppRepository with MachineTransactionDataSourceMixin {
  @override
  Future<RepoResult<MachineDetailResponse>> fetchMachineDetail(
    String machineId,
  ) async {
    try {
      if (kDebugMode) {
        return RepoResult.success(
          data: MachineDetailResponse.fromJson(
            jsonDecode('''
            {"id": 895,"capacity_kg": 16,"store_name": {"th": "ปั๊มซัสโก้ บางหว้า - เพชรเกษม 33","en": "SUSCO Bangwa Phetkasam 33","zh": "SUSCO Bangwa Phetkasam 33"},"status": "Busy","finish_datatime": "18:52","remaining_time": "00:00:10","machine_no": "6","machine_image": "https://gateway.abgroup.co.th/storage/galleries/az5kkRdMQqi526XNlCy04cU0HtfTr8Kh3UofRvRC.png","machine_type": {"th": "เครื่องอบ","en": "Dryer","zh": "烘干机"},"name": {"th": "เครื่องอบ 6 - 16.00 กก.","en": "Dryer 6 - 16.00 kg","zh": "烘干机 6 - 16.00 公斤"},"order_id": "019f9e1f-9c03-7186-96d9-ad5aee4d931a","receipt_no": "BNP20260726-181202957555","startTime": "2026-07-26 18:12","addTime": [{"name": {"th": "+ 6 นาที","en": "+ 6 minutes","zh": "+ 6 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "10.00","program_code": "addTime","discount": null,"net": "10.00"},{"name": {"th": "+ 12 นาที","en": "+ 12 minutes","zh": "+ 12 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "20.00","program_code": "addTime","discount": null,"net": "20.00"},{"name": {"th": "+ 18 นาที","en": "+ 18 minutes","zh": "+ 18 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "30.00","program_code": "addTime","discount": null,"net": "30.00"},{"name": {"th": "+ 24 นาที","en": "+ 24 minutes","zh": "+ 24 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "40.00","program_code": "addTime","discount": null,"net": "40.00"}],"program_image": "https://gateway.abgroup.co.th/storage/galleries/vKaQcmOFX9uN6D9FlnWLY2MdLi9y5k5K1lcvLbst.png","program_name": {"th": "ร้อนปานกลาง","en": "Medium hot","zh": "中辣"}}
            '''),
            // jsonDecode('''
            // {"id": 895,"capacity_kg": 16,"store_name": {"th": "ปั๊มซัสโก้ บางหว้า - เพชรเกษม 33","en": "SUSCO Bangwa Phetkasam 33","zh": "SUSCO Bangwa Phetkasam 33"},"status": "Vacant","finish_datatime": "18:52","remaining_time": "00:00:00","machine_no": "6","machine_image": "https://gateway.abgroup.co.th/storage/galleries/az5kkRdMQqi526XNlCy04cU0HtfTr8Kh3UofRvRC.png","machine_type": {"th": "เครื่องอบ","en": "Dryer","zh": "烘干机"},"name": {"th": "เครื่องอบ 6 - 16.00 กก.","en": "Dryer 6 - 16.00 kg","zh": "烘干机 6 - 16.00 公斤"},"order_id": "","receipt_no": "","startTime": "2026-07-26 18:12","addTime": [{"name": {"th": "+ 6 นาที","en": "+ 6 minutes","zh": "+ 6 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "10.00","program_code": "addTime","discount": null,"net": "10.00"},{"name": {"th": "+ 12 นาที","en": "+ 12 minutes","zh": "+ 12 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "20.00","program_code": "addTime","discount": null,"net": "20.00"},{"name": {"th": "+ 18 นาที","en": "+ 18 minutes","zh": "+ 18 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "30.00","program_code": "addTime","discount": null,"net": "30.00"},{"name": {"th": "+ 24 นาที","en": "+ 24 minutes","zh": "+ 24 分钟"},"image": "https://brownypay.com/asset/เพิ่มเวลา.png","price": "40.00","program_code": "addTime","discount": null,"net": "40.00"}],"program_image": "https://gateway.abgroup.co.th/storage/galleries/vKaQcmOFX9uN6D9FlnWLY2MdLi9y5k5K1lcvLbst.png","program_name": {"th": "ร้อนปานกลาง","en": "Medium hot","zh": "中辣"}}
            // '''),
          ),
        );
      }
      final response = await requireRemote.fetchMachineDetail(machineId);
      if (!response.isSuccessful) {
        return RepoResult.empty();
      }
      return RepoResult.success(data: response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<MachineProgramsResponse>> fetchMachinePrograms(
    String machineId,
    String customerId,
  ) async {
    try {
      final response = await requireRemote.fetchMachinePrograms(
        machineId,
        customerId,
      );
      if (!response.isSuccessful) {
        return RepoResult.empty();
      }
      return RepoResult.success(data: response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<MachineOrderResponse>> createMachineOrder(
    MachineOrderRequest request,
  ) async {
    // ========== Mock Data for Debug Mode (priceFinal = 0.0) ==========
    if (kDebugMode) {
      // await Future.delayed(const Duration(seconds: 30));
      // Mock response สำหรับทดสอบกรณีลด 100% (priceFinal = 0.0)
      final mockTimestamp = DateTime.now().millisecondsSinceEpoch;
      final mockResponse = MachineOrderResponse(
        message: 'Mock: Free order created successfully (100% discount)',
        data: MachineOrderData(
          id: 'mock-order-$mockTimestamp',
          customerId: request.customerId,
          customerPhone: request.customerPhone,
          storeMachineId: request.storeMachineId,
          programCode: request.programCode,
          programName: 'Mock Program',
          addTimeValue: request.addTimeValue,
          couponCustomerId: request.couponCustomerId,
          discountId: request.discountId,
          priceOriginal: '100.0',
          priceFinal: '0.0', // ← สำคัญที่สุด: ราคาสุดท้าย = 0
          discountAmount: '100.0',
          couponDiscount: '0',
          systemDiscount: '100.0',
          paymentMethod: request.paymentMethod,
          paymentStatus: 'paid', // ถือว่าจ่ายเงินแล้ว (เพราะไม่ต้องจ่าย)
          paymentRef: '20260307134508',
          machineStatus: 'pending',
          deviceLogId: 'mock-device-log-$mockTimestamp',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          responsePayload: null,
        ),
        redirectUrl: null,
        qrAndWechat: null,
      );

      debugPrint('🧪 [DEBUG] Mock Order Created: priceFinal = 0.0');
      return RepoResult.success(data: mockResponse);
    }
    // ========== End Mock Data ==========

    try {
      final response = await requireRemote.createMachineOrder(request);
      if (!response.isSuccessful) {
        return RepoResult.empty();
      }
      return RepoResult.success(data: response.data);
    } on DioException catch (dioEx) {
      try {
        final serverMessage = MachineOrderResponse.fromJson(
          dioEx.response?.data,
        );
        return RepoResult.error(
          error: Unprocessable(serverMessage.message),
        );
      } catch (_) {
        return RepoResult.error(
          error: Exception(
            dioEx.response?.data?['message'] ??
                dioEx.message ??
                'Network error occurred',
          ),
        );
      }
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<BaseResponse>> submitMachineOrderReview(
    String orderId,
    MachineOrderReviewRequest request,
  ) async {
    try {
      if (kDebugMode) {
        return RepoResult.success(data: BaseResponse());
      }
      final response = await requireRemote.submitMachineOrderReview(
        orderId,
        request,
      );
      if (!response.isSuccessful) {
        return RepoResult.empty();
      }
      return RepoResult.success(data: response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<MachineStatusResponse>> checkMachineStatus(
    String qrCode,
  ) async {
    try {
      final response = await requireRemote.checkMachineStatus({
        'qr': qrCode,
      });
      if (!response.isSuccessful) {
        return RepoResult.empty();
      }
      return RepoResult.success(data: response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }
}
