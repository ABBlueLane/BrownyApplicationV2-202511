import 'dart:async';

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_detail_model.dart';
import 'package:browny_applications_new/feature/transactions/models/customer_coupon_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_programs_response.dart';
import 'package:browny_applications_new/core/widgets/qr_promptpay_dialog.dart';
import 'package:browny_applications_new/feature/authentication/screen/app_pin_page.dart';
import 'package:browny_applications_new/feature/transactions/models/machine_program_model.dart';
import 'package:browny_applications_new/feature/transactions/repository/coupon_voucher_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/machine_transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/screens/available_payment_method_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/receipt_machine_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';
import 'package:browny_applications_new/feature/wallet/screen/wallet_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MachineTransactionPage2 extends StatelessWidget {
  const MachineTransactionPage2({
    super.key,
    required this.machineId,
    this.customerCouponModel,
  });

  static final pagePath = '/machine_page';
  static final pageName = 'machine_page';

  /// machineId ที่ scan ได้จาก QRCode
  final String machineId;

  /// เก็บ Coupon, E-Voucher ที่เลือกใช้งาน
  final CustomerCouponModel? customerCouponModel;

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    required String machineId,
  }) async {
    return await context.pushNamed(
      MachineTransactionPage2.pageName,
      extra: [machineId],
    );
  }

  /// util function route to pageName
  static void goReplacementPage(
    BuildContext context, {
    required String machineId,
    CustomerCouponModel? customerCouponModel,
  }) async {
    context.pushReplacementNamed(
      MachineTransactionPage2.pageName,
      extra: [
        machineId,
        customerCouponModel,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MachineTransactionViewmodel(
        context: context,
        couponRepo: CouponVoucherRepo(),
        transactionRepo: TransactionRepo(),
        machineRepo: MachineRepo(),
      ),
      child: _MachineContent(
        machineId: machineId,
        customerCouponModel: customerCouponModel,
      ),
    );
  }
}

class _MachineContent extends StatefulWidget {
  const _MachineContent({
    required this.machineId,
    this.customerCouponModel,
  });

  /// machineId ที่ scan ได้จาก QRCode
  final String machineId;

  /// เก็บ Coupon, E-Voucher ที่เลือกใช้งาน
  final CustomerCouponModel? customerCouponModel;

  @override
  State<_MachineContent> createState() => __MachineContentState();
}

