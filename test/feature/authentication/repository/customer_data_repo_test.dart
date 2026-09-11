import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/core/data/cache/app_local_secure_storage.dart';
import 'package:browny_applications_new/core/data/cache/app_local_storage.dart';
import 'package:browny_applications_new/core/data/remote/app_client.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_available_count_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/customer_profile_response.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

/// Fake ของ [AppClient] ใช้ `noSuchMethod` แทนการ override ครบทั้ง 64 เมธอด
/// (เหมือน mock ที่ mockito generate ให้) - override เฉพาะ endpoint ที่
/// [CustomerDataRepo.fetchProfile] เรียกใช้จริง ตัวอื่นถ้าถูกเรียกโดยไม่ตั้งใจ
/// จะ throw ทันทีเพื่อให้ test fail ชัดเจนแทนที่จะเงียบ
class FakeAppClient implements AppClient {
  FakeAppClient({
    this.fetchCustomerProfileResult,
    this.fetchCustomerCreditResult,
    this.fetchCouponAvailableCountResult,
  });

  final HttpResponse<CustomerProfileResponse?> Function(
    Map<String, dynamic> body,
  )?
  fetchCustomerProfileResult;

  final HttpResponse<CustomerProfileData> Function(String uuid)?
  fetchCustomerCreditResult;

  final HttpResponse<CouponAvailableCountResponse> Function(String uuid)?
  fetchCouponAvailableCountResult;

  @override
  Future<HttpResponse<CustomerProfileResponse?>> fetchCustomerProfile(
    Map<String, dynamic> body,
  ) async {
    return fetchCustomerProfileResult!(body);
  }

  @override
  Future<HttpResponse<CustomerProfileData>> fetchCustomerCredit(
    String uuid,
  ) async {
    return fetchCustomerCreditResult!(uuid);
  }

  @override
  Future<HttpResponse<CouponAvailableCountResponse>> fetchCouponAvailableCount(
    String uuid,
  ) async {
    return fetchCouponAvailableCountResult!(uuid);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'FakeAppClient.${invocation.memberName} ไม่ได้ถูก stub ไว้ - '
      'fetchProfile ไม่ควรเรียก endpoint นี้ในเคสนี้',
    );
  }
}

/// Fake ของ [AppLocalStorage] เก็บข้อมูลใน memory แทน Hive จริง
class FakeAppLocalStorage implements AppLocalStorage {
  final Map<String, dynamic> _store = {};
  final List<String> writtenKeys = [];

  @override
  R? read<R>(String key, {R? defaultValue}) {
    return (_store[key] as R?) ?? defaultValue;
  }

  @override
  void write<W>({required String key, required W value}) {
    _store[key] = value;
    writtenKeys.add(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'FakeAppLocalStorage.${invocation.memberName} ไม่ได้ถูก stub ไว้',
    );
  }
}

/// Fake ของ [AppLocalSecureStorage] - fetchProfile ไม่แตะ secure storage เลย
/// ดังนั้นทุก method จะ throw ถ้าถูกเรียกโดยไม่ตั้งใจ
class FakeAppLocalSecureStorage implements AppLocalSecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'FakeAppLocalSecureStorage.${invocation.memberName} ไม่ควรถูกเรียกจาก fetchProfile',
    );
  }
}

HttpResponse<T> httpResponse<T>(T data, {int statusCode = 200}) {
  return HttpResponse<T>(
    data,
    Response(
      requestOptions: RequestOptions(path: '/customer/profile'),
      statusCode: statusCode,
    ),
  );
}

/// Regression tests for the "CustomerDataRepo.fetchProfile - Null check
/// operator used on a null value" crash (Crashlytics issue #3).
void main() {
  group('CustomerDataRepo.fetchProfile - local cache path (id ว่าง)', () {
    test(
      'cache เก่าไม่มี id -> คืน RepoResult.empty() แทนการ crash ด้วย null check',
      () async {
        final localStorage = FakeAppLocalStorage()
          ..write(
            key: kCustomerProfile,
            // จำลอง cache เก่าที่ไม่มี id (schema เปลี่ยน/ข้อมูลไม่สมบูรณ์)
            value: CustomerProfileData(name: 'no-id-user'),
          );

        final repo = CustomerDataRepo(
          appClient: FakeAppClient(),
          localStorage: localStorage,
          secureStorage: FakeAppLocalSecureStorage(),
        );

        final result = await repo.fetchProfile('');

        expect(result.isEmpty, isTrue);
      },
    );

    test('cache มี id ที่ใช้ได้ -> ไปต่อจนดึง profile จาก remote สำเร็จ', () async {
      final localStorage = FakeAppLocalStorage()
        ..write(
          key: kCustomerProfile,
          value: CustomerProfileData(id: 'cached-id-123'),
        );

      final repo = CustomerDataRepo(
        appClient: FakeAppClient(
          fetchCustomerProfileResult: (body) {
            expect(body['id'], 'cached-id-123');
            return httpResponse(
              CustomerProfileResponse(
                data: CustomerProfileData(id: 'cached-id-123'),
                message: null,
                errorType: null,
              ),
            );
          },
          fetchCustomerCreditResult: (uuid) =>
              httpResponse(CustomerProfileData(id: uuid)),
          fetchCouponAvailableCountResult: (uuid) =>
              httpResponse(CouponAvailableCountResponse()),
        ),
        localStorage: localStorage,
        secureStorage: FakeAppLocalSecureStorage(),
      );

      final result = await repo.fetchProfile('');

      expect(result.isSuccess, isTrue);
      expect(result.data.data.id, 'cached-id-123');
    });
  });

  group(
    'CustomerDataRepo.fetchProfile - remote response path (id ไม่ว่าง)',
    () {
      test(
        'HTTP 200 แต่ body เป็น null -> คืน RepoResult.empty() แทนการ crash ด้วย null check',
        () async {
          final repo = CustomerDataRepo(
            appClient: FakeAppClient(
              fetchCustomerProfileResult: (body) => httpResponse<CustomerProfileResponse?>(
                null,
              ),
            ),
            localStorage: FakeAppLocalStorage(),
            secureStorage: FakeAppLocalSecureStorage(),
          );

          final result = await repo.fetchProfile('some-customer-id');

          expect(result.isEmpty, isTrue);
        },
      );

      test('happy path: response มีข้อมูลครบ -> merge credit และ coupon count เข้า profile', () async {
        final localStorage = FakeAppLocalStorage();

        final repo = CustomerDataRepo(
          appClient: FakeAppClient(
            fetchCustomerProfileResult: (body) => httpResponse(
              CustomerProfileResponse(
                data: CustomerProfileData(id: 'user-1', name: 'Dong'),
                message: null,
                errorType: null,
              ),
            ),
            fetchCustomerCreditResult: (uuid) => httpResponse(
              CustomerProfileData(creditBalance: '100.00', brownyCoin: '5'),
            ),
            fetchCouponAvailableCountResult: (uuid) => httpResponse(
              CouponAvailableCountResponse(
                data: CouponAvailableCountData(total: 3),
              ),
            ),
          ),
          localStorage: localStorage,
          secureStorage: FakeAppLocalSecureStorage(),
        );

        final result = await repo.fetchProfile('user-1');

        expect(result.isSuccess, isTrue);
        expect(result.data.data.id, 'user-1');
        expect(result.data.data.creditBalance, '100.00');
        expect(result.data.data.brownyCoin, '5');
        expect(result.data.data.totalCoupons, 3);
        // ต้อง save ลง local storage ด้วยหลังดึงสำเร็จ
        expect(localStorage.writtenKeys, contains(kCustomerProfile));
      });
    },
  );
}
