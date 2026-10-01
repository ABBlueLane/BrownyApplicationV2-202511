import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/ui_result.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/contacts/models/contact_model.dart';
import 'package:browny_applications_new/feature/contacts/screens/contact_page.dart';
import 'package:browny_applications_new/feature/scaner/screen/scanner_page.dart';
import 'package:browny_applications_new/feature/wallet/models/wallet_model.dart';
import 'package:browny_applications_new/feature/wallet/screen/show_qr_promptpay_page.dart';
import 'package:browny_applications_new/feature/wallet/screen/topup_widget.dart';
import 'package:browny_applications_new/feature/wallet/screen/wallet_history_page.dart';
import 'package:browny_applications_new/feature/wallet/viewmodel/wallet_viewmodel.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  static final pagePath = '/wallet';
  static final pageName = 'walletPage';

  /// util function route to pageName
  static Future<T?> goToPage<T>(BuildContext context) async {
    return await context.pushNamed(WalletPage.pageName);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WalletViewModel(context: context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        onVerticalDragEnd: (drag) =>
            FocusManager.instance.primaryFocus?.unfocus(),
        child: WalletWidget(),
      ),
    );
  }
}

class WalletWidget extends StatefulWidget {
  const WalletWidget({super.key});

  @override
  State<WalletWidget> createState() => _WalletWidgetState();
}

