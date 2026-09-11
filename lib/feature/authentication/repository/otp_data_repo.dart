import 'package:browny_applications_new/core/data/remote/models/request/request_otp.dart';
import 'package:browny_applications_new/core/data/remote/models/request/verify_otp.dart';
import 'package:browny_applications_new/core/data/remote/models/response/request_otp_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/verify_otp_response.dart';
import 'package:browny_applications_new/core/data/repo/app_repository.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:dio/dio.dart';

mixin OTPDataSourceMixin {
  Future<RepoResult<VerifyOTPResponse>> verifyOTP(VerifyOTP data);

  Future<RepoResult<RequestOTPResponse>> requestOTP(RequestOTP data);
}

class OTPDataRepo extends AppRepository with OTPDataSourceMixin {
  // forward ให้ constructor ของ AppRepository เพื่อเปิดช่องให้ inject
  // fake AppClient/AppLocalStorage ใน unit test ได้ (ค่า default เหมือนเดิมทุกจุด
  // เพราะเป็น optional parameter ที่ AppRepository จัดการ fallback เป็น
  // singleton จริงอยู่แล้วเมื่อไม่ส่งมา)
  OTPDataRepo({super.appClient, super.localStorage, super.secureStorage});

  @override
  Future<RepoResult<RequestOTPResponse>> requestOTP(RequestOTP data) async {
    try {
      final response = await requireRemote.requestOtp(data);

      if (!response.isSuccessful) {
        return RepoResult.empty(
          error: Exception(response.data?.message),
        );
      }

      return RepoResult.success(data: response.data!);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }

  @override
  Future<RepoResult<VerifyOTPResponse>> verifyOTP(VerifyOTP data) async {
    try {
      final response = await requireRemote.verifyOTP(data);

      if (!response.isSuccessful) {
        return RepoResult.empty(
          error: Exception(response.data?.message),
        );
      }

      return RepoResult.success(data: response.data!);
    } on DioException catch (dioEx) {
      if (dioEx.response!.isUnauthorized) {
        return RepoResult.empty(error: OTPUnauthorized());
      }
      if (dioEx.response!.isNotFound || dioEx.response!.isGone) {
        return RepoResult.empty(error: OTPExpired());
      }
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    }
  }
}
