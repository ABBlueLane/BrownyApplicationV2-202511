import 'dart:async';
import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/core/data/remote/models/request/topup_request.dart';
import 'package:browny_applications_new/core/data/remote/models/response/contact_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/topup_request_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/wallet_history_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/wallet_receipt_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/ui_result.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/feature/contacts/repository/contact_repo.dart';
import 'package:browny_applications_new/feature/wallet/error/wallet_exception.dart';
import 'package:browny_applications_new/feature/wallet/models/receipt_data_model.dart';
import 'package:browny_applications_new/feature/wallet/models/wallet_model.dart';
import 'package:browny_applications_new/feature/wallet/repository/wallet_repo.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum WalletProcessState {
  // สำหรับเติมเงิน
  topup,
  // สำหรับ Scan เปิดกล้อง
  scan,
  // สำหรับประวัติ
  history,
}

class WalletViewModel extends AppViewModelObscureHandler {
  WalletViewModel({
    required super.context,
    super.initIsObscure = false,
    WalletDataSourceMixin? walletRepo,
    ContactDataSourceMixin? contactRepo,
  }) {
    repo = walletRepo ?? WalletRepo();
    _contactRepo = contactRepo ?? ContactRepo();
  }

  // ========= repo =========
  late WalletDataSourceMixin repo;
  late ContactDataSourceMixin _contactRepo;

  // ========= dispose =========
  Timer? _statusCheckTimer;

