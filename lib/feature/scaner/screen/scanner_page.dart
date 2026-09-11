import 'package:browny_applications_new/core/utils/permission_helper.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/scaner/viewmodel/scanner_viewmodel.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({
    super.key,
    required this.process,
    this.initialIndex = 0,
  });

  final int initialIndex;
  final ScannerProcess process;

  static final pagePath = '/scanner';
  static final pageName = 'scannerPage';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    int initialIndex = 0,
    ScannerProcess process = ScannerProcess.machine,
  }) async {
    return await context.pushNamed(
      ScannerPage.pageName,
      extra: [
        initialIndex,
        process,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ScannerViewModel(
        context: context,
        process: process,
        repo: CustomerDataRepo(),
      ),
      child: _ScannerWidget(
        initialIndex: initialIndex,
      ),
    );
  }
}

class _ScannerWidget extends StatefulWidget {
  const _ScannerWidget({
    this.initialIndex = 0,
  });
  final int initialIndex;
  @override
  State<_ScannerWidget> createState() => __ScannerWidgetState();
}

class __ScannerWidgetState extends State<_ScannerWidget>
    with SingleTickerProviderStateMixin {
  late ScannerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ScannerViewModel>();
    _viewModel.attachContext(context);

    // Initialize camera controller
    _viewModel.cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: false,
    );

    // Initialize camera after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.initializeCamera(
        onPermissionDenied: () {
          AppOverlays.showBrownyDialog(
            context,
            imageAsset: Assets.png.brownyError2.path,
            // ไม่สามารถเปิดกล้องได้
            title: context.wording.cameraAccessDenied,
            // กรุณาให้สิทธิ์ใช้งานกล้องก่อนใช้งาน
            message: context.wording.cameraPermissionRequired,
            confirmText: context.wording.openSettings,
            onConfirm: () async {
              await PermissionHelper.openAppSettings();
            },
            cancelText: context.wording.cancel,
          );
        },
      );
      if (widget.initialIndex != 0) {
        await _viewModel.onTabChanged(widget.initialIndex);
      }
    });
  }

  @override
  void dispose() {
    try {
      _viewModel.cameraController.stop();
    } finally {
      _viewModel.cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex,
      child: ValueListenableBuilder(
        valueListenable: _viewModel.selectedTab,
        builder: (context, tabIndex, _) {
          return Scaffold(
            extendBody: tabIndex == 0,
            extendBodyBehindAppBar: tabIndex == 0,
            persistentFooterDecoration: BoxDecoration(),
            persistentFooterButtons: [
              tabIndex == 0
                  ? _buildBottomButtons(context)
                  : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDims.size_16.w,
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.safePop(),
                        child: AppText(context.wording.backToHome),
                      ),
                    ),
            ],
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(context, tabIndex),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // index 0 : Scanner
                _buildScannerView(context),

                // index 1 : QRCode
                ValueListenableBuilder(
                  valueListenable: _viewModel.qrNotifier,
                  builder: (context, result, child) {
                    if (result.isLoading) {
                      Future.microtask(_viewModel.fetchCustomerQRCode);

                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (result.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            Spacer(),
                            Assets.png.brownyError2.image(
                              width: 145.w,
                              height: 100.h,
                            ),
                            AppDims.vericalPadding_8,
                            // ไม่พบข้อมูล
                            AppText(
                              '${context.wording.dataNotFound} Browny ID',
                            ),
                            Spacer(),
                          ],
                        ),
                      );
                    }
                    return Center(
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
                          child: result.isLoading
                              ? CircularProgressIndicator()
                              : Container(
                                  width: 292.w,
                                  height: 427.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(
                                      16.r,
                                    ),
                                    border: BoxBorder.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10.r,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(
                                    AppDims.size_24.w,
                                  ),
                                  child: Column(
                                    children: [
                                      // PromptPay Logo
                                      Assets.png.brownyHorizaontal2.image(
                                        height: 44.w,
                                        width: 135.h,
                                      ),
                                      AppDims.vericalPadding_20,
                                      Divider(),
                                      AppDims.vericalPadding_16,

                                      // QR Code
                                      Image.network(result.data!.url!),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, int tabIndex) {
    return AppBar(
      backgroundColor: tabIndex == 0
          ? AppColors.black.withValues(alpha: 0.5)
          : AppColors.primary,
      bottom: TabBar(
        indicatorColor: tabIndex == 0 ? AppColors.primary : AppColors.white,
        dividerColor: AppColors.transparent,
        labelStyle: context.textTheme.titleMedium!.copyWith(
          color: tabIndex == 0 ? AppColors.primary : AppColors.white,
        ),
        unselectedLabelStyle: context.textTheme.titleMedium!.copyWith(
          color: tabIndex == 0 ? AppColors.gray500 : AppColors.white,
        ),
        onTap: (index) async {
          await _viewModel.onTabChanged(index);
        },
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Adjust alignment as needed
              children: [
                AppText(
                  context.wording.scanQR,
                ),
                SizedBox(width: 8), // Add spacing between text and icon
                Assets.svg.icScan2.svg(
                  colorFilter: ColorFilter.mode(
                    tabIndex == 0 ? AppColors.primary : AppColors.white,
                    BlendMode.srcIn,
                  ),
                ), // Your trailing icon
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Adjust alignment as needed
              children: [
                AppText(
                  context.wording.brownyID,
                ),
                SizedBox(width: 8), // Add spacing between text and icon
                Assets.svg.icQrDummy.svg(
                  colorFilter: ColorFilter.mode(
                    tabIndex == 0 ? AppColors.gray500 : AppColors.white,
                    BlendMode.srcIn,
                  ),
                ), // Your trailing icon
              ],
            ),
          ),
        ],
      ),
      title: AppText(
        context.wording.scanning,
        style: context.textTheme.titleLarge!.copyWith(
          color: AppColors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildScannerView(BuildContext context) {
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: _viewModel.cameraController,
          onDetect: _viewModel.onQRCodeDetected,
        ),

        // Scanning frame overlay
        Center(
          child: Assets.svg.icCrossHair.svg(),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_24.w,
        vertical: AppDims.size_32.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash button
          ValueListenableBuilder<bool>(
            valueListenable: _viewModel.isFlashOn,
            builder: (context, isFlashOn, _) {
              return _buildCircleButton(
                icon: Icons.flash_on,
                isActive: isFlashOn,
                onTap: _viewModel.toggleFlash,
              );
            },
          ),

          SizedBox(width: 48.w),

          // Gallery button
          _buildCircleButton(
            icon: Icons.image,
            isActive: false,
            onTap: _viewModel.pickImageAndScan,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.walletBackground
              : AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 28.sp,
        ),
      ),
    );
  }
}
