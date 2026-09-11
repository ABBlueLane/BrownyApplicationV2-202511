import 'package:browny_applications_new/core/env/app_evnironment.dart';
import 'package:browny_applications_new/core/providers/customer_provider.dart';
import 'package:browny_applications_new/core/viewmodels/app_preferences.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Fake ของ [AppEvnironment] (abstract) สำหรับ unit test - ไม่แตะ network/Hive
/// จริงใดๆ (loadEnv ไม่ทำอะไร, currentUser คืนค่า [CustomerProvider] ที่ inject มา)
class FakeAppEnvironment extends AppEvnironment {
  FakeAppEnvironment({required CustomerProvider customerProvider})
    : _customerProvider = customerProvider,
      super(appPreferences: AppPreferences());

  final CustomerProvider _customerProvider;

  @override
  CustomerProvider get currentUser => _customerProvider;

  @override
  Future<void> loadEnv() async {}

  @override
  String get laravelAppKey => 'test-laravel-app-key';
}

/// Regression tests for the "Provider._inheritedElementOf - Null check
/// operator used on a null value" crash (Crashlytics issue #2).
///
/// ก่อนแก้ [AppViewModel.currentCustomerProvider] เป็น getter ที่เรียก
/// `context.read<CustomerProvider>()` ใหม่ทุกครั้ง - ถ้าเรียกหลังจาก context
/// ที่สร้าง ViewModel ถูก unmount ไปแล้ว (เช่น เรียกหลัง await ตอนที่หน้าจอถูก
/// pop) จะ throw ทันที ดู MachineTransactionViewmodel.fetchPaymentMethod
void main() {
  Widget buildProviderTree({
    required AppEvnironment environment,
    required CustomerProvider customerProvider,
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppEvnironment>.value(value: environment),
        ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
      ],
      child: child,
    );
  }

  testWidgets(
    'currentCustomerProvider still returns the right provider after the '
    'creating context is unmounted',
    (tester) async {
      final customerProvider = CustomerProvider();
      final environment = FakeAppEnvironment(customerProvider: customerProvider);
      late AppViewModelObscureHandler viewModel;

      await tester.pumpWidget(
        MaterialApp(
          home: buildProviderTree(
            environment: environment,
            customerProvider: customerProvider,
            child: Builder(
              builder: (context) {
                viewModel = AppViewModelObscureHandler(context: context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // จำลองหน้าที่สร้าง ViewModel ถูก pop/dispose ไปแล้ว โดยแทนที่ widget
      // tree ทั้งหมดด้วย tree ใหม่ที่ไม่มี Provider เดิมอยู่เลย
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(() => viewModel.currentCustomerProvider, returnsNormally);
      expect(viewModel.currentCustomerProvider, same(customerProvider));
    },
  );

  testWidgets(
    'currentCustomerProvider returns the provider while context is still mounted',
    (tester) async {
      final customerProvider = CustomerProvider();
      final environment = FakeAppEnvironment(customerProvider: customerProvider);
      late AppViewModelObscureHandler viewModel;

      await tester.pumpWidget(
        MaterialApp(
          home: buildProviderTree(
            environment: environment,
            customerProvider: customerProvider,
            child: Builder(
              builder: (context) {
                viewModel = AppViewModelObscureHandler(context: context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(viewModel.currentCustomerProvider, same(customerProvider));
    },
  );
}