class __MachineContentState extends State<_MachineContent>
    with WidgetsBindingObserver {
  late final MachineTransactionViewmodel _viewmodel;

  MachineProgramModel? _machineProgram;
  bool _paymentProcessing = false;

  Timer? _pollingTimer;
  String? _currentPaymentRef;
  bool _isPolling = false;
  // DONG 2026-05-01
  // เพิ่ม flag ดัก event กดเบิ้ลๆ
  bool _isPurchaseClicked = false;
  void _purchaseClicked() {
    _isPurchaseClicked = true;
  }

  void _clearPurchaseClicked() {
    _isPurchaseClicked = false;
  }

  @override
  void initState() {
    super.initState();
    _viewmodel = context.read();
    _viewmodel.attachContext(context);
    WidgetsBinding.instance.addObserver(this);

    // Fetch coupon detail data with location
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // final result = await _viewmodel.fetchMachineDetail(widget.machineId);
      // if (!mounted) return;

      // if (result.hasError || result.isEmpty) {
      //   await AppOverlays.showBrownyDialog(
      //     context,
      //     title: context.wording.errorOccurred,
      //     message: context.wording.errorUi,
      //     onConfirm: () {
      //       if (!mounted) return;
      //       context.pop();
      //     },
      //   );
      //   return;
      // }

      // final machine = result.data!;

      // if (machine.isBusy) {
      //   await AppOverlays.showBrownyDialog(
      //     // เดิม: เครื่องกำลังทำงาน
      //     context,
      //     title: context.wording.theMachineIsWorking,
      //     // เดิม: กรุณาลองเครื่องอื่น
      //     message: context.wording.pleaseTryAnotherMachine,
      //     onConfirm: () {
      //       if (!mounted) return;
      //       context.pop();
      //     },
      //   );
      //   return;
      // }

      // if (machine.isTimeOut) {
      //   await AppOverlays.showBrownyDialog(
      //     context,
      //     imageAsset: Assets.png.brownyMachineError1.path,
      //     // เดิม: เครื่องไม่สามารถใช้งานได้ในขณะนี้
      //     title: context.wording.machineUnavailableAtTheMoment,
      //     // เดิม: กรุณาลองเครื่องอื่น
      //     message: context.wording.pleaseTryAnotherMachine,
      //     onConfirm: () {
      //       if (!mounted) return;
      //       context.pop();
      //     },
      //   );
      //   return;
      // }

      if (!mounted) return;
      await _viewmodel.fetchMachinePrograms(widget.machineId);
      if (widget.customerCouponModel != null) {
        if (!mounted) return;
        AppOverlays.showLoading(context);

        await _viewmodel.onCustomerCouponSelected(
          widget.customerCouponModel,
        );
        AppOverlays.hideLoading();
      }
    });
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _isPolling) {
      // App resumed - check payment status immediately
      _checkPaymentStatus();
    }
  }

  void _startPolling(String paymentRef) {
    _currentPaymentRef = paymentRef;
    _isPolling = true;

    // Check immediately
    _checkPaymentStatus();

    // Start periodic timer (5 seconds)
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkPaymentStatus();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _currentPaymentRef = null;
  }

  Future<void> _checkPaymentStatus() async {
    if (_currentPaymentRef == null) return;

    final result = await _viewmodel.checkMachineOrderPaymentStatus(
      _currentPaymentRef!,
    );

    if (!mounted || !context.mounted) return;

    if (result.isSuccess && result.data != null) {
      final status = result.data!;

      if (status.isPaid) {
        // Payment successful
        _stopPolling();

        // Close WebView if open
        if (_paymentProcessing && context.canPop()) {
          context.pop();
        }

        _showDialogPaymentSuccess();
      } else if (status.isNotFound) {
        // Order not found
        _stopPolling();

        if (context.canPop()) {
          context.pop();
        }

        AppOverlays.showBrownyDialog(
          context,
          imageAsset: Assets.png.brownyError2.path,
          // เดิม: ไม่พบรายการ
          title: context.wording.orderNotFoundTitle,
          // เดิม: ไม่พบรายการสั่งซื้อนี้
          message: context.wording.orderNotFoundMessage,
          confirmText: context.wording.confirm,
          onConfirm: () {},
        );
      }
      // If pending, continue polling
    }
  }

  /// แสดง Popup ทำรายการทุกอย่างสำเร็จ เพื่อไปหน้า Receipt
  void _showDialogPaymentSuccess() {
    AppOverlays.showBrownyDialog(
      context,
      imageAsset: Assets.png.brownySuccess.path,
      title: context.wording.transactionSuccessful, // เดิม: ชำระเงินสำเร็จ
      message: context
          .wording
          .orderCompletedMessage, // เดิม: คำสั่งซื้อของคุณเสร็จสิ้น
      confirmText: context.wording.confirm,
      onConfirm: () async {
        if (!mounted) return;
        AppOverlays.showLoading(context);
        await _viewmodel.fetchMachineReceipt();

        if (!mounted) return;
        AppOverlays.hideLoading();
        await ReceiptMachinePage.goToPage(
          context,
          viewmodel: _viewmodel,
        );
      },
    );
  }

  void _onPurchaseClicked() async {
    // ReceiptMachinePage.goToPage(
    //   context,
    //   viewmodel: _viewmodel,
    // );
    // return;
    if (_isPurchaseClicked) {
      return;
    }
    // flagกันคลิกเบิ้ล
    _purchaseClicked();
    final result = await _viewmodel.verifyOrder();
    if (!mounted) return;

    if (result.isEmpty &&
        (_viewmodel.paymentSelected?.isTpWallet == true ||
            _viewmodel.paymentSelected?.isCoin == true)) {
      final String title;
      final String message;

      if (_viewmodel.paymentSelected!.isTpWallet) {
        // TP+ Wallet เงินไม่เพียงพอ
        title = context.wording.insufficientWalletBalanceTitle;
        // กรุณาเติมเงิน หรือเปลี่ยนวิธีการชำระเงิน
        message = context.wording.insufficientWalletBalanceMessage;
      } else {
        // ชำระด้วย Browny Coin ไม่พอ
        // Browny Coin ไม่เพียงพอ
        title = context.wording.insufficientCoinTitle;
        // กรุณาเปลี่ยนวิธีชำระเงิน
        message = context.wording.changePaymentMethod;
      }
      AppOverlays.showBrownyDialog(
        context,
        // เดิม: TP+ Wallet เงินไม่เพียงพอ
        title: title,
        // เดิม: กรุณาเติมเงิน หรือเปลี่ยนวิธีการชำระเงิน
        message: message,
      );

      // flagกันคลิกเบิ้ล
      _clearPurchaseClicked();
      return;
    }

    // ช่องทางชำระที่เลือกใช้ไม่ได้แล้ว (คูปองไม่รองรับ / เครื่องปิดช่องทางนั้น)
    if (result.hasError) {
      AppOverlays.showBrownyErrorDialog(
        context,
        error: result.error,
      );

      // flagกันคลิกเบิ้ล
      _clearPurchaseClicked();
      return;
    }
    // ไปหน้า PIN/Biometric เพื่อยืนยันการทำรายการ
    TransactionAuthenPage.goToPage(context).then(
      (result) async {
        if (!mounted) return;

        if (result is bool && result) {
          AppOverlays.showLoading(
            context,
            timeout: Duration.zero,
          );
          final orderResult = await _viewmodel.createMachineOrder(
            widget.machineId,
          );

          if (!mounted) return;

          if (orderResult.isSuccess) {
            final orderResponse = orderResult.data!;
            final orderData = orderResponse.data;

            if (orderData == null) {
              AppOverlays.hideLoading();
              AppOverlays.showBrownyDialog(
                context,
                // เดิม: ไม่สามารถสร้างคำสั่งซื้อได้
                message: context.wording.cannotCreateOrder,
              );

              // flagกันคลิกเบิ้ล
              _clearPurchaseClicked();
              return;
            }

            // Check payment_ref
            final paymentRef = orderData.paymentRef;
            if (paymentRef == null || paymentRef.isEmpty) {
              AppOverlays.hideLoading();
              AppOverlays.showBrownyDialog(
                context,
                // เดิม: ไม่พบข้อมูล Payment Reference
                message: context.wording.paymentReferenceNotFound,
              );

              // flagกันคลิกเบิ้ล
              _clearPurchaseClicked();
              return;
            }

            // เช็ค Status ว่าชำระเงินแล้ว
            if (orderResponse.data!.isPaymentPaid) {
              // ถ้าน้อยกว่าหรือ 0.0 บาท จะแสดง popup ไปหน้า receipt เลย
              _paymentProcessing = false;

              if (!mounted) return;
              // เก็บ paymentRef ก่อนที่จะ call payment check
              _currentPaymentRef = paymentRef;
              await _checkPaymentStatus();
              AppOverlays.hideLoading();
              return;
            }
            // ปิด Dialog Loading ถ้าผ่าน condition ข้างบนทั้งหมด
            AppOverlays.hideLoading();
            // รอเก็บข้อมูล QRCode ที่ได้จาก payload
            String? qrData = '';
            // เช็ค flag ว่าต้องเปิด In-app QR หรือไม่
            if (_viewmodel.paymentSelected?.isShowInAppQR == true) {
              if (_viewmodel.paymentSelected!.isWeChat) {
                // WeChat
                qrData = orderResponse.data?.responsePayload?.wechat;
              } else {
                // QR Promptpay
                qrData = orderResponse.data?.responsePayload?.qrcode;
              }
            }
            // ถ้ามีค่าเป็น null จะ error
            if (qrData == null) {
              AppOverlays.showBrownyDialog(
                context,
                // ข้อมูลการชำระไม่ครบถ้วน กรุณาลองใหม่อีกครั้ง
                message: context.wording.incompletePaymentData,
              );

              // flagกันคลิกเบิ้ล
              _clearPurchaseClicked();
              return;
            }

            // Start polling for payment status
            _startPolling(paymentRef);
            _paymentProcessing = true;
            // DONG 2026-02-28
            // เพิ่มการเช็คว่าถ้ามีค่า qrAndWechat จะทำการเปิดหน้า QR ในแอพแทน
            if (_viewmodel.paymentSelected?.isShowInAppQR == true) {
              await showDialog(
                useSafeArea: false,
                context: context,
                builder: (context) => Dialog.fullscreen(
                  child: QrPromptpayDialog(
                    qrData: qrData!,
                    paymentDadge: _viewmodel.paymentSelected!.isQR
                        ? Assets.png.promptpayBadgeNoLine
                        : Assets.png.wechatPayBadge,
                    // isQRPromptPay: _viewmodel.paymentSelected!.isQR,
                  ),
                ),
              );
            } else {
              // Show WebView
              // WebViewController? controller;
              if (_viewmodel.paymentSelected!.isLaunchExternalWeb == true) {
                LaunchHelper.openUrlInBrowser(orderResponse.redirectUrl!);
              }
              await showModalBottomSheet(
                context: context,
                showDragHandle: true,
                enableDrag: false,
                isScrollControlled: true,
                isDismissible: false,
                builder: (dialogContext) {
                  return SizedBox(
                    height: 812.h * 0.85,
                    child: Scaffold(
                      persistentFooterDecoration: BoxDecoration(),
                      persistentFooterButtons: [
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDims.size_16.w,
                            ),
                            child: ElevatedButton(
                              onPressed: () => dialogContext.pop(),
                              child: AppText(context.wording.backToMainPage),
                            ),
                          ),
                        ),
                      ],
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: AppDims.size_8.h,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            CircularProgressIndicator(),

                            AppText(
                              // กำลังดำเนินการ กรุณารอซักครู่...,
                              context.wording.processingPleaseWait,
                              style: context.textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
              // controller?.clearCache();
            }
            _paymentProcessing = false;
            _stopPolling();
            await _checkPaymentStatus();
            return;
          }

          // flagกันคลิกเบิ้ล
          _clearPurchaseClicked();
          AppOverlays.hideLoading();
          if (orderResult.hasError) {
            AppOverlays.showBrownyErrorDialog(
              context,
              error: orderResult.error,
            );
          }
          return;
        } else {
          // flagกันคลิกเบิ้ล
          _clearPurchaseClicked();
        }
      },
    );
  }

  TextStyle get _textPrimary => context.textTheme.labelLarge!.copyWith(
    color: AppColors.textPrimary,
  );
  TextStyle get _textPrimarySelected => context.textTheme.labelLarge!.copyWith(
    color: AppColors.primary,
  );
  TextStyle get _textPrice => context.textTheme.headlineSmall!.copyWith(
    fontSize: AppDims.size_16.sp,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // เพิ่มป้องกัน User กดกลับออกจากหน้าจาก Navigator ของระบบ
      // ถ้ากดในจังหวะที่กำลังสร้่างออร์เดอร์ จะทำให้ route กลับไป HomePage แต่
      // Process การชำระยังทำงานอยู่ จะทำให้เปิด Receipt ขึ้นมา replace หน้า HomePage แทน
      onPopInvokedWithResult: (didPop, result) {
        // ถ้า didpop เป็น true แสดงว่า context.pop ทำงาน จะ return ออกไม่ต้องทำอะไร
        if (didPop) return;
        // ถ้า didpop เป็น false แสดงว่ามีการกด Back จาก Navigtor ของระบบ จะต้องเช็ค flag
        // _isPurchaseClicked == true แสดงว่ากำลัง process ไม่จะให้ออกจากหน้าจนกว่าจะ process เสร็จ
        if (_isPurchaseClicked) {
          return;
        }
        // ไม่เข้าทุกเงื่อนไข จะอนุญาตให้ pop ได้
        context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        persistentFooterDecoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: AppColors.defatultShadow,
        ),
        persistentFooterButtons: [
          // ปุ่มยืนยันสั่งเครื่องทำงาน
          ValueListenableBuilder(
            valueListenable: _viewmodel.machineProgramsNotifier,
            builder: (context, result, child) {
              if (!result.isSuccess) {
                return SizedBox();
              }

              return ValueListenableBuilder(
                valueListenable: _viewmodel.paymentMethodNotifier,
                builder: (context, paymentResult, paymentChild) {
                  // ต้องมีช่องทางชำระที่เลือกไว้และยังใช้งานได้ (ไม่ถูกปิดจากคูปอง/flag)
                  final paymentSelected = _viewmodel.paymentSelected;
                  final hasUsablePayment =
                      paymentSelected != null &&
                      result.data!.isPaymentMethodActive(
                        paymentSelected.method,
                      );
                  final enable =
                      result.data!.hasSelectedProgram && hasUsablePayment;
                  return Column(
                    children: [
                      Builder(
                        builder: (context) {
                          final totalDiscount =
                              result.data!.getTotalDiscountStore() +
                              result.data!.getTotalCouponOnlyDiscount() +
                              result.data!.getTotalEVoucherDiscount();
                          final discountText = formatCurrency(
                            value: totalDiscount,
                          );

                          if (totalDiscount == 0) {
                            return SizedBox();
                          }

                          return Padding(
                            padding: EdgeInsets.only(top: AppDims.size_8.h),
                            child: RichText(
                              text: TextSpan(
                                style: context.textTheme.bodyMedium!,
                                children: [
                                  TextSpan(
                                    text: '${context.wording.totalDiscount} ',
                                  ),
                                  TextSpan(
                                    text: '฿',
                                    style: AppTextNumberStyles.labelLarge
                                        .copyWith(
                                          color: AppColors.error,
                                        ),
                                  ),
                                  TextSpan(
                                    text: discountText,
                                    style: AppTextNumberStyles.labelLarge
                                        .copyWith(
                                          color: AppColors.error,
                                        ),
                                  ),
                                  TextSpan(text: ' ${context.wording.thb}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        padding: EdgeInsets.only(
                          left: AppDims.size_16.w,
                          right: AppDims.size_16.w,
                          top: AppDims.size_8.h,
                        ),
                        child: ElevatedButton(
                          onPressed: enable ? _onPurchaseClicked : null,
                          child: AppText(
                            '${context.wording.makePayment} ${formatCurrency(
                              leadingSign: '฿',
                              value: result.data!.getNetPrice(),
                            )}',
                            style: context.textTheme.headlineSmall!.copyWith(
                              fontSize: AppDims.size_14.sp,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        body: ValueListenableBuilder(
          valueListenable: _viewmodel.machineProgramsNotifier,
          builder: (context, result, child) {
            if (result.isLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (result.hasError || result.isEmpty) {
              return Scaffold(
                appBar: AppBar(
                  leading: BackButton(
                    color: AppColors.textPrimary,
                  ),
                ),
                body: Center(
                  child: AppText(
                    // เดิม: ไม่พบข้อมูลเครื่องหรือเกิดข้อผิดพลาด\nกรุณาตรวจสอบและลองใหม่อีกครั้ง
                    context.wording.machineDataLoadError,
                  ),
                ),
              );
            }
            // assign value
            _machineProgram = result.data!;
            return Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        // Fixed Header with Machine Image
                        _buildFixedHeader(),

                        // Title เครื่องซัก, สาขา
                        _mainTitle(),

                        // Program ของเครื่องซักที่มี
                        _programWidget(),

                        // Program เพิ่มเวลา ของเครื่องอบที่มี
                        if (_machineProgram!.hasAddTime)
                          _programAddTimeWidget(),

                        // คูปอง / E-Voucher
                        _couponEVoucherWidget(),

                        // ประเภทชำระ
                        _paymentMethods(),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDims.size_16.w,
                          ),
                          child: AppDims.vericalPadding_24,
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDims.size_16.w,
                          ),
                          child: Divider(),
                        ),

                        // Summary Transaction
                        _summary(),

                        // Extra padding เพื่อให้ scroll พ้น footer button
                        // SizedBox(height: 42.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// โปรแกรมซัก
  /// Program ของเครื่องซักที่มี
  /// เช่น ซักน้ำเย็น, ซักน้ำอุ่น
  Widget _programWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: _title(
            icon: Assets.svg.icWashWhiteRoundedGreen.svg(),
            title: _machineProgram!.getMachineTypeDisplay(context.languageCode),
          ),
        ),
        // Card Programs Grid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: MasonryGridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _machineProgram!.programs.orEmpty.length,
            itemBuilder: (context, index) {
              final program = _machineProgram!.programs![index];
              final isSelected = _machineProgram!.isProgramSelected(index);
              return _programSingleItem(
                context,
                program,
                isSelected: isSelected,
                onTap: () {
                  debugPrint('Program tap $index');
                  _viewmodel.selectProgram(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// โปรแกรมเพิ่มเวลา
  /// Program เพิ่มเวลา ของเครื่องอบที่มี
  /// เช่น +6 นาที, +10 นาที
  Widget _programAddTimeWidget() {
    return Column(
      children: [
        AppDims.vericalPadding_24,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: _title(
            icon: Assets.svg.icClockRoundedGreen.svg(),
            // เดิม: ต่อเวลาอบผ้า
            title: context.wording.addDryingTime,
          ),
        ),
        AppDims.vericalPadding_8,
        // Card Programs List
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _machineProgram!.addTimes.orEmpty.length,
            separatorBuilder: (_, __) => AppDims.vericalPadding_8,
            itemBuilder: (context, index) {
              final addTime = _machineProgram!.addTimes![index];
              final isSelected = _machineProgram!.isAddTimeSelected(index);
              return _programAddTimeSingleItem(
                context,
                addTime,
                isSelected: isSelected,
                onTap: () => _viewmodel.selectAddTime(index),
              );
            },
          ),
        ),
      ],
    );
  }

  /// คูปอง / E-Voucher
  /// แสดง Coupon / E-Voucher ที่เลือกมาใช้งาน
  Widget _couponEVoucherWidget() {
    return ValueListenableBuilder(
      valueListenable: _viewmodel.paymentMethodNotifier,
      builder: (context, paymentResult, child) {
        // เก็บ Error ก่อนว่า Counpon ที่เลือกมาสามารถใช้งานได้หรือไม่
        // ส่งรายการช่องทางชำระเข้าไปด้วย เพื่อตรวจว่าคูปองใบนี้ยังมีช่องทางให้ใช้อยู่
        final String? validCouponMessage = _machineProgram!
            .validSelectedCouponAndMessageError(
              context,
              availablePaymentMethods: paymentResult.data,
            );
        return _couponEVoucherContent(validCouponMessage);
      },
    );
  }

  Widget _couponEVoucherContent(String? validCouponMessage) {
    return Column(
      children: [
        AppDims.vericalPadding_24,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: Row(
            children: [
              Expanded(
                child: _title(
                  icon: Assets.svg.icWashWhiteRoundedGreen.svg(),
                  // เดิม: คูปอง / E-Voucher
                  title: context.wording.couponAndEVoucher,
                ),
              ),
              GestureDetector(
                onTap: onCouponEVoucherTap,
                child: Row(
                  children: [
                    AppText(
                      // เดิม: เพิ่ม/เลือก
                      context.wording.addOrSelect,
                      style: context.textTheme.labelLarge!.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    AppDims.horizonPadding_8,
                    Assets.svg.icArrowForward.svg(),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppDims.vericalPadding_8,
        // Coupon, E-Voucher Using
        GestureDetector(
          onTap: onCouponEVoucherTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
            child: Builder(
              builder: (context) {
                final couponSelected = _machineProgram?.selectedCoupon;
                return Container(
                  height: couponSelected == null ? 85.h : null,
                  decoration: BoxDecoration(
                    image: couponSelected == null
                        ? DecorationImage(
                            image: Assets.png.bgUnselectedCouponEvoucher
                                .provider(),
                          )
                        : null,
                  ),
                  child: couponSelected != null
                      ? CouponEVoucherCardWidget(
                          icon: Image.network(
                            couponSelected.getCouponImageDisplay(
                              context.languageCode,
                            ),
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.ci2,
                            ),
                          ),
                          title: couponSelected.getCouponNameDisplay(
                            context.languageCode,
                          ),
                          description: context
                              .wording
                              .participatingStoresOnly, // เดิม: เฉพาะสาขาที่ร่วมรายการ
                          detailUsing: '',
                          expired: couponSelected.getExpireDisplay(
                            context.languageCode,
                          ),
                          isDisabled: validCouponMessage != null,
                          borderColor: validCouponMessage == null
                              ? AppColors.primary
                              : AppColors.error,
                        )
                      : null,
                );
              },
            ),
          ),
        ),
        if (validCouponMessage != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
            child: Row(
              spacing: AppDims.size_4.w,
              children: [
                Assets.svg.icInfoRad.svg(),
                // แจ้งเตือน error ถ้ามี
                AppText(
                  validCouponMessage,
                  style: context.textTheme.labelSmall!.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ] else
          SizedBox(),
      ],
    );
  }

  void onCouponEVoucherTap() {
    CouponVoucherPage.goToPage(
      context,
      state: CouponVoucherState.using,
      // ส่ง machineProgram เพื่อให้ CouponVoucherPage derive availableCoupons
      // และ selectedCoupon จาก model โดยตรง รวมถึง re-fetch หลัง collectCoupon
      machineUsing: _machineProgram!,
    ).then((result) async {
      if (!mounted) return;
      // ถ้า result เป็น bool แสดงว่ามาจากการกดกลับเฉยๆ ไม่ต้องทำอะไร
      if (result != null && result is bool) {
        AppOverlays.showLoading(context);
        // ถ้ากดกลับมาเฉยๆ จะ fetch program ใหม่ด้วย เผื่อกรณีมีการรับ Coupon แต่ไม่เลือกใช้
        // ถ้าไม่ fetch ใหม่ availableCoupons จะไม่ถูกอัพเดทในหน้านี้
        await _viewmodel.fetchMachinePrograms(_viewmodel.machineId);
        AppOverlays.hideLoading();
        return;
      }

      try {
        final customerCouponModelSelected = result as CustomerCouponModel;
        AppOverlays.showLoading(context);
        await _viewmodel.onCustomerCouponSelected(
          customerCouponModelSelected,
        );
        AppOverlays.hideLoading();
      } catch (_) {}
    });
  }

  /// ประเภทชำระ
  /// แสดงประเภทชำระที่รองรับ
  Widget _paymentMethods() {
    return Column(
      children: [
        AppDims.vericalPadding_12,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: Row(
            children: [
              Expanded(
                child: _title(
                  icon: Assets.svg.icWalletRoundedGreen.svg(),
                  // เดิม: วิธีการชำระเงิน
                  title: context.wording.paymentMethod,
                ),
              ),
              GestureDetector(
                onTap: () {
                  AvailablePaymentMethodPage.goToPage(
                    context,
                    viewmodel: _viewmodel,
                  );
                },
                child: Row(
                  children: [
                    AppText(
                      // เดิม: เลือก
                      context.wording.select,
                      style: context.textTheme.labelLarge!.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    AppDims.horizonPadding_8,
                    Assets.svg.icArrowForward.svg(),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppDims.vericalPadding_8,
        // ประเภทชำระ
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: ValueListenableBuilder(
            valueListenable: _viewmodel.paymentMethodNotifier,
            builder: (context, value, child) {
              if (value.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (value.hasError) {
                return AppText(context.wording.errorUi);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...value.data.orEmpty
                      .take(3)
                      .map(
                        (payment) => _cardPaymentDependOnState(
                          payment,
                          // isTPWallet:
                          //     payment.isSelected &&
                          //     payment.method == 'tp_wallet',
                          // selected: payment.isSelected,
                          // child: ListTile(
                          //   minVerticalPadding: 0,
                          //   contentPadding: EdgeInsets.zero,
                          //   minTileHeight: 0,
                          //   horizontalTitleGap: AppDims.size_8.w,
                          //   leading: payment.imageUrl != null
                          //       ? CachedNetworkImage(
                          //           imageUrl: payment.imageUrl!,
                          //           width: 22.w,
                          //           height: 22.h,
                          //           fit: BoxFit.contain,
                          //           placeholder: (_, __) =>
                          //               SizedBox(width: 22.w, height: 22.h),
                          //           errorWidget: (_, __, ___) =>
                          //               SizedBox(width: 22.w, height: 22.h),
                          //         )
                          //       : null,
                          //   title: AppText(
                          //     payment.name,
                          //     style: payment.isSelected
                          //         ? _textPrimarySelected
                          //         : _textPrimary,
                          //   ),
                          //   onTap: () {
                          //     _viewmodel.onPaymentChanged(
                          //       payment,
                          //     );
                          //   },
                          //   trailing: payment.isSelected
                          //       ? Padding(
                          //           padding: EdgeInsets.only(
                          //             right: 6.0.w,
                          //           ),
                          //           child: Assets.svg.icChecked.svg(),
                          //         )
                          //       : null,
                          // ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDims.vericalPadding_16,
          _title(
            icon: Assets.svg.icListRoundedGreen.svg(),
            // เดิม: สรุปราคา
            title: context.wording.paymentSummary,
          ),
          AppDims.vericalPadding_16,
          // detail
          // Title
          _lineSummay(
            title: _machineProgram!.getSummaryMachineTypeDisplay(
              context.languageCode,
            ),
            price: _machineProgram!.totalSelectedPrice.toString(),
          ),
          AppDims.vericalPadding_16,
          // ส่วนลดถ้ามี
          _lineSummay(
            // เดิม: โปรโมชั่นสาขา
            title: context.wording.storePromotion,
            price: _machineProgram!.getTotalDiscountStore().toString(),
            textPriceColor: _machineProgram!.getTotalDiscountStore() > 0
                ? AppColors.error
                : null,
            discount: _machineProgram!.getTotalDiscountStore() > 0,
          ),
          AppDims.vericalPadding_16,
          // สรุปยอด คูปองส่วนลด
          _lineSummay(
            // เดิม: คูปองส่วนลด
            title: context.wording.discountCoupon,
            price: _machineProgram!.getTotalCouponOnlyDiscount().toString(),
            textPriceColor: _machineProgram!.getTotalCouponOnlyDiscount() > 0
                ? AppColors.error
                : null,
            discount: _machineProgram!.getTotalCouponOnlyDiscount() > 0,
          ),
          AppDims.vericalPadding_16,
          // สรุปยอด E-Voucher
          _lineSummay(
            title: context.wording.eVouchers,
            price: _machineProgram!.getTotalEVoucherDiscount().toString(),
            textPriceColor: _machineProgram!.getTotalEVoucherDiscount() > 0
                ? AppColors.error
                : null,
            discount: _machineProgram!.getTotalEVoucherDiscount() > 0,
          ),
          AppDims.vericalPadding_16,
          _lineSummay(
            // เดิม: ยอดชำระทั้งหมด
            title: context.wording.totalPayment,
            price: _machineProgram!.getNetPrice().toString(),
            textPriceColor: AppColors.primary,
          ),
          AppDims.vericalPadding_24,
        ],
      ),
    );
  }

  Widget _lineSummay({
    required String title,
    required String price,
    Color? textPriceColor,
    bool discount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          style: _textPrimary,
        ),

        AppText(
          formatCurrency(
            string: price,
            decimal: true,
            leadingSign: discount ? '-฿' : '฿',
          ),
          style: _textPrice.copyWith(color: textPriceColor),
        ),
      ],
    );
  }

  Widget _cardPaymentDependOnState(
    PaymentMethodModel payment,
    //   , {
    //   bool selected = false,
    //   bool isCoin = false,
    //   required bool isTPWallet,
    //   required Widget child,
    // }
  ) {
    final isDisabled = !payment.isActive;
    final isSelected = payment.isSelected && !isDisabled;
    final isTPWallet = payment.isTpWallet;
    final isCoin = payment.isCoin;
    // เหตุผลที่เลือกช่องทางนี้ไม่ได้ (null = เลือกได้ปกติ)
    final disabledReason = _viewmodel.paymentMethodDisabledReason(
      context,
      payment,
    );
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              _viewmodel.onPaymentChanged(
                payment,
              );
            },
      child: Opacity(
        opacity: isDisabled ? 0.45 : 1.0,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: AppDims.size_8.h),
          padding: EdgeInsets.symmetric(
            horizontal: AppDims.size_16.w,
            vertical: AppDims.size_16.h,
          ),
          decoration: BoxDecoration(
            border: BoxBorder.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? AppDims.size_2.h : AppDims.size_1.h,
            ),
            borderRadius: BorderRadius.circular(
              AppDims.size_8.r,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ListTile(
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                minTileHeight: 0,
                horizontalTitleGap: AppDims.size_8.w,
                leading: payment.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: payment.imageUrl!,
                        width: 22.w,
                        height: 22.h,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            SizedBox(width: 22.w, height: 22.h),
                        errorWidget: (_, __, ___) =>
                            SizedBox(width: 22.w, height: 22.h),
                      )
                    : null,
                title: AppText(
                  payment.name,
                  style: isSelected ? _textPrimarySelected : _textPrimary,
                ),
                trailing: isSelected
                    ? Padding(
                        padding: EdgeInsets.only(
                          right: 6.0.w,
                        ),
                        child: Assets.svg.icChecked.svg(),
                      )
                    : null,
              ),
              if (disabledReason != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: AppDims.size_4.h),
                    child: AppText(
                      disabledReason,
                      style: context.textTheme.labelSmall!.copyWith(
                        color: AppColors.black2A,
                      ),
                    ),
                  ),
                ),
              if (isTPWallet && isSelected) ...[
                Consumer<CustomerProvider>(
                  builder: (context, provider, _) {
                    return ListTile(
                      minVerticalPadding: AppDims.size_8.h,
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 0,
                      horizontalTitleGap: AppDims.size_8.w,
                      title: AppText(
                        context
                            .wording
                            .balanceRemaining, // เดิม: จำนวนเงินคงเหลือ
                        style: _textPrimary,
                      ),
                      trailing: AppText(
                        formatCurrency(
                          leadingSign: '฿ ',
                          string: provider.current.creditBalance,
                          decimal: true,
                        ),
                        style: _textPrimarySelected.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),

                ElevatedButton(
                  onPressed: () {
                    WalletPage.goToPage(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(54.w, 30.h),
                  ),
                  child: AppText(
                    context.wording.topup,
                    style: context.textTheme.labelMedium!.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
              if (isCoin) ...[
                Consumer<CustomerProvider>(
                  builder: (context, provider, _) {
                    return ListTile(
                      minVerticalPadding: AppDims.size_8.h,
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 0,
                      horizontalTitleGap: AppDims.size_8.w,
                      title: AppText(
                        // มูลค่า
                        context.wording.coinValue,
                        style: _textPrimary,
                      ),
                      trailing: AppText(
                        formatCurrency(
                          leadingSign: '฿ ',
                          string: provider.current.currentCoin,
                          decimal: true,
                        ),
                        style: _textPrimarySelected.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  },
                ),

                Consumer<CustomerProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppDims.size_4.w,
                      children: [
                        payment.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: payment.imageUrl!,
                                width: AppDims.size_12.w,
                                height: AppDims.size_12.h,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => SizedBox(
                                  width: AppDims.size_12.w,
                                  height: AppDims.size_12.h,
                                ),
                                errorWidget: (_, _, _) => SizedBox(
                                  width: AppDims.size_12.w,
                                  height: AppDims.size_12.h,
                                ),
                              )
                            : SizedBox(
                                width: AppDims.size_12.w,
                                height: AppDims.size_12.h,
                              ),
                        AppText(
                          formatCurrency(
                            string: provider.current.brownyCoin,
                            decimal: true,
                            // คอยน์
                            trailingSign: ' ${context.wording.coin}',
                          ),
                          style: _textPrimarySelected.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _programSingleItem(
    BuildContext context,
    ProgramData program, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Stack(
      children: [
        // Text แสดง discount
        if (program.hasDiscount)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 8,
                top: 2,
                right: 8,
                bottom: 20,
              ),
              margin: EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: AppColors.error,
              ),
              child: Row(
                children: [
                  Assets.png.icDiscount.image(
                    width: AppDims.size_8.h,
                  ),
                  AppDims.horizonPadding_4,
                  AppText(
                    context.wording.discount, // เดิม: ลดราคา
                    style: context.textTheme.labelSmall!.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Card แสดง
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.only(
              top: program.hasDiscount ? AppDims.size_21.h : AppDims.size_16.h,
            ),
            // padding: EdgeInsets.symmetric(
            //   vertical: AppDims.size_12.h,
            //   horizontal: AppDims.size_29.w,
            // ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                width: 2,
                color: isSelected ? AppColors.primary : AppColors.productStroke,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(
                    top: AppDims.size_12.h,
                    bottom: AppDims.size_12.h,
                    left: AppDims.size_29.w,
                    right: AppDims.size_29.w,
                  ),
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: Image.network(
                    width: AppDims.size_50.h,
                    height: AppDims.size_50.h,
                    program.image!,
                  ),
                ),
                AppDims.vericalPadding_8,

                Container(
                  margin: EdgeInsets.symmetric(horizontal: AppDims.size_6.w),
                  child: AppText(
                    program.getProgramNameDisplay(context.languageCode),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium,
                  ),
                ),

                AppDims.vericalPadding_8,

                AppText(
                  program.hasDiscount ? '฿ ${program.price}' : '',
                  style: context.textTheme.labelMedium!.copyWith(
                    fontSize: AppDims.size_10.sp,
                    color: AppColors.error,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.error,
                  ),
                ),
                AppDims.vericalPadding_4,
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppDims.size_2.h,
                    horizontal: AppDims.size_8.w,
                  ),
                  margin: EdgeInsets.only(
                    bottom: AppDims.size_12.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: AppText(
                    '฿ ${program.net}',
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _programAddTimeSingleItem(
    BuildContext context,
    ProgramData addTime, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      tileColor: AppColors.background, // Set background color
      shape: RoundedRectangleBorder(
        // Add border and rounded corners
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      title: AppText(
        addTime.getProgramNameDisplay(context.languageCode),
        style: context.textTheme.labelMedium!.copyWith(
          fontSize: AppDims.size_16.sp,
        ),
      ),
      horizontalTitleGap: 0.0,
      contentPadding: EdgeInsets.symmetric(horizontal: AppDims.size_8.w),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (addTime.hasDiscount)
            AppText(
              '฿ ${addTime.price}',
              style: context.textTheme.labelMedium!.copyWith(
                fontSize: AppDims.size_16.sp,
                color: AppColors.error,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.error,
              ),
            ),
          if (addTime.hasDiscount) AppDims.horizonPadding_16,
          Container(
            padding: EdgeInsets.symmetric(
              vertical: AppDims.size_2.h,
              horizontal: AppDims.size_8.w,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(32.r),
            ),
            child: AppText(
              '฿ ${addTime.net}',
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _mainTitle() {
    return Column(
      children: [
        // Title เครื่องซัก
        AppText(
          _machineProgram!.machineName!.getByLocaleCode(
            context.languageCode,
          )!,
          style: context.textTheme.headlineMedium,
        ),
        AppDims.vericalPadding_4,

        // สาขา
        AppText(
          _machineProgram!.storeName!.getByLocaleCode(
            context.languageCode,
          )!,
          style: context.textTheme.bodyMedium!.copyWith(
            color: AppColors.gray500,
          ),
        ),

        AppDims.vericalPadding_24,
      ],
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      height: 365.h, // กำหนดความสูงเท่าเดิม (ตาม SliverAppBar expandedHeight)
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.png.bgMachine.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: AppText(
                  context.wording.startOperation, // เดิม: เริ่มต้นทำงาน
                  style: context.appBarTextThemeWhite,
                ),
              ),
            ),

            // Machine Model Image
            Padding(
              padding: EdgeInsets.only(
                top: AppDims.size_42.h,
                bottom: AppDims.size_42.h,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 56.w),
                  Image.network(
                    _machineProgram!.machineImage.orEmpty,
                  ),
                  Container(
                    padding: EdgeInsets.only(right: AppDims.size_16.w),
                    width: 56.w,
                    height: 87.h,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Machine No
                        Stack(
                          children: [
                            Assets.png.icPaw2RoundedGreen.image(
                              width: AppDims.size_39.w,
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: AlignmentGeometry.center,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 2.0.w,
                                    top: 8.0.h,
                                  ),
                                  child: AppText(
                                    _machineProgram!.machineNo.toString(),
                                    style: context.textTheme.headlineSmall!
                                        .copyWith(
                                          fontSize: AppDims.size_16.sp,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppDims.vericalPadding_8,
                        ValueListenableBuilder(
                          valueListenable: _viewmodel.machineProgramsNotifier,
                          builder: (context, result, child) {
                            return Container(
                              width: AppDims.size_40.h,
                              height: result.data?.selectedProgram == null
                                  ? null
                                  : AppDims.size_40.h,
                              padding: EdgeInsets.symmetric(
                                vertical: AppDims.size_8.h,
                                horizontal: AppDims.size_13.w,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ci3,
                                shape: BoxShape.circle,
                              ),
                              child: result.data?.selectedProgram == null
                                  ? AppText(
                                      '?',
                                      style: context.textTheme.labelLarge!
                                          .copyWith(
                                            color: AppColors.primary,
                                            fontSize: AppDims.size_24.sp,
                                          ),
                                    )
                                  : Image.network(
                                      result.data!.selectedProgram!.image!,
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Background Radius
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppContainerRadius(
                height: AppDims.size_24.h,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title({
    required Widget icon,
    required String title,
  }) {
    return ElevatedButton.icon(
      onPressed: null,
      icon: icon,
      label: AppText(
        title,
        style: context.textTheme.labelLarge!.copyWith(
          fontSize: AppDims.size_16.sp,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.primary,
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.zero,
        disabledBackgroundColor: AppColors.transparent,
        overlayColor: AppColors.transparent,
      ),
    );
  }
}
