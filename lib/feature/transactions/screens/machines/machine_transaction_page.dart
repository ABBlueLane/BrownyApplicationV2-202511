import 'package:browny_applications_new/core/core_index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_programs_response.dart';
import 'package:browny_applications_new/feature/transactions/models/machine_program_model.dart';
import 'package:browny_applications_new/feature/transactions/repository/coupon_voucher_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/machine_transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/screens/available_payment_method_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';
import 'package:browny_applications_new/feature/wallet/screen/wallet_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MachineTransactionPage extends StatelessWidget {
  const MachineTransactionPage({
    super.key,
    required this.machineId,
  });

  static final pagePath = '/machine_page';
  static final pageName = 'machine_page';

  final String machineId;

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    required String machineId,
  }) async {
    return await context.pushNamed(
      MachineTransactionPage.pageName,
      extra: machineId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MachineTransactionViewmodel(
        context: context,
        couponRepo: CouponVoucherRepo(),
        transactionRepo: TransactionRepo(),
        machineRepo: MachineRepo(),
      ),
      child: _MachineContent(
        machineId: machineId,
      ),
    );
  }
}

class _MachineContent extends StatefulWidget {
  const _MachineContent({
    required this.machineId,
  });
  final String machineId;

  @override
  State<_MachineContent> createState() => __MachineContentState();
}

class __MachineContentState extends State<_MachineContent> {
  late final MachineTransactionViewmodel _viewmodel;

  MachineProgramModel? _machineProgram;

