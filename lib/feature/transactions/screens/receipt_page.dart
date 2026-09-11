import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/utils/share_helper.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_receipt_model.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/history_transaction_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({
    super.key,
    required this.viewmodel,
  });

  final TransactionsViewmodel viewmodel;

  static final pagePath = '/receipt';
  static final pageName = 'receiptPage';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    required TransactionsViewmodel viewmodel,
  }) async {
    return await context.pushNamed(ReceiptPage.pageName, extra: viewmodel);
  }

  static void goReplacementPage(
    BuildContext context, {
    required TransactionsViewmodel viewmodel,
  }) {
    context.pushReplacementNamed(
      ReceiptPage.pageName,
      extra: viewmodel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewmodel,
      child: ReceiptWidget(
        viewmodel: viewmodel,
      ),
    );
  }
}

class ReceiptWidget extends StatefulWidget {
  const ReceiptWidget({
    super.key,
    required this.viewmodel,
  });

  final TransactionsViewmodel viewmodel;

  @override
  State<ReceiptWidget> createState() => _ReceiptWidgetState();
}

class _ReceiptWidgetState extends State<ReceiptWidget> {
  final GlobalKey _receiptKey = GlobalKey();

  /// Capture widget เป็นรูปภาพ
  Future<Uint8List?> _captureWidget() async {
    try {
      RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// แชร์ใบเสร็จ
  Future<void> _shareReceipt() async {
    try {
      // Capture widget
      final imageBytes = await _captureWidget();

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                context.wording.errorOccurred,
                style: context.textTheme.labelLarge!.copyWith(
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (!mounted) return;

      // แชร์รูปภาพ
      await ShareHelper.shareImage(
        imageBytes,
        fileName: 'browny_receipt_${DateTime.now().millisecondsSinceEpoch}.png',
        text: context.wording.brownyReceipt, // ใบเสร็จ Browny
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              '${context.wording.errorOccurred}: $e',
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// บันทึกใบเสร็จลงอุปกรณ์
  Future<void> _captureAndSaveReceipt() async {
    try {
      // Request storage permission using helper
      // final status = await PermissionHelper.requestStoragePermission(context);

      // if (status.isGranted || status.isLimited) {
      // Capture the widget
      final pngBytes = await _captureWidget();

      if (pngBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                context.wording.errorOccurred,
                style: context.textTheme.labelLarge!.copyWith(
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'browny_receipt_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                context.wording.saveTheReceipt,
                style: context.textTheme.labelLarge!.copyWith(
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                left: AppDims.size_24.w,
                right: AppDims.size_24.w,
                bottom: AppDims.size_24.w,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                context.wording.cannotSaveQRCode,
                style: context.textTheme.labelLarge!.copyWith(
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: AppDims.size_64.w,
              ),
            ),
          );
        }
      }
      // } else if (status.isPermanentlyDenied) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: AppText(
      //           context.wording.pleaseAllowPhotoLibraryAccess,
      //           style: context.textTheme.labelLarge!.copyWith(
      //             color: AppColors.white,
      //           ),
      //         ),
      //         backgroundColor: AppColors.error,
      //         action: SnackBarAction(
      //           label: context.wording.openSettings,
      //           textColor: AppColors.white,
      //           onPressed: () {
      //             PermissionHelper.openAppSettings();
      //           },
      //         ),
      //       ),
      //     );
      //   }
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              '${context.wording.errorOccurred}: $e',
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: AppDims.size_64.w,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        leading: widget.viewmodel.isFromHistory
            ? BackButton(
                color: AppColors.textPrimary,
                onPressed: () => context.safePop(),
              )
            : null,
        title: AppText(
          context.wording.receipt, // ใบเสร็จ
          style: context.textTheme.titleLarge!.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      persistentFooterDecoration: BoxDecoration(),
      persistentFooterButtons: [
        Container(
          padding: EdgeInsets.only(
            left: AppDims.size_24.w,
            right: AppDims.size_24.w,
            top: AppDims.size_8.h,
          ),
          child: ElevatedButton(
            onPressed: () {
              if (widget.viewmodel.isFromHistory) {
                context.popUntil(
                  predicate: (route) {
                    return route.name.orEmpty ==
                        HistoryTransactionPage.pageName;
                  },
                );
              } else {
                context.popUntil(
                  predicate: (route) {
                    return route.name.orEmpty == CouponVoucherPage.pageName;
                  },
                );
              }
            },
            child: AppText(
              widget.viewmodel.isFromHistory
                  ?
                    // กลับ
                    context.wording.back
                  :
                    // กลับสู่ E-Voucher
                    context.wording.backToEvoucher,
            ),
          ),
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card หลัก - ใบเสร็จ
            _capturableArea(
              child: ValueListenableBuilder(
                valueListenable: widget.viewmodel.transactionStateNotifier,
                builder: (context, result, child) {
                  // Loading state
                  if (result.isLoading || result.data?.isLoading == true) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Error state
                  if (result.hasError) {
                    return Center(
                      child: AppText(
                        // เกิดข้อผิดพลาด
                        result.error.toString(),
                      ),
                    );
                  }

                  // Error state
                  if (result.data?.hasError == true) {
                    return Center(
                      child: AppText(
                        // เกิดข้อผิดพลาด
                        result.data?.error?.toString() ??
                            context.wording.errorOccurred,
                      ),
                    );
                  }

                  // No receipt data
                  if (!result.data!.hasReceipt) {
                    return Center(
                      child: AppText(
                        context.wording.receiptNotFound,
                      ), // ไม่พบข้อมูลใบเสร็จ
                    );
                  }

                  final receiptData = result.data!.receipt!;
                  return Column(
                    children: [
                      AppDims.vericalPadding_24,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDims.size_24.w,
                        ),
                        child: Column(
                          children: [
                            Assets.png.brownySuccess.image(
                              width: AppDims.size_100.w,
                            ),
                            AppDims.vericalPadding_4,

                            AppText(
                              context
                                  .wording
                                  .operationSuccessful, // ดำเนินการสำเร็จ
                              style: context.textTheme.titleMedium!.copyWith(
                                color: AppColors.textBlack,
                              ),
                            ),
                            AppText(
                              receiptData.receiptDateDisplay(context),
                              style: context.textTheme.bodySmall!.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                            AppDims.vericalPadding_8,

                            Divider(),
                          ],
                        ),
                      ),
                      AppDims.vericalPadding_8,

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDims.size_24.w,
                        ),
                        child: Column(
                          children: [
                            // ข้อมูลเพิ่มเติมของใบเสร็จ
                            AppText(
                              receiptData.netPriceFormatted,
                              style: context.textTheme.displayLarge!.copyWith(
                                color: AppColors.primary,
                                fontSize: AppDims.size_36.sp,
                              ),
                            ),
                            // Browny Coin Bonus
                            if (receiptData.bonus.orEmpty.isNotEmpty) ...[
                              AppDims.vericalPadding_4,
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppDims.size_2.h,
                                  horizontal: AppDims.size_8.w,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.walletCoinBonusGradient,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Assets.png.brownyCoin.image(
                                      width: 20.w,
                                      height: 20.w,
                                    ),
                                    SizedBox(width: 8.w),
                                    AppText(
                                      // คุณได้รับโบนัส
                                      context.wording.youReceivedBonus,
                                      style: context.textTheme.labelMedium!
                                          .copyWith(
                                            color: AppColors.cocoaBrown,
                                          ),
                                    ),
                                    AppText(
                                      ' Browny Coin ${formatCurrency(string: receiptData.bonus, leadingSign: '+ ')}',
                                      style: context.textTheme.labelMedium!
                                          .copyWith(
                                            color: AppColors.cocoaBrown,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            AppDims.vericalPadding_16,

                            _listTile(
                              // Order ID
                              leading: 'Order ID',
                              trailing: receiptData.receiptNo.orEmpty,
                            ),
                            _listTile(
                              // Date
                              leading: context.wording.dateTime, // วัน / เวลา
                              trailing: receiptData.receiptDateDisplay(
                                context,
                              ),
                            ),
                            _listTile(
                              // Payment Method
                              leading: context
                                  .wording
                                  .paymentMethod, // ช่องทางการชำระเงิน
                              trailing: receiptData.paymentMethodNameDisplay(
                                context,
                              ),
                            ),
                            AppDims.vericalPadding_4,
                            _listTile(
                              // Icon
                              leading: '',
                              trailing: '',
                              trailingWidget: Image.network(
                                width: AppDims.size_30.w,
                                height: AppDims.size_30.h,
                                receiptData.paymentIcon.orEmpty,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.account_balance_rounded,
                                    ),
                              ),
                            ),
                            AppDims.vericalPadding_8,

                            Divider(),
                          ],
                        ),
                      ),
                      AppDims.vericalPadding_8,

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDims.size_24.w,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _listTile(
                              // การสั่งซื้อ
                              leading:
                                  context.wording.orderLabel, // การสั่งซื้อ
                              trailing: '',
                            ),
                            _listTile(
                              // การสั่งซื้อ
                              leading: receiptData.packageNameDisplay(
                                context,
                              ),
                              trailing: '',
                              trailingWidget: AppText(
                                receiptData.totalPriceFormatted,
                                style: context.textTheme.headlineMedium!
                                    .copyWith(
                                      fontSize: AppDims.size_14.sp,
                                      color: AppColors.gray600,
                                    ),
                              ),
                            ),
                            _listTile(
                              // คูปองส่วนลด
                              leading: context.wording.savedAmount, // ประหยัดไป
                              trailing: '',
                              trailingWidget: AppText(
                                receiptData.savePriceFormatted,
                                style: context.textTheme.headlineMedium!
                                    .copyWith(
                                      fontSize: AppDims.size_14.sp,
                                      color: AppColors.error,
                                    ),
                              ),
                            ),
                            _listTile(
                              // E-Voucher
                              leading: context
                                  .wording
                                  .totalPayment, // ยอดชำระทั้งหมด
                              trailing: '',
                              trailingWidget: AppText(
                                receiptData.netPriceFormatted,
                                style: context.textTheme.headlineMedium!
                                    .copyWith(
                                      fontSize: AppDims.size_14.sp,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ),
                            AppDims.vericalPadding_16,

                            _listTile(
                              // Icon
                              leading: '',
                              trailing: '',
                              trailingWidget: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppDims.size_2.h,
                                  horizontal: AppDims.size_4.w,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bareBackground,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(AppDims.size_4.r),
                                  ),
                                ),
                                child: AppText(
                                  context
                                      .wording
                                      .qrCodeForSupportOnly, // QR Code สำหรับฝ่าย Browny Support เท่านั้น
                                  style: context.textTheme.labelSmall!.copyWith(
                                    fontSize: AppDims.size_10.sp,
                                  ),
                                ),
                              ),
                            ),
                            // AppDims.vericalPadding_10,
                            Image.network(
                              receiptData.qrImage.orEmpty,
                              width: 90.w,
                              height: 90.w,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) =>
                                  SizedBox(),
                            ),
                          ],
                        ),
                      ),

                      AppDims.vericalPadding_24,

                      Align(
                        alignment: AlignmentGeometry.bottomCenter,
                        child: Image.network(receiptData.luckyImage.orEmpty),
                      ),
                    ],
                  );
                },
              ),
            ),
            AppDims.vericalPadding_24,

            // ปุ่ม แชร์ และ บันทึกใบเสร็จ
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ปุ่มแชร์
                InkResponse(
                  onTap: _shareReceipt,
                  child: Column(
                    children: [
                      Assets.svg.icShare.svg(),
                      AppDims.vericalPadding_8,
                      AppText(
                        context.wording.share,
                        style: context.textTheme.labelSmall!.copyWith(
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                AppDims.horizonPadding_32,
                // ปุ่มบันทึกใบเสร็จ
                InkResponse(
                  onTap: _captureAndSaveReceipt,
                  child: Column(
                    children: [
                      Assets.svg.icDownStorage.svg(),
                      AppDims.vericalPadding_8,
                      AppText(
                        context.wording.saveTheReceipt,
                        style: context.textTheme.labelSmall!.copyWith(
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppDims.vericalPadding_24,
            // SizedBox(
            //   height: AppDims.size_100.h,
            // ), // Space for bottom sheet button
          ],
        ),
      ),
    );
  }

  Widget _listTile({
    required String leading,
    Widget? leadingWidget,
    required String trailing,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDims.size_2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child:
                leadingWidget ??
                AppText(
                  leading,
                  style: context.textTheme.titleMedium!.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
          ),
          trailingWidget ??
              AppText(
                trailing,
                style: context.textTheme.titleMedium!.copyWith(
                  color: AppColors.gray600,
                ),
              ),
        ],
      ),
    );
  }

  Widget _capturableArea({required Widget child}) {
    return RepaintBoundary(
      key: _receiptKey,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          image: DecorationImage(
            alignment: AlignmentGeometry.topCenter,
            image: Assets.png.bgPawnPattern.provider(),
            repeat: ImageRepeat.repeatY,
            isAntiAlias: true,
            opacity: 0.15,
          ),
          borderRadius: BorderRadius.circular(AppDims.size_16.r),
          boxShadow: AppColors.defatultShadow,
        ),
        // padding: EdgeInsets.all(AppDims.size_24.w),
        margin: EdgeInsets.all(AppDims.size_15.w),
        child: child,
      ),
    );
  }
}
