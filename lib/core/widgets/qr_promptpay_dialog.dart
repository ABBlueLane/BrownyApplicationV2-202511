import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:browny_applications_new/core/core_index.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPromptpayDialog extends StatefulWidget {
  const QrPromptpayDialog({
    super.key,
    required this.qrData,
    required this.paymentDadge,
    // this.isQRPromptPay = true,
  });

  final String qrData;
  // final bool isQRPromptPay;
  final AssetGenImage paymentDadge;

  @override
  State<QrPromptpayDialog> createState() => _QrPromptpayDialogState();
}

class _QrPromptpayDialogState extends State<QrPromptpayDialog>
    with SingleTickerProviderStateMixin {
  final GlobalKey _qrKey = GlobalKey();
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  bool _isDownloadSuccess = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flashController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _playFlashAnimation() async {
    for (int i = 0; i < 1; i++) {
      await _flashController.forward();
      await _flashController.reverse();
      if (i < 1) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// DONG 2026-02-15
  /// เปลี่ยนวิธีการแสดง QRCode เพราะมีปัญหาเรื่องการ capture Image ที่แสดงผ่าน ​WebView ไม่ได้
  /// Extract QR code data string from URL
  /// Example: https://dev.abgroup.co.th/pay/wallet/00020101021...
  /// Returns: 00020101021...
  String? _extractQRDataFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    // Get the last segment of the path
    final segments = uri.pathSegments;
    if (segments.isEmpty) return url;

    final qrData = segments.last;

    // Validate if it looks like PromptPay QR data (starts with 00020101)
    if (qrData.startsWith('00020101')) {
      return qrData;
    }

    // If not, return the original URL (might be direct QR string)
    return url;
  }

  Future<void> _captureAndSaveQR() async {
    try {
      // Request storage permission using helper
      // final status = await PermissionHelper.requestStoragePermission(context);

      // if (status.isGranted || status.isLimited) {
      // Capture the widget
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'promptpay_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          await _playFlashAnimation();
          setState(() {
            _isDownloadSuccess = true;
          });
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _isDownloadSuccess = false;
            });
          }
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
                bottom: AppDims.size_16.w,
                left: AppDims.size_16.w,
                right: AppDims.size_16.w,
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
              bottom: AppDims.size_16.w,
              left: AppDims.size_16.w,
              right: AppDims.size_16.w,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        AppOverlays.showBrownyDialog(
          context,
          title: context.wording.cancelTransaction,
          message: context.wording.confirmCancelTransaction,
          confirmText: context.wording.confirm,
          cancelText: context.wording.cancel,
          onConfirm: () {
            context.safePop();
          },
        );
      },
      child: Scaffold(
        persistentFooterDecoration: BoxDecoration(),
        persistentFooterButtons: [
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDims.size_24.w,
              ),
              child: ElevatedButton(
                onPressed: () {
                  AppOverlays.showBrownyDialog(
                    context,
                    title: context.wording.cancelTransaction,
                    message: context.wording.confirmCancelTransaction,
                    confirmText: context.wording.confirm,
                    cancelText: context.wording.cancel,
                    onConfirm: () {
                      context.safePop();
                    },
                  );
                },
                child: AppText(
                  context.wording.backToHome,
                  style: context.textTheme.labelLarge!.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
        appBar: AppBar(
          title: AppText(
            context.wording.payment,
            style: context.appBarTextThemeWhite,
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Assets.png.bgAppBar.image(
              fit: BoxFit.cover,
            ),
          ),
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.centerRight,
                colors: [
                  AppColors.ci2.withValues(
                    alpha: 0.03,
                  ),
                  AppColors.background,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDims.size_42.w,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // QR Code Section
                      AnimatedBuilder(
                        animation: _flashAnimation,
                        builder: (context, child) => Stack(
                          children: [
                            child!,
                            if (_flashAnimation.value > 0)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.walletBackground
                                        .withValues(
                                          alpha: _flashAnimation.value * 0.3,
                                        ),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: _qrKey,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10.r,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(AppDims.size_24.w),
                            child: Column(
                              children: [
                                // PromptPay Logo
                                // if (widget.isQRPromptPay) ...[
                                // Assets.png.promptpayBadgeNoLine.image(
                                widget.paymentDadge.image(
                                  height: 73.w,
                                  width: 228.h,
                                ),
                                AppDims.vericalPadding_16,
                                Divider(),

                                // ],
                                AppDims.vericalPadding_16,

                                QrImageView(
                                  data: _extractQRDataFromUrl(widget.qrData)!,
                                  version: QrVersions.auto,
                                  size: 228.w,
                                  backgroundColor: Colors.white,
                                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                                ),

                                AppDims.vericalPadding_16,
                              ],
                            ),
                          ),
                        ),
                      ),

                      AppDims.vericalPadding_24,

                      // ปุ่มบันทึกรูปภาพ
                      GestureDetector(
                        onTap: _captureAndSaveQR,
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isDownloadSuccess
                                  ? Assets.svg.icChecked2.svg(
                                      width: AppDims.size_20.w,
                                      key: const ValueKey('checked'),
                                    )
                                  : Assets.svg.icDownStorage.svg(
                                      width: AppDims.size_20.w,
                                      key: const ValueKey('download'),
                                    ),
                            ),
                            AppDims.vericalPadding_8,
                            AppText(
                              context.wording.save,
                              style: context.textTheme.labelLarge!.copyWith(
                                color: AppColors.textBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