  @override
  void initState() {
    super.initState();
    _viewmodel = context.read();
    _viewmodel.attachContext(context);

    // Fetch coupon detail data with location
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await _viewmodel.fetchMachineDetail(widget.machineId);
      if (!mounted) return;

      if (result.hasError || result.isEmpty) {
        await AppOverlays.showBrownyDialog(
          context,
          title: context.wording.errorOccurred,
          message: context.wording.errorUi,
          onConfirm: () {
            if (!mounted) return;
            context.safePop();
          },
        );
        return;
      }

      final machine = result.data!;

      if (machine.isBusy) {
        await AppOverlays.showBrownyDialog(
          context,
          // เครื่องกำลังทำงาน
          title: context.wording.machineInUse,
          // กรุณาลองเครื่องอื่น
          message: context.wording.tryOtherMachine,
          onConfirm: () {
            if (!mounted) return;
            context.safePop();
          },
        );
        return;
      }

      if (machine.isTimeOut) {
        await AppOverlays.showBrownyDialog(
          context,
          imageAsset: Assets.png.brownyMachineError1.path,
          // เครื่องไม่สามารถใช้งานได้ในขณะนี้
          title: context.wording.machineUnavailable,
          // กรุณาลองเครื่องอื่น
          message: context.wording.tryOtherMachine,
          onConfirm: () {
            if (!mounted) return;
            context.safePop();
          },
        );
        return;
      }

      if (!mounted) return;
      await _viewmodel.fetchMachinePrograms(widget.machineId);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      persistentFooterDecoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: AppColors.defatultShadow,
      ),
      persistentFooterButtons: [
        // ปุ่มยืนยันซื้อคูปอง
        ValueListenableBuilder(
          valueListenable: _viewmodel.paymentMethodNotifier,
          builder: (context, value, child) {
            return Container(
              padding: EdgeInsets.only(
                left: AppDims.size_16.w,
                right: AppDims.size_16.w,
                top: AppDims.size_8.h,
              ),
              child: ElevatedButton(
                onPressed: null,
                child: AppText(
                  '${context.wording.makePayment} ${formatCurrency(
                    leadingSign: '฿',
                    string: '0.0',
                  )}',
                  style: context.textTheme.labelLarge!.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            );
          },
        ),
      ],
      body: ValueListenableBuilder(
        valueListenable: _viewmodel.machineProgramsNotifier,
        builder: (context, result, child) {
          if (result.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (result.hasError || result.isEmpty) {
            return Center(
              child: AppText(
                'ไม่พบข้อมูลเครื่องหรือเกิดข้อผิดพลาด\nกรุณาตรวจสอบและลองใหม่อีกครั้ง',
              ),
            );
          }
          // assign value
          _machineProgram = result.data!;
          return CustomScrollView(
            // physics: const ClampingScrollPhysics(),
            slivers: [
              // build AppBar
              _buildMyAppBar(),

              // Title เครื่องซัก, สาขา
              _mainTitle(),

              // Program ของเครื่องซักที่มี
              // เช่น ซักน้ำเย็น, ซักน้ำอุ่น
              ..._programWidget(),

              // Program เพิ่มเวลา ของเครื่องอบที่มี
              // เช่น +6 นาที, +10 นาที
              ..._programAddTimeWidget(),

              // คูปอง / E-Voucher
              ..._couponEVoucherWidget(),

              // ประเภทชำระ
              ..._paymentMethods(),

              _mySliverToBoxAdapter(
                child: AppDims.vericalPadding_24,
              ),

              _mySliverToBoxAdapter(
                child: Divider(),
              ),

              // Summary Transaction
              ..._summary(),

              // Extra padding เพื่อให้ scroll พ้น footer button
              SliverPadding(
                padding: EdgeInsets.only(bottom: 100.h),
              ),
            ],
          );
        },
      ),
    );
  }

  /// โปรแกรมซัก
  /// Program ของเครื่องซักที่มี
  /// เช่น ซักน้ำเย็น, ซักน้ำอุ่น
  List<Widget> _programWidget() {
    // _machineProgram
    return [
      _mySliverToBoxAdapter(
        child: _title(
          icon: Assets.svg.icWashWhiteRoundedGreen.svg(),
          title: _machineProgram!.getMachineTypeDisplay(context.languageCode),
        ),
      ),

      // Card Programs Grid
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
        ),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childCount: _machineProgram!.programs.orEmpty.length,
          itemBuilder: (context, index) {
            final program = _machineProgram!.programs![index];
            final isSelected = _machineProgram!.isProgramSelected(index);
            return _programSingleItem(
              context,
              program,
              isSelected: isSelected,
              onTap: () => _viewmodel.selectProgram(index),
            );
          },
        ),
      ),
    ];
  }

  /// โปรแกรมซัก
  /// Program ของเครื่องซักที่มี
  /// เช่น ซักน้ำเย็น, ซักน้ำอุ่น
  List<Widget> _programAddTimeWidget() {
    if (!_machineProgram!.hasAddTime) return [];
    return [
      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_24,
      ),
      _mySliverToBoxAdapter(
        child: _title(
          icon: Assets.svg.icClockRoundedGreen.svg(),
          // ต่อเวลาอบผ้า
          title: context.wording.extendDryingTime,
        ),
      ),

      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_8,
      ),

      // Card Programs List - ใช้ SliverList แทน ListView
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // คำนวณ index จริงจาก separator
              final itemIndex = index ~/ 2;

              // ถ้าเป็น separator (index คี่)
              if (index.isOdd) {
                return AppDims.vericalPadding_8;
              }

              // ถ้าเป็น item (index คู่)
              final addTime = _machineProgram!.addTimes![itemIndex];
              final isSelected = _machineProgram!.isAddTimeSelected(itemIndex);
              return _programAddTimeSingleItem(
                context,
                addTime,
                isSelected: isSelected,
                onTap: () => _viewmodel.selectAddTime(itemIndex),
              );
            },
            childCount: _machineProgram!.addTimes.orEmpty.length * 2 - 1,
          ),
        ),
      ),
    ];
  }

  /// คูปอง / E-Voucher
  /// แสดง Coupon / E-Voucher ที่เลือกมาใช้งาน
  List<Widget> _couponEVoucherWidget() {
    return [
      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_24,
      ),
      _mySliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: _title(
                icon: Assets.svg.icWashWhiteRoundedGreen.svg(),
                title: 'คูปอง / E-Voucher',
              ),
            ),
            GestureDetector(
              onTap: () {
                CouponVoucherPage.goToPage(
                  context,
                  state: CouponVoucherState.using,
                  machineUsing: _machineProgram,
                );
              },
              child: Row(
                children: [
                  AppText(
                    'เพิ่ม/เลือก',
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  AppDims.horizonPadding_8,

                  Assets.svg.icArrowForward.svg(),
                ],
              ),
            ),
          ],
        ),
      ),
      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_8,
      ),
      // Coupon, E-Voucher Using
      _mySliverToBoxAdapter(
        child: Container(
          height: 85.h,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: Assets.png.bgUnselectedCouponEvoucher.provider(),
            ),
          ),
        ),
      ),
    ];
  }

  /// ประเภทชำระ
  /// แสดงประเภทชำระที่รองรับ
  List<Widget> _paymentMethods() {
    return [
      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_24,
      ),
      _mySliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: _title(
                icon: Assets.svg.icWalletRoundedGreen.svg(),
                // วิธีการชำระเงิน
                title: context.wording.paymentMethods,
              ),
            ),
            GestureDetector(
              onTap: () {
                AvailablePaymentMethodPage.goToPage(
                  context,
                  viewmodel: _viewmodel,
                );
              },
              child: Row(
                children: [
                  AppText(
                    // เลือก
                    context.wording.select,
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  AppDims.horizonPadding_8,

                  Assets.svg.icArrowForward.svg(),
                ],
              ),
            ),
          ],
        ),
      ),
      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_8,
      ),
      // ประเภทชำระ
      _mySliverToBoxAdapter(
        child: ValueListenableBuilder(
          valueListenable: _viewmodel.paymentMethodNotifier,
          builder: (context, value, child) {
            if (value.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (value.hasError) {
              return AppText(context.wording.errorUi);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...value.data!
                    .take(3)
                    .map(
                      (payment) => _cardPaymentDependOnState(
                        isTPWallet:
                            payment.isSelected && payment.method == 'tp_wallet',
                        selected: payment.isSelected,
                        child: ListTile(
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
                                  placeholder: (_, __) =>
                                      SizedBox(width: 22.w, height: 22.h),
                                  errorWidget: (_, __, ___) =>
                                      SizedBox(width: 22.w, height: 22.h),
                                )
                              : null,
                          title: AppText(
                            payment.name,
                            style: payment.isSelected
                                ? _textPrimarySelected
                                : _textPrimary,
                          ),
                          onTap: () {
                            _viewmodel.onPaymentChanged(
                              payment,
                            );
                          },
                          trailing: payment.isSelected
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    right: 6.0.w,
                                  ),
                                  child: Assets.svg.icChecked.svg(),
                                )
                              : null,
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _summary() {
    return [
      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_24,
      ),
      _mySliverToBoxAdapter(
        child: _title(
          icon: Assets.svg.icListRoundedGreen.svg(),
          // สรุปราคา
          title: context.wording.priceSummary,
        ),
      ),
      _mySliverToBoxAdapter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDims.vericalPadding_16,

            // detail
            // Title
            _lineSummay(
              title: _machineProgram!.getSummaryMachineTypeDisplay(
                context.languageCode,
              ),
              price: _machineProgram!.getNetPrice().toString(),
            ),
            AppDims.vericalPadding_16,
            // โปรโมชั่นสาขา
            _lineSummay(
              title: context.wording.branchPromotion,
              price: _machineProgram!.getTotalDiscountStore().toString(),
            ),
            AppDims.vericalPadding_16,
            // คูปองส่วนลด
            _lineSummay(
              title: context.wording.discountCoupon,
              price: _machineProgram!.getTotalCouponOnlyDiscount().toString(),
              textPriceColor: AppColors.primary,
            ),
            AppDims.vericalPadding_16,
            // สรุปยอด E-Voucher
            _lineSummay(
              title: 'E-Voucher',
              price: _machineProgram!.getTotalEVoucherDiscount().toString(),
              textPriceColor: AppColors.primary,
            ),
            AppDims.vericalPadding_16,
            _lineSummay(
              title: 'ยอดชำระทั้งหมด ',
              price: _machineProgram!.getNetPrice().toString(),
              textPriceColor: AppColors.primary,
            ),
          ],
        ),
      ),
      _mySliverToBoxAdapter(
        child: AppDims.vericalPadding_24,
      ),
    ];
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

  Widget _cardPaymentDependOnState({
    bool selected = false,
    required bool isTPWallet,
    required Widget child,
  }) {
    return Theme(
      data: context.appTheme.copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: AppDims.size_8.h),
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
          vertical: AppDims.size_16.h,
        ),
        decoration: BoxDecoration(
          border: BoxBorder.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? AppDims.size_2.h : AppDims.size_1.h,
          ),
          borderRadius: BorderRadius.circular(
            AppDims.size_8.r,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            child,
            if (isTPWallet) ...[
              Consumer<CustomerProvider>(
                builder: (context, provider, _) {
                  return ListTile(
                    minVerticalPadding: AppDims.size_8.h,
                    contentPadding: EdgeInsets.zero,
                    minTileHeight: 0,
                    horizontalTitleGap: AppDims.size_8.w,
                    // จำนวนเงินคงเหลือ
                    title: AppText(
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
                  WalletPage.goToPage(context);
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
          ],
        ),
      ),
    );
  }

  Widget _programSingleItem(
    BuildContext context,
    ProgramData program, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Stack(
      children: [
        // Text เก็บได้ทุกวัน และ Icon browny
        if (program.hasDiscount)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 8,
                top: 2,
                right: 8,
                bottom: 20,
              ),
              margin: EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: AppColors.error,
              ),
              child: Row(
                children: [
                  Assets.png.icDiscount.image(
                    width: AppDims.size_8.h,
                  ),
                  AppDims.horizonPadding_4,
                  AppText(
                    // ลดราคา
                    context.wording.discountLabel,
                    style: context.textTheme.labelSmall!.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Card แสดง Coin
        Container(
          margin: EdgeInsets.only(
            top: program.hasDiscount ? AppDims.size_21.h : AppDims.size_16.h,
          ),
          // padding: EdgeInsets.symmetric(
          //   vertical: AppDims.size_12.h,
          //   horizontal: AppDims.size_29.w,
          // ),
          decoration: BoxDecoration(
            // color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              width: isSelected ? 2 : 1,
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(
                    top: AppDims.size_12.h,
                    bottom: AppDims.size_12.h,
                    left: AppDims.size_29.w,
                    right: AppDims.size_29.w,
                  ),
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: Image.network(
                    width: AppDims.size_50.h,
                    height: AppDims.size_50.h,
                    program.image!,
                  ),
                ),
                AppDims.vericalPadding_8,

                Container(
                  margin: EdgeInsets.symmetric(horizontal: AppDims.size_6.w),
                  child: AppText(
                    program.getProgramNameDisplay(context.languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium,
                  ),
                ),

                AppDims.vericalPadding_8,

                AppText(
                  program.hasDiscount ? '฿ ${program.price}' : '',
                  style: context.textTheme.labelMedium!.copyWith(
                    fontSize: AppDims.size_10.sp,
                    color: AppColors.error,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.error,
                  ),
                ),
                AppDims.vericalPadding_4,
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppDims.size_2.h,
                    horizontal: AppDims.size_8.w,
                  ),
                  margin: EdgeInsets.only(
                    bottom: AppDims.size_12.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: AppText(
                    '฿ ${program.net}',
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _programAddTimeSingleItem(
    BuildContext context,
    ProgramData addTime, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      tileColor: AppColors.background, // Set background color
      shape: RoundedRectangleBorder(
        // Add border and rounded corners
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      title: AppText(
        addTime.getProgramNameDisplay(context.languageCode),
        style: context.textTheme.labelMedium!.copyWith(
          fontSize: AppDims.size_16.sp,
        ),
      ),
      horizontalTitleGap: 0.0,
      contentPadding: EdgeInsets.symmetric(horizontal: AppDims.size_8.w),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (addTime.hasDiscount)
            AppText(
              '฿ ${addTime.price}',
              style: context.textTheme.labelMedium!.copyWith(
                fontSize: AppDims.size_16.sp,
                color: AppColors.error,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.error,
              ),
            ),
          if (addTime.hasDiscount) AppDims.horizonPadding_16,
          Container(
            padding: EdgeInsets.symmetric(
              vertical: AppDims.size_2.h,
              horizontal: AppDims.size_8.w,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(32.r),
            ),
            child: AppText(
              '฿ ${addTime.net}',
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _mainTitle() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Title เครื่องซัก
          AppText(
            _machineProgram!.machineName!.getByLocaleCode(
              context.languageCode,
            )!,
            style: context.textTheme.headlineMedium,
          ),
          AppDims.vericalPadding_4,

          // สาขา
          AppText(
            _machineProgram!.storeName!.getByLocaleCode(
              context.languageCode,
            )!,
            style: context.textTheme.bodyMedium!.copyWith(
              color: AppColors.gray500,
            ),
          ),

          AppDims.vericalPadding_24,
        ],
      ),
    );
  }

  Widget _buildMyAppBar() {
    return SliverAppBar(
      pinned: false,
      floating: false,
      surfaceTintColor: AppColors.transparent,
      stretch: false,
      expandedHeight: 365.h,
      elevation: 0.0,
      // เริ่มต้นทำงาน
      title: AppText(
        context.wording.startMachine,
        style: context.appBarTextThemeWhite,
      ),
      flexibleSpace: FlexibleSpaceBar(
        // FlexibleSpaceBar: ส่วนที่ยืด-หดได้ของ AppBar=
        background: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: Assets.png.bgMachine.provider(),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Machine Model Image
                Padding(
                  padding: EdgeInsets.only(
                    top: AppDims.size_42.h,
                    bottom: AppDims.size_42.h,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //
                      SizedBox(
                        width: 56.w,
                      ),
                      // Container(
                      //   width: 167.w,
                      //   height: 224.h,
                      //   color: AppColors.gray600,
                      // ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppDims.size_16.h,
                          // bottom: AppDims.size_21.h,
                        ),
                        child: Image.network(
                          // height: 224.h,
                          _machineProgram!.machineImage.orEmpty,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(right: AppDims.size_16.w),
                        width: 56.w,
                        height: 87.h,
                        // color: AppColors.gray600,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Machine No
                            Stack(
                              children: [
                                Assets.png.icPaw2RoundedGreen.image(
                                  width: AppDims.size_39.w,
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: AlignmentGeometry.center,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 2.0.w,
                                        top: 8.0.h,
                                      ),
                                      child: AppText(
                                        _machineProgram!.machineNo.toString(),
                                        style: context.textTheme.headlineSmall!
                                            .copyWith(
                                              fontSize: AppDims.size_16.sp,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppDims.vericalPadding_8,

                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: AppDims.size_8.h,
                                horizontal: AppDims.size_13.w,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ci3,
                                shape: BoxShape.circle,
                              ),
                              child: AppText(
                                '?',
                                style: context.textTheme.labelLarge!.copyWith(
                                  color: AppColors.primary,
                                  fontSize: AppDims.size_24.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Background Radius
                Align(
                  alignment: AlignmentGeometry.bottomCenter,
                  child: AppContainerRadius(
                    height: AppDims.size_24.h,
                  ),
                ),
              ],
            ),
          ),
        ),
        expandedTitleScale: 8,
        title: AppContainerRadius(
          height: AppDims.size_2.h,
        ),
        // collapseMode: CollapseMode.none,
        titlePadding: EdgeInsets.all(0.0),
      ),
    );
  }

  SliverToBoxAdapter _mySliverToBoxAdapter({required Widget child}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
        ),
        child: child,
      ),
    );
  }

  Widget _title({
    required Widget icon,
    required String title,
  }) {
    return ElevatedButton.icon(
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
    );
  }
}
