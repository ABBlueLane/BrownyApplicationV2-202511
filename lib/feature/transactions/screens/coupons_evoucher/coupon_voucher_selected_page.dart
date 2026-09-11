import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_status_response.dart';
import 'package:browny_applications_new/feature/scaner/screen/scanner_page.dart';
import 'package:browny_applications_new/feature/scaner/viewmodel/scanner_viewmodel.dart';
import 'package:browny_applications_new/feature/transactions/screens/machines/machine_transaction_page_2.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/coupon_voucher_selected_viewmodel_delegate.dart';
import 'package:flutter_html/flutter_html.dart';

/// DONG 2026-02-11
///
/// เพิ่ม Widget สำหรับแสดง E-Voucher ที่ซื้อไว้
class CouponVoucherSelected extends StatefulWidget {
  const CouponVoucherSelected({
    super.key,
    required CouponVoucherSelectedViewmodelDelegate viewmodel,
  }) : _viewmodel = viewmodel;

  final CouponVoucherSelectedViewmodelDelegate _viewmodel;

  static final pagePath = '/CouponVoucherSelected';
  static final pageName = 'CouponVoucherSelected';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    required CouponVoucherSelectedViewmodelDelegate viewmodel,
  }) async {
    return await context.pushNamed(
      CouponVoucherSelected.pageName,
      extra: viewmodel,
    );
  }

  @override
  State<CouponVoucherSelected> createState() => _CouponVoucherSelectedState();
}

class _CouponVoucherSelectedState extends State<CouponVoucherSelected> {
  @override
  void dispose() {
    widget._viewmodel.disposeDelegate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // รายละเอียด Coupon / E-Voucher
        title: AppText(
          widget._viewmodel.customerCouponModelDelegate!
              .getSelectedTitleDisplay(
                context,
              ),
        ),
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () => context.safePop(),
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
        // ปุ่มเริ่มต้นใช้บริการ
        Container(
          padding: EdgeInsets.only(
            left: AppDims.size_24.w,
            right: AppDims.size_24.w,
            top: AppDims.size_8.h,
          ),
          child: ElevatedButton.icon(
            icon: Assets.svg.icScan2.svg(
              colorFilter: ColorFilter.mode(
                AppColors.white,
                BlendMode.srcIn,
              ),
            ), //
            iconAlignment: IconAlignment.end,
            onPressed: () async {
              await ScannerPage.goToPage(
                context,
                process: ScannerProcess.machineButNeedResult,
              ).then((data) {
                if (!context.mounted) return;

                try {
                  final couponData =
                      widget._viewmodel.customerCouponModelDelegate;
                  final machine = data as MachineStatusResponse;
                  MachineTransactionPage2.goReplacementPage(
                    context,
                    machineId: machine.storeMachineId!.toString(),
                    customerCouponModel: couponData,
                  );
                } catch (_) {
                  if (!context.mounted) return;

                  AppOverlays.showBrownyDialog(
                    context,
                    title: context.wording.errorOccurred,
                    message: context.wording.errorUi,
                  );
                }
              });
            },
            // เริ่มต้นใช้บริการ
            label: AppText(context.wording.startService),
          ),
        ),
      ],
      body: _buildBodyContent(
        widget._viewmodel.customerCouponModelDelegate!.getSelectedTypeDisplay(
          context,
        ),
      ),
    );
  }

  Widget _buildBodyContent(String typeDisplay) {
    final data = widget._viewmodel.customerCouponModelDelegate;
    if (data == null) {
      return SizedBox();
    }
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
                data.imageUrlDisplay(context),
                errorBuilder: (_, _, _) => _onImageError(),
              ),
              title: data.packageNameDisplay(context),
              description: data.storeNameDisplay(context),
              detailUsing: data.usageLabelDisplay(context),
              expired: data.expireDateDisplay(context),
            ),
          ),

          // Title and Description
          _viewGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  data.packageNameDisplay(context),
                  style: context.textTheme.titleLarge!.copyWith(
                    fontSize: AppDims.size_20.sp,
                  ),
                ),
                AppText(
                  // 'expireDateDisplay หลังซื้อ E-Voucher',
                  context.wording.afterPurchaseEVoucher(
                    data.expireDateDisplay(context),
                    typeDisplay,
                  ),
                  style: context.textTheme.bodyMedium!.copyWith(
                    fontSize: AppDims.size_15.sp,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),

          // Condition
          Center(
            child: Container(
              margin: EdgeInsets.only(
                top: AppDims.size_16.h,
                left: AppDims.size_16.w,
                right: AppDims.size_16.w,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 0,
                vertical: AppDims.size_16.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.ci3,
                borderRadius: BorderRadius.circular(AppDims.size_16.r),
              ),
              child: Row(
                children: [
                  _buildConditionItem(
                    // ใช้งานภายใน\n dateLeftDisplay',
                    wording: context.wording.useWithin(
                      data.dateLeftDisplay(context),
                    ),
                    icon: Assets.svg.icCalendarRoundedGreen.svg(
                      width: AppDims.size_28.w,
                      height: AppDims.size_28.h,
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: AppDims.size_4.w,
                    ),
                    width: AppDims.size_1.w,
                    height: AppDims.size_40.h,
                    decoration: BoxDecoration(
                      color: AppColors.ci7,
                    ),
                  ),

                  if (!data.isSplitMode)
                    _buildConditionItem(
                      // 'ซัก\nwashRemainDisplay',
                      // ซัก/อบ n ครั้ง
                      wording: data.sharedOrApplieBothWordingDisplay(context),
                      icon: Assets.svg.icWashRoundedGreen.svg(
                        width: AppDims.size_28.w,
                        height: AppDims.size_28.h,
                      ),
                    )
                  else ...[
                    _buildConditionItem(
                      // 'ซัก\nwashRemainDisplay',
                      wording: context.wording.washRemainLabel(
                        data.washRemainDisplay,
                      ),
                      icon: Assets.svg.icWashRoundedGreen.svg(
                        width: AppDims.size_28.w,
                        height: AppDims.size_28.h,
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppDims.size_4.w,
                      ),
                      width: AppDims.size_1.w,
                      height: AppDims.size_40.h,
                      decoration: BoxDecoration(
                        color: AppColors.ci7,
                      ),
                    ),

                    _buildConditionItem(
                      // อบ\ndryRemainDisplay',
                      wording: context.wording.dryRemainLabel(
                        data.dryRemainDisplay,
                      ),
                      icon: Assets.svg.icDryRoundedGreen.svg(
                        width: AppDims.size_28.w,
                        height: AppDims.size_28.h,
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

                CustomDropdown(
                  items: [],
                  hint: data.storeNameDisplay(context).orEmpty,
                  isInteractive: false,
                  showDisableDecoration: true,
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
                  data: data.descriptionDisplay(context),
                  style: {
                    "body": Style(
                      fontSize: FontSize(AppDims.size_15.sp),
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
      margin: EdgeInsets.only(top: AppDims.size_16.h),
      padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
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
            padding: EdgeInsets.all(AppDims.size_8),
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
