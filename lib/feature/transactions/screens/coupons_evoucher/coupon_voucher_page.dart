import 'dart:async';
import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/feature/authentication/screen/authentication_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/authentication_viewmodel.dart';
import 'package:browny_applications_new/feature/scaner/screen/scanner_page.dart';
import 'package:browny_applications_new/feature/scaner/viewmodel/scanner_viewmodel.dart';
import 'package:browny_applications_new/feature/transactions/models/customer_coupon_model.dart';
import 'package:browny_applications_new/feature/transactions/models/machine_program_model.dart';
import 'package:browny_applications_new/feature/transactions/repository/coupon_voucher_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/machine_transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';

enum CouponVoucherState {
  using,
  purshasing,
  redeeming,
  brownyShop,
}

class CouponVoucherPage extends StatelessWidget {
  const CouponVoucherPage({
    super.key,
    required this.state,
    this.autoCollectQRData,
    this.machineProgram,
  });

  static final pagePath = '/coupon_voucher';
  static final pageName = 'CouponVoucherPage';
  final CouponVoucherState state;

  /// QR data สำหรับ auto-collect เมื่อ scan จากหน้า Home
  final String? autoCollectQRData;

  /// MachineProgramModel จาก MachineTransactionPage
  /// ใช้สำหรับ derive availableCoupons filter, selectedCoupon
  /// และ re-fetch หลัง collectCoupon สำเร็จ
  final MachineProgramModel? machineProgram;

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    CouponVoucherState state = CouponVoucherState.purshasing,
    String? autoCollectQRData,
    MachineProgramModel? machineUsing,
  }) async {
    if (context.read<CustomerProvider>().current.isGuest) {
      return await AuthenticationPage.goToPage(
        context,
        process: AuthenProcess.login,
      );
    }
    return await context.pushNamed(
      CouponVoucherPage.pageName,
      extra: [state, autoCollectQRData, machineUsing],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TransactionsViewmodel(
        context: context,
        couponRepo: CouponVoucherRepo(),
        transactionRepo: TransactionRepo(),
        machineRepo: MachineRepo(),
      ),
      child: _CouponVoucherWidget(
        state: state,
        autoCollectQRData: autoCollectQRData,
        machineProgram: machineProgram,
      ),
    );
  }
}

class _CouponVoucherWidget extends StatefulWidget {
  const _CouponVoucherWidget({
    required this.state,
    this.autoCollectQRData,
    this.machineProgram,
  });

  final CouponVoucherState state;
  final String? autoCollectQRData;
  final MachineProgramModel? machineProgram;

  @override
  State<_CouponVoucherWidget> createState() => _CouponVoucherWidgetState();
}

