import 'dart:async';

import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/core/data/remote/models/request/change_password_request.dart';
import 'package:browny_applications_new/core/data/remote/models/request/referral_status_request.dart';
import 'package:browny_applications_new/core/data/remote/models/request/social_login_request.dart';
import 'package:browny_applications_new/core/data/remote/models/request/customer_credential.dart';
import 'package:browny_applications_new/core/data/remote/models/response/base_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/referral_status_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/check_token_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_available_count_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/customer_profile_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/customer_qr_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/login_customer_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/repository/otp_data_repo.dart';
import 'package:dio/dio.dart';

/// มิกซ์อินสำหรับจัดการข้อมูลการเข้าสู่ระบบ
mixin CustomerDataSourceMixin {
  Future<RepoResult<CustomerQRResponse>> fetchCustomerQR(String uuid);

  Future<RepoResult<BaseResponse>> saveReferral(CustomerCredential data);

  Future<RepoResult<bool>> checkUsernameExists(String username);

  FutureOr<RepoResult<CustomerProfileData>> customerProfileData();

  /// ฟังก์ชันดึง coin และ wallet ตาม [id] ของ user ที่ login เข้ามา
  Future<RepoResult<CustomerProfileData>> fetchCustomerCredit(String id);

  /// ฟังก์ชันดึงจำนวนคูปองที่มีอยู่ตาม [uuid]
  Future<RepoResult<CouponAvailableCountData>> fetchCouponAvailableCount(
    String uuid,
  );

  /// ฟังก์ชันดึงข้อมูลอื่นๆ ของ [id] ที่ส่งเข้ามา เช่น [fetchCustomerCredit], [fetchCouponAvailableCount]
  /// จะดึงข้อมูล Profile จาก Locale [customerProfileData] เท่านั้น
  /// - [id] จะได้จากการ [login] สำเร็จเท่านั้น
  Future<RepoResult<CustomerProfileData>> fetchProfileInfo(String id);

  /// ฟังก์ชันดึงข้อมูล Profile ของ [id] ที่ส่งเข้ามา
  /// - [id] จะได้จากการ [login] สำเร็จเท่านั้น
  Future<RepoResult<CustomerProfileResponse>> fetchProfile(String id);

  /// ฟังก์ชันเข้าสู่ระบบ รับ username และ password
  /// [username] - ชื่อผู้ใช้ที่ต้องการเข้าสู่ระบบ ใช้สำหรับระบุตัวตนของผู้ใช้
  /// [password] - รหัสผ่านของผู้ใช้ ใช้สำหรับตรวจสอบความถูกต้องในการเข้าสู่ระบบ
  /// คืนค่าเป็น Future ของ RepoResult ที่มี LoginCustomerResponse
  Future<RepoResult<LoginCustomerResponse>> login({
    required String username, // ชื่อผู้ใช้ที่ต้องการเข้าสู่ระบบ
    required String password, // รหัสผ่านของผู้ใช้
  });

  /// ฟังก์ชันเข้าสู่ระบบด้วย Social Login (Google, Facebook)
  /// [request] - SocialLoginRequest ที่มีข้อมูล provider, appId, name, email, profileImage
  /// คืนค่าเป็น Future ของ RepoResult ที่มี LoginCustomerResponse
  Future<RepoResult<LoginCustomerResponse>> socialLogin(
    SocialLoginRequest request,
  );

  Future<RepoResult<LoginCustomerResponse>> register(
    CustomerCredential credential,
  );

  /// ฟังก์ชันอัพเดทรหัสผ่านของผู้ใช้
  /// [data] - Map ที่มี 'id' (UUID ของผู้ใช้) และ 'new_password' (รหัสผ่านใหม่)
  /// คืนค่าเป็น Future ของ RepoResult bool ที่บอกว่าอัพเดทสำเร็จหรือไม่
  Future<RepoResult<bool>> updatePassword(Map<String, String> data);

  /// ฟังก์ชันเปลี่ยนรหัสผ่านของผู้ใช้
  /// - id: String (customer_id UUID)
  /// - old_password: String (รหัสผ่านเดิม)
  /// - new_password: String (รหัสผ่านใหม่)
  Future<RepoResult<bool>> changePassword(ChangePasswordRequest data);

  /// ฟังก์ชันตรวจสอบความถูกต้องของ Token
  /// คืนค่า [CheckTokenResponse] ที่มี client version และ status
  /// - 200: Token ถูกต้อง
  /// - 401: Token ไม่ถูกต้องหรือหมดอายุ
  Future<RepoResult<CheckTokenResponse>> checkToken();

  /// ตรวจสอบสถานะระบบแนะนำเพื่อน
  Future<RepoResult<ReferralStatusResponse>> fetchReferralStatus({
    String? phone,
  });
}

