import 'package:browny_applications_new/core/data/remote/models/api_model_index.dart';
import 'package:browny_applications_new/core/data/remote/models/request/payment_check.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_detail_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_store_list_response.dart';
import 'package:flutter/foundation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'app_client.g.dart';

/// Note: เมื่อมีการแก้ไข ให้ run command นี้ใน terminal ด้วย
///
/// dart run build_runner build --delete-conflicting-outputs
/// dart run build_runner watch
@RestApi()
abstract class AppClient {
  static final _AppClient _instance = _AppClient(
    Dio(
      BaseOptions(
        contentType: 'application/json; charset=utf-8',
        connectTimeout: const Duration(minutes: 1),
        sendTimeout: const Duration(minutes: 1),
        receiveTimeout: const Duration(minutes: 1),
      ),
    ),
  );

  factory AppClient.instance() => _instance;

  factory AppClient.init(ApiConfigs config) {
    if (kDebugMode) {
      _instance._dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
        ),
        // InterceptorsWrapper(
        //   onRequest: (options, handler) {
        //     // ignore: avoid_print
        //     debugPrint(
        //       'DIO: REQUEST[${options.method}] => PATH: ${options.path}',
        //     );
        //     return handler.next(options); // continue
        //   },
        //   onResponse: (response, handler) {
        //     debugPrint('DIO: RESPONSE : ${response.toString()}');
        //     return handler.next(response); // continue
        //   },
        //   onError: (error, handler) {
        //     debugPrint('DIO: RESPONSE : ${error.toString()}');
        //     return handler.next(error); // continue
        //   },
        // ),
      );
    }
    return _instance
      ..baseUrl = config.baseUrl
      .._dio.options.headers.putIfAbsent(
        'Authorization',
        () => 'Bearer ${config.token}',
      )
      .._dio.options.headers.putIfAbsent(
        'clientVersion',
        () => config.clientVersion,
      );
  }

  /// DONG 2026-02-15
  ///
  /// API fetch ข้อมูลร้านค้าตาม location (latitude, longitude)
  ///
  /// Body parameters:
  /// - latitude: String
  /// - longitude: String
  ///
  /// Response:
  /// - StoreDetailResponse with store info, services, machines status
  @GET('/{storeId}/store')
  Future<HttpResponse<StoreDetailResponse>> fetchStoreDetail(
    @Path('storeId') String storeId,
    @Body() StoreLocationRequest body,
  );

  /// DONG 2026-02-13
  ///
  /// API ตั้งค่า PIN สำหรับลูกค้า
  ///
  /// Body parameters:
  /// - id: String (customer_id)
  /// - pin: String (6 หลัก)
  @POST('/customer/set-pin')
  Future<HttpResponse<BaseResponse>> setPin(
    @Body() PinRequest body,
  );

  /// DONG 2026-02-13
  ///
  /// API ดึงข้อมูล PIN ที่เข้ารหัสของลูกค้า
  @GET('/customer/{uuid}/get-pin')
  Future<HttpResponse<GetPinResponse>> getPin(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-02-13
  ///
  /// API ยืนยัน PIN
  ///
  /// Body parameters:
  /// - id: String (customer_id)
  /// - pin: String (6 หลัก)
  ///
  /// Response HTTP Codes:
  /// - 200: PIN ถูกต้อง (returns token and expire)
  /// - 422: ข้อมูลไม่ถูกต้อง (validation error)
  /// - 401: PIN ไม่ถูกต้อง (error_type: "invalid_pin")
  @POST('/customer/verify-pin')
  Future<HttpResponse<VerifyPinResponse>> verifyPin(
    @Body() PinRequest body,
  );

  /// DONG 2026-03-07
  ///
  /// API เปลี่ยนรหัสผ่าน
  ///
  /// Body parameters:
  /// - id: String (customer_id UUID)
  /// - old_password: String (รหัสผ่านเดิม)
  /// - new_password: String (รหัสผ่านใหม่)
  ///
  /// Response HTTP Codes:
  /// - 200: เปลี่ยนรหัสผ่านสำเร็จ
  /// - 403: รหัสผ่านเดิมไม่ถูกต้อง (error_type: "invalid_old_password")
  /// - 422: รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม (error_type: "password_reused")
  @PUT('/customer/change-password')
  Future<HttpResponse<BaseResponse>> changePassword(
    @Body() ChangePasswordRequest body,
  );

  /// API ขอเปลี่ยนอีเมล/เบอร์โทร (ส่ง OTP ไปช่องทางเดิมหรือใหม่)
  ///
  /// Body: id, field (`email`|`phone`), new_value
  /// Response data.step: `verify_old` | `verify_new`
  @POST('/customer/contact-change/request')
  Future<HttpResponse<ContactChangeResponse>> requestContactChange(
    @Body() ContactChangeRequest body,
  );

  /// API ยืนยัน OTP ช่องทางเดิม แล้วส่ง OTP ไปช่องทางใหม่
  @POST('/customer/contact-change/verify-old')
  Future<HttpResponse<ContactChangeResponse>> verifyOldContactChange(
    @Body() ContactChangeOtpRequest body,
  );

  /// API ยืนยัน OTP ช่องทางใหม่ และบันทึกการเปลี่ยนอีเมล/เบอร์
  @POST('/customer/contact-change/confirm')
  Future<HttpResponse<ContactChangeResponse>> confirmContactChange(
    @Body() ContactChangeOtpRequest body,
  );

  /// DONG 2026-02-12
  ///
  /// API fetch popups สำหรับแสดงในแต่ละหน้า
  ///
  /// Response: List of PopupData
  /// - แสดงตามช่วงเวลา (start_date, end_date)
  /// - แสดงตามหน้า (show_on: ["home", "program"])
  /// - แสดงตามสถานะ (active: "true" or "false")
  @GET('/popups')
  Future<HttpResponse<List<PopupData>>> fetchPopups();

  /// DONG 2026-02-11
  ///
  /// API บันทึกข้อมูลอุปกรณ์เข้า backend
  ///
  /// Body parameters:
  /// - device_identity_id: String (required)
  /// - device_model: String (required)
  /// - device_platform: String (required) - "IOS" or "ANDROID"
  /// - transaction_token: String? (optional)
  /// - notification_token: String? (optional)
  /// - app_version: String (required)
  /// - customer_id: String? (optional)
  @POST('/device-log')
  Future<HttpResponse<DeviceLogResponse>> saveDeviceLog(
    @Body() DeviceLogRequest body,
  );

  /// DONG 2026-02-09
  ///
  /// API fetch home menu items
  @GET('/home-menu')
  Future<HttpResponse<HomeMenuResponse>> fetchHomeMenu();

  /// DONG 2026-02-09
  ///
  /// API fetch Browny Live status and link
  @GET('/browny-live')
  Future<HttpResponse<BrownyLiveResponse>> fetchBrownyLive();

  /// DONG 2026-02-09
  ///
  /// API fetch customer notifications
  @GET('/customer-notifications/{uuid}')
  Future<HttpResponse<CustomerNotificationResponse>> fetchCustomerNotifications(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-02-09
  ///
  /// API fetch customer notification preferences
  @GET('/customer/{uuid}/notification-settings')
  Future<HttpResponse<NotificationPreferencesResponse>>
  fetchNotificationPreferences(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-02-14
  ///
  /// API อัพเดทการตั้งค่าการแจ้งเตือนของลูกค้า
  ///
  /// Body parameters:
  /// - notify_machine_done: bool
  /// - notify_news: bool
  /// - notify_promotion: bool
  @PATCH('/customer/{uuid}/notification-preferences')
  Future<HttpResponse<UpdateNotificationPreferencesResponse>>
  updateNotificationPreferences(
    @Path('uuid') String uuid,
    @Body() UpdateNotificationPreferencesRequest body,
  );

  /// DONG 2026-02-09
  ///
  /// API fetch contact information (social media links)
  @GET('/contact')
  Future<HttpResponse<ContactResponse>> fetchContact();

  /// DONG 2026-02-08
  ///
  /// API Social Login (Google, Facebook)
  ///
  /// Body parameters:
  /// - provider: String (facebook, google, apple, line)
  /// - app_id: String
  /// - name: String
  /// - email: String
  /// - profile_image: String
  @POST('/customer/social-login')
  Future<HttpResponse<LoginCustomerResponse?>> socialLogin(
    @Body() SocialLoginRequest body,
  );

  /// DONG 2026-01-28
  ///
  /// API fetch map locations (สาขาทั้งหมดบนแผนที่)
  @GET('/map/locations')
  Future<HttpResponse<MapLocationResponse>> fetchMapLocations();

  /// DONG 2026-02-09
  ///
  /// API fetch ใบเสร็จรับเงินคูปอง/e-voucher ตาม order_id
  @GET('/payment/coupon-evorcher/receipt/{order_id}')
  Future<HttpResponse<CouponReceiptResponse>> fetchCouponReceipt(
    @Path('order_id') String orderId,
  );

  /// DONG 2026-01-24
  ///สร้างคำสั่งซื้อคูปอง (create coupon order)
  @POST('/coupon-orders')
  Future<HttpResponse<CouponOrderResponse>> createCouponOrder(
    @Body() CouponOrderRequest body,
  );

  /// DONG 2026-02-24
  ///
  /// เปลี่ยนใช้ model request [PaymentCheck] แทน
  /// DONG 2026-02-08
  ///
  /// API ตรวจสอบสถานะการชำระเงินคูปอง/e-voucher (ใช้ CouponOrderData ส่ง payment_ref)
  @POST('/payment/coupon-evorcher/check')
  Future<HttpResponse<PaymentStatusCheckResponse>> checkPaymentStatusByRef(
    @Body() PaymentCheck body,
  );

  /// DONG 2026-02-24
  ///
  /// API ตรวจสอบสถานะการชำระเงิน Machine Order
  ///
  /// Body parameters:
  /// - payment_ref: String (รหัสอ้างอิงการชำระเงิน)
  ///
  /// Response:
  /// - PaymentStatusCheckResponse with status, redirect url, and order_id
  @POST('/payment/machine-order/payment/check')
  Future<HttpResponse<PaymentStatusCheckResponse>>
  checkMachineOrderPaymentStatus(
    @Body() PaymentCheck body,
  );

  /// DONG 2026-01-24
  ///
  /// API fetch รายการแพ็คเกจคูปอง
  ///
  /// Body parameters:
  /// - latitude: String
  /// - longitude: String
  /// - customer_id: String
  @GET('/coupon/list')
  Future<HttpResponse<CouponPackageListResponse>> fetchCouponPackageList(
    @Body() CouponListRequest body,
  );

  /// DONG 2026-01-31
  ///
  /// API fetch รายละเอียดคูปองตาม coupon_id
  ///
  /// Body parameters:
  /// - latitude: String
  /// - longitude: String
  /// - customer_id: String
  @GET('/coupon/detail/{coupon_id}')
  Future<HttpResponse<CouponDetailResponse>> fetchCouponDetail(
    @Path('coupon_id') int couponId,
    @Body() CouponListRequest body,
  );

  /// DONG 2026-03-03
  ///
  /// API collect coupon จาก code หรือ QR
  ///
  /// Body parameters:
  /// - type: String ("code" หรือ "qr")
  /// - data: String (URL ของ coupon หรือ QR code data)
  /// - customer_id: String (UUID ของลูกค้า)
  ///
  /// Response:
  /// - CouponCollectResponse with success message and coupon_customer data
  ///
  /// Error States:
  /// - 404/400: {"message": "Invalid or expired coupon code."}
  @POST('/coupon/collect')
  Future<HttpResponse<CouponCollectResponse>> collectCoupon(
    @Body() CouponCollectRequest body,
  );

  /// DONG 2026-01-20
  ///
  /// API fetch จำนวนคูปองที่มีอยู่ของ customer ตาม uuid
  @GET('/customer/{uuid}/coupons/available-count')
  Future<HttpResponse<CouponAvailableCountResponse>> fetchCouponAvailableCount(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-01-20
  ///
  /// API fetch รายการสาขาร้านค้าที่ใช้คูปองได้
  @GET('/coupon/stores/list')
  Future<HttpResponse<CouponStoreListResponse>> fetchCouponStoreList();

  /// DONG 2026-01-21
  ///
  /// API fetch คูปองแลกซื้อของ customer ตาม uuid
  @GET('/customer/coupons/redemption/{uuid}')
  Future<HttpResponse<CouponRedemptionResponse>> fetchCouponRedemption(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-01-21
  ///
  /// API fetch คูปองส่วนลดของ customer ตาม uuid
  @GET('/customer/coupons/discount/{uuid}')
  Future<HttpResponse<CouponDiscountResponse>> fetchCouponDiscount(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-01-21
  ///
  /// API fetch E-Voucher ของ customer ตาม uuid
  @GET('/customer/coupons/e-voucher/{uuid}')
  Future<HttpResponse<CouponEVoucherResponse>> fetchCouponEVoucher(
    @Path('uuid') String uuid,
    @Query('store_machine_id') String? storeMachinId,
  );

  /// DONG 2026-01-15
  ///
  /// API ส่งไป claim coin
  @POST('/coin/claim')
  Future<HttpResponse<CoinClaimedResponse>> coinClaiming(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2026-01-15
  ///
  /// API fetch coin calendar data ตาม customer_id
  @GET('/coin/calendar')
  Future<HttpResponse<CoinClaimResponse>> getCoinClaimData(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2026-02-19
  ///
  /// API fetch ประวัติ Browny Coin (รับ/ใช้/หมดอายุ)
  ///
  /// Body parameters:
  /// - customer_id: String
  ///
  /// Response:
  /// - CoinHistoryResponse with coin balance, expire info, and history
  @GET('/coin/history')
  Future<HttpResponse<CoinHistoryResponse>> fetchCoinHistory(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2026-03-03
  ///
  /// API ตรวจสอบสถานะเครื่องจาก QR code
  ///
  /// Body parameters:
  /// - qr: String (QR code URL เช่น "http://brownypay.com/wash/dry/2")
  ///
  /// Response:
  /// - MachineStatusResponse with status, message, store_machine_id, qr
  /// - status: "available" (พร้อมใช้งาน), "busy" (กำลังใช้งาน), "unavailable" (ไม่พร้อมใช้งาน)
  ///
  /// Example Response:
  /// {"status": "available", "message": "พร้อมใช้งาน", "store_machine_id": 2, "qr": "http://brownypay.com/wash/dry/2"}
  @GET('/status/machine')
  Future<HttpResponse<MachineStatusResponse>> checkMachineStatus(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2026-03-01
  /// ปรับเส้น API เป็น /machines/{id}/progress
  ///
  /// DONG 2026-02-20
  ///
  /// API fetch รายละเอียดเครื่อง (machine detail)
  ///
  /// Response:
  /// - MachineDetailResponse with machine info, status, remaining time
  @GET('/machines/{id}/progress')
  Future<HttpResponse<MachineDetailResponse>> fetchMachineDetail(
    @Path('id') String machineId,
  );

  /// DONG 2026-02-20
  ///
  /// API fetch โปรแกรมของเครื่อง (machine programs)
  ///
  /// Query parameters:
  /// - customer_id: String (uuid)
  ///
  /// Response:
  /// - MachineProgramsResponse with programs, available coupons, payment methods
  @GET('/machine/{id}/programs')
  Future<HttpResponse<MachineProgramsResponse>> fetchMachinePrograms(
    @Path('id') String machineId,
    @Query('customer_id') String customerId,
  );

  /// DONG 2026-02-24
  ///
  /// API สร้างคำสั่งซื้อเครื่องซัก/อบ (create machine order)
  ///
  /// Body parameters:
  /// - customer_id: String? (uuid ของลูกค้า หรือ null)
  /// - customer_phone: String (เบอร์โทรศัพท์)
  /// - store_machine_id: int (รหัสเครื่อง)
  /// - program_code: String (รหัสโปรแกรม เช่น WASH60)
  /// - add_time_value: int? (เวลาเพิ่มเติม)
  /// - payment_method: String (วิธีการชำระเงิน qr, tp_wallet, shopee_pay, etc.)
  /// - coupon_customer_id: int? (รหัสคูปองที่ใช้)
  /// - discount_id: String? (uuid ส่วนลด)
  /// - notification_token: String? (FCM token)
  ///
  /// Response:
  /// - MachineOrderResponse with order data, payment_ref, redirect_url
  ///
  /// Error States:
  /// - Wallet insufficient: {"message": "ยอดเงินใน Wallet ไม่เพียงพอ", "wallet_balance": 10.00, "price_required": 30.00}
  /// - Machine busy: {"status": "error", "message": "เครื่องไม่ว่าง...", "machine_status": "Busy"}
  /// - General error: {"message": "เกิดข้อผิดพลาด", "error": "รายละเอียด"}
  @POST('/machine-orders')
  Future<HttpResponse<MachineOrderResponse>> createMachineOrder(
    @Body() MachineOrderRequest body,
  );

  /// DONG 2026-02-25
  ///
  /// API fetch ใบเสร็จคำสั่งซื้อเครื่องซัก/อบ (machine order receipt)
  ///
  /// Path parameters:
  /// - order_id: String (UUID ของคำสั่งซื้อ)
  ///
  /// Response:
  /// - MachineOrderReceiptResponse with branch, machine info, payment, summary,
  ///   support channels, lucky no, and review score
  @GET('/machine-orders/{order_id}/receipt')
  Future<HttpResponse<MachineOrderReceiptResponse>> fetchMachineOrderReceipt(
    @Path('order_id') String orderId,
  );

  /// DONG 2026-02-26
  ///
  /// API ส่งคะแนนรีวิวคำสั่งซื้อเครื่องซัก/อบ
  ///
  /// Path parameters:
  /// - order_id: String (UUID ของคำสั่งซื้อ)
  ///
  /// Body parameters:
  /// - score: int (คะแนนรีวิว 1-5)
  ///
  /// Response:
  /// - BaseResponse with success status and message
  @POST('/machine-orders/{order_id}/review')
  Future<HttpResponse<BaseResponse>> submitMachineOrderReview(
    @Path('order_id') String orderId,
    @Body() MachineOrderReviewRequest body,
  );

  /// DONG 2026-02-28
  ///
  /// API fetch รายการเครื่องที่กำลังทำงาน (working machines)
  ///
  /// Query parameters:
  /// - customer_id: String (UUID ของลูกค้า)
  /// - notification_token: String? (FCM token, nullable)
  ///
  /// Response:
  /// - WorkingMachinesResponse with count and list of working machines
  @GET('/machines/working')
  Future<HttpResponse<List<WorkingMachineData>>> fetchWorkingMachines({
    @Query('customer_id') String? customerId,
    @Query('notification_token') String? notificationToken,
  });

  /// DONG 2026-01-13
  ///
  /// API fetch referral rewards ตาม customer_id
  @GET('/referral/rewards')
  Future<HttpResponse<ReferralRewardResponse>> fetchReferralReward(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2026-05-09
  ///
  /// API ตรวจสอบสถานะการแนะนำเพื่อน (referral status)
  ///
  /// Body parameters:
  /// - phone: String (เบอร์โทรศัพท์)
  ///
  /// Response:
  /// - ReferralStatusResponse with enabled flag and terms content
  @GET('/referral/status')
  Future<HttpResponse<ReferralStatusResponse>> fetchReferralStatus(
    @Body() ReferralStatusRequest body,
  );

  /// DONG 2026-01-11
  ///
  /// API fetch QRCode ของ customer ตาม [uuid]
  @GET('/customer/{uuid}/qrcode')
  Future<HttpResponse<CustomerQRResponse>> fetchCustomerQRCode(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-02-16
  ///
  /// API fetch ประวัติการทำธุรกรรม wallet
  ///
  /// Body parameters:
  /// - customer_id: String
  ///
  /// Response:
  /// - WalletHistoryResponse with history list
  @GET('/wallet/history')
  Future<HttpResponse<WalletHistoryResponse>> fetchWalletHistory(
    @Body() WalletHistoryRequest body,
  );

  /// DONG 2026-01-10
  ///
  /// สำหรับเช็คข้อมูล Receipt ตาม [paymentRef]
  @GET('/wallet/receipt/{payment_ref}')
  Future<HttpResponse<WalletReceiptResponse>> walletReceipt(
    @Path('payment_ref') String paymentRef,
  );

  /// DONG 2026-01-10
  ///
  /// สำหรับเช็ค Status ที่ [topupRequest]
  @GET('/wallet/payment/status/{payment_ref}')
  Future<HttpResponse<TopupRequestResponse>> checkWalletStatusPayment(
    @Path('payment_ref') String paymentRef,
  );

  /// DONG 2026-01-10
  ///
  /// สำหรับสร้าง request เติมเงิน
  @POST('/wallet/topup-request')
  Future<HttpResponse<TopupRequestResponse>> topupRequest(
    @Body() TopupRequest body,
  );

  @POST('/referrals')
  Future<HttpResponse<BaseResponse?>> saveReferral(
    @Body() CustomerCredential body,
  );

  /// DONG 2025-12-05
  ///
  /// API สำหรับ verify OTP ที่กรอกเข้ามา
  @POST('/customer/verify-otp')
  Future<HttpResponse<VerifyOTPResponse?>> verifyOTP(
    @Body() VerifyOTP body,
  );

  /// DONG 2025-12-05
  ///
  /// API ส่ง OTP ไปที่ User
  @POST('/customer/request-otp')
  Future<HttpResponse<RequestOTPResponse?>> requestOtp(
    @Body() RequestOTP body,
  );

  /// DONG 2025-12-05
  ///
  /// API สำหรับเช็ค [CustomerCredential.username] ว่ามีในระบบแล้วหรือยัง
  ///
  /// ---
  /// **NOTE** ใช้ model [LoginCustomerResponse] รับ Response แต่จะไม่ได้ข้อมูลอะไรกลับมา
  /// เพราะจะเอาแค่ [LoginCustomerResponse.success] เท่านั้น
  @POST('/customer/check-username')
  Future<HttpResponse<LoginCustomerResponse?>> checkUsername(
    @Body() CustomerCredential body,
  );

  /// DONG 2025-12-05
  ///
  /// fetch ข้อมูล เงินคงเหลือ, coin คงเหลือของ User
  @GET('/customer/{uuid}/credit')
  Future<HttpResponse<CustomerProfileData>> fetchCustomerCredit(
    @Path('uuid') String uuid,
  );

  /// DONG 2026-01-06
  ///
  /// API อัพเดทข้อมูล Profile ของ User
  @PUT('/customer/update-profile')
  Future<HttpResponse<CustomerProfileResponse?>> updateProfile(
    @Body() UpdateProfileRequest body,
  );

  /// DONG 2026-01-27
  ///
  /// API อัพเดทรหัสผ่านของ User
  @PUT('/customer/update-password')
  Future<HttpResponse<BaseResponse>> updatePassword(
    @Body() Map<String, String> body,
  );

  /// DONG 2025-11-24
  ///
  /// API fech profile ของ User ที่ login เข้ามาใช้งาน
  @POST('/customer/profile')
  Future<HttpResponse<CustomerProfileResponse?>> fetchCustomerProfile(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2025-11-17
  ///
  /// API register new customer
  @POST('/customer/register')
  Future<HttpResponse<LoginCustomerResponse?>> register(
    @Body() CustomerCredential credential,
  );

  /// DONG 2025-11-10
  ///
  /// API Login Customer
  ///
  /// ***param*** : [CustomerCredential] กำหนดข้อมูลในการเข้าใช้งานระบบ
  @POST('/customer/login')
  Future<HttpResponse<LoginCustomerResponse?>> login(
    @Body() CustomerCredential credential,
  );

  /// DONG 2025-11-13
  ///
  /// API Fetch รูป Banners
  ///
  /// Query parameters:
  /// - customer_id: String? (UUID ของลูกค้า, nullable)
  @GET('/banners')
  Future<HttpResponse<BannerResponse?>> fetchBanners(
    @Query('customer_id') String? customerId,
  );

  /// DONG 2026-02-17
  ///
  /// API Fetch รูป Banners Highlight
  ///
  /// Query parameters:
  /// - customer_id: String? (UUID ของลูกค้า, nullable)
  @GET('/banners/highlight')
  Future<HttpResponse<BannerHighlightResponse?>> fetchBannersHighlight(
    @Query('customer_id') String? customerId,
  );

  /// DONG 2026-03-08
  ///
  /// API Collect Banner (เก็บคูปองจาก Banner)
  ///
  /// Path parameters:
  /// - banner_id: int (ID ของ Banner)
  ///
  /// Body parameters:
  /// - customer_id: String (UUID ของลูกค้า)
  ///
  /// Response HTTP Codes:
  /// - 200: สำเร็จ
  /// - 400: ข้อมูลไม่ถูกต้อง
  /// - 500: เกิดข้อผิดพลาดภายในระบบ
  @POST('/banners/collect/{banner_id}')
  Future<HttpResponse<BannerCollectResponse>> collectBanner(
    @Path('banner_id') int bannerId,
    @Body() BannerCollectRequest body,
  );

  /// DONG 2025-11-10
  ///
  /// API fetch Content OnBoarding
  @GET('/introductions')
  Future<HttpResponse<List<IntroductionsResponse>?>> fetchIntroductions();

  /// DONG 2026-03-19
  ///
  /// API fetch รายการ Festive Event (Lucky Scan campaigns)
  ///
  /// Response:
  /// - has_event: bool (มี event หรือไม่)
  /// - data: List<FestiveData> (รายการ campaign)
  @GET('/festive/index')
  Future<HttpResponse<FestiveIndexResponse>> fetchFestiveIndex();

  /// DONG 2026-03-20
  ///
  /// API fetch ประวัติการร่วมกิจกรรม Lucky Scan ของลูกค้า
  ///
  /// Body:
  /// - customer_id: String (uuid)
  ///
  /// Response: FestiveHistoryResponse
  /// - data: List<FestiveHistoryData> (ประวัติ)
  @POST('/festive/history')
  Future<HttpResponse<FestiveHistoryResponse>> fetchFestiveHistory(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2026-03-20
  ///
  /// API สแกน QR Lucky Draw
  ///
  /// Body:
  /// - customer_id: String (uuid)
  /// - qr_code: String (QR code URL)
  ///
  /// Response: LuckyDrawResponse
  /// - type: "won" / "lose" / "limit_reached" / "scanned_today"
  /// - status: "error" (กรณี QR ไม่ถูกต้อง)
  @POST('/lucky/draw')
  Future<HttpResponse<LuckyDrawResponse>> postLuckyDraw(
    @Body() Map<String, dynamic> body,
  );

  /// DONG 2026-03-29
  ///
  /// API fetch รายการ Payment Methods ที่รองรับในระบบ
  ///
  /// Response:
  /// - PaymentMethodResponse with list of payments (code, name, image)
  @GET('/payment-methods')
  Future<HttpResponse<PaymentMethodResponse>> fetchPaymentMethods();

  /// DONG 2026-04-12
  ///
  /// API ตรวจสอบความถูกต้องของ Token
  ///
  /// Response HTTP Codes:
  /// - 200: Token ถูกต้อง (returns message and client info)
  /// - 401: Token ไม่ถูกต้องหรือหมดอายุ
  @GET('/check-token')
  Future<HttpResponse<CheckTokenResponse>> checkToken();

  /// DONG 2026-05-02
  ///
  /// API fetch ประวัติการสั่งซื้อของลูกค้า
  ///
  /// Path Parameters:
  /// - customerId: String (uuid)
  ///
  /// Query Parameters:
  /// - page: int (หน้าที่ต้องการดึง)
  ///
  /// Response:
  /// - OrderHistoryResponse with list of orders (machine_order / coupon_package_order) and pagination meta
  @GET('/customer/{customerId}/order-history')
  Future<HttpResponse<OrderHistoryResponse>> fetchOrderHistory(
    @Path('customerId') String customerId,
    @Query('page') int page,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
  );
}
