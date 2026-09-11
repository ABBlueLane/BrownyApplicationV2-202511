import 'package:browny_applications_new/core/const/app_constants.dart';
import 'package:browny_applications_new/core/providers/customer_provider.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/ui_result.dart';
import 'package:browny_applications_new/core/widgets/app_container_radius.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/coin/models/coin_data_model.dart';
import 'package:browny_applications_new/feature/coin/repository/coin_claim_repo.dart';
import 'package:browny_applications_new/feature/coin/screens/coin_history_page.dart';
import 'package:browny_applications_new/feature/coin/viewmodel/coin_viewmodel.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CoinPage extends StatelessWidget {
  const CoinPage({super.key});

  static final pagePath = '/coin_page';
  static final pageName = 'CoinPage';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CoinViewmModel(
        context: context,
        repo: CoinClaimRepo(),
      ),
      child: _CoinContent(),
    );
  }
}

class _CoinContent extends StatefulWidget {
  const _CoinContent();

  @override
  State<_CoinContent> createState() => __CoinContentState();
}

class __CoinContentState extends State<_CoinContent> {
  late final CoinViewmModel _viewModel;

  String _popupConditionImageUrl(BuildContext context) {
    final result = _viewModel.coinClaimDataNotifier.value;
    if (!result.isSuccess || result.data == null) return '';

    final imageUrl = result.data!.popupImages
        ?.getByLocaleCode(context.languageCode)
        .orEmpty;
    return imageUrl.orEmpty;
  }

  /// รายละเอียดเงื่อนไขจาก API `popup_details` (HTML) ตามภาษา — ถ้า null/ว่างทุกภาษาให้ว่าง
  String _conditionPopupHtml(BuildContext context) {
    final result = _viewModel.coinClaimDataNotifier.value;
    if (!result.isSuccess || result.data == null) return '';
    return result.data!.popupDetailsDisplay.trim();
  }

  String _formatTodayDateDisplay(BuildContext context, String rawDate) {
    final parsedDate = rawDate.convertToDateTime(
      'yyyy-MM-dd',
      context.languageCode,
    );
    if (parsedDate == null) return rawDate;

    return parsedDate.formatDateLocale(
      context.languageCode,
      pattern: 'dd MMM yyyy',
    );
  }

