import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_detail_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:browny_applications_new/core/providers/customer_provider.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';
import 'package:browny_applications_new/feature/wallet/screen/wallet_page.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AvailablePaymentMethodPage extends StatefulWidget {
  const AvailablePaymentMethodPage({
    super.key,
    required TransactionsViewmodel viewmodel,
  }) : _viewmodel = viewmodel;

  final TransactionsViewmodel _viewmodel;

  static final pagePath = '/AvailablePayments';
  static final pageName = 'AvailablePayments';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    required TransactionsViewmodel viewmodel,
  }) async {
    return await context.pushNamed(
      AvailablePaymentMethodPage.pageName,
      extra: viewmodel,
    );
  }

  @override
  State<AvailablePaymentMethodPage> createState() =>
      _AvailablePaymentMethodPageState();
}

class _AvailablePaymentMethodPageState
    extends State<AvailablePaymentMethodPage> {
  TextStyle _textPrimary(BuildContext context) =>
      context.textTheme.labelLarge!.copyWith(
        color: AppColors.textPrimary,
      );

  TextStyle _textPrimarySelected(BuildContext context) =>
      context.textTheme.labelLarge!.copyWith(
        color: AppColors.primary,
      );

  @override
  void initState() {
    super.initState();
    // เก็บค่า payment เดิมไว้ก่อนเริ่มแก้ไข
    widget._viewmodel.startEditingPaymentMethod();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget._viewmodel.fetchPaymentMethod(
        context,
        fetchAll: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // ถ้า user กด back button ให้ cancel การเปลี่ยนแปลง
          await widget._viewmodel.cancelPaymentMethodEdit(context);
        }
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
            valueListenable: widget._viewmodel.paymentMethodNotifier,
            builder: (context, value, child) {
              return Container(
                padding: EdgeInsets.only(
                  left: AppDims.size_24.w,
                  right: AppDims.size_24.w,
                  top: AppDims.size_8.h,
                ),
                child: ElevatedButton(
                  // ต้องมีช่องทางชำระที่ใช้งานได้อย่างน้อย 1 ช่อง
                  onPressed:
                      value.isSuccess &&
                          value.data.orEmpty.any((e) => e.isActive)
                      ? () {
                          // ยืนยันการเลือก payment method
                          widget._viewmodel.confirmPaymentMethodEdit();
                          // Pop กลับไป transaction_selected_page
                          context.pop();
                        }
                      : null,
                  // เลือก
                  child: AppText(context.wording.select),
                ),
              );
            },
          ),
        ],
        appBar: AppBar(
          title: AppText(
            // เลือกวิธีการชำระเงิน
            context.wording.selectPaymentMethod,
            style: context.appBarTextThemeWhite,
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Assets.png.bgAppBar.image(
              fit: BoxFit.cover,
            ),
          ),
        ),
        backgroundColor: AppColors.bareBackground,
        body: SingleChildScrollView(
          child: ValueListenableBuilder(
            valueListenable: widget._viewmodel.paymentMethodNotifier,
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
                    // ประเภทชำระแต่ละละแบบ ตามที่ API ส่งมา
                    ...value.data.orEmpty.map(
                      (payment) => _cardPaymentDependOnState(
                        payment,
                        // context,
                        // isTPWallet:
                        //     payment.isSelected && payment.method == 'tp_wallet',
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
                        //         ? _textPrimarySelected(context)
                        //         : _textPrimary(context),
                        //   ),
                        //   onTap: () {
                        //     widget._viewmodel.onPaymentChanged(
                        //       payment,
                        //       fetchAll: true,
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
        ),
      ),
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
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }

  Widget _cardPaymentDependOnState(
    PaymentMethodModel payment,
    //   BuildContext context, {
    //   bool selected = false,
    //   required bool isTPWallet,
    //   required Widget child,
    // }
  ) {
    final isDisabled = !payment.isActive;
    final isSelected = payment.isSelected && !isDisabled;
    final isTPWallet = payment.isTpWallet;
    final isCoin = payment.isCoin;
    // เหตุผลที่เลือกช่องทางนี้ไม่ได้ (null = เลือกได้ปกติ)
    final disabledReason = widget._viewmodel.paymentMethodDisabledReason(
      context,
      payment,
    );
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              widget._viewmodel.onPaymentChanged(
                payment,
                fetchAll: true,
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
            color: AppColors.background,
            border: isSelected
                ? BoxBorder.all(
                    color: AppColors.primary,
                    width: AppDims.size_2.h,
                  )
                : BoxBorder.all(
                    color: AppColors.border,
                    width: AppDims.size_1.h,
                  ),
            borderRadius: BorderRadius.circular(
              AppDims.size_8.r,
            ),
          ),
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
                        width: 22.w,
                        height: 22.h,
                        fit: BoxFit.contain,
                        placeholder: (_, _) =>
                            SizedBox(width: 22.w, height: 22.h),
                        errorWidget: (_, _, _) =>
                            SizedBox(width: 22.w, height: 22.h),
                      )
                    : null,
                title: AppText(
                  payment.name,
                  style: isSelected
                      ? _textPrimarySelected(context)
                      : _textPrimary(context),
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
                        // จำนวนเงินคงเหลือ
                        context.wording.balanceRemaining,
                        style: _textPrimary(context),
                      ),
                      trailing: AppText(
                        formatCurrency(
                          leadingSign: '฿ ',
                          string: provider.current.creditBalance,
                          decimal: true,
                        ),
                        style: _textPrimarySelected(context).copyWith(
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
                        style: _textPrimary(context),
                      ),
                      trailing: AppText(
                        formatCurrency(
                          leadingSign: '฿ ',
                          string: provider.current.currentCoin,
                          decimal: true,
                        ),
                        style: _textPrimarySelected(context).copyWith(
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
                          style: _textPrimarySelected(context).copyWith(
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
}
