import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/share_helper.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/wallet/viewmodel/wallet_viewmodel.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    super.key,
    required this.viewmodel,
  });

  static const pagePath = '/payment-success';
  static const pageName = 'paymentSuccessPage';
  final WalletViewModel viewmodel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewmodel,
      child: PaymentSuccessWidget(
        viewmodel: viewmodel,
      ),
    );
  }
}

class PaymentSuccessWidget extends StatefulWidget {
  const PaymentSuccessWidget({
    super.key,
    required this.viewmodel,
  });

  final WalletViewModel viewmodel;

  @override
  State<PaymentSuccessWidget> createState() => _PaymentSuccessWidgetState();
}

class _PaymentSuccessWidgetState extends State<PaymentSuccessWidget> {
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.viewmodel.recieptDataNotifier.addListener(() {
        if (widget.viewmodel.recieptDataNotifier.value.hasError) {
          AppOverlays.showWalletDialog(
            context,
            // เติมเงินไม่สำเร็จ
            title: context.wording.topUpFailed,
            // เนื่องจากธนาคารปลายทางมีปัญหา หรือเงินในบัญชีอาจไม่พอ กรุณาตรวจสอบรายการใหม่อีกครั้ง
            message: context.wording.topUpFailedMessage,
            confirmText: context.wording.tryAgain,
            onConfirm: () async {
              if (context.mounted) {
                await widget.viewmodel.fetchReceiptData(context);
              }
            },
            cancelText: context.wording.reportAnIssue,
            onCancel: () {},
          );
        }
      });
      await widget.viewmodel.fetchReceiptData(context);
    });
  }

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

      // แชร์รูปภาพ
      await ShareHelper.shareImage(
        imageBytes,
        fileName: 'browny_receipt_${DateTime.now().millisecondsSinceEpoch}.png',
        text: 'Browny TP+ Wallet',
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
        name: 'promptpay_qr_${DateTime.now().millisecondsSinceEpoch}',
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
              backgroundColor: AppColors.walletBackground,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                left: AppDims.size_24.w,
                right: AppDims.size_24.w,
                bottom: AppDims.size_84.w,
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
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () => context.safePop(),
        ),
        title: AppText(
          context.wording.transactionReceipt,
          style: context.textTheme.titleLarge!.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.only(
          left: AppDims.size_24.w,
          right: AppDims.size_24.w,
          bottom: AppDims.size_24.w,
          top: AppDims.size_8.w,
        ),
        child: ElevatedButton(
          onPressed: () {
            context.safePop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkBlue,
            foregroundColor: AppColors.white,
            minimumSize: Size(double.infinity, 48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: AppText(
            context.wording.backToTopUpPage,
            style: context.textTheme.labelLarge!.copyWith(
              color: AppColors.white,
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.viewmodel.recieptDataNotifier,
        builder: (context, result, _) {
          if (result.isLoading) {
            return SizedBox.expand(
              child: Container(
                color: AppColors.background,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          if (result.hasError) {
            return SizedBox.expand(
              child: Container(
                color: AppColors.background,
                child: SizedBox(),
              ),
            );
          }

          final receiptData = result.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDims.size_24.w,
                vertical: AppDims.size_24.h,
              ),
              child: SizedBox(
                child: Column(
                  children: [
                    AppDims.vericalPadding_32,
                    // Card หลัก
                    RepaintBoundary(
                      key: _receiptKey,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: BoxBorder.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.all(AppDims.size_24.w),
                        child: Column(
                          children: [
                            // TP+ Wallet Icon
                            Assets.svg.icTpWallet.svg(
                              width: 54.w,
                              height: 50.w,
                            ),
                            AppDims.vericalPadding_8,

                            // ทำรายการสำเร็จ
                            AppText(
                              context.wording.transactionSuccessful,
                              style: context.textTheme.bodySmall!.copyWith(
                                color: AppColors.textBlack,
                              ),
                            ),
                            AppDims.vericalPadding_4,

                            // วันที่เวลา
                            AppText(
                              receiptData.confirmedDateTime,
                              style: context.textTheme.bodySmall!.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: AppDims.size_10.sp,
                              ),
                            ),
                            AppDims.vericalPadding_16,

                            // Divider
                            Divider(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.2,
                              ),
                              height: 1,
                            ),
                            AppDims.vericalPadding_4,

                            // จำนวนเงิน
                            AppText(
                              formatCurrency(
                                leadingSign: '฿ ',
                                string: receiptData.amount.orEmpty.ifEmpty(
                                  '0.0',
                                ),
                              ),
                              style: context.textTheme.headlineLarge!.copyWith(
                                color: AppColors.textBlack,
                                fontSize: AppDims.size_36.sp,
                              ),
                            ),
                            AppDims.vericalPadding_4,
                            // Browny Coin Bonus
                            if (result.data!.bonus.orEmpty.isNotEmpty)
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
                                      context.wording.youReceivedBonus,
                                      style: context.textTheme.labelMedium!
                                          .copyWith(
                                            color: AppColors.cocoaBrown,
                                          ),
                                    ),
                                    AppText(
                                      ' Browny Coin ${formatCurrency(string: result.data!.bonus, leadingSign: '+ ')}',
                                      style: context.textTheme.labelMedium!
                                          .copyWith(
                                            color: AppColors.cocoaBrown,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            AppDims.vericalPadding_12,

                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ข้อมูลการโอน - จาก
                                    Row(
                                      children: [
                                        // ข้อมูลการโอน - จาก
                                        Assets.png.promptpayBadge.image(
                                          width: 150.w,
                                        ),
                                      ],
                                    ),
                                    AppDims.vericalPadding_8,
                                    // ลูกศรลง
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 24.w,
                                      color: AppColors.gray500,
                                    ),
                                    AppDims.vericalPadding_8,

                                    // ข้อมูลการโอน - ถึง
                                    Row(
                                      children: [
                                        Container(
                                          width: 36.w,
                                          height: 36.h,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.border,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              100.r,
                                            ),
                                          ),
                                          child: Assets.svg.icTpWallet.svg(
                                            width: 22.w,
                                            height: 20.h,
                                            fit: BoxFit.none,
                                          ),
                                        ),
                                        AppDims.horizonPadding_8,

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              'TP+ Wallet',
                                              style: context
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: AppColors.textBlack,
                                                  ),
                                            ),
                                            AppText(
                                              result.data!.walletShow,
                                              style: context
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize:
                                                        AppDims.size_10.sp,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    AppDims.vericalPadding_16,
                                    // เลขที่รายการ
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        AppText(
                                          context.wording.transactionNumber,
                                          style: context.textTheme.labelMedium!
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                        AppText(
                                          receiptData.receiptNo.orEmpty,
                                          style: context.textTheme.labelMedium!
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        receiptData.qrImage.orEmpty,
                                        width: 58.w,
                                        height: 58.w,
                                        fit: BoxFit.fill,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => QrImageView(
                                              data: receiptData.qrImage.orEmpty,
                                              version: QrVersions.auto,
                                              size: 58.w,
                                              backgroundColor: Colors.white,
                                              errorCorrectionLevel:
                                                  QrErrorCorrectLevel.M,
                                            ),
                                      ),
                                      AppText(
                                        context
                                            .wording
                                            .qrCodeForSupportOnly, // QR Code สำหรับฝ่าย Browny Support เท่านั้น
                                        style: context.textTheme.labelSmall!
                                            .copyWith(
                                              fontSize: AppDims.size_7.sp,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                    SizedBox(height: 100.h), // Space for bottom sheet button
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