  @override
  void initState() {
    super.initState();
    _viewModel = context.read();
    _viewModel.attachContext(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // โหลดข้อมูล CoinClaim
      await _viewModel.fetchCoinCliamData();
      if (!mounted) return;

      _showCondition(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                // gradient: AppColors.primaryGradient,
                image: DecorationImage(
                  image: Assets.png.bgCoinClaim.provider(),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppDims.size_24.r),
                  bottomRight: Radius.circular(AppDims.size_24.r),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // AppBar
                  _buildAppBar(context),

                  ValueListenableBuilder(
                    valueListenable: _viewModel.coinClaimDataNotifier,
                    builder: (context, result, child) {
                      if (result.isLoading) {
                        return CircularProgressIndicator();
                      }
                      if (!result.isSuccess) {
                        return Column(
                          children: [
                            Assets.png.brownyError2.image(),
                            AppDims.vericalPadding_12,

                            AppText(context.wording.errorUi),
                          ],
                        );
                      }

                      // ข้อมูลสำหรับ Display ทั้งหมด
                      final coinData = result.data!;
                      return Container(
                        padding: EdgeInsets.only(
                          left: AppDims.size_16,
                          right: AppDims.size_16,
                          bottom: AppDims.size_16,
                        ),
                        child: Column(
                          // Main container - จัดเรียงแนวตั้ง
                          children: [
                            // แถวบน
                            Row(
                              // จัดเรียง 2 กล่องแนวนอน
                              crossAxisAlignment:
                                  CrossAxisAlignment.end, // จัดชิดด้านล่าง
                              children: [
                                // กล่องซ้ายบน (เล็ก) - 50% ความกว้าง
                                _buildCoinBalance(),

                                // SizedBox(width: 16.w), // ช่องว่างระหว่างกล่อง
                                // กล่องขวาบน (ใหญ่) - 50% ความกว้าง
                                _getBrownyCoinClaimedDisplay(),
                              ],
                            ),

                            // กล่องล่าง (กว้างเต็มพื้นที่)
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  decoration: BoxDecoration(
                                    boxShadow: AppColors.defatultShadow,
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16.r),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // text title
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // แสดง day ที่เป็นวันปัจจุบัน
                                            _buildTextToDay(),
                                            // ปุ่ม ประวัติ
                                            _buildHistory(context),
                                          ],
                                        ),
                                      ),
                                      AppDims.vericalPadding_16,

                                      // Claim Coin
                                      _buildListClaimCoinProgress(coinData),
                                      // Row(
                                      //   mainAxisAlignment:
                                      //       MainAxisAlignment.spaceBetween,
                                      //   children: List.generate(
                                      //     coinData.maxDay!,
                                      //     (index) {
                                      //       // สร้าง item สำหรับ Claim Coin
                                      //       return _buildItemCoinClaim(
                                      //         coinData.streaksDisplay[index],
                                      //         context,
                                      //       );
                                      //     },
                                      //   ),
                                      // ),
                                      // AppDims.vericalPadding_2,

                                      // แถวเงื่อนไข
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: _buildButtonCondition(context),
                                      ),
                                      AppDims.vericalPadding_16,

                                      // Button Get Coin
                                      _buildButtonClaimCoin(
                                        coinData,
                                        context,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 12.w,
                                  top: -14,
                                  child: Assets.png.decoratCardCoinClaim.image(
                                    width: AppDims.size_84.w,
                                    height: AppDims.size_25.h,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Expanded(child: Text('')),
          ],
        ),
      ),
    );
  }

  Widget _getBrownyCoinClaimedDisplay() {
    switch (context.languageCode) {
      case 'zh':
        return Assets.png.brownyCoinClaimedZh.image(
          width: 190.w,
        );
      case 'en':
        return Assets.png.brownyCoinClaimedEn.image(
          width: 190.w,
        );
      default:
        return Assets.png.brownyCoinClaimTitle.image(
          width: 190.w,
        );
    }
  }

  Widget _buildListClaimCoinProgress(CoinDataModel coinData) {
    return SizedBox(
      height: 100.0.h,
      child: ListView.separated(
        padding: EdgeInsets.only(
          top: 10.h,
          left: AppDims.size_4.w,
          right: AppDims.size_4.w,
        ),
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) => _buildItemCoinClaim(
          coinData.streaksDisplay[index],
          context,
        ),
        separatorBuilder: (_, _) => AppDims.horizonPadding_12,
        itemCount: coinData.maxDay!,
      ),
    );
  }