/// คลาสสำหรับจัดการรีโพซิทอรีการเข้าสู่ระบบ
class CustomerDataRepo extends OTPDataRepo with CustomerDataSourceMixin {
  @override
  Future<RepoResult<CustomerQRResponse>> fetchCustomerQR(String uuid) async {
    try {
      final response = await requireRemote.fetchCustomerQRCode(uuid);
      if (!response.isSuccessful) {
        return RepoResult.empty();
      }
      return RepoResult.success(data: response.data);
    } catch (e) {
      return RepoResult.empty();
    }
  }

  @override
  Future<RepoResult<BaseResponse>> saveReferral(CustomerCredential data) async {
    try {
      final saveReferralResponse = await requireRemote.saveReferral(data);
      return RepoResult.dependOn(saveReferralResponse.data);
    } on DioException catch (dioEx) {
      if (dioEx.response!.isNotFound) {
        return RepoResult.empty(error: UserNotFound());
      }
      if (dioEx.response!.isDuplicated) {
        return RepoResult.empty(error: UserDuplicated());
      }
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<bool>> checkUsernameExists(String username) async {
    try {
      final checkUserResponse = await requireRemote.checkUsername(
        CustomerCredential(username: username, password: ''),
      );

      return RepoResult.success(data: checkUserResponse.data!.success);
    } on DioException catch (dioEx) {
      if (dioEx.response!.isDuplicated) {
        return RepoResult.empty(error: UserDuplicated());
      }
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }

    return RepoResult.empty();
  }

  @override
  FutureOr<RepoResult<CustomerProfileData>> customerProfileData() {
    try {
      final readResult = requireLocalStorage.read<CustomerProfileData>(
        kCustomerProfile,
      );

      return RepoResult.dependOn(readResult);
    } catch (e) {
      return RepoResult.error(error: Exception(e.toString()));
    }
  }

  @override
  Future<RepoResult<CustomerProfileData>> fetchCustomerCredit(String id) async {
    try {
      final creditDataResponse = await requireRemote.fetchCustomerCredit(id);
      // จะสนใจแค่ดึงได้หรือไม่
      return RepoResult.dependOn(creditDataResponse.data);
    } on DioException catch (dioEx) {
      // ถ้าดึงไม่ได้เพราะ id ไม่ถูกจะได้ code 500
      return RepoResult.empty(error: dioEx);
    } on Exception catch (e) {
      // error อื่นๆ
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CouponAvailableCountData>> fetchCouponAvailableCount(
    String uuid,
  ) async {
    try {
      final couponCountResponse = await requireRemote.fetchCouponAvailableCount(
        uuid,
      );
      return RepoResult.dependOn(couponCountResponse.data.data);
    } on DioException catch (dioEx) {
      return RepoResult.empty(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CustomerProfileResponse>> fetchProfile(String id) async {
    try {
      String mId = id;
      CustomerProfileResponse? profileResult;
      if (mId.isEmpty) {
        final localProfileResult = await customerProfileData();
        if (localProfileResult.isEmpty) {
          return RepoResult.empty();
        }

        if (localProfileResult.hasError) {
          return RepoResult.error(error: localProfileResult.error);
        }

        // ข้อมูล cache เก่าอาจไม่มี id (schema เปลี่ยน/ข้อมูลไม่สมบูรณ์)
        // ถ้าไม่มี id ให้ถือว่าไม่มี profile ที่ใช้ต่อได้ แทนที่จะ crash ด้วย !
        final localId = localProfileResult.data.id;
        if (localId == null || localId.isEmpty) {
          return RepoResult.empty();
        }
        mId = localId;
      }

      final response = await requireRemote.fetchCustomerProfile(
        {'id': mId},
      );
      if (response.isSuccessful) {
        profileResult = response.data;

        // response.data ประกาศเป็น nullable (CustomerProfileResponse?) เอง
        // HTTP 2xx ไม่ได้แปลว่า body แปลงเป็น object สำเร็จเสมอไป (เช่น
        // gateway ตอบ 200 แต่ body ว่าง/พัง) ต้องเช็ค null ก่อนใช้งานจริง
        if (profileResult != null) {
          var profile = profileResult.data;

          try {
            // ถ้า fetch profile ได้ จะ fetch coin มาด้วย
            final creditData = await fetchCustomerCredit(mId);

            if (creditData.isSuccess) {
              profile = profile.copyWith(
                creditBalance: creditData.data.creditBalance,
                brownyCoin: creditData.data.brownyCoin,
                coinValue: creditData.data.coinValue,
                currentCoin: creditData.data.currentCoin,
              );

              profileResult = profileResult.copyWith(
                data: profile,
              );
            }

            // fetch coupon available count
            final couponCountData = await fetchCouponAvailableCount(mId);

            if (couponCountData.isSuccess) {
              profile = profile.copyWith(
                couponsRedemption: couponCountData.data.coupons?.redemption,
                couponsDiscount: couponCountData.data.coupons?.discount,
                couponsEVoucher: couponCountData.data.coupons?.eVoucher,
                totalCoupons: couponCountData.data.total,
              );

              profileResult = profileResult.copyWith(
                data: profile,
              );
            }
          } finally {
            saveLocalProfile(profile);
          }
        }
      }

      // คืนค่าตามข้อมูลที่ได้รับจาก response
      return RepoResult.dependOn(profileResult);
    } on DioException catch (dioEx) {
      // ถ้าไม่พบผู้ใช้
      if (dioEx.response?.isNotFound == true) {
        return RepoResult.empty(
          error: UserNotFound(),
        );
      }

      // ถ้าผู้ใช้ไม่ได้รับอนุญาต
      if (dioEx.response?.isUnauthorized == true) {
        return RepoResult.empty(
          error: UserUnauthorized(),
        );
      }
      // เพิ่ม return สำหรับกรณีอื่น ๆ ของ DioException
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      // คืนค่าข้อผิดพลาดอื่น ๆ
      return RepoResult.error(
        error: e,
      );
    }
  }

  @override
  Future<RepoResult<CustomerProfileData>> fetchProfileInfo(
    String id,
  ) async {
    try {
      String mId = id;
      CustomerProfileData? profileDataLocal;
      final localProfileResult = await customerProfileData();
      if (localProfileResult.isEmpty) {
        return RepoResult.empty();
      }

      if (localProfileResult.hasError) {
        return RepoResult.error(error: localProfileResult.error);
      }
      profileDataLocal = localProfileResult.data;
      if (mId.isEmpty) {
        mId = profileDataLocal.id!;
      }

      try {
        // ถ้า fetch profile ได้ จะ fetch coin มาด้วย
        final creditData = await fetchCustomerCredit(mId);

        if (creditData.isSuccess) {
          profileDataLocal = profileDataLocal.copyWith(
            creditBalance: creditData.data.creditBalance,
            brownyCoin: creditData.data.brownyCoin,
            currentCoin: creditData.data.currentCoin,
            coinValue: creditData.data.coinValue,
          );
        }

        // fetch coupon available count
        final couponCountData = await fetchCouponAvailableCount(mId);

        if (couponCountData.isSuccess) {
          profileDataLocal = profileDataLocal.copyWith(
            couponsRedemption: couponCountData.data.coupons?.redemption,
            couponsDiscount: couponCountData.data.coupons?.discount,
            couponsEVoucher: couponCountData.data.coupons?.eVoucher,
            totalCoupons: couponCountData.data.total,
          );
        }
      } finally {
        saveLocalProfile(profileDataLocal!);
      }

      // คืนค่าตามข้อมูลที่ได้รับจาก response
      return RepoResult.dependOn(profileDataLocal.copyWith());
    } on DioException catch (dioEx) {
      // ถ้าไม่พบผู้ใช้
      if (dioEx.response!.isNotFound) {
        return RepoResult.empty(
          error: UserNotFound(),
        );
      }

      // ถ้าผู้ใช้ไม่ได้รับอนุญาต
      if (dioEx.response!.isUnauthorized) {
        return RepoResult.empty(
          error: UserUnauthorized(),
        );
      }
      // เพิ่ม return สำหรับกรณีอื่น ๆ ของ DioException
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      // คืนค่าข้อผิดพลาดอื่น ๆ
      return RepoResult.error(
        error: e,
      );
    }
  }

  /// ฟังก์ชันเข้าสู่ระบบ
  /// [username] - ชื่อผู้ใช้ที่ต้องการเข้าสู่ระบบ ใช้สำหรับระบุตัวตนของผู้ใช้
  /// [password] - รหัสผ่านของผู้ใช้ ใช้สำหรับตรวจสอบความถูกต้องในการเข้าสู่ระบบ
  /// คืนค่าเป็น Future ของ RepoResult ที่มี LoginCustomerResponse
  @override
  Future<RepoResult<LoginCustomerResponse>> login({
    required String username, // ชื่อผู้ใช้ที่ต้องการเข้าสู่ระบบ
    required String password, // รหัสผ่านของผู้ใช้
  }) async {
    try {
      // เรียกใช้งาน remote เพื่อเข้าสู่ระบบด้วยข้อมูลผู้ใช้
      final response = await requireRemote.login(
        CustomerCredential(username: username, password: password),
      );

      // ถ้าเข้าสู่ระบบสำเร็จ
      if (response.isSuccessful) {
        // ถ้า login ด้วย username, password ผ่าน จะ fetch profile มาเก็บไว้
        final fetchProfileResult = await fetchProfile(
          // ใช้ customer id จากการ login
          response.data!.data!.customerId!,
        );

        if (fetchProfileResult.isSuccess) {
          // เขียนข้อมูลผู้ใช้ลง local storage เฉพาะ login, fetch profile ผ่านเท่านั้น
          saveLocalLoginCustomerData(response.data!.data!);

          // คืนค่าความสำเร็จพร้อมข้อมูล
          return RepoResult.success(data: response.data!);
        }
      }

      // คืนค่าตามข้อมูลที่ได้รับจาก response
      return RepoResult.dependOn(response.data);
    } catch (e) {
      // กรณีเกิดข้อผิดพลาดจาก DioException
      if (e is DioException) {
        // ถ้าไม่พบผู้ใช้
        if (e.response!.isNotFound) {
          return RepoResult.empty(
            error: UserNotFound(),
          );
        }

        // ถ้าผู้ใช้ไม่ได้รับอนุญาต
        if (e.response!.isUnauthorized) {
          return RepoResult.empty(
            error: UserUnauthorized(),
          );
        }
      }
      // คืนค่าข้อผิดพลาดอื่น ๆ
      return RepoResult.error(
        error: Exception('Unknown error occurred'),
      );
    }
  }

  /// ฟังก์ชันเข้าสู่ระบบด้วย Social Login (Google, Facebook)
  /// [request] - SocialLoginRequest ที่มีข้อมูล provider, appId, name, email, profileImage
  /// คืนค่าเป็น Future ของ RepoResult ที่มี LoginCustomerResponse
  @override
  Future<RepoResult<LoginCustomerResponse>> socialLogin(
    SocialLoginRequest request,
  ) async {
    try {
      // เรียกใช้งาน remote เพื่อเข้าสู่ระบบด้วย Social Login
      final response = await requireRemote.socialLogin(request);

      // ถ้าเข้าสู่ระบบสำเร็จ
      if (response.isSuccessful) {
        // fetch profile มาเก็บไว้
        final fetchProfileResult = await fetchProfile(
          // ใช้ customer id จากการ login
          response.data!.data!.customerId!,
        );

        if (fetchProfileResult.isSuccess) {
          // เขียนข้อมูลผู้ใช้ลง local storage
          saveLocalLoginCustomerData(response.data!.data!);

          // คืนค่าความสำเร็จพร้อมข้อมูล
          return RepoResult.success(data: response.data!);
        }
      }

      // คืนค่าตามข้อมูลที่ได้รับจาก response
      return RepoResult.dependOn(response.data);
    } catch (e) {
      // กรณีเกิดข้อผิดพลาดจาก DioException
      if (e is DioException) {
        // ถ้าไม่พบผู้ใช้
        if (e.response!.isNotFound) {
          return RepoResult.empty(
            error: UserNotFound(),
          );
        }

        // ถ้าผู้ใช้ไม่ได้รับอนุญาต
        if (e.response!.isUnauthorized) {
          return RepoResult.empty(
            error: UserUnauthorized(),
          );
        }
      }
      // คืนค่าข้อผิดพลาดอื่น ๆ
      return RepoResult.error(
        error: Exception('Unknown error occurred'),
      );
    }
  }

  @override
  Future<RepoResult<LoginCustomerResponse>> register(
    CustomerCredential credential,
  ) async {
    try {
      final response = await requireRemote.register(credential);

      return RepoResult.dependOn(response.data);
    } on DioException catch (dioEx) {
      if (dioEx.response!.isDuplicated) {
        return RepoResult.empty(error: UserDuplicated());
      }
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  void saveLocalLoginCustomerData(LoginCustomerData data) {
    requireLocalStorage.write<LoginCustomerData>(
      key: kCustomerData,
      value: data,
    );
  }

  void saveLocalProfile(CustomerProfileData data) {
    requireLocalStorage.write(
      key: kCustomerProfile,
      value: data,
    );
  }

  @override
  Future<RepoResult<bool>> updatePassword(Map<String, String> data) async {
    try {
      final response = await requireRemote.updatePassword(data);

      if (response.isSuccessful) {
        return RepoResult.success(data: response.data.success);
      }

      return RepoResult.empty();
    } on DioException catch (dioEx) {
      // ถ้าไม่พบผู้ใช้
      if (dioEx.response!.isNotFound) {
        return RepoResult.empty(error: UserNotFound());
      }

      // ถ้าผู้ใช้ไม่ได้รับอนุญาต
      if (dioEx.response!.isUnauthorized) {
        return RepoResult.empty(error: UserUnauthorized());
      }

      if (dioEx.response!.isUnprocessable) {
        return RepoResult.empty(error: Unprocessable());
      }

      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<bool>> changePassword(ChangePasswordRequest data) async {
    try {
      final response = await requireRemote.changePassword(data);

      if (response.isSuccessful) {
        return RepoResult.success(data: response.data.success);
      }

      return RepoResult.empty();
    } on DioException catch (dioEx) {
      // ใส่รหัสผ่านปัจจุบันไม่ถูก
      if (dioEx.response!.isForbidden) {
        return RepoResult.empty(error: ChangePasswordInvalidOldPassword());
      }

      // ใช้รหัสผ่านซ้ำกับปัจจุบัน
      if (dioEx.response!.isUnprocessable) {
        return RepoResult.empty(error: ChangePasswordReused());
      }
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<CheckTokenResponse>> checkToken() async {
    try {
      final response = await requireRemote.checkToken();

      if (!response.isSuccessful) {
        return RepoResult.empty();
      }

      return RepoResult.success(data: response.data);
    } on DioException catch (dioEx) {
      if (dioEx.response?.isUnauthorized == true) {
        return RepoResult.empty(error: UserUnauthorized());
      }
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<ReferralStatusResponse>> fetchReferralStatus({
    String? phone,
  }) async {
    try {
      final response = await requireRemote.fetchReferralStatus(
        ReferralStatusRequest(phone: phone),
      );
      if (!response.isSuccessful) {
        return RepoResult.empty();
      }
      return RepoResult.success(data: response.data);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }
}