class _WalletWidgetState extends State<WalletWidget> {
  late WalletViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read();
    _viewModel.attachContext(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchCredit();
      // แสดง popup แจ้งเตือนจาก API (ถ้ามี)
      _viewModel.showFirstNotificationIfNeeded();
    });
  }

  /// สร้าง IconButton.filled พร้อม style และ color filter สำหรับ SVG
  Widget _buildWalletIconButton(
    bool isSelected, {
    required SvgGenImage svgIcon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: isSelected ? AppColors.paleOrange : AppColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: CircleBorder(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDims.size_13.w,
            vertical: AppDims.size_8.h,
          ),
          decoration: BoxDecoration(
            // color: isSelected ? AppColors.paleOrange : AppColors.background,
            border: Border.all(
              color: isSelected ? AppColors.cocoaBrown : AppColors.border,
              width: 1,
            ),
            shape: BoxShape.circle,
          ),
          child: svgIcon.svg(
            width: 24.w,
            height: 24.h,
            colorFilter: ColorFilter.mode(
              isSelected ? AppColors.cocoaBrown : AppColors.textBlack,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.walletBackground,
      // ปุ่มยืนยันการเติมเงิน
      bottomSheet: _buildSummitButton(context),
      // AppBa ปุ่มย้อนกลับและติดต่อขอช่วยเหลือ
      appBar: _buildAppBar(context),
      body: ValueListenableBuilder(
        valueListenable: _viewModel.walletNotifier,
        builder: (context, result, _) {
          if (result.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.walletBackground,
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Background ที่เป็น Object
              _buildBackgroundObject(),

              // onBackground Container สีขาว
              ValueListenableBuilder(
                valueListenable: _viewModel.procesStateNotfier,
                builder: (context, state, _) {
                  switch (state) {
                    case WalletProcessState.topup:
                      // return _buildContentAndAmountBadge(context, result);
                      return TopupWidget(
                        viewModel: _viewModel,
                        result: result,
                      );
                    case WalletProcessState.scan:
                      // TODO: Handle this case.
                      throw UnimplementedError();
                    case WalletProcessState.history:
                      return WalletHistoryPage(
                        viewModel: _viewModel,
                        result: result,
                      );
                  }
                },
              ),

              // Card แสดงยอดเงิน และ ปุุ่ม เติมเงิน, แสกนจ่าย, ประวัติ
              _buildCard(context, result),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, UiResult<WalletModel> result) {
    return SizedBox(
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDims.size_24.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppDims.vericalPadding_32,
              // Card Balance
              SizedBox(
                width: 305.w,
                height: 187.h,
                child: Card(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: 24,
                      right: 14,
                      top: 24,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          AppText(
                            context.wording.balanceRemaining,
                            style: context.textTheme.bodySmall!.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppDims.vericalPadding_4,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: null,
                                icon: Assets.svg.icObscureOn.svg(
                                  colorFilter: ColorFilter.mode(
                                    AppColors.transparent,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: _viewModel.isObscure,
                                builder: (context, isObscure, _) => AppText(
                                  isObscure
                                      ? '฿****'
                                      : '฿${result.requireData.creditBalance}',
                                  style: context.textTheme.headlineLarge!
                                      .copyWith(
                                        fontSize: AppDims.size_36.sp,
                                        color: AppColors.textBlack,
                                      ),
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: _viewModel.isObscure,
                                builder: (context, isObscure, _) => IconButton(
                                  onPressed: () => _viewModel.onObscureChange(),
                                  padding: EdgeInsets.zero,
                                  style: ButtonStyle(
                                    overlayColor: WidgetStatePropertyAll(
                                      AppColors.paleOrange,
                                    ),
                                  ),
                                  icon:
                                      (isObscure
                                              ? Assets.svg.icObscureOff
                                              : Assets.svg.icObscureOn)
                                          .svg(
                                            width: 20.w,
                                            height: 20.h,
                                          ),
                                ),
                              ),
                            ],
                          ),
                          AppDims.vericalPadding_12,

                          ValueListenableBuilder(
                            valueListenable: _viewModel.procesStateNotfier,
                            builder: (context, state, _) {
                              return Row(
                                spacing: AppDims.size_16.w,
                                mainAxisAlignment: MainAxisAlignment.center,
                                // mainAxisAlignment:
                                //     MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      _buildWalletIconButton(
                                        // deposit
                                        state == WalletProcessState.topup,
                                        svgIcon: Assets.svg.icDownload,
                                        onPressed: () =>
                                            _viewModel.onProcessStateChange(
                                              WalletProcessState.topup,
                                            ),
                                      ),
                                      AppDims.vericalPadding_2,
                                      AppText(
                                        // เติมเงิน
                                        context.wording.topup,
                                        style: context.textTheme.bodySmall!
                                            .copyWith(
                                              fontSize: AppDims.size_10.sp,
                                              color: AppColors.textBlack,
                                            ),
                                      ),
                                    ],
                                  ),

                                  Column(
                                    children: [
                                      _buildWalletIconButton(
                                        // scan
                                        state == WalletProcessState.scan,
                                        svgIcon: Assets.svg.icScan,
                                        onPressed: () => ScannerPage.goToPage(
                                          context,
                                        ),
                                      ),
                                      AppDims.vericalPadding_2,
                                      AppText(
                                        context.wording.scan,
                                        style: context.textTheme.bodySmall!
                                            .copyWith(
                                              fontSize: AppDims.size_10.sp,
                                              color: AppColors.textBlack,
                                            ),
                                      ),
                                    ],
                                  ),

                                  Column(
                                    children: [
                                      _buildWalletIconButton(
                                        // history
                                        state == WalletProcessState.history,
                                        svgIcon: Assets.svg.icHistory,
                                        onPressed: () =>
                                            _viewModel.onProcessStateChange(
                                              WalletProcessState.history,
                                            ),
                                      ),
                                      AppDims.vericalPadding_2,
                                      AppText(
                                        context.wording.history,
                                        style: context.textTheme.bodySmall!
                                            .copyWith(
                                              fontSize: AppDims.size_10.sp,
                                              color: AppColors.textBlack,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundObject() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Assets.png.walletObjBg.image(
        fit: BoxFit.contain,
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.walletBackground,
      title: AppText(
        'TP+ Wallet',
        style: context.textTheme.titleLarge!.copyWith(color: AppColors.white),
      ),
      actions: [
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
    );
  }

  Widget _buildSummitButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDims.size_24.w,
        right: AppDims.size_24.w,
        // bottom: AppDims.size_24.w,
        bottom: MediaQuery.of(context).viewPadding.bottom,
        top: AppDims.size_8.w,
      ),
      child: ElevatedButton(
        onPressed: () async {
          AppOverlays.showLoading(
            context,
            timeout: Duration(seconds: 10),
            progressColors: AppColors.walletBackground,
          );
          final result = await _viewModel.onSummitClick();
          AppOverlays.hideLoading();

          if (result.hashData && context.mounted) {
            // Navigate to QR page with ViewModel
            _viewModel.clearValue();
            context.pushNamed(
              ShowQRPromptpayPage.pageName,
              extra: _viewModel,
            );
          } else if (result.hasError && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText(
                  'เกิดข้อผิดพลาดในการสร้าง QR Code',
                  style: context.textTheme.labelLarge!.copyWith(
                    color: AppColors.white,
                  ),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        style: context.appTheme.elevatedButtonTheme.style!.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            AppColors.walletBackground,
          ),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return AppColors.walletBackgroundHover.withValues(
                  alpha: 0.1,
                );
              }
              if (states.contains(WidgetState.pressed)) {
                return AppColors.walletBackgroundClicked.withValues(
                  alpha: 0.7,
                );
              }
              return null;
            },
          ),
        ),
        child: AppText(context.wording.topup),
      ),
    );
  }
}