  Widget _buildButtonClaimCoin(CoinDataModel coinData, BuildContext context) {
    return GestureDetector(
      onTap: coinData.claimableToday! ? _onCoinClaiming : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 57,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          gradient: coinData.claimableToday!
              ? AppColors.claimCoinButtonGradient
              : null,
          color: coinData.claimableToday! ? null : AppColors.green400,
          borderRadius: BorderRadius.all(
            Radius.circular(8.r),
          ),
          // ถ้าสามารถ claim. ได้
          boxShadow: coinData.claimableToday!
              ? [
                  BoxShadow(
                    color: AppColors.ci4,
                    blurRadius: 6.r,
                  ),
                ]
              // claim ไม่ได้ ไม่ต้องมี shadow
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              // รับคอนย์ : รับพรุ่งนี้
              coinData.claimableToday!
                  ? context.wording.collectCoins
                  : context.wording.collectTomorrow,
              style: context.textTheme.headlineSmall!.copyWith(
                fontSize: AppDims.size_14.sp,
                color: AppColors.textWhite,
              ),
            ),
            AppDims.horizonPadding_8,

            Assets.svg.icPaw.svg(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonCondition(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCondition(context),
      child: Row(
        spacing: AppDims.size_2.w,
        children: [
          Spacer(),
          Assets.svg.icCoinCondition.svg(),
          AppText(
            // 'เงื่อนไข',
            context.wording.conditions,
            style: context.textTheme.labelSmall!.copyWith(
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCondition(BuildContext context) async {
    final popupImageUrl = _popupConditionImageUrl(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: AppDims.size_32.w),
          child: FractionallySizedBox(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => dialogContext.safePop(),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Assets.svg.icClosePopup.svg(
                            width: 20.w,
                            height: 20.h,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AppContainerRadius(
                        decoration: BoxDecoration(
                          gradient: AppColors.popupGradient,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // AppDims.vericalPadding_16,
                              SizedBox(
                                height: 200.h,
                              ),

                              // AppDims.vericalPadding_16,
                              Padding(
                                padding: EdgeInsets.all(AppDims.size_16),
                                child: Column(
                                  children: [
                                    AppText(
                                      'Browny Coin',
                                      textAlign: TextAlign.center,
                                      style: context.textTheme.headlineLarge!
                                          .copyWith(
                                            fontSize: AppDims.size_24.sp,
                                            color: AppColors.primary,
                                          ),
                                    ),
                                    AppDims.vericalPadding_10,

                                    // รายละเอียดเงื่อนไข (จาก API popup_details เท่านั้น)
                                    Html(
                                      data: _conditionPopupHtml(context),
                                      style: {
                                        "p": Style(
                                          fontSize: FontSize(
                                            AppDims.size_12.sp,
                                          ),
                                          fontFamily:
                                              GoogleFonts.prompt().fontFamily,
                                          padding: HtmlPaddings.zero,
                                          textAlign: TextAlign.start,
                                          margin: Margins.zero,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gray600,
                                        ),
                                        "p.fancy": Style(
                                          fontSize: FontSize(
                                            AppDims.size_12.sp,
                                          ),
                                          fontFamily:
                                              GoogleFonts.prompt().fontFamily,
                                          padding: HtmlPaddings.zero,
                                          textAlign: TextAlign.start,
                                          margin: Margins.zero,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.gray600,
                                        ),
                                        "ul": Style(
                                          fontFamily:
                                              GoogleFonts.prompt().fontFamily,
                                          fontSize: FontSize(
                                            AppDims.size_12.sp,
                                          ),
                                          padding: HtmlPaddings.only(
                                            left: 16,
                                          ), // ลด indent ของ bullet list
                                          margin: Margins.zero,
                                        ),
                                        "li": Style(
                                          fontSize: FontSize(
                                            AppDims.size_12.sp,
                                          ),
                                          fontFamily:
                                              GoogleFonts.prompt().fontFamily,
                                          padding: HtmlPaddings.zero,
                                          margin: Margins.only(
                                            bottom: 2,
                                          ), // ลดช่องว่างระหว่าง item
                                          color: AppColors.gray600,
                                        ),
                                      },
                                    ),

                                    AppDims.vericalPadding_16,

                                    ElevatedButton(
                                      onPressed: () {
                                        dialogContext.safePop();
                                      },
                                      child: AppText(
                                        context.wording.acknowledge,
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
                  ],
                ),

                Positioned(
                  top: -35.w,
                  right: 10.w,
                  child: popupImageUrl.isNotEmpty
                      ? Image.network(
                          popupImageUrl,
                          width: 330.w,
                          errorBuilder: (_, _, _) {
                            return Assets.png.brownyCoinclaimCondition.image(
                              width: 330.w,
                            );
                          },
                        )
                      : Assets.png.brownyCoinclaimCondition.image(
                          width: 330.w,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onCoinClaiming() async {
    AppOverlays.showLoading(context);
    final result = await _viewModel.coinClaiming();

    AppOverlays.hideLoading();
    if (mounted) {
      if (result.hasError) {
        AppOverlays.showBrownyErrorDialog(
          context,
          title: context.wording.errorOccurred,
          error: result.error,
        );
        return;
      }

      AppOverlays.showBrownyDialog(
        context,
        imageAsset: Assets.png.brownyCoinClaimed.path,
        // รับ Browny Coin สำเร็จ,
        title: context.wording.collectCoinSuccess,
        // เก็บต่อทุกวัน สิทธิประโยชน์ดีๆ รออยู่เพียบ!,
        message: context.wording.collectCoinMotivation,
      );
    }
  }

  Widget _buildHistory(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        CoinHistoryPage.pageName,
        extra: _viewModel,
      ),
      child: Row(
        spacing: AppDims.size_2.w,
        children: [
          Assets.svg.icHistory2.svg(
            colorFilter: ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          AppText(
            context.wording.history,
            style: context.textTheme.titleSmall!.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  ValueListenableBuilder<UiResult<String>> _buildTextToDay() {
    return ValueListenableBuilder(
      valueListenable: _viewModel.toDayDataNotifier,
      builder: (context, value, child) {
        return TextButton.icon(
          onPressed: null,
          style: context.appTheme.textButtonTheme.style!.copyWith(
            minimumSize: WidgetStatePropertyAll(
              Size(
                AppDims.size_50.w,
                AppDims.size_18.h,
              ),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStatePropertyAll(
              EdgeInsets.only(
                top: AppDims.size_2.h,
              ),
            ),
          ),
          icon: Assets.svg.icCalendarToday.svg(
            colorFilter: ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          label: AppText(
            _formatTodayDateDisplay(context, value.data.orEmpty),
            style: context.textTheme.titleSmall!.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoinBalance() {
    return Expanded(
      // ✅ ขยาย 50% ของพื้นที่
      // flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: Consumer<CustomerProvider>(
          builder: (context, value, child) {
            return Row(
              children: [
                Assets.png.brownyCoin.image(
                  width: AppDims.size_30.w,
                  height: AppDims.size_30.h,
                ),
                AppDims.horizonPadding_8,

                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: 8,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.containerCoinGradient,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.r),
                      ),
                    ),
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        // text: '= 0.25',
                        text: formatCurrency(
                          string: value.current.brownyCoin,
                          leadingSign: '= ',
                        ),
                        style:
                            GoogleFonts.prompt(
                              textStyle: context.textTheme.headlineMedium,
                            ).copyWith(
                              color: AppColors.textWhite,
                            ),
                        children: [
                          TextSpan(text: ' '),
                          TextSpan(
                            text: context.wording.coin,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: AppColors.textWhite,
                              fontSize: AppDims.size_10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      title: AppText(
        'Browny Coin',
        style: context.textTheme.titleLarge!.copyWith(
          fontSize: AppDims.size_18.sp,
          color: AppColors.textWhite,
        ),
      ),
    );
  }

  Widget _buildItemCoinClaim(StreakModelItem item, BuildContext context) {
    bool isClaimed = item.claimedAtDisplay.isNotEmpty;
    bool isHighlight = item.highlight;

    SvgGenImage brownyItemState;

    if (!isClaimed && !isHighlight) {
      // ยังไม่ claim และไม่เป็น highlight
      brownyItemState = Assets.svg.icBrownySmile2;
    } else if (isHighlight) {
      // เป็น highlight (มี icon เดียว)
      brownyItemState = Assets.svg.icBrownyLove;
    } else {
      // มีการ claim แล้ว
      brownyItemState = Assets.svg.icBrownySmile;
    }

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none, // ✅ ให้วงกลมยื่นออกนอกขอบได้
          children: [
            Container(
              width: 35.w,
              height: 60.h,
              padding: EdgeInsets.only(
                left: 2,
                right: 2,
                bottom: 2,
              ),
              decoration: BoxDecoration(
                color: isClaimed ? AppColors.primary : AppColors.ci5,
                borderRadius: BorderRadius.all(
                  Radius.circular(6.r),
                ),
                boxShadow: item.isToday
                    ? [
                        BoxShadow(
                          color: AppColors.yellow,
                          blurRadius: 5.r,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(6.r),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppDims.vericalPadding_8,
                    Container(
                      margin: EdgeInsets.only(right: 3.w),
                      width: double.infinity,
                      color: isHighlight ? AppColors.borderError : null,
                      child: Align(
                        alignment: Alignment.center,
                        child: AppText(
                          formatCurrency(
                            string: item.amount,
                            leadingSign: '+',
                          ),
                          style: context.textTheme.headlineSmall!.copyWith(
                            fontSize: AppDims.size_10.sp,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: brownyItemState.svg(
                        fit: BoxFit.cover,
                        width: 33.w,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -13, // ✅ ติดลบ = ยื่นออกขอบบน
              right: -13, // ✅ ติดลบ = ยื่นออกขอบขวา
              child: Assets.png.coinCoinClaim.image(
                width: 25.w,
                height: 25.h,
              ),
            ),
          ],
        ),
        AppDims.vericalPadding_4,

        AppText(
          item.isToday ? context.wording.today : item.dayDisplay,
          style: context.textTheme.labelSmall!.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
