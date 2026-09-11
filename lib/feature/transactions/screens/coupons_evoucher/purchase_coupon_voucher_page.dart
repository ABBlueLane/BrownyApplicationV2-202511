import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/feature/home/screens/home_page.dart';
import 'package:browny_applications_new/feature/map/screens/map_page.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_detail_model.dart';
import 'package:browny_applications_new/feature/transactions/screens/transaction_selected_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/purchase_coupon_viewmodel_delegate.dart';
import 'package:browny_applications_new/feature/transactions/widgets/store_search_page.dart';
import 'package:flutter_html/flutter_html.dart';

class PurchaseCouponVoucherPage extends StatefulWidget {
  const PurchaseCouponVoucherPage({
    super.key,
    required this.viewmodel,
  });

  final PurchaseCouponViewmodelDelegate viewmodel;

  static final pagePath = '/purchase_coupon_voucher';
  static final pageName = 'purchase_coupon_voucher';

  @override
  State<PurchaseCouponVoucherPage> createState() =>
      _PurchaseCouponVoucherPageState();
}

class _PurchaseCouponVoucherPageState extends State<PurchaseCouponVoucherPage> {
  late final PurchaseCouponViewmodelDelegate _viewmodel;

  @override
  void initState() {
    super.initState();
    _viewmodel = widget.viewmodel;
    // Fetch coupon detail data with location
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeLocationAndFetchDetail();
    });
  }

  /// Initialize location permission and fetch coupon detail
  Future<void> _initializeLocationAndFetchDetail() async {
    // Check location permission
    final hasPermission = await PermissionHelper.hasLocationPermission();

    String? latitude;
    String? longitude;

    if (hasPermission) {
      // Permission already granted - get location
      try {
        final position = await LocationHelper.getCurrentPosition();
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
      } catch (_) {}
    }

    // Fetch coupon detail with or without location
    await _viewmodel.fetchCouponDetail(
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  void dispose() {
    _viewmodel.disposeDelegate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // รายละเอียด E-Voucher
        title: AppText(context.wording.eVoucherDetails),
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () {
            if (!mounted) {
              return;
            }

            if (context.canPop()) {
              context.safePop();
            } else {
              HomePage.goToPage(context);
            }
          },
        ),
      ),
      persistentFooterDecoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5), // Shadow color
            spreadRadius: 1, // How much the shadow should spread
            blurRadius: 10, // How soft the shadow should be
            offset: Offset(0, -5), // Negative dy value moves the shadow upwards
          ),
        ],
      ),
      persistentFooterButtons: [
        // ปุ่มยืนยันซื้อคูปอง
        Container(
          padding: EdgeInsets.only(
            left: AppDims.size_24.w,
            right: AppDims.size_24.w,
            top: AppDims.size_8.h,
          ),
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed(
                TransactionSelectedPage.pageName,
                extra: _viewmodel,
              );
            },
            child: AppText(context.wording.buyEVoucher),
          ),
        ),
      ],
      body: ValueListenableBuilder(
        valueListenable: _viewmodel.couponDetailNotifier!,
        builder: (context, couponDetailResult, child) {
          // Loading state
          if (couponDetailResult.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Empty or error state
          if (couponDetailResult.isEmpty || couponDetailResult.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.png.brownyError1.image(width: 145.w, height: 100.h),
                  AppDims.vericalPadding_16,
                  AppText(
                    // 'ไม่สามารถโหลดข้อมูลคูปองได้',
                    context.wording.cannotLoadCouponData,
                    style: context.textTheme.labelLarge!.copyWith(
                      fontSize: AppDims.size_16.sp,
                    ),
                  ),
                ],
              ),
            );
          }

          // Success state - get data
          final couponDetail = couponDetailResult.data!;
          final couponData = couponDetail.coupon;

          return ValueListenableBuilder(
            valueListenable: _viewmodel.selectedPackageNotifier!,
            builder: (context, selectedPackage, child) {
              // Use selected package or fallback to first package
              final packageData =
                  selectedPackage ?? couponDetail.packages.firstOrNull;

              if (packageData == null || couponData == null) {
                return Center(
                  child: AppText(
                    // 'ไม่พบข้อมูล',
                    context.wording.dataNotFound,
                  ),
                );
              }

              return _buildContent(
                context,
                couponData,
                packageData,
                couponDetail,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CouponData couponData,
    PackageDetailData packageData,
    CouponDetailModel couponDetail,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 29.h,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.purchaseBackgroundGradient,
            ),
            child: CouponEVoucherCardWidget(
              icon: Image.network(
                couponData.couponImageDisplay(context),
                errorBuilder: (_, _, _) => _onImageError(),
              ),
              title: packageData.packageNameDisplay(context),
              description: packageData.storeNameDisplay(context),
              detailUsing: packageData.usageLabelDisplay(context),
              expired: couponData.usageDurationTextDisplay(context),
            ),
            // child: CouponEVoucherCardWidget(
            //   icon: Assets.png.brownyCreatePin.image(),
            //   title: 'Title',
            //   description: 'Description',
            //   detailUsing: 'Detail using',
            //   expired: 'Expired',
            // ),
          ),

          // Title and Description
          _viewGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  packageData.packageNameDisplay(context),
                  style: context.textTheme.titleLarge!.copyWith(
                    fontSize: AppDims.size_20.sp,
                  ),
                ),
                AppText(
                  couponData.usageDurationTextDisplay(context),
                  style: context.textTheme.bodyMedium!.copyWith(
                    fontSize: AppDims.size_15.sp,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),

          // Pricing, Discount, Coin
          _viewGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promotion Price
                Row(
                  children: [
                    AppText(
                      formatCurrency(
                        value: packageData.priceValue,
                        decimal: false,
                        leadingSign: '฿',
                        trailingSign: ' บาท',
                      ),
                      style: context.textTheme.headlineMedium!.copyWith(
                        fontSize: AppDims.size_20.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    AppDims.horizonPadding_8,

                    AppText(
                      formatCurrency(
                        value: packageData.normalPriceValue,
                        decimal: true,
                        leadingSign: '฿',
                      ),
                      style: context.textTheme.headlineMedium!.copyWith(
                        fontSize: AppDims.size_14.sp,
                        color: AppColors.gray500,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.gray600,
                      ),
                    ),
                    AppDims.horizonPadding_8,

                    AppText(
                      formatCurrency(
                        string:
                            '-${packageData.discountPercentValue.toStringAsFixed(0)}',
                        decimal: false,
                        trailingSign: '%',
                      ),
                      style: context.textTheme.headlineMedium!.copyWith(
                        fontSize: AppDims.size_14.sp,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),

                // ถ้ามี coin value มาถึงจะแสดง
                if (packageData.brownyCoinValue > 0) ...[
                  AppDims.vericalPadding_8,

                  // Browny Coin
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 8.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ci6,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Assets.png.brownyCoin.image(
                              width: 20.w,
                              height: 20.h,
                            ),
                            AppDims.horizonPadding_8,

                            AppText(
                              formatCurrency(
                                string: '${packageData.brownyCoinValue}',
                                decimal: false,
                                trailingSign: ' ${context.wording.coin}',
                              ),
                              style: context.textTheme.headlineSmall!.copyWith(
                                fontSize: AppDims.size_14.sp,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Condition
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.ci3,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  _buildConditionItem(
                    wording: context.wording.useWithin(
                      couponData.dateLeftDisplay(context),
                    ),
                    icon: Assets.svg.icCalendarRoundedGreen.svg(
                      width: 28.w,
                      height: 28.h,
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 1.w,
                    height: 40.h,
                    decoration: BoxDecoration(color: AppColors.ci7),
                  ),

                  if (packageData.qtySharedValue > 0)
                    _buildConditionItem(
                      wording: context.wording.washAndDryTimesLabel(
                        '${packageData.qtySharedValue}',
                      ),
                      icon: Assets.svg.icWashRoundedGreen.svg(
                        width: 28.w,
                        height: 28.h,
                      ),
                    )
                  else ...[
                    _buildConditionItem(
                      wording: context.wording.washTimesLabel(
                        '${packageData.qtyWasherValue}',
                      ),
                      icon: Assets.svg.icWashRoundedGreen.svg(
                        width: 28.w,
                        height: 28.h,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: 1.w,
                      height: 40.h,
                      decoration: BoxDecoration(color: AppColors.ci7),
                    ),
                    _buildConditionItem(
                      wording: context.wording.dryTimesLabel(
                        '${packageData.qtyDryerValue}',
                      ),
                      icon: Assets.svg.icDryRoundedGreen.svg(
                        width: 28.w,
                        height: 28.h,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // เลือกสาขา - เปิด SearchDelegate
          _viewGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  // 'เลือกสาขา',
                  context.wording.chooseStore,
                  style: context.textTheme.titleMedium!.copyWith(
                    fontSize: AppDims.size_16.sp,
                  ),
                ),
                AppDims.vericalPadding_4,

                GestureDetector(
                  onTap: () async {
                    // เปิดหน้าค้นหาสาขาแบบ Fullscreen
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StoreSearchPage(
                          packages: couponDetail.packages,
                          selectedPackage: packageData,
                          onPackageSelected: (selected) {
                            if (selected != null) {
                              _viewmodel.selectPackage(selected);
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                  child: CustomDropdown(
                    items: couponDetail.packages.orEmpty
                        .map(
                          (e) => DropdownCustomItem<PackageDetailData>(
                            value: e,
                            label: e.packageNameDisplay(context),
                          ),
                        )
                        .toList(),
                    hint: packageData.storeNameDisplay(context).isEmpty
                        // 'ค้นหาสาขาที่ร่วมรายการ'
                        ? context.wording.searchStoreParticipating
                        : packageData.storeNameDisplay(context),
                    isInteractive: false,
                    onLocationTap: () async {
                      await context.pushNamed(MapPage.pageName);
                    },
                  ),
                  // child: Container(
                  //   padding: EdgeInsets.symmetric(
                  //     horizontal: 16.w,
                  //     vertical: 12.h,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     border: Border.all(color: AppColors.border),
                  //     borderRadius: BorderRadius.circular(8.r),
                  //     color: AppColors.background,
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Expanded(
                  //         child: AppText(
                  //           packageData.storeNameDisplay(context).isEmpty
                  //               ? 'ค้นหาสาขาที่ร่วมรายการ'
                  //               : packageData.storeNameDisplay(context),
                  //           style: context.textTheme.bodyMedium!.copyWith(
                  //             color:
                  //                 packageData.storeNameDisplay(context).isEmpty
                  //                 ? AppColors.gray500
                  //                 : AppColors.textPrimary,
                  //           ),
                  //         ),
                  //       ),
                  //       Icon(
                  //         Icons.search,
                  //         color: AppColors.gray600,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ),
              ],
            ),
          ),

          // Condition text
          _viewGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Html(
                  data: couponData.couponDescriptionHTMLDisplay(context),
                  style: {
                    "body": Style(
                      fontSize: FontSize(15.sp),
                      padding: HtmlPaddings.zero,
                      textAlign: TextAlign.start,
                      margin: Margins.all(0),
                      fontWeight: FontWeight.w300,
                      color: AppColors.gray600,
                    ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewGroup({
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: child,
    );
  }

  Widget _onImageError() {
    return Container(
      color: AppColors.ci2,
    );
  }

  Widget _buildConditionItem({
    required String wording,
    required Widget icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          icon,
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppText(
              wording,
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge!.copyWith(
                fontSize: AppDims.size_16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
