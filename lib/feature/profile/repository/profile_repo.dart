import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/core/data/remote/models/api_model_index.dart';
import 'package:browny_applications_new/core/data/remote/models/request/update_profile_request.dart';
import 'package:browny_applications_new/core/data/remote/models/response/customer_profile_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:dio/dio.dart';

mixin ProfileDataSourceMixin {
  FutureOr<RepoResult<CustomerProfileResponse>> updateProfile(
    UpdateProfileRequest request,
  );
  FutureOr<RepoResult<CustomerProfileData>> logout();
  FutureOr<RepoResult<BirthdayPromoInfoResponse?>> fetchBirthdayPromoInfo();
}

class ProfileRepo extends CustomerDataRepo with ProfileDataSourceMixin {
  final UnmodifiableListView<String> genders = UnmodifiableListView([
    'other',
    'male',
    'female',
  ]);

  @override
  FutureOr<RepoResult<BirthdayPromoInfoResponse?>> fetchBirthdayPromoInfo() async {
    try {
      final response = await requireRemote.fetchBirthdayPromoInfo();
      if (response.isSuccessful) {
        // API คืน null เมื่อ inactive — ใช้ empty เพื่อให้แอป fallback
        if (response.data == null) {
          return RepoResult.empty();
        }
        return RepoResult.success(data: response.data);
      }
      return RepoResult.empty(
        error: Exception(
          'HTTP ${response.response.statusCode}: ${response.response.statusMessage}',
        ),
      );
    } catch (e) {
      return RepoResult.error(error: Exception(e.toString()));
    }
  }

  @override
  FutureOr<RepoResult<CustomerProfileResponse>> updateProfile(
    UpdateProfileRequest request,
  ) async {
    try {
      final response = await requireRemote.updateProfile(request);

      if (response.isSuccessful) {
        final data = response.data;
        if (data != null && data.success) {
          // Update LocalStorage หลังจาก API success
          saveLocalProfile(data.data);
          return RepoResult.success(data: data);
        }
        return RepoResult.empty(
          error: Exception(data?.message ?? 'Update profile failed'),
        );
      }

      return RepoResult.empty(
        error: Exception(
          'HTTP ${response.response.statusCode}: ${response.response.statusMessage}',
        ),
      );
    } on DioException catch (dioEx) {
      if (dioEx.response?.isDuplicated == true) {
        return RepoResult.error(error: UserDuplicated());
      }
      if (dioEx.response?.isUnprocessable == true) {
        String? message;
        try {
          final handler = BaseResponse.fromJson(
            dioEx.response?.data,
          );
          message = handler.errorType;
        } catch (_) {}
        return RepoResult.error(error: Unprocessable(message));
      }
      return RepoResult.empty(error: Unprocessable());
    } catch (e) {
      return RepoResult.error(error: Exception(e.toString()));
    }
  }

  @override
  FutureOr<RepoResult<CustomerProfileData>> logout() async {
    requireLocalStorage.delete(kCustomerProfile);
    await requireSecureStorage.deleteAllSecure();

    final logoutResult = requireLocalStorage.read<CustomerProfileData>(
      kCustomerProfile,
      defaultValue: null,
    );

    if (logoutResult == null) {
      return RepoResult.success(data: CustomerProfileData());
    }

    return RepoResult.error(
      error: Exception(
        'Cannot Logout Profile ${logoutResult.id}',
      ),
    );
  }
}