  @override
  void dispose() {
    _procesStateNotfier.dispose();
    _recieptDataNotifier.dispose();
    _walletDataNotifier.dispose();
    _walletHistoryNotifier.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  // ========= valueNotifier, controller =========
  final ValueNotifier<WalletProcessState> _procesStateNotfier = ValueNotifier(
    WalletProcessState.topup,
  );
  ValueListenable<WalletProcessState> get procesStateNotfier =>
      _procesStateNotfier;

  /// เก็บ Response จากที่ ChechStatus
  /// จะถูก Assign จาก [startPaymentStatusCheck] เท่านั่น
  late final ValueNotifier<UiResult<ReceiptDataModel>> _recieptDataNotifier =
      ValueNotifier(UiResult.loading());
  ValueListenable<UiResult<ReceiptDataModel>> get recieptDataNotifier =>
      _recieptDataNotifier;

  final ValueNotifier<UiResult<WalletModel>> _walletDataNotifier =
      ValueNotifier(
        UiResult.loading(),
      );
  ValueListenable<UiResult<WalletModel>> get walletNotifier =>
      _walletDataNotifier;

  final ValueNotifier<UiResult<WalletHistoryResponse>> _walletHistoryNotifier =
      ValueNotifier(
        UiResult.loading(),
      );
  ValueListenable<UiResult<WalletHistoryResponse>> get walletHistoryNotifier =>
      _walletHistoryNotifier;

  TextEditingController amountController = TextEditingController();

  // ========= Logic =========

  bool _amountValidNotifier = false;
  // เก็บ Response จากที่ Request ชำระ
  TopupRequestResponse? _topupResponse;
  TopupRequestResponse? get topupResponse => _topupResponse;

  /// DONG 2026-02-21
  ///
  /// fetch ข้อมูลช่องทางการติดต่อต่างๆ
  Future<UiResult<ContactResponse>> fetchTermsLink() async {
    try {
      final result = await _contactRepo.fetchContact();
      if (result.hasError || result.isEmpty) {
        return UiResult.empty();
      }

      return UiResult.success(data: result.data);
    } catch (_) {
      return UiResult.empty();
    }
  }

  Future<UiResult<TopupRequestResponse>> onSummitClick() async {
    if (_amountValidNotifier) {
      final result = await repo.requestTopup(
        TopupRequest(
          customerId: currentCustomerProvider.current.id!,
          amount: int.parse(amountController.text.commaReplacer()),
          gateway: 'qr',
        ),
      );

      if (result.hasData) {
        _topupResponse = result.data;
        return UiResult.success(data: result.data);
      }

      return UiResult.error(error: result.error);
    }

    return UiResult.empty();
  }

  void selectAmount(int amount) {
    final currentData = _walletDataNotifier.value.data;
    if (currentData == null) return;

    amountController.text = amount.toString();

    int newSelectedIndex = currentData.amountBadge.indexOf(amount);
    if (newSelectedIndex >= 0) {
      _walletDataNotifier.value = UiResult.success(
        data: currentData.copyWith(
          selectedAmount: currentData.amountBadge.indexOf(amount),
        ),
      );

      return;
    }

    if (newSelectedIndex == -1 && currentData.selectedAmount > -1) {
      _walletDataNotifier.value = UiResult.success(
        data: currentData.copyWith(
          selectedAmount: -1,
        ),
      );
      return;
    }
  }

  void onTextAmountChange(String value) {
    selectAmount(
      double.parse(
        value.orEmpty.ifEmpty('0').commaReplacer(),
      ).toInt(),
    );
  }

  String? amountValidator(String? value) {
    int inputAmount = double.parse(
      value.orEmpty.ifEmpty('0').commaReplacer(),
    ).toInt();
    String? ret;
    if (inputAmount < 100) {
      ret = context.wording.minimumTopUpValidation;
    }

    if (inputAmount > 2000) {
      ret = context.wording.maximumTopUpValidation;
    }

    amountController.text = inputAmount == 0
        ? ''
        : formatCurrency(value: inputAmount, decimal: false);

    _amountValidNotifier = (ret == null);
    ret = inputAmount == 0 ? null : ret;
    return ret;
  }

  /// เริ่มตรวจสอบสถานะการชำระเงินทุก 30 วินาที
  void startPaymentStatusCheck(VoidCallback onSuccess) {
    // if (kDebugMode) {
    //   onSuccess.call();
    //   return;
    // }
    final paymentRef = topupResponse!.paymentRef!;
    _statusCheckTimer?.cancel();

    // Start status check timer
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 7),
      (timer) async {
        // ======= mock =======
        // stopPaymentStatusCheck();
        // onSuccess.call();
        // return;

        // ======= real =======
        try {
          final result = await repo.checkWalletStatusPayment(paymentRef);

          if (result.hasData) {
            final data = result.data;
            if (data.confirmedAt != null) {
              // Payment confirmed - stop timers
              stopPaymentStatusCheck();

              // Refresh credit balance
              await fetchCredit();
              onSuccess.call();
            }
          }
        } catch (_) {}
      },
    );
  }

  /// หยุดการตรวจสอบสถานะการชำระเงิน
  void stopPaymentStatusCheck() {
    _statusCheckTimer?.cancel();
  }

  /// DONG 2026-07-31
  ///
  /// fetch ข้อความแจ้งเตือนจาก API `/wallet/firstNotification`
  /// แล้วแสดงเป็น popup ตอนเปิดหน้า Wallet
  ///
  /// ถ้า response เป็น null (ไม่มีประกาศ) จะไม่แสดงอะไร
  Future<void> showFirstNotificationIfNeeded() async {
    try {
      final result = await repo.fetchFirstNotification();
      if (!result.hasData || !result.data.hasContent) return;

      if (!context.mounted) return;

      final locale = context.languageCode;
      await AppOverlays.showWalletDialog(
        context,
        title: result.data.title?.getTextByLocale(locale),
        message: result.data.description?.getTextByLocale(locale) ?? '',
      );
    } catch (_) {
      // ถ้า fetch ไม่สำเร็จ ไม่ต้องแสดง popup ใช้งานหน้า Wallet ต่อได้ปกติ
    }
  }

  Future<void> fetchCredit() async {
    final oldWalletData = _walletDataNotifier.value.data;

    final result = await repo.fetchCustomerCredit(
      currentCustomerProvider.current.id!,
    );

    if (result.isEmpty || result.hasError) {
      _walletDataNotifier.value = UiResult.empty();
      return;
    }

    final amountBadgeResult = await repo.fetchAmountBadge();

    _walletDataNotifier.value = UiResult.success(
      data:
          WalletModel.fromCustomerProfileData(
            result.data,
          ).copyWith(
            amountBadge: amountBadgeResult.data,
            selectedAmount: amountBadgeResult.data.indexOf(
              oldWalletData?.selectedAmount ?? 0,
            ),
          ),
    );
    // update ข้อมูล User ด้วย
    currentCustomerProvider.updateCreditAndCoinBalance(result.data);
  }

  Future<void> fetchReceiptData(BuildContext context) async {
    // ======= mock =======
    // if (kDebugMode) {
    //   final locale = Localizations.localeOf(context);
    //   _recieptDataNotifier.value = UiResult.success(
    //     data: ReceiptDataModel.fromWalletReceiptData(
    //       locale.languageCode.orEmpty.ifEmpty('th'),
    //       WalletReceiptData(
    //         amount: '100',
    //         dateTime: DateTime.now(),
    //         paymentRef: topupResponse?.paymentRef,
    //         gateway: 'promptpay',
    //         receiptNo: 'RCPT202506101430',
    //         transactionId: 'TXN123456789',
    //         bonus: '100',
    //         qrImage:
    //             // 'https://dev.abgroup.co.th/storage/qrcodes/019ccd2e-6c2d-7043-b53a-1a0eb16bf59a.png',
    //             'customer_id:019ccd2e-6c2d-7043-b53a-1a0eb16bf59a',
    //       ),
    //     ),
    //   );
    //   return;
    // }

    // ======= real =======
    if (!_recieptDataNotifier.value.isLoading) {
      _recieptDataNotifier.value = UiResult.loading();
    }

    final paymentRef = topupResponse!.paymentRef!;
    final result = await repo.fetchReciept(paymentRef);

    if (result.hasError) {
      _recieptDataNotifier.value = UiResult.error(error: Unprocessable());
      return;
    }

    if (result.isSuccess && context.mounted) {
      final qrImage =
          result.data.data!.qrImage ??
          'customer_id:${currentCustomerProvider.current.id}';

      final locale = Localizations.localeOf(context);
      _recieptDataNotifier.value = UiResult.success(
        data: ReceiptDataModel.fromWalletReceiptData(
          locale.countryCode.orEmpty.ifEmpty('th'),
          result.data.data!,
        ).copyWith(qrImage: qrImage),
      );
    }
  }

  void clearValue() {
    onTextAmountChange('');
  }

  void onProcessStateChange(WalletProcessState toState) {
    final currentState = _procesStateNotfier.value;
    if (currentState == toState) return;

    _procesStateNotfier.value = toState;
  }

  /// Fetch wallet transaction history
  Future<void> fetchWalletHistory() async {
    if (!_walletHistoryNotifier.value.isLoading) {
      _walletHistoryNotifier.value = UiResult.loading();
    }

    final result = await repo.fetchWalletHistory(
      currentCustomerProvider.current.id!,
    );

    if (result.hasError) {
      _walletHistoryNotifier.value = UiResult.error(
        error: result.error,
      );
      return;
    }

    if (result.isEmpty) {
      _walletHistoryNotifier.value = UiResult.empty();
      return;
    }

    _walletHistoryNotifier.value = UiResult.success(
      data: result.data,
    );
  }
}