class _CouponVoucherWidgetState extends State<_CouponVoucherWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TransactionsViewmodel _viewmodel;

  /// คืนค่าดัชนีเริ่มต้นของ TabBar ตามสถานะปัจจุบันของ widget
  /// - สำหรับ 'using' หรือ 'purshasing' จะคืนค่า 1
  /// - สำหรับ 'redeeming' จะคืนค่า 0
  /// - สำหรับ 'brownyShop' จะคืนค่า 2
  int get initialIndexByState {
    switch (widget.state) {
      case CouponVoucherState.using:
      case CouponVoucherState.purshasing:
        return 1;
      case CouponVoucherState.redeeming:
        return 0;
      case CouponVoucherState.brownyShop:
        return 2;
    }
  }

  @override
  void initState() {
    super.initState();
    _viewmodel = context.read();
    _viewmodel.attachContext(context);
    _viewmodel.machineProgram = widget.machineProgram;
    // เก็บ State ปัจจุบันที่เปิดหน้า coupon
    _viewmodel.couponState = widget.state;
    _tabController = TabController(
      initialIndex: initialIndexByState,
      length: 3,
      vsync: this,
    );

    // collectCoupon สำเร็จ (กรอกรหัส/สแกนเอง ไม่ใช่ auto-scan) → เลื่อนกลับ tab แรก
    _viewmodel.onCouponCollected = () {
      if (_tabController.index != 0) {
        _tabController.animateTo(0);
      }
    };

    // Auto-collect coupon เมื่อ scan QR จากหน้า Home
    if (widget.autoCollectQRData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewmodel.collectCoupon(
          widget.autoCollectQRData,
          'qr',
          // from auto scan
          true,
        );
      });
    }
  }

  @override
  void dispose() {
    _viewmodel.onCouponCollected = null;
    _tabController.dispose();
    super.dispose();
  }

  BoxDecoration? _persistentFooterDecorationByState() {
    if (widget.state == CouponVoucherState.purshasing) {
      return BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5), // Shadow color
            spreadRadius: 1, // How much the shadow should spread
            blurRadius: 10, // How soft the shadow should be
            offset: Offset(
              0,
              -5,
            ), // Negative dy value moves the shadow upwards
          ),
        ],
      );
    }

    return null;
  }

  List<Widget>? _persistentFooterButtonsByState() {
    if (widget.state == CouponVoucherState.purshasing) {
      return [
        Container(
          padding: EdgeInsets.only(
            left: AppDims.size_24.w,
            right: AppDims.size_24.w,
            top: AppDims.size_8.h,
          ),
          child: ElevatedButton(
            onPressed: () {
              context.safePop();
            },
            // ดำเนินการต่อโดยไม่ใช้คูปอง
            child: AppText(context.wording.continueWithoutCoupon),
          ),
        ),
      ];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bareBackground,
      persistentFooterDecoration: _persistentFooterDecorationByState(),
      persistentFooterButtons: _persistentFooterButtonsByState(),
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // AppBar with background
            SliverAppBar(
              flexibleSpace: FlexibleSpaceBar(
                background: Assets.png.bgAppBar.image(
                  fit: BoxFit.cover,
                ),
              ),
              title: AppText(
                // คูปองและรหัสคูปอง
                context.wording.couponAndVoucherCode,
                style: context.textTheme.titleLarge!.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
              leading: BackButton(
                onPressed: () {
                  context.safePop(
                    // _viewmodel.customerCouponModelSelected,
                    true,
                  );
                },
              ),
              pinned: true,
              floating: false,
            ),

            // ช่องกรอก, Scan Section
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(AppDims.size_16),
                padding: EdgeInsets.all(AppDims.size_16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    // Title
                    Row(
                      children: [
                        Assets.svg.icCouponEditRoundedGreen.svg(),
                        AppDims.horizonPadding_8,
                        AppText(
                          // รหัสและการสแกน
                          context.wording.codeAndScan,
                          style: context.textTheme.labelLarge!.copyWith(
                            fontSize: AppDims.size_16.sp,
                          ),
                        ),
                      ],
                    ),
                    AppDims.vericalPadding_8,

                    // ช่องกรอก
                    _buildInputCollectCoupon(),
                    AppDims.vericalPadding_8,

                    // ปุ่มเปิดกล้อง Scan
                    ElevatedButton.icon(
                      onPressed: () {
                        ScannerPage.goToPage(
                          context,
                          process: ScannerProcess.needResult,
                        ).then((data) {
                          if (context.mounted && data != null) {
                            try {
                              final qrdata = data as String;
                              _viewmodel.collectCoupon(qrdata, 'qr');
                            } catch (_) {
                              // cast type เป็น String ไม่ได้ ไม่ควรเกิดขึ้น
                              AppOverlays.showBrownyDialog(
                                context,
                                title: context.wording.errorOccurred,
                                message: context.wording.errorUi,
                              );
                            }
                          }
                        });
                      },
                      label: AppText(context.wording.scanCoupon),
                      iconAlignment: IconAlignment.end,
                      icon: Assets.svg.icScan3.svg(width: 16.w, height: 16.h),
                      style: context.appTheme.elevatedButtonTheme.style!
                          .copyWith(
                            backgroundColor: WidgetStatePropertyAll(
                              AppColors.ci3,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              AppColors.ci,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // TabBar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  dividerColor: AppColors.transparent,
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: context.textTheme.titleMedium!.copyWith(
                    color: AppColors.primary,
                  ),
                  unselectedLabelStyle: context.textTheme.titleMedium!.copyWith(
                    color: AppColors.gray500,
                  ),
                  tabs: [
                    Tab(
                      child: AppText(
                        context.wording.sakob,
                        style: context.textTheme.labelLarge!.copyWith(
                          color: AppColors.gray500,
                          fontSize: AppDims.size_16.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Tab(
                      child: AppText(
                        context.wording.eVouchers,
                        style: context.textTheme.labelLarge!.copyWith(
                          color: AppColors.gray500,
                          fontSize: AppDims.size_16.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Tab(
                      child: AppText(
                        context.wording.brownyShop,
                        style: context.textTheme.labelLarge!.copyWith(
                          color: AppColors.gray500,
                          fontSize: AppDims.size_15.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Container(
          color: AppColors.background,
          child: TabBarView(
            controller: _tabController,
            children: [
              // ซักอบ
              _CustomerWashDryCouponWidget(
                viewModel: _viewmodel,
              ),

              // E-Voucher
              _CustomerEVoucherWidget(
                viewModel: _viewmodel,
              ),

              // Browny Shop
              _buildTabContent(
                context: context,
                icon: Assets.svg.icCouponCheckRoundedGreen.svg(),
                title: context.wording.brownyShop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCollectCoupon() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDims.size_16,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: BoxBorder.fromLTRB(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1.w,
                ),
                left: BorderSide(
                  color: AppColors.border,
                  width: 1.w,
                ),
                top: BorderSide(
                  color: AppColors.border,
                  width: 1.w,
                ),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.r),
                topLeft: Radius.circular(8.r),
              ),
            ),
            child: TextField(
              controller: _viewmodel.inputCollectCouponControler,
              style: AppTextNumberStyles.labelMedium,
              decoration: InputDecoration(
                // ใส่รหัสคูปองของคุณได้ที่นี่
                hintText: context.wording.enterYourCouponCode,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: context.textTheme.titleSmall!.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              onChanged: _viewmodel.onInputCouponChange,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ValueListenableBuilder(
            valueListenable: _viewmodel.inputCollectCouponNotifier,
            builder: (context, enable, child) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDims.size_8,
                ),
                decoration: BoxDecoration(
                  color: enable ? AppColors.primary : AppColors.gray400,
                  border: BoxBorder.all(
                    color: enable ? AppColors.primary : AppColors.border,
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(8.r),
                    topRight: Radius.circular(8.r),
                  ),
                ),
                child: GestureDetector(
                  onTap: enable ? () => _viewmodel.collectCoupon() : null,
                  child: AppTextFormField(
                    enabled: false,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                        ),
                        child: Assets.svg.icMagnify.svg(
                          colorFilter: ColorFilter.mode(
                            AppColors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      hintStyle: context.textTheme.labelLarge!.copyWith(
                        color: AppColors.textWhite,
                      ),
                      // ใช้คูปอง
                      hintText: context.wording.useCoupon,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required Widget icon,
    required String title,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
        vertical: AppDims.size_14.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_14.w,
        vertical: AppDims.size_8.h,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Assets.png.brownySuccess1.image(
                width: 145.w,
                height: 100.h,
              ),
            ),
            AppDims.vericalPadding_16,

            AppText(
              // พบกันเร็ว ๆ นี้
              ContentLocalizeData(
                en: 'Coming Soon.',
                zh: '敬请期待',
                th: 'พบกันเร็ว ๆ นี้',
              ).getTextByLocale(context.languageCode),
              style: context.textTheme.labelLarge!.copyWith(
                fontSize: AppDims.size_16.sp,
              ),
            ),

            // ElevatedButton.icon(
            //   onPressed: null,
            //   icon: Assets.svg.icCouponWashRoundedGreen.svg(),
            //   label: AppText(
            //     'คูปองซัก',
            //     style: context.textTheme.labelLarge,
            //   ),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.transparent,
            //     foregroundColor: AppColors.primary,
            //     alignment: AlignmentDirectional.centerStart,
            //     padding: EdgeInsets.zero,
            //     disabledBackgroundColor: AppColors.transparent,
            //     overlayColor: AppColors.transparent,
            //   ),
            // ),
            // AppDims.vericalPadding_16,

            // Column(
            //   children: [
            //     Center(
            //       child: Assets.png.brownyError1.image(
            //         width: 145.w,
            //         height: 100.h,
            //       ),
            //     ),
            //     AppDims.vericalPadding_16,

            //     AppText(
            //       'ไม่พบคูปอง',
            //       style: context.textTheme.labelLarge!.copyWith(
            //         fontSize: AppDims.size_16.sp,
            //       ),
            //     ),
            //   ],
            // ),

            // ...List.generate(6, (index) => '').map(
            //   (e) => CouponEVoucherCardWidget(
            //     icon: Assets.png.brownyCreatePin.image(),
            //     title: 'Title',
            //     description: 'Description',
            //     detailUsing: 'Detail using',
            //     expired: 'Expired',
            //   ),
            // ),
            // ElevatedButton.icon(
            //   onPressed: null,
            //   icon: Assets.svg.icCouponDryRoundedGreen.svg(),
            //   label: AppText(
            //     'คูปองอบ',
            //     style: context.textTheme.labelLarge,
            //   ),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.transparent,
            //     foregroundColor: AppColors.primary,
            //     alignment: AlignmentDirectional.centerStart,
            //     padding: EdgeInsets.zero,
            //     disabledBackgroundColor: AppColors.transparent,
            //     overlayColor: AppColors.transparent,
            //   ),
            // ),
            // AppDims.vericalPadding_16,

            // Column(
            //   children: [
            //     Center(
            //       child: Assets.png.brownyError1.image(
            //         width: 145.w,
            //         height: 100.h,
            //       ),
            //     ),
            //     AppDims.vericalPadding_16,

            //     AppText(
            //       'ไม่พบคูปอง',
            //       style: context.textTheme.labelLarge!.copyWith(
            //         fontSize: AppDims.size_16.sp,
            //       ),
            //     ),
            //   ],
            // ),

            // ...List.generate(3, (index) => '').map(
            //   (e) => Container(
            //     // Disable
            //     // foregroundDecoration: BoxDecoration(
            //     //   color: Colors.grey,
            //     //   backgroundBlendMode: BlendMode.saturation,
            //     // ),
            //     height: 85.h,
            //     margin: EdgeInsets.only(bottom: AppDims.size_12),
            //     decoration: BoxDecoration(
            //       border: BoxBorder.all(
            //         width: 1,
            //         color: AppColors.primary,
            //       ),
            //       color: AppColors.white,
            //       borderRadius: BorderRadius.circular(8.r),
            //     ),
            //     child: Row(
            //       children: [
            //         // Icon
            //         Container(
            //           width: 100,
            //           height: 85.h,
            //           padding: EdgeInsets.all(8),
            //           decoration: BoxDecoration(
            //             border: BoxBorder.fromLTRB(
            //               right: BorderSide(
            //                 width: 1,
            //                 color: AppColors.primary,
            //               ),
            //             ),
            //             color: AppColors.white,
            //             borderRadius: BorderRadius.only(
            //               bottomLeft: Radius.circular(8.r),
            //               topLeft: Radius.circular(8.r),
            //             ),
            //           ),
            //           // child: Icon(Icons.discount_rounded),
            //           child: Assets.png.brownyCreatePin.image(),
            //         ),

            //         Container(
            //           padding: EdgeInsets.all(AppDims.size_8),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               AppText(
            //                 'Title',
            //                 style: context.textTheme.titleSmall,
            //               ),
            //               AppText(
            //                 'Description',
            //                 style: context.textTheme.labelSmall!.copyWith(
            //                   color: AppColors.primary,
            //                 ),
            //               ),
            //               Spacer(),

            //               RichText(
            //                 text: TextSpan(
            //                   text: 'Expried',
            //                   style: context.textTheme.bodySmall?.copyWith(
            //                     fontSize: AppDims.size_10.sp,
            //                     color: AppColors.textSecondary,
            //                   ),
            //                   children: [
            //                     TextSpan(text: ' '),
            //                     TextSpan(
            //                       text: 'เงื่อนไข',
            //                       style: context.textTheme.labelSmall?.copyWith(
            //                         color: AppColors.primary,
            //                         fontSize: AppDims.size_10.sp,
            //                       ),
            //                       recognizer: TapGestureRecognizer()
            //                         ..onTap = () {},
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // ElevatedButton.icon(
            //   onPressed: null,
            //   icon: Assets.svg.icCrossRoundGreen.svg(),
            //   label: AppText(
            //     'คูปองที่ใช้ไม่ได้',
            //     style: context.textTheme.labelLarge,
            //   ),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.transparent,
            //     foregroundColor: AppColors.primary,
            //     alignment: AlignmentDirectional.centerStart,
            //     padding: EdgeInsets.zero,
            //     disabledBackgroundColor: AppColors.transparent,
            //     overlayColor: AppColors.transparent,
            //   ),
            // ),
            // AppDims.vericalPadding_16,

            // Column(
            //   children: [
            //     Center(
            //       child: Assets.png.brownyError1.image(
            //         width: 145.w,
            //         height: 100.h,
            //       ),
            //     ),
            //     AppDims.vericalPadding_16,

            //     AppText(
            //       'ไม่พบคูปอง',
            //       style: context.textTheme.labelLarge!.copyWith(
            //         fontSize: AppDims.size_16.sp,
            //       ),
            //     ),
            //   ],
            // ),
            // ...List.generate(2, (index) => '').map(
            //   (e) => Container(
            //     // Disable
            //     // foregroundDecoration: BoxDecoration(
            //     //   color: Colors.grey,
            //     //   backgroundBlendMode: BlendMode.saturation,
            //     // ),
            //     height: 85.h,
            //     margin: EdgeInsets.only(bottom: AppDims.size_12),
            //     decoration: BoxDecoration(
            //       border: BoxBorder.all(
            //         width: 1,
            //         color: AppColors.primary,
            //       ),
            //       color: AppColors.white,
            //       borderRadius: BorderRadius.circular(8.r),
            //     ),
            //     child: Row(
            //       children: [
            //         // Icon
            //         Container(
            //           width: 100,
            //           height: 85.h,
            //           padding: EdgeInsets.all(8),
            //           decoration: BoxDecoration(
            //             border: BoxBorder.fromLTRB(
            //               right: BorderSide(
            //                 width: 1,
            //                 color: AppColors.primary,
            //               ),
            //             ),
            //             color: AppColors.white,
            //             borderRadius: BorderRadius.only(
            //               bottomLeft: Radius.circular(8.r),
            //               topLeft: Radius.circular(8.r),
            //             ),
            //           ),
            //           // child: Icon(Icons.discount_rounded),
            //           child: Assets.png.brownyCreatePin.image(),
            //         ),

            //         Container(
            //           padding: EdgeInsets.all(AppDims.size_8),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               AppText(
            //                 'Title',
            //                 style: context.textTheme.titleSmall,
            //               ),
            //               AppText(
            //                 'Description',
            //                 style: context.textTheme.labelSmall!.copyWith(
            //                   color: AppColors.primary,
            //                 ),
            //               ),
            //               Spacer(),

            //               RichText(
            //                 text: TextSpan(
            //                   text: 'Expried',
            //                   style: context.textTheme.bodySmall?.copyWith(
            //                     fontSize: AppDims.size_10.sp,
            //                     color: AppColors.textSecondary,
            //                   ),
            //                   children: [
            //                     TextSpan(text: ' '),
            //                     TextSpan(
            //                       text: 'เงื่อนไข',
            //                       style: context.textTheme.labelSmall?.copyWith(
            //                         color: AppColors.primary,
            //                         fontSize: AppDims.size_10.sp,
            //                       ),
            //                       recognizer: TapGestureRecognizer()
            //                         ..onTap = () {},
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _CustomerWashDryCouponWidget extends StatefulWidget {
  const _CustomerWashDryCouponWidget({
    required TransactionsViewmodel viewModel,
  }) : _viewModel = viewModel;

  final TransactionsViewmodel _viewModel;

  @override
  State<_CustomerWashDryCouponWidget> createState() =>
      _CustomerWashDryCouponWidgetState();
}

class _CustomerWashDryCouponWidgetState
    extends State<_CustomerWashDryCouponWidget> {
  // Map to track expand state for each section
  final Map<String, bool> _sectionExpandedStates = {};

  @override
  void initState() {
    super.initState();
    // Fetch discount coupons
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget._viewModel.fetchCustomerDiscount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
        vertical: AppDims.size_14.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_14.w,
        vertical: AppDims.size_8.h,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ValueListenableBuilder(
          valueListenable: widget._viewModel.discountNotifier,
          builder: (context, discountResult, child) {
            if (discountResult.isLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (discountResult.isEmpty || discountResult.hasError) {
              return _buildNotFoundData(context);
            }

            final discountMap = discountResult.data ?? {};

            // if (discountMap.isEmpty) {
            //   return _buildNotFoundData(context);
            // }

            bool isUnavailable(CustomerCouponModel c) =>
                (c.isAvailable != true) || (c.isExpired == true);

            // Filter ออกในแต่ละ group เก็บเฉพาะคูปองที่ใช้ได้
            final washerAvailable =
                (discountMap['washer'] ?? [])
                    .where((c) => !isUnavailable(c))
                    .toList();
            final dryerAvailable =
                (discountMap['dryer'] ?? [])
                    .where((c) => !isUnavailable(c))
                    .toList();
            final bothAvailable =
                (discountMap['both'] ?? [])
                    .where((c) => !isUnavailable(c))
                    .toList();

            // รวมคูปองที่ใช้ไม่ได้จากทุก group
            final unavailableCoupons = <CustomerCouponModel>[
              ...(discountMap['washer'] ?? []).where(isUnavailable),
              ...(discountMap['dryer'] ?? []).where(isUnavailable),
              ...(discountMap['both'] ?? []).where(isUnavailable),
            ];

            // Build sections for washer, dryer, and both
            final sections = <Widget>[];

            // Section: คูปองซัก (washer)
            sections.addAll(
              _buildSection(
                context: context,
                key: 'washer',
                icon: Assets.svg.icCouponWashRoundedGreen.svg(),
                // คูปองซัก
                title: context.wording.washerCoupon,
                coupons: washerAvailable,
              ),
            );

            // Section: คูปองอบ (dryer)
            sections.addAll(
              _buildSection(
                context: context,
                key: 'dryer',
                icon: Assets.svg.icCouponDryRoundedGreen.svg(),
                // คูปองอบ
                title: context.wording.dryerCoupon,
                coupons: dryerAvailable,
              ),
            );

            // Section: คูปองซักอบ (both)
            sections.addAll(
              _buildSection(
                context: context,
                key: 'both',
                icon: Assets.svg.icCouponWashRoundedGreen.svg(),
                // คูปองซักอบ
                title: context.wording.washerDryerCoupon,
                coupons: bothAvailable,
              ),
            );

            // Section: คูปองที่ใช้ไม่ได้ (unavailable / expired)
            if (unavailableCoupons.isNotEmpty) {
              sections.addAll(
                _buildUnavailableSection(
                  context: context,
                  coupons: unavailableCoupons,
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: sections,
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSection({
    required BuildContext context,
    required String key,
    required Widget icon,
    required String title,
    required List<CustomerCouponModel> coupons,
  }) {
    final lengthList = coupons.length;
    final needButtonExpanding = lengthList > 2;
    final isExpanded = _sectionExpandedStates[key] ?? false;

    return [
      // Section Title
      ElevatedButton.icon(
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
      ),
      AppDims.vericalPadding_8,

      // Section Coupons List
      ...coupons
          .take(isExpanded ? lengthList : 2)
          .map(
            (customerDiscount) => _buildCustomerDiscount(
              context,
              customerDiscount,
            ),
          ),

      if (coupons.isEmpty)
        Column(
          children: [
            if (widget._viewModel.isUsing) ...[
              Center(
                child: Assets.png.brownyError4.image(
                  width: 145.w,
                  height: 100.h,
                ),
              ),
              AppDims.vericalPadding_16,

              AppText(
                // ไม่พบคูปองที่ร่วมรายการ
                context.wording.noCouponEligible,
                style: context.textTheme.labelLarge!.copyWith(
                  fontSize: AppDims.size_16.sp,
                ),
              ),
            ] else ...[
              Center(
                child: Assets.png.brownyError1.image(
                  width: 145.w,
                  height: 100.h,
                ),
              ),
              AppDims.vericalPadding_16,

              AppText(
                // ไม่พบ$title
                context.wording.couponNotFoundOf(title),
                style: context.textTheme.labelLarge!.copyWith(
                  fontSize: AppDims.size_16.sp,
                ),
              ),
            ],
          ],
        ),

      // Expand/Collapse button
      if (needButtonExpanding)
        _buildButtonExpandable(
          () {
            setState(() {
              _sectionExpandedStates[key] = !isExpanded;
            });
          },
          isExpanded,
        ),

      AppDims.vericalPadding_14,
    ];
  }

  /// Section "คูปองที่ใช้ไม่ได้" — รวมคูปองที่ isAvailable != true || isExpired == true
  /// แสดง Card แบบ disabled และ flag isExpired ตาม model
  List<Widget> _buildUnavailableSection({
    required BuildContext context,
    required List<CustomerCouponModel> coupons,
  }) {
    const key = 'unavailable';
    final lengthList = coupons.length;
    final needButtonExpanding = lengthList > 2;
    final isExpanded = _sectionExpandedStates[key] ?? false;

    return [
      ElevatedButton.icon(
        onPressed: null,
        icon: Assets.svg.icCrossRoundGreen.svg(),
        label: AppText(
          // คูปองที่ใช้ไม่ได้
          context.wording.unavailableCoupons,
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
      ),
      AppDims.vericalPadding_8,

      ...coupons
          .take(isExpanded ? lengthList : 2)
          .map(
            (c) => CouponEVoucherCardWidget(
              isExpired: c.isExpired ?? false,
              isFullyRedeemed:
                  (c.isAvailable != true) && c.remainingCount == 0,
              icon: Image.network(
                c.imageUrlDisplay(context),
                errorBuilder: (_, _, _) => _onImageError(),
              ),
              title: c.packageNameDisplay(context),
              description: c.storeNameDisplay(context),
              detailUsing: c.usageLabelDisplay(context),
              expired: c.expireDateDisplay(context),
            ),
          ),

      if (needButtonExpanding)
        _buildButtonExpandable(
          () {
            setState(() {
              _sectionExpandedStates[key] = !isExpanded;
            });
          },
          isExpanded,
        ),

      AppDims.vericalPadding_14,
    ];
  }

  GestureDetector _buildCustomerDiscount(
    BuildContext context,
    CustomerCouponModel customerDiscount,
  ) {
    void onTap() {
      switch (widget._viewModel.couponState) {
        case CouponVoucherState.using:
          widget._viewModel.onCustomerDiscountSelected(
            customerDiscount,
          );
          context.safePop(
            widget._viewModel.customerCouponModelSelected,
          );
          break;
        case CouponVoucherState.purshasing:
          widget._viewModel.goSelectedPage(
            context,
            customerDiscount,
          );
        case CouponVoucherState.redeeming:
        case CouponVoucherState.brownyShop:
          break;
        default:
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      // Counpon ส่วนลดใน Tab ซักอบ
      child: CouponEVoucherCardWidget(
        initialChecked:
            customerDiscount.customerCouponId ==
            widget._viewModel.machineProgram?.selectedCoupon?.id,
        icon: Image.network(
          customerDiscount.imageUrlDisplay(context),
          errorBuilder: (_, _, _) => _onImageError(),
        ),
        title: customerDiscount.packageNameDisplay(
          context,
        ),
        description: customerDiscount.storeNameDisplay(
          context,
        ),
        detailUsing: customerDiscount.usageLabelDisplay(
          context,
        ),
        expired: customerDiscount.expireDateDisplay(
          context,
        ),
        borderColor: customerDiscount.isSelected ? AppColors.primary : null,
        showCheckBox: widget._viewModel.couponState == CouponVoucherState.using,
        onChanged: (value) => onTap(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildButtonExpandable(
    VoidCallback onPressed,
    bool expanded,
  ) {
    return TextButton(
      style: context.appTheme.textButtonTheme.style!.copyWith(
        textStyle: WidgetStatePropertyAll(context.textTheme.labelLarge),
        foregroundColor: WidgetStatePropertyAll(AppColors.gray500),
      ),
      onPressed: onPressed,
      child: Column(
        children: [
          AppText(
            // 'ปิดการแสดงเพิ่มเติม' : 'แสดงเพิ่มเติม'
            expanded ? context.wording.collapseMore : context.wording.showMore,
          ),
          expanded ? Assets.svg.icArrowUp.svg() : Assets.svg.icArrowDown.svg(),
        ],
      ),
    );
  }

  Widget _onImageError() {
    return Container(
      color: AppColors.transparent,
    );
  }

  Widget _buildNotFoundData(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: null,
          icon: Assets.svg.icCouponWashRoundedGreen.svg(),
          label: AppText(
            // 'คูปองซัก',
            context.wording.washerCoupon,
            style: context.textTheme.labelLarge,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.transparent,
            foregroundColor: AppColors.primary,
            alignment: AlignmentDirectional.centerStart,
            padding: EdgeInsets.zero,
            disabledBackgroundColor: AppColors.transparent,
            overlayColor: AppColors.transparent,
          ),
        ),
        AppDims.vericalPadding_16,
        Center(
          child: Assets.png.brownyError1.image(
            width: 145.w,
            height: 100.h,
          ),
        ),
        AppDims.vericalPadding_16,
        AppText(
          // 'ไม่พบคูปอง',
          context.wording.couponNotFoundOf(context.wording.washerCoupon),
          style: context.textTheme.labelLarge!.copyWith(
            fontSize: AppDims.size_16.sp,
          ),
        ),
        AppDims.vericalPadding_16,
        ElevatedButton.icon(
          onPressed: null,
          icon: Assets.svg.icCouponDryRoundedGreen.svg(),
          label: AppText(
            // 'คูปองอบ',
            context.wording.dryerCoupon,
            style: context.textTheme.labelLarge,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.transparent,
            foregroundColor: AppColors.primary,
            alignment: AlignmentDirectional.centerStart,
            padding: EdgeInsets.zero,
            disabledBackgroundColor: AppColors.transparent,
            overlayColor: AppColors.transparent,
          ),
        ),
        AppDims.vericalPadding_16,
        Center(
          child: Assets.png.brownyError1.image(
            width: 145.w,
            height: 100.h,
          ),
        ),
        AppDims.vericalPadding_16,
        AppText(
          // 'ไม่พบคูปอง',
          context.wording.couponNotFoundOf(context.wording.dryerCoupon),
          style: context.textTheme.labelLarge!.copyWith(
            fontSize: AppDims.size_16.sp,
          ),
        ),
      ],
    );
  }
}

class _CustomerEVoucherWidget extends StatefulWidget {
  const _CustomerEVoucherWidget({
    required TransactionsViewmodel viewModel,
  }) : _viewModel = viewModel;

  final TransactionsViewmodel _viewModel;

  @override
  State<_CustomerEVoucherWidget> createState() =>
      _CustomerEVoucherWidgetState();
}

class _CustomerEVoucherWidgetState extends State<_CustomerEVoucherWidget> {
  // Map to track expand state for each typeLabel group
  final Map<String, bool> _sectionExpandedStates = {};
  bool _eVoucherExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize location permission and fetch coupon packages
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget._viewModel.initializeLocationAndFetchCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
        vertical: AppDims.size_14.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_14.w,
        vertical: AppDims.size_8.h,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dynamic sections for each coupon type
            ValueListenableBuilder(
              valueListenable: widget._viewModel.evoucherNotifier,
              builder: (context, evoucherResult, child) {
                if (evoucherResult.isLoading) {
                  Future.microtask(widget._viewModel.fetchCustomerEVoucher);
                  return CircularProgressIndicator();
                }

                if (evoucherResult.isEmpty || evoucherResult.hasError) {
                  // ไม่พบข้อมูลอะไร
                  return _buidlNotFoundData(context);
                }

                final evoucherMap = evoucherResult.data ?? {};

                if (evoucherMap.isEmpty) {
                  return _buidlNotFoundData(context);
                }

                bool isUnavailable(CustomerCouponModel c) =>
                    (c.isAvailable != true) || (c.isExpired == true);

                // Build sections for each coupon type (filter ออก unavailable)
                final sections = <Widget>[];

                evoucherMap.forEach((typeKey, allCoupons) {
                  final coupons = allCoupons
                      .where((c) => !isUnavailable(c))
                      .toList();
                  if (coupons.isEmpty) return;

                  // Get the first coupon to access typeLabel
                  final firstCoupon = coupons.first;
                  final sectionTitle = firstCoupon.typeLabelDisplay(
                    context,
                    mineText: context.wording.mine,
                  );
                  final lengthList = coupons.length;
                  final needButtonExpanding = lengthList > 2;

                  // Get or initialize expand state for this section
                  final isExpanded = _sectionExpandedStates[typeKey] ?? false;

                  sections.addAll([
                    // Section Title
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: Assets.svg.icEvoucherCheckRoundedGreen.svg(),
                      label: AppText(
                        sectionTitle,
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
                    ),
                    AppDims.vericalPadding_16,

                    // Section Coupons List
                    ...coupons
                        .take(isExpanded ? lengthList : 2)
                        .map(
                          (customerEVoucher) => _buildCustomerEVoucher(
                            context,
                            customerEVoucher,
                          ),
                        ),

                    // Expand/Collapse button
                    if (needButtonExpanding)
                      _buildButtonExpandable(
                        () {
                          setState(() {
                            _sectionExpandedStates[typeKey] = !isExpanded;
                          });
                        },
                        isExpanded,
                      ),

                    AppDims.vericalPadding_14,
                  ]);
                });

                return Column(
                  children: sections,
                );
              },
            ),

            // สำหรับทดลองเวลาไม่มี Data
            // ...List.generate(
            //   _myEVoucherExpanded ? 10 : 2,
            //   (index) => CouponEVoucherCardWidget(
            //     key: ValueKey(index),
            //     title: index.toString(),
            //     description: 'description',
            //     detailUsing: 'detailUsing',
            //     expired: 'expired',
            //   ),
            // ),
            // _buildButtonExpandable(
            //   () {
            //     setState(() {
            //       _myEVoucherExpanded = !_myEVoucherExpanded;
            //     });
            //   },
            //   _myEVoucherExpanded,
            // ),
            ElevatedButton.icon(
              onPressed: null, //() => _viewModel.goPurchasePage(context),
              icon: Assets.svg.icEvoucherPercentRoundedGreen.svg(),
              label: AppText(
                // 'เลือกซื้อแพ็คเกจ E-Voucher'
                context.wording.selectEVoucherPackage,
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
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText(
                    // 'แสดงแพ็คเกจ E-Voucher สาขาใกล้ฉัน ระยะ 25 กม.',
                    context.wording.showNearbyEVoucherPackages,
                    style: context.textTheme.titleSmall!.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ),
                SizedBox(
                  width: AppDims.size_30.w, // Desired width
                  height: AppDims.size_25.h, // Desired height
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: ValueListenableBuilder<bool>(
                      valueListenable:
                          widget._viewModel.showNearbyStoresNotifier,
                      builder: (context, showNearby, child) {
                        return Switch(
                          value: showNearby,
                          onChanged: (bool value) async {
                            await widget._viewModel.onNearbyStoresSwitchChanged(
                              value,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            AppDims.vericalPadding_16,

            // List E-Voucher ที่จะให้เลือกซื้อ
            ValueListenableBuilder(
              valueListenable: widget._viewModel.evoucherForSellNotifier,
              builder: (context, allStoreResult, child) {
                if (allStoreResult.isLoading) {
                  return CircularProgressIndicator();
                }

                if (allStoreResult.isEmpty || allStoreResult.hasError) {
                  // ไม่พบข้อมูลอะไร
                  return _buidlNotFoundData(context);
                }

                final evoucherForSellList =
                    allStoreResult.data?.getActivePackages() ?? [];

                if (evoucherForSellList.isEmpty) {
                  // ไม่พบข้อมูลอะไร
                  return _buidlNotFoundData(context);
                }

                final lengthList = evoucherForSellList.length;

                final needButtonExpanding =
                    evoucherForSellList.isNotEmpty && lengthList > 2;

                return Column(
                  children: [
                    ...allStoreResult.data!
                        .getActivePackages()
                        .take(_eVoucherExpanded ? lengthList : 2)
                        .map(
                          (e) => GestureDetector(
                            onTap: () =>
                                widget._viewModel.goPurchasePage(context, e),
                            child: CouponEVoucherCardWidget(
                              icon: Image.network(
                                e.couponImageDisplay(context),
                                errorBuilder: (_, _, _) => _onImageError(),
                              ),
                              title: e.couponNameDisplay(context),
                              description: e.storeNameDisplay(context),
                              detailUsing: e.usageLabelDisplay(context),
                              expired: e.usageDurationTextDisplay(context),
                              showCheckBox: false,
                              onChanged: (value) {},
                            ),
                          ),
                        ),
                    if (needButtonExpanding)
                      _buildButtonExpandable(
                        () {
                          setState(() {
                            _eVoucherExpanded = !_eVoucherExpanded;
                          });
                        },
                        _eVoucherExpanded,
                      ),
                  ],
                );
              },
            ),

            // Section: E-Voucher ที่ใช้ไม่ได้ (วางไว้ใต้ List E-Voucher ที่จะให้เลือกซื้อ)
            ValueListenableBuilder(
              valueListenable: widget._viewModel.evoucherNotifier,
              builder: (context, evoucherResult, child) {
                final evoucherMap = evoucherResult.data ?? {};
                final unavailableCoupons = <CustomerCouponModel>[
                  for (final entry in evoucherMap.entries)
                    ...entry.value.where(
                      (c) => (c.isAvailable != true) || (c.isExpired == true),
                    ),
                ];

                if (unavailableCoupons.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: _buildUnavailableEVoucherSection(
                    context: context,
                    coupons: unavailableCoupons,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Section "E-Voucher ที่ใช้ไม่ได้" — รวม E-Voucher ที่ isAvailable != true || isExpired == true
  /// แสดง Card แบบ disabled และ flag isExpired ตาม model
  List<Widget> _buildUnavailableEVoucherSection({
    required BuildContext context,
    required List<CustomerCouponModel> coupons,
  }) {
    const key = 'unavailable_evoucher';
    final lengthList = coupons.length;
    final needButtonExpanding = lengthList > 2;
    final isExpanded = _sectionExpandedStates[key] ?? false;

    return [
      ElevatedButton.icon(
        onPressed: null,
        icon: Assets.svg.icCrossRoundGreen.svg(),
        label: AppText(
          // E-Voucher ที่ใช้ไม่ได้
          context.wording.unavailableEVouchers,
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
      ),
      AppDims.vericalPadding_16,

      ...coupons
          .take(isExpanded ? lengthList : 2)
          .map(
            (c) => CouponEVoucherCardWidget(
              isExpired: c.isExpired ?? false,
              isFullyRedeemed:
                  (c.isAvailable != true) && c.remainingCount == 0,
              icon: Image.network(
                c.imageUrlDisplay(context),
                errorBuilder: (_, _, _) => _onImageError(),
              ),
              title: c.packageNameDisplay(context),
              description: c.storeNameDisplay(context),
              detailUsing: c.usageLabelDisplay(context),
              expired: c.expireDateDisplay(context),
            ),
          ),

      if (needButtonExpanding)
        _buildButtonExpandable(
          () {
            setState(() {
              _sectionExpandedStates[key] = !isExpanded;
            });
          },
          isExpanded,
        ),

      AppDims.vericalPadding_14,
    ];
  }

  GestureDetector _buildCustomerEVoucher(
    BuildContext context,
    CustomerCouponModel customerEVoucher,
  ) {
    void onTap() {
      switch (widget._viewModel.couponState) {
        case CouponVoucherState.using:
          widget._viewModel.onCustomerEVoucherSelected(
            customerEVoucher,
          );
          context.safePop(
            widget._viewModel.customerCouponModelSelected,
          );
          break;
        case CouponVoucherState.purshasing:
          widget._viewModel.goSelectedPage(
            context,
            customerEVoucher,
          );
        case CouponVoucherState.redeeming:
          // TODO: Handle this case.
          break;
        case CouponVoucherState.brownyShop:
          // TODO: Handle this case.
          throw UnimplementedError();
        default:
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: CouponEVoucherCardWidget(
        initialChecked:
            customerEVoucher.customerCouponId ==
            widget._viewModel.machineProgram?.selectedCoupon?.id,
        icon: Image.network(
          customerEVoucher.imageUrlDisplay(context),
          errorBuilder: (_, _, _) => _onImageError(),
        ),
        title: customerEVoucher.packageNameDisplay(
          context,
        ),
        description: customerEVoucher.storeNameDisplay(
          context,
        ),
        detailUsing: customerEVoucher.usageLabelDisplay(
          context,
        ),
        expired: customerEVoucher.expireDateDisplay(
          context,
        ),
        borderColor: customerEVoucher.isSelected ? AppColors.primary : null,
        showCheckBox: widget._viewModel.couponState == CouponVoucherState.using,
        onChanged: (value) => onTap(),
        // onChanged: widget._viewModel.couponState == CouponVoucherState.using
        //     ? (value) {
        //         widget._viewModel.onCustomerEVoucherSelected(
        //           customerEVoucher,
        //         );
        //       }
        //     : null,
      ),
    );
  }

  Widget _buildButtonExpandable(
    VoidCallback onPressed,
    bool expanded,
  ) {
    return TextButton(
      style: context.appTheme.textButtonTheme.style!.copyWith(
        textStyle: WidgetStatePropertyAll(context.textTheme.labelLarge),
        foregroundColor: WidgetStatePropertyAll(AppColors.gray500),
      ),
      onPressed: onPressed,
      child: Column(
        children: [
          AppText(
            // 'ปิดการแสดงเพิ่มเติม' : 'แสดงเพิ่มเติม'
            expanded ? context.wording.collapseMore : context.wording.showMore,
          ),
          expanded ? Assets.svg.icArrowUp.svg() : Assets.svg.icArrowDown.svg(),
        ],
      ),
    );
  }

  Widget _onImageError() {
    return Container(
      color: AppColors.ci2,
    );
  }

  Widget _buidlNotFoundData(BuildContext context) {
    return Column(
      children: [
        if (widget._viewModel.isUsing) ...[
          Center(
            child: Assets.png.brownyError4.image(
              width: 145.w,
              height: 100.h,
            ),
          ),
          AppDims.vericalPadding_16,

          AppText(
            // ไม่พบคูปองที่ร่วมรายการ
            'ไม่พบ E-Voucher ที่ร่วมรายการ',
            style: context.textTheme.labelLarge!.copyWith(
              fontSize: AppDims.size_16.sp,
            ),
          ),
        ] else ...[
          Center(
            child: Assets.png.brownyError1.image(
              width: 145.w,
              height: 100.h,
            ),
          ),
          AppDims.vericalPadding_16,

          AppText(
            // 'ไม่พบคูปอง E-Voucher'
            context.wording.evoucherNotFound,
            style: context.textTheme.labelLarge!.copyWith(
              fontSize: AppDims.size_16.sp,
            ),
          ),
        ],
      ],
    );
  }
}

// Custom SliverPersistentHeaderDelegate for sticky TabBar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
