// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/response/coupon_order_response.dart';
import 'package:browny_applications_new/core/widgets/qr_promptpay_dialog.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/screen/app_pin_page.dart';
import 'package:browny_applications_new/feature/contacts/models/contact_model.dart';
import 'package:browny_applications_new/feature/contacts/screens/contact_page.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_detail_model.dart';
import 'package:browny_applications_new/feature/transactions/screens/available_payment_method_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/receipt_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';
import 'package:browny_applications_new/feature/wallet/screen/wallet_page.dart';

class TransactionSelectedPage extends StatefulWidget {
  const TransactionSelectedPage({
    super.key,
    required this.viewmodel,
  });

  final TransactionsViewmodel viewmodel;

  static final pagePath = '/transaction_selected';
  static final pageName = 'transaction_selected';

  @override
  State<TransactionSelectedPage> createState() =>
      _TransactionSelectedPageState();
}

class _TransactionSelectedPageState extends State<TransactionSelectedPage>
    with WidgetsBindingObserver {
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

  late final TransactionsViewmodel _viewmodel;
  bool _paymentProcessing = false;

  Timer? _pollingTimer;
  CouponOrderData? _currentOrderData;
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
    _viewmodel = widget.viewmodel;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewmodel.fetchPaymentMethod(context);
    });
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    _viewmodel.disposeTransaction();
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

  void _startPolling(CouponOrderData orderData) {
    _currentOrderData = orderData;
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
    _currentOrderData = null;
  }

  Future<void> _checkPaymentStatus() async {
    if (_currentOrderData == null) return;

    final result = await _viewmodel.checkPaymentStatus(_currentOrderData!);

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
        await _viewmodel.fetchCouponReceipt();
        ReceiptPage.goReplacementPage(
          context,
          viewmodel: _viewmodel,
        );
      } else if (status.isNotFound) {
        // Order not found
        _stopPolling();

        if (context.canPop()) {
          context.pop();
        }

        AppOverlays.showBrownyDialog(
          context,
          imageAsset: Assets.png.brownyError2.path,
          // ไม่พบรายการ
          title: context.wording.orderNotFoundTitle,
          // ไม่พบรายการสั่งซื้อนี้
          message: context.wording.orderNotFoundMessage,
          // ตกลง
          confirmText: context.wording.ok,
          onConfirm: () {},
        );
      }
      // If pending, continue polling
    }
  }

  void onPurchaseClicked() async {
    if (_isPurchaseClicked) {
      return;
    }
    // flagกันคลิกเบิ้ล
    _purchaseClicked();

    final result = await _viewmodel.verifyOrder();
    if (!mounted) return;

    if (result.isEmpty &&
        (_viewmodel.paymentSelected!.isTpWallet ||
            _viewmodel.paymentSelected!.isCoin)) {
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
        title: title,
        message: message,
      );
      // flagกันคลิกเบิ้ล
      _clearPurchaseClicked();
      return;
    }
    TransactionAuthenPage.goToPage(context).then((
      result,
    ) async {
      if (!context.mounted) return;

      if (result is bool) {
        if (result) {
          // _startPolling(CouponOrderData(paymentRef: '20260208150706'));
          // return;

          AppOverlays.showLoading(
            context,
            timeout: Duration.zero,
          );
          final orderResult = await _viewmodel.createCouponOrder();

          if (!context.mounted) return;

          if (orderResult.isSuccess) {
            final orderResponse = orderResult.data!;
            final orderData = orderResponse.data;

            if (orderData == null) {
              AppOverlays.hideLoading();
              AppOverlays.showBrownyDialog(
                context,
                // ไม่สามารถสร้างคำสั่งซื้อได้
                message: context.wording.cannotCreateOrder,
              );
              // flagกันคลิกเบิ้ล
              _clearPurchaseClicked();
              return;
            }

            // เช็ค Status ว่าชำระเงินแล้ว
            if (orderResponse.data!.isPaid) {
              // ถ้าน้อยกว่าหรือ 0.0 บาท จะแสดง popup ไปหน้า receipt เลย
              _paymentProcessing = false;
              _currentOrderData = orderData;

              if (!mounted) return;
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
            _startPolling(orderData);
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
                              // กำลังดำเนินการ กรุณารอซักครู่...
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
        }
        return;
      } else {
        // flagกันคลิกเบิ้ล
        _clearPurchaseClicked();
      }
      // Handler develop
      // ถ้าส่ง type มาผิดจะ throw ให้ App Error
      throw Unprocessable();
    });
  }

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
        persistentFooterDecoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5), // Shadow color
              spreadRadius: 1, // How much the shadow should spread
              blurRadius: 10, // How soft the shadow should be
              offset: Offset(
                0,
                -2,
              ), // Negative dy value moves the shadow upwards
            ),
          ],
        ),
        persistentFooterButtons: [
          // ปุ่มยืนยันซื้อคูปอง
          ValueListenableBuilder(
            valueListenable: _viewmodel.paymentMethodNotifier,
            builder: (context, value, child) {
              return Container(
                padding: EdgeInsets.only(
                  left: AppDims.size_24.w,
                  right: AppDims.size_24.w,
                  top: AppDims.size_8.h,
                ),
                child: ElevatedButton(
                  onPressed: value.isSuccess ? onPurchaseClicked : null,
                  child: AppText(context.wording.makePayment),
                ),
              );
            },
          ),
        ],
        appBar: AppBar(
          title: AppText(
            // ทำการสั่งซื้อ
            context.wording.makeOrder,
            style: context.appBarTextThemeWhite,
          ),
          actions: [
            // แจ้งปัญหา
            IconButton(
              onPressed: () {
                ContactPage.goToPage(
                  context,
                  ContactProvider.helpAndProblemNoti,
                );
              },
              icon: Assets.svg.icHeadset.svg(),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Assets.png.bgAppBar.image(
              fit: BoxFit.cover,
            ),
          ),
        ),
        backgroundColor: AppColors.bareBackground,
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: AppDims.size_14.w,
              right: AppDims.size_14.w,
              top: AppDims.size_16.h,
            ),
            child: ValueListenableBuilder(
              valueListenable: _viewmodel.selectedPackageNotifier!,
              builder: (context, package, child) {
                return Column(
                  children: [
                    // สาขา
                    _card(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Assets.svg.icLocationRoundedGreen.svg(),
                          AppDims.horizonPadding_8,

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                context.wording.stores,
                                style: _textPrimary,
                              ),
                              AppText(
                                package!.storeNameDisplay(context),
                                style: context.textTheme.labelLarge!.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // คูปองและรหัสคูปองที่จะใช้ ปิดไปก่อน ยังใช้ไม่ได้
                    // Visibility(
                    //   visible: false,
                    //   child: _card(
                    //     child: Column(
                    //       children: [
                    //         AppDims.vericalPadding_14,

                    //         // Title
                    //         Row(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Assets.svg.icCouponRoundGreen.svg(),
                    //             AppDims.horizonPadding_8,

                    //             Expanded(
                    //               child: Row(
                    //                 mainAxisAlignment:
                    //                     MainAxisAlignment.spaceBetween,
                    //                 children: [
                    //                   SizedBox(
                    //                     child: AppText(
                    //                       'คูปองและรหัสคูปอง',
                    //                       style: _textPrimary,
                    //                     ),
                    //                   ),
                    //                   GestureDetector(
                    //                     onTap: () {},
                    //                     child: Assets.svg.icArrowForward.svg(),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         AppDims.vericalPadding_8,

                    //         CouponEVoucherCardWidget(
                    //           title: 'title',
                    //           description: 'description',
                    //           detailUsing: 'detailUsing',
                    //           expired: 'expired',
                    //           borderColor: AppColors.checkboxSelectedBg,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    AppDims.vericalPadding_14,

                    // สินค้าที่กำลังจะซื้อ
                    ValueListenableBuilder(
                      valueListenable: _viewmodel.couponDetailNotifier!,
                      builder: (context, couponDetailResult, child) {
                        // Success state - get data
                        final couponDetail = couponDetailResult.data!;
                        final couponData = couponDetail.coupon!;

                        // Use selected package or fallback to first package
                        final packageData = package;
                        return _card(
                          child: Column(
                            children: [
                              // Title
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Assets.svg.icLikeBadgeRoundedGreen.svg(),
                                  AppDims.horizonPadding_8,

                                  SizedBox(
                                    child: AppText(
                                      context.wording.products,
                                      style: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              AppDims.vericalPadding_8,

                              _buildItemCard(
                                context,
                                couponData,
                                packageData,
                                couponDetail,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    AppDims.vericalPadding_14,

                    // ประเภทชำระ
                    ValueListenableBuilder(
                      valueListenable: _viewmodel.paymentMethodNotifier,
                      builder: (context, value, child) {
                        if (value.isLoading) {
                          return _card(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (value.hasError) {
                          return _card(
                            child: AppText(context.wording.errorUi),
                          );
                        }

                        return _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Row(
                                children: [
                                  Assets.svg.icWalletRoundedGreen.svg(),
                                  AppDims.horizonPadding_8,

                                  Expanded(
                                    child: AppText(
                                      // เลือกวิธีชำระเงิน
                                      context.wording.selectPaymentMethod,
                                      style: _textPrimary,
                                    ),
                                  ),

                                  // ดูประเภทชำระทั้งหมด
                                  GestureDetector(
                                    onTap: () {
                                      context.pushNamed(
                                        AvailablePaymentMethodPage.pageName,
                                        extra: _viewmodel,
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        AppText(
                                          // ดูทั้งหมด
                                          context.wording.seeAll,
                                          style: _textPrimary,
                                        ),
                                        AppDims.horizonPadding_8,
                                        Assets.svg.icArrowForward.svg(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              AppDims.vericalPadding_8,

                              // ประเภทชำระแต่ละละแบบ ตามที่ API ส่งมา
                              ...value.data!
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
                                      //           placeholder: (_, _) => SizedBox(
                                      //             width: 22.w,
                                      //             height: 22.h,
                                      //           ),
                                      //           errorWidget: (_, _, _) =>
                                      //               SizedBox(
                                      //                 width: 22.w,
                                      //                 height: 22.h,
                                      //               ),
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
                          ),
                        );
                      },
                    ),
                    AppDims.vericalPadding_14,

                    // สรุปยอดเงิน
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Row(
                            children: [
                              Assets.svg.icListRoundedGreen.svg(),
                              AppDims.horizonPadding_8,

                              AppText(
                                // สรุปการสั่งซื้อ
                                context.wording.orderSummary,
                                style: _textPrimary,
                              ),
                            ],
                          ),
                          AppDims.vericalPadding_16,

                          // detail
                          // Title
                          _lineSummay(
                            // สรุปการสั่งซื้อ
                            title: context.wording.orderSummary,
                            price: package.price.ifNullOrEmpty('0.0'),
                          ),
                          AppDims.vericalPadding_16,
                          // ส่วนลดถ้ามี
                          _lineSummay(
                            // ส่วนลดสินค้า
                            title: context.wording.productDiscount,
                            price: '0',
                          ),
                          AppDims.vericalPadding_16,
                          // สรุปยอด
                          _lineSummay(
                            // ยอดชำระทั้งหมด
                            title: context.wording.totalPayment,
                            price: package.price.ifNullOrEmpty('0.0'),
                            textPriceColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    AppDims.vericalPadding_14,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    CouponData couponData,
    PackageDetailData packageData,
    CouponDetailModel couponDetail,
  ) {
    return CouponEVoucherCardWidget(
      icon: Image.network(
        couponData.couponImageDisplay(context),
        errorBuilder: (_, _, _) => _onImageError(),
      ),
      title: packageData.packageNameDisplay(context),
      description: packageData.storeNameDisplay(context),
      detailUsing: packageData.usageLabelDisplay(context),
      expired: couponData.usageDurationTextDisplay(context),
    );
  }

  Widget _onImageError() {
    return Container(
      color: AppColors.ci2,
    );
  }

  Widget _lineSummay({
    required String title,
    required String price,
    Color? textPriceColor,
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
            leadingSign: '฿',
          ),
          style: _textPrice.copyWith(color: textPriceColor),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
        vertical: AppDims.size_16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
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
    final isSelected = payment.isSelected;
    final isTPWallet = payment.isTpWallet;
    final isCoin = payment.isCoin;
    return GestureDetector(
      onTap: () {
        _viewmodel.onPaymentChanged(
          payment,
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: AppDims.size_8.h),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppDims.size_16.w : AppDims.size_8.w,
          vertical: isSelected ? AppDims.size_16.h : AppDims.size_8.h,
        ),
        decoration: isSelected
            ? BoxDecoration(
                border: BoxBorder.all(
                  color: AppColors.primary,
                  width: AppDims.size_2.h,
                ),
                borderRadius: BorderRadius.circular(
                  AppDims.size_8.r,
                ),
              )
            : null,
        child: Column(
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
                      width: AppDims.size_22.w,
                      height: AppDims.size_22.h,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => SizedBox(
                        width: AppDims.size_22.w,
                        height: AppDims.size_22.h,
                      ),
                      errorWidget: (_, _, _) => SizedBox(
                        width: AppDims.size_22.w,
                        height: AppDims.size_22.h,
                      ),
                    )
                  : null,
              title: AppText(
                payment.name,
                style: payment.isSelected ? _textPrimarySelected : _textPrimary,
              ),
              trailing: payment.isSelected
                  ? Padding(
                      padding: EdgeInsets.only(
                        right: AppDims.size_6.w,
                      ),
                      child: Assets.svg.icChecked.svg(),
                    )
                  : null,
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
                      // จำนวนเงินคงเหลือ
                      context.wording.balanceRemaining,
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
                  context.pushNamed(WalletPage.pageName);
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
    );
  }
}
