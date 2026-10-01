import 'package:browny_applications_new/core/data/remote/models/api_model_index.dart';
import 'package:browny_applications_new/core/data/repo/app_repository.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:dio/dio.dart';

class ContactChangeRepo extends AppRepository {
  ContactChangeRepo({
    super.appClient,
    super.localStorage,
    super.secureStorage,
  });

  final CustomerDataRepo _customerDataRepo = CustomerDataRepo();

  Future<RepoResult<ContactChangeResponse>> requestChange(
    ContactChangeRequest request,
  ) async {
    try {
      final response = await requireRemote.requestContactChange(request);
      if (response.isSuccessful && response.data.success) {
        return RepoResult.success(data: response.data);
      }
      return RepoResult.error(
        error: Exception(response.data.message ?? 'Request contact change failed'),
      );
    } on DioException catch (dioEx) {
      return RepoResult.error(error: _mapDioError(dioEx));
    } catch (e) {
      return RepoResult.error(error: Exception(e.toString()));
    }
  }

  Future<RepoResult<ContactChangeResponse>> verifyOld(
    ContactChangeOtpRequest request,
  ) async {
    try {
      final response = await requireRemote.verifyOldContactChange(request);
      if (response.isSuccessful && response.data.success) {
        return RepoResult.success(data: response.data);
      }
      return RepoResult.error(
        error: Exception(response.data.message ?? 'Verify old OTP failed'),
      );
    } on DioException catch (dioEx) {
      return RepoResult.error(error: _mapDioError(dioEx));
    } catch (e) {
      return RepoResult.error(error: Exception(e.toString()));
    }
  }

  Future<RepoResult<ContactChangeResponse>> confirm(
    ContactChangeOtpRequest request,
  ) async {
    try {
      final response = await requireRemote.confirmContactChange(request);
      if (response.isSuccessful && response.data.success) {
        await _syncLocalProfile(response.data.data);
        return RepoResult.success(data: response.data);
      }
      return RepoResult.error(
        error: Exception(response.data.message ?? 'Confirm contact change failed'),
      );
    } on DioException catch (dioEx) {
      return RepoResult.error(error: _mapDioError(dioEx));
    } catch (e) {
      return RepoResult.error(error: Exception(e.toString()));
    }
  }

  Future<void> _syncLocalProfile(ContactChangeData? data) async {
    if (data == null) return;

    final local = await _customerDataRepo.customerProfileData();
    if (!local.isSuccess) return;

    final updated = local.data.copyWith(
      email: data.email ?? local.data.email,
      phone: data.phone ?? local.data.phone,
    );
    _customerDataRepo.saveLocalProfile(updated);
  }

  Exception _mapDioError(DioException dioEx) {
    if (dioEx.response?.isDuplicated == true) {
      return UserDuplicated();
    }

    String? message;
    try {
      final body = dioEx.response?.data;
      if (body is Map<String, dynamic>) {
        message = body['message']?.toString();
      } else if (body is Map) {
        message = body['message']?.toString();
      }
    } catch (_) {}

    if (message != null && message.isNotEmpty) {
      return Exception(message);
    }

    if (dioEx.response?.isUnprocessable == true) {
      return Unprocessable(message);
    }

    return Exception(dioEx.message ?? 'Request failed');
  }
}
