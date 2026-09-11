import 'package:browny_applications_new/core/data/remote/models/response/store_detail_response.dart';
import 'package:browny_applications_new/core/providers/customer_provider.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/articles/screens/article_detail_page.dart';
import 'package:browny_applications_new/feature/articles/screens/articles_page.dart';
import 'package:browny_applications_new/feature/authentication/screen/biometric_page.dart';
import 'package:browny_applications_new/feature/authentication/screen/app_pin_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/authentication_viewmodel.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/pin_biometric_viewmodel.dart';
import 'package:browny_applications_new/feature/coin/screens/coin_history_page.dart';
import 'package:browny_applications_new/feature/coin/screens/coin_page.dart';
import 'package:browny_applications_new/feature/coin/viewmodel/coin_viewmodel.dart';
import 'package:browny_applications_new/feature/contacts/models/contact_model.dart';
import 'package:browny_applications_new/feature/contacts/screens/contact_page.dart';
import 'package:browny_applications_new/feature/home/screens/app_notifications_page.dart';
import 'package:browny_applications_new/feature/home/viewmodel/home_page_viewmodel.dart';
import 'package:browny_applications_new/feature/lucky_scan/screens/lucky_mockup.dart';
import 'package:browny_applications_new/feature/lucky_scan/screens/lucky_scan_page.dart';
import 'package:browny_applications_new/feature/transactions/models/customer_coupon_model.dart';
import 'package:browny_applications_new/feature/transactions/screens/history_transaction_page.dart';
import 'package:browny_applications_new/feature/update/screen/force_update_page.dart';
import 'package:browny_applications_new/feature/map/screens/map_page.dart';
import 'package:browny_applications_new/feature/map/screens/store_detail_page.dart';
import 'package:browny_applications_new/feature/profile/screen/change_contact_page.dart';
import 'package:browny_applications_new/feature/profile/screen/my_profile_and_preferences_page.dart';
import 'package:browny_applications_new/feature/profile/viewmodel/change_contact_viewmodel.dart';
import 'package:browny_applications_new/feature/scaner/viewmodel/scanner_viewmodel.dart';
import 'package:browny_applications_new/feature/transactions/screens/available_payment_method_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_selected_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/purchase_coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/machines/machine_status_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/machines/machine_transaction_page_2.dart';
import 'package:browny_applications_new/feature/transactions/screens/receipt_machine_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/receipt_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/transaction_selected_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/coupon_voucher_selected_viewmodel_delegate.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/purchase_coupon_viewmodel_delegate.dart';
import 'package:browny_applications_new/feature/home/screens/home_page.dart';
import 'package:browny_applications_new/feature/invit_friend/screen/invit_friend_page.dart';
import 'package:browny_applications_new/feature/onboarding/screen/onboarding_page.dart';
import 'package:browny_applications_new/feature/authentication/screen/authentication_page.dart';
import 'package:browny_applications_new/feature/profile/screen/profile_page.dart';
import 'package:browny_applications_new/feature/scaner/screen/scanner_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';
import 'package:browny_applications_new/feature/wallet/screen/payment_sucess_page.dart';
import 'package:browny_applications_new/feature/wallet/screen/show_qr_promptpay_page.dart';
import 'package:browny_applications_new/feature/wallet/screen/wallet_page.dart';
import 'package:browny_applications_new/feature/transactions/models/machine_program_model.dart';
import 'package:browny_applications_new/feature/wallet/viewmodel/wallet_viewmodel.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter({
    required this.initialLocation,
  });

  final String initialLocation;

  late final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    // initialLocation: RegistrationPage.pagePath,
    debugLogDiagnostics: true, // Enable debug logs
    routes: [
      GoRoute(
        path: OnBoardingPage.pagePath,
        name: OnBoardingPage.pageName,
        builder: (context, state) => const OnBoardingPage(),
      ),
      GoRoute(
        path: HomePage.pagePath,
        name: HomePage.pageName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppNotificationsPage.pagePath,
        name: AppNotificationsPage.pageName,
        builder: (context, state) => const AppNotificationsPage(),
      ),
      GoRoute(
        path: AuthenticationPage.pagePath,
        name: AuthenticationPage.pageName,
        builder: (context, state) {
          final extra = state.extra as Map<Type, dynamic>?;
          final authenProcess = extra?[AuthenProcess];
          return AuthenticationPage(authenProcess: authenProcess);
        },
      ),
      GoRoute(
        path: ProfilePage.pagePath,
        name: ProfilePage.pageName,
        builder: (context, state) {
          bool isEditing = false;
          try {
            final extra = state.extra as Map<String, dynamic>?;
            isEditing = extra?[ProfilePage.kFirstSignup];
          } catch (_) {}
          return ProfilePage(isFirstSignup: isEditing);
        },
      ),
      GoRoute(
        path: MyProfileAndPreferencesPage.pagePath,
        name: MyProfileAndPreferencesPage.pageName,
        builder: (context, state) {
          return MyProfileAndPreferencesPage();
        },
      ),
      GoRoute(
        path: ChangeContactPage.pagePath,
        name: ChangeContactPage.pageName,
        builder: (context, state) {
          ChangeContactField field = ChangeContactField.email;
          try {
            final extra = state.extra as Map<String, dynamic>?;
            field = extra?[ChangeContactPage.kField] as ChangeContactField? ??
                ChangeContactField.email;
          } catch (_) {}
          return ChangeContactPage(field: field);
        },
      ),
      GoRoute(
        path: CreateAppPinPage.pagePath,
        name: CreateAppPinPage.pageName,
        builder: (context, state) {
          bool implementBackButton = false;
          bool isFirstSignup = false;
          PinBiometricPross process;
          try {
            final extra = state.extra as Map<String, dynamic>?;
            implementBackButton = extra?[CreateAppPinPage.kImplementBackButton];
            isFirstSignup = extra?[CreateAppPinPage.kFirstSignup];
          } catch (_) {}
          try {
            final extra = state.extra as Map<String, dynamic>?;
            // {String, Map<Type, PinBiometricPross>}
            process =
                extra?[CreateAppPinPage
                    .kPinBiometricProcess][PinBiometricPross];
          } catch (ignore) {
            return Scaffold(
              body: Center(
                child: AppText(
                  'PIN Page needs PinBiometricPross',
                  style: context.textTheme.labelLarge!.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            );
          }

          return CreateAppPinPage(
            implementBackButton: implementBackButton,
            isFirstSignup: isFirstSignup,
            process: process,
          );
        },
      ),
      GoRoute(
        path: BiometricPage.pagePath,
        name: BiometricPage.pageName,
        builder: (context, state) {
          bool isFirstSignup = false;
          try {
            final extra = state.extra as Map<String, dynamic>?;
            isFirstSignup = extra?[BiometricPage.kFirstSignup];
          } catch (_) {}
          return BiometricPage(
            isFirstSignup: isFirstSignup,
          );
        },
      ),
      GoRoute(
        path: WalletPage.pagePath,
        name: WalletPage.pageName,
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: ShowQRPromptpayPage.pagePath,
        name: ShowQRPromptpayPage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as WalletViewModel;
          return ShowQRPromptpayPage(viewModel: viewModel);
        },
      ),
      GoRoute(
        path: PaymentSuccessPage.pagePath,
        name: PaymentSuccessPage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as WalletViewModel;
          return PaymentSuccessPage(
            viewmodel: viewModel,
          );
        },
      ),
      GoRoute(
        path: ScannerPage.pagePath,
        name: ScannerPage.pageName,
        builder: (context, state) {
          if (context.read<CustomerProvider>().current.isGuest) {
            return AuthenticationPage(
              authenProcess: AuthenProcess.login,
            );
          }
          int initIndex = 0;
          ScannerProcess process = ScannerProcess.machine;
          try {
            final listExtra = state.extra as List<Object>;
            initIndex = listExtra[0] as int;
            process = listExtra[1] as ScannerProcess;
          } catch (_) {}
          return ScannerPage(
            initialIndex: initIndex,
            process: process,
          );
        },
      ),
      GoRoute(
        path: InvitFriendPage.pagePath,
        name: InvitFriendPage.pageName,
        builder: (context, state) => const InvitFriendPage(),
      ),
      GoRoute(
        path: CoinPage.pagePath,
        name: CoinPage.pageName,
        builder: (context, state) {
          if (context.read<CustomerProvider>().current.isGuest) {
            return AuthenticationPage(
              authenProcess: AuthenProcess.login,
            );
          }
          return const CoinPage();
        },
      ),
      GoRoute(
        path: CoinHistoryPage.pagePath,
        name: CoinHistoryPage.pageName,
        builder: (context, state) {
          final viewmodel = state.extra as CoinViewmModel;
          return CoinHistoryPage(viewmodel: viewmodel);
        },
      ),
      GoRoute(
        path: CouponVoucherPage.pagePath,
        name: CouponVoucherPage.pageName,
        builder: (context, state) {
          CouponVoucherState couponState = CouponVoucherState.purshasing;
          String? autoCollectQRData;
          MachineProgramModel? machineProgram;
          try {
            List<Object?> list = state.extra as List<Object?>;
            couponState = list[0] as CouponVoucherState;
            if (list.length > 1) {
              autoCollectQRData = list[1] as String?;
            }
            if (list.length > 2) {
              machineProgram = list[2] as MachineProgramModel?;
            }
          } catch (_) {
            rethrow;
          }
          return CouponVoucherPage(
            state: couponState,
            autoCollectQRData: autoCollectQRData,
            machineProgram: machineProgram,
          );
        },
      ),
      GoRoute(
        path: CouponVoucherSelected.pagePath,
        name: CouponVoucherSelected.pageName,
        builder: (context, state) {
          final viewModel =
              state.extra as CouponVoucherSelectedViewmodelDelegate;
          return CouponVoucherSelected(
            viewmodel: viewModel,
          );
        },
      ),
      GoRoute(
        path: PurchaseCouponVoucherPage.pagePath,
        name: PurchaseCouponVoucherPage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as PurchaseCouponViewmodelDelegate;
          return PurchaseCouponVoucherPage(
            viewmodel: viewModel,
          );
        },
      ),
      GoRoute(
        path: TransactionSelectedPage.pagePath,
        name: TransactionSelectedPage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as TransactionsViewmodel;
          return TransactionSelectedPage(
            viewmodel: viewModel,
          );
        },
      ),
      GoRoute(
        path: ReceiptPage.pagePath,
        name: ReceiptPage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as TransactionsViewmodel;
          return ReceiptPage(
            viewmodel: viewModel,
          );
        },
      ),
      GoRoute(
        path: ReceiptMachinePage.pagePath,
        name: ReceiptMachinePage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as MachineTransactionViewmodel;
          return ReceiptMachinePage(
            viewmodel: viewModel,
          );
        },
      ),
      GoRoute(
        path: MachineStatusPage.pagePath,
        name: MachineStatusPage.pageName,
        builder: (context, state) {
          final machineId = state.extra as String;
          return MachineStatusPage(
            machineId: machineId,
          );
        },
      ),
      GoRoute(
        path: MapPage.pagePath,
        name: MapPage.pageName,
        builder: (context, state) {
          return MapPage();
        },
      ),
      GoRoute(
        path: StoreDetailPage.pagePath,
        name: StoreDetailPage.pageName,
        builder: (context, state) {
          return StoreDetailPage(storeDetail: state.extra as StoreDataDetail);
        },
      ),
      GoRoute(
        path: AvailablePaymentMethodPage.pagePath,
        name: AvailablePaymentMethodPage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as TransactionsViewmodel;
          return AvailablePaymentMethodPage(
            viewmodel: viewModel,
          );
        },
      ),
      GoRoute(
        path: TransactionAuthenPage.pagePath,
        name: TransactionAuthenPage.pageName,
        builder: (context, state) {
          return TransactionAuthenPage(
            process: state.extra as PinBiometricPross,
          );
        },
      ),
      GoRoute(
        path: ArticlesPage.pagePath,
        name: ArticlesPage.pageName,
        builder: (context, state) {
          final viewModel = state.extra as HomePageViewmodel;
          return ArticlesPage(
            viewModel: viewModel,
          );
        },
      ),
      GoRoute(
        path: ArticleDetailPage.pagePath,
        name: ArticleDetailPage.pageName,
        builder: (context, state) {
          // final article = state.extra as ArticleDetailModel;
          final viewmodel = state.extra as HomePageViewmodel;
          return ArticleDetailPage(
            viewmodel: viewmodel,
          );
        },
      ),
      GoRoute(
        path: ContactPage.pagePath,
        name: ContactPage.pageName,
        builder: (context, state) {
          List<ContactProvider>? filter;
          try {
            filter = state.extra as List<ContactProvider>;
          } catch (_) {}
          return ContactPage(
            provider: filter,
          );
        },
      ),
      GoRoute(
        path: MachineTransactionPage2.pagePath,
        name: MachineTransactionPage2.pageName,
        builder: (context, state) {
          String machineId = '';
          CustomerCouponModel? customerCouponModel;
          try {
            final objs = state.extra as List<Object?>;
            machineId = objs[0] as String;
            if (objs[1] != null) {
              customerCouponModel = objs[1] as CustomerCouponModel;
            }
          } catch (_) {}
          return MachineTransactionPage2(
            machineId: machineId,
            customerCouponModel: customerCouponModel,
          );
        },
      ),
      GoRoute(
        path: LuckyScanPage.pagePath,
        name: LuckyScanPage.pageName,
        builder: (context, state) {
          String? autoScanQRData;
          try {
            autoScanQRData = state.extra as String?;
          } catch (_) {}
          return LuckyScanPage(autoScanQRData: autoScanQRData);
        },
      ),
      GoRoute(
        path: LuckyMockupPage.pagePath,
        name: LuckyMockupPage.pageName,
        builder: (context, state) => const LuckyMockupPage(),
      ),
      GoRoute(
        path: ForceUpdatePage.pagePath,
        name: ForceUpdatePage.pageName,
        builder: (context, state) => const ForceUpdatePage(),
      ),
      GoRoute(
        path: HistoryTransactionPage.pagePath,
        name: HistoryTransactionPage.pageName,
        builder: (context, state) => const HistoryTransactionPage(),
      ),
    ],
  );
}
