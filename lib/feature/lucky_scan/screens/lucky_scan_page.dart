import 'dart:ui';

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/data/remote/models/response/festive_index_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/lucky_draw_response.dart';
import 'package:browny_applications_new/feature/lucky_scan/repository/lucky_repo.dart';
import 'package:browny_applications_new/feature/lucky_scan/viewmodel/lucky_viewmodel.dart';
import 'package:browny_applications_new/feature/scaner/screen/scanner_page.dart';
import 'package:browny_applications_new/feature/scaner/viewmodel/scanner_viewmodel.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/wallet/error/wallet_exception.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';

class LuckyScanPage extends StatelessWidget {
  const LuckyScanPage({super.key, this.autoScanQRData});

  /// QR data สำหรับ auto-process เมื่อ scan จากหน้า Home
  final String? autoScanQRData;

  static final pagePath = '/lucky_scan_page';
  static final pageName = 'lucky_scan_page';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    String? autoScanQRData,
  }) async {
    return await context.pushNamed(
      LuckyScanPage.pageName,
      extra: autoScanQRData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LuckyViewmodel(
        context: context,
        repo: LuckyRepo(),
      ),
      child: LuckyScanContent(autoScanQRData: autoScanQRData),
    );
  }
}

class LuckyScanContent extends StatefulWidget {
  const LuckyScanContent({super.key, this.autoScanQRData});

  final String? autoScanQRData;

  @override
  State<LuckyScanContent> createState() => _LuckyScanContentState();
}

class _LuckyScanContentState extends State<LuckyScanContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LuckyViewmodel _viewmodel;

  /// ความสูงจริงของ image container — ใช้คำนวณจุด overlap คงที่
  double _imageHeight = 0;
  final _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    _viewmodel = context.read();
    _viewmodel.attachContext(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewmodel.fetchFestiveIndex();
      _handlePostFetch();

      // Auto-process lucky draw เมื่อ scan QR จากหน้า Home
      if (widget.autoScanQRData != null) {
        final result = _viewmodel.festiveIndexNotifier.value;
        if (result.isSuccess && result.data?.hasEvent == true) {
          _onScanResult(
            widget.autoScanQRData!,
            // from scan auto
            true,
          );
        }
      }
    });
  }

  void _handlePostFetch() {
    if (!mounted) return;
    final result = _viewmodel.festiveIndexNotifier.value;

    // error หรือ empty → แสดง error dialog แล้ว pop
    if (result.hasError || result.isEmpty) {
      AppOverlays.showBrownyDialog(
        context,
        message: context.wording.errorOccurred,
        onConfirm: () => context.safePop(),
      );
      return;
    }

    // has_event = false → แจ้งเตือนว่าไม่มีกิจกรรม แล้ว pop
    if (result.isSuccess && result.data?.hasEvent == false) {
      AppOverlays.showBrownyDialog(
        context,
        // ขณะนี้ยังไม่มีกิจกรรม Lucky Scan
        title: context.wording.noLuckyScanActivityTitle,
        // รอติดตามกิจกรรมครั้งถัดไปนะ
        message: context.wording.noLuckyScanActivityMessage,
        // กลับสู่หน้าหลัก
        confirmText: context.wording.backToHome,
        onConfirm: () => context.safePop(),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// วัดความสูงจริงของ image container แล้ว setState เพื่อคำนวณ overlap
  void _measureImage() {
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final h = box.size.height;
      if (h > 0 && h != _imageHeight) {
        setState(() => _imageHeight = h);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      persistentFooterDecoration: BoxDecoration(),
      persistentFooterButtons: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          child: ElevatedButton.icon(
            onPressed: () async {
              // if (kDebugMode) {
              //   _onScanResult(
              //     'http://brownypay.com/lucky/draw/3cd789cf-0c35-4006-a5f5-fa9ef09d7e37',
              //   );
              //   return;
              // }
              ScannerPage.goToPage(
                context,
                process: ScannerProcess.needResult,
              ).then((qrData) async {
                if (qrData != null && context.mounted) {
                  _onScanResult(qrData);
                }
              });
            },
            iconAlignment: IconAlignment.end,
            icon: Assets.svg.icScan2.svg(
              colorFilter: ColorFilter.mode(
                AppColors.white,
                BlendMode.srcIn,
              ),
            ),
            label: AppText(context.wording.scanQrActivity),
          ),
        ),
      ],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.transparent,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDims.size_14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ปุ่มกลับ
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: EdgeInsets.only(
                      left: AppDims.size_4.w,
                      top: AppDims.size_2.h,
                      right: AppDims.size_6.w,
                      bottom: AppDims.size_2.h,
                    ),
                    iconSize: AppDims.size_8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(32.r),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.safePop(),
                  child: Row(
                    spacing: AppDims.size_4.w,
                    children: [
                      Assets.svg.icArrowBackward.svg(
                        color: AppColors.primary,
                      ),
                      AppText(
                        // ย้อนกลับ
                        context.wording.back,
                        style: context.textTheme.labelLarge!.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // ประวัติ
                GestureDetector(
                  onTap: () async {
                    await _showFestiveHistory(context);
                  },
                  child: ClipRect(
                    clipBehavior: Clip.antiAlias,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: EdgeInsets.only(
                          left: AppDims.size_6.w,
                          top: AppDims.size_2.h,
                          right: AppDims.size_6.w,
                          bottom: AppDims.size_2.h,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(32.r),
                          color: Colors.grey.shade200.withValues(
                            alpha: 0.10,
                          ), // Tint for glass effect
                        ),
                        child: Row(
                          spacing: AppDims.size_4.w,
                          children: [
                            Assets.luckyScan.icClock.svg(
                              color: AppColors.background,
                            ),
                            AppText(
                              // ประวัติ
                              context.wording.history,
                              style: context.textTheme.labelLarge!.copyWith(
                                color: AppColors.background,
                              ),
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
      ),
      body: ValueListenableBuilder(
        valueListenable: _viewmodel.selectedFestiveNotifier,
        builder: (context, selected, _) {
          return ValueListenableBuilder(
            valueListenable: _viewmodel.festiveIndexNotifier,
            builder: (context, festiveResult, _) {
              if (festiveResult.isLoading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final locale = context.languageCode;
              final bannerUrl =
                  selected?.getBannerUrl(
                    context.languageCode,
                  ) ??
                  '';
              return SingleChildScrollView(
                physics: bannerUrl.isEmpty
                    ? NeverScrollableScrollPhysics()
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blue zone — image fills width; white-zone overlaps at fixed offset
                    // แสดงรูปภาพ Festive ที่ได้จาก API แบบเต็มหน้าจอ
                    Stack(
                      children: [
                        // Image — non-positioned, กำหนดขนาด Stack ตาม image
                        Container(
                          key: _imageKey,
                          width: double.infinity,
                          color: AppColors.primary,
                          child: Image.network(
                            bannerUrl,
                            fit: BoxFit.fitWidth,
                            width: double.infinity,
                            frameBuilder: (_, child, frame, _) {
                              if (frame != null) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) _measureImage();
                                });
                              }
                              return child;
                            },
                            errorBuilder: (_, _, _) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _measureImage();
                              });
                              return Container(
                                color: AppColors.background,
                                height: MediaQuery.of(context).size.height,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Assets.png.brownyError2.image(width: 120.w),
                                    AppDims.vericalPadding_8,
                                    AppText(context.wording.errorUi),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // White zone — เริ่มที่ตำแหน่งคงที่ (imageHeight - overlap)
                        // แสดง Text Content และ TabBar
                        // ไม่ว่า content จะมากหรือน้อย จุด overlap จะไม่เปลี่ยน
                        if (_imageHeight > 0 && bannerUrl.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              // กำหนดจุดที่ White zone จะเริ่ม Overlap
                              top: _imageHeight - 155.h,
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(AppDims.size_16.r),
                                  topRight: Radius.circular(AppDims.size_16.r),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // TabBar
                                  TabBar(
                                    controller: _tabController,
                                    dividerColor: AppColors.transparent,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    labelStyle: context.textTheme.titleMedium!
                                        .copyWith(
                                          fontSize: AppDims.size_16.sp,
                                          color: AppColors.primary,
                                        ),
                                    unselectedLabelStyle: context
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          fontSize: AppDims.size_16.sp,
                                          color: AppColors.gray500,
                                        ),
                                    tabs: [
                                      Tab(
                                        child: AppText(
                                          // รายละเอียดเงื่อนไข
                                          context.wording.conditionsAndDetails,
                                        ),
                                      ),
                                      Tab(
                                        child: AppText(
                                          // แคมเปญอื่นๆ
                                          context.wording.otherCampaigns,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Tab content
                                  if (_tabController.index == 0)
                                    _buildConditionsTab(
                                      context,
                                      selected,
                                      locale,
                                    )
                                  else
                                    // TabBar
                                    _buildCampaignsTab(
                                      context,
                                      festiveResult.data?.data,
                                      selected,
                                      locale,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<dynamic> _showFestiveHistory(BuildContext context) {
    Future.microtask(_viewmodel.fetchFestiveHistory);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow content to exceed half screen
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      builder: (context) {
        return Container(
          // height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(16.r),
              right: Radius.circular(16.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDims.vericalPadding_16,
              Center(
                child: AppText(
                  // ประวัติ Lucky Scan ทั้งหมด
                  context.wording.luckyScanHistoryTitle,
                  style: context.textTheme.labelLarge!.copyWith(
                    fontSize: AppDims.size_16.sp,
                    color: AppColors.textBare,
                  ),
                ),
              ),
              AppDims.vericalPadding_14,
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _viewmodel.festiveHistoryNotifier,
                  builder: (context, result, child) {
                    if (result.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (result.hasError) {
                      return Center(
                        child: AppText(
                          result.error.toString(),
                        ),
                      );
                    }

                    if (result.isEmpty ||
                        result.data?.data.orEmpty.isEmpty == true) {
                      return Center(
                        child: SizedBox(
                          height: double.infinity,
                          child: Column(
                            spacing: AppDims.size_8.h,
                            children: [
                              Assets.png.brownyError1.image(width: 90.w),
                              AppText(
                                // ไม่พบประวัติ Lucky Scan
                                context.wording.noLuckyScanHistory,
                                style: context.textTheme.labelLarge!.copyWith(
                                  fontSize: AppDims.size_16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final histories = result.data!.data!;
                    return ListView.separated(
                      separatorBuilder: (_, _) => Divider(),
                      padding: EdgeInsets.only(
                        left: AppDims.size_16.w,
                        right: AppDims.size_16.w,
                        bottom: AppDims.size_24.w,
                      ),
                      itemCount: histories.length,
                      itemBuilder: (context, index) {
                        final data = histories[index];
                        final locale = context.languageCode;
                        final isWon = data.isWon;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Assets.svg.icScanFestiveHistory.svg(
                            width: AppDims.size_44.w,
                            height: AppDims.size_44.h,
                          ),
                          title: AppText(
                            data.getTitleDisplay(locale),
                            style: context.textTheme.labelMedium,
                          ),
                          subtitle: AppText(
                            data.getCreateAtDisplay(locale),
                            style: context.textTheme.labelSmall!.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                          trailing: Column(
                            spacing: AppDims.size_4.h,
                            children: [
                              AppText(
                                isWon
                                    // ได้รางวัล
                                    ? context.wording.luckyScanWon
                                    // ไม่ได้รับรางวัล
                                    : context.wording.luckyScanNotWon,
                                style: context.textTheme.labelMedium!.copyWith(
                                  color: isWon
                                      ? AppColors.primary
                                      : AppColors.gray500,
                                ),
                              ),
                              if (isWon)
                                GestureDetector(
                                  onTap: () {
                                    CouponVoucherPage.goToPage(
                                      context,
                                      state: CouponVoucherState.redeeming,
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppDims.size_4.h,
                                      horizontal: AppDims.size_12.w,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32.r),
                                      color: AppColors.ci3,
                                    ),
                                    child: AppText(
                                      // ดูคูปอง
                                      context.wording.viewCoupon,
                                      style: context.textTheme.labelMedium!
                                          .copyWith(
                                            color: AppColors.primary,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConditionsTab(
    BuildContext context,
    FestiveData? selected,
    String locale,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDims.size_4.w,
        right: AppDims.size_16.w,
        // bottom: 32.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered condition list
          Html(
            data: selected?.getMessageDisplay(locale) ?? '',
            style: {
              "body": Style(
                fontSize: FontSize(AppDims.size_15.sp),
                fontFamily: GoogleFonts.prompt().fontFamily,
                padding: HtmlPaddings.zero,
                textAlign: TextAlign.start,
                margin: Margins.all(0),
                fontWeight: FontWeight.w400,
                color: AppColors.gray600,
              ),
            },
          ),

          // SizedBox(height: AppDims.size_16.h),
          // Scan QR button
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
          //   child: ElevatedButton.icon(
          //     onPressed: () async {
          //       if (kDebugMode) {
          //         _onScanResult(
          //           'http://brownypay.com/lucky/draw/3cd789cf-0c35-4006-a5f5-fa9ef09d7e37',
          //         );
          //         return;
          //       }
          //       ScannerPage.goToPage(
          //         context,
          //         process: ScannerProcess.needResult,
          //       ).then((qrData) async {
          //         if (qrData != null && context.mounted) {
          //           _onScanResult(qrData);
          //         }
          //       });
          //     },
          //     iconAlignment: IconAlignment.end,
          //     icon: Assets.svg.icScan2.svg(
          //       colorFilter: ColorFilter.mode(
          //         AppColors.white,
          //         BlendMode.srcIn,
          //       ),
          //     ),
          //     label: AppText(context.wording.scanQrActivity),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildCampaignsTab(
    BuildContext context,
    List<FestiveData>? campaigns,
    FestiveData? selected,
    String locale,
  ) {
    if (campaigns == null || campaigns.isEmpty) {
      return SizedBox(height: 80.h);
    }
    return SafeArea(
      top: false,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
          vertical: AppDims.size_16.h,
        ),
        itemCount: campaigns.length,
        separatorBuilder: (_, _) => AppDims.vericalPadding_14,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _viewmodel.selectFestive(campaigns[i]),
          child: _buildCampaignCard(
            context,
            campaigns[i],
            locale,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(
    BuildContext context,
    FestiveData item,
    String locale,
  ) {
    final thumbnailUrl = item.getThumbnailUrl(locale);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail placeholder — replace with Image.network(item.imageUrl) when API is ready
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDims.size_8.r),
          child: thumbnailUrl.isNotEmpty
              ? Image.network(
                  thumbnailUrl,
                  width: 80.w,
                  height: 80.w,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 80.w,
                  height: 80.w,
                  color: AppColors.gray500,
                ),
        ),
        SizedBox(width: AppDims.size_12.w),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                item.getTitleDisplay(locale),
                style: context.textTheme.labelLarge!.copyWith(
                  fontSize: AppDims.size_16.sp,
                ),
              ),
              SizedBox(height: AppDims.size_4.h),
              Row(
                children: [
                  Assets.luckyScan.icTicket.image(
                    width: AppDims.size_16.w,
                  ),
                  SizedBox(width: AppDims.size_4.w),
                  AppText(
                    // 'เหลือ ${item.remain} สิทธิ์',
                    item.getRemainDisplay(locale),
                    style: context.textTheme.bodyMedium!.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDims.size_2.h),
              Row(
                children: [
                  Assets.luckyScan.icClock2.image(
                    width: AppDims.size_16.w,
                  ),
                  SizedBox(width: AppDims.size_4.w),
                  AppText(
                    // 'หมดเขต ${item.expiredDate}',
                    item.getExpiredDesisplay(locale),
                    style: context.textTheme.bodyMedium!.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onScanResult(
    String qrData, [
    bool fromAuto = false,
  ]) async {
    AppOverlays.showLoading(context);
    final result = await _viewmodel.postLuckyDraw(
      qrCode: qrData,
    );

    if (!mounted) return;
    AppOverlays.hideLoading();

    if (result.hasError) {
      if (result.error is Unprocessable) {
        AppOverlays.showBrownyDialog(
          context,
          title: ContentLocalizeData(
            en: 'Invalid QR Code',
            zh: '无效的二维码',
            th: 'QR Code ไม่ถูกต้อง',
          ).getTextByLocale(context.languageCode),
          message: ContentLocalizeData(
            en: 'Please scan the “Lucky Scan” QR Code inside Browny store',
            zh: '请扫描Browny店内的”Lucky Scan”二维码',
            th: 'กรุณาสแกนที่ QR Code “Lucky Scan” ภายในร้าน Browny',
          ).getTextByLocale(context.languageCode),
        );
        return;
      }

      AppOverlays.showBrownyErrorDialog(
        context,
        title: context.wording.errorOccurred,
        error: result.error,
      );
      return;
    }

    if (result.isEmpty) {
      AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        message: context.wording.errorUi,
      );
      return;
    }

    _showLucyScanResult(
      context,
      result.data!,
      fromAuto,
    );
  }

  /// DONG
  ///
  /// แสดงผลการ Scan festive
  Future<void> _showLucyScanResult(
    BuildContext context,
    LuckyDrawResponse type, [
    bool fromAuto = false,
  ]) async {
    if (type.isScannedToday) {
      AppOverlays.showBrownyDialog(
        context,
        // คุณแสกนกิจกรรมนี้ไปแล้ว
        title: ContentLocalizeData(
          en: 'You have already scanned this activity',
          zh: '您已扫描过此活动',
          th: 'คุณแสกนกิจกรรมนี้ไปแล้ว',
        ).getTextByLocale(context.languageCode),
        // รอเล่นกิจกรรมในวันถัดไปนะ
        message: ContentLocalizeData(
          en: 'Please come back and play again tomorrow',
          zh: '请明天再来参与活动吧',
          th: 'รอเล่นกิจกรรมในวันถัดไปนะ',
        ).getTextByLocale(context.languageCode),
        onConfirm: () {
          if (fromAuto && context.canPop()) {
            context.safePop();
          }
        },
      );
      return;
    }

    Gradient gradientType = AppColors.popupFestiveFailedGradient;
    if (type.isWon) {
      gradientType = AppColors.popupFestiveWonGradient;
    } else if (type.isLose) {
      gradientType = AppColors.popupFestiveLoseGradient;
    }

    String bannerDisplay = type.getBannerDisplay(context.languageCode);
    if (bannerDisplay.isEmpty) {
      if (type.isWon) {
        bannerDisplay = Assets.luckyScan.brownyWon.path;
      } else if (type.isLose) {
        bannerDisplay = Assets.luckyScan.brownyLose.path;
      } else {
        bannerDisplay = Assets.luckyScan.brownyFailed.path;
      }
    }
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
                          gradient: gradientType,
                          // gradient: AppColors.popupFestiveWonGradient,
                          // gradient: AppColors.popupFestiveLoseGradient,
                          // gradient: AppColors.popupFestiveFailedGradient,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // AppDims.vericalPadding_16,
                              SizedBox(
                                height: 186.h,
                              ),

                              // AppDims.vericalPadding_16,
                              Padding(
                                padding: EdgeInsets.all(AppDims.size_16),
                                child: Column(
                                  children: [
                                    AppText(
                                      type.getTitleDisplay(
                                        context.languageCode,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: context.textTheme.headlineLarge!
                                          .copyWith(
                                            fontSize: AppDims.size_24.sp,
                                            color: AppColors.primary,
                                          ),
                                    ),
                                    // AppDims.vericalPadding_10,

                                    // AppText(
                                    //   type.getMessageDisplay(
                                    //     context.languageCode,
                                    //   ),
                                    //   textAlign: TextAlign.start,
                                    //   style: context.textTheme.labelMedium!
                                    //       .copyWith(
                                    //         color: AppColors.gray600,
                                    //       ),
                                    // ),
                                    Html(
                                      data: type.getMessageDisplay(
                                        context.languageCode,
                                      ),
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
                                        // ชนะ lucky draw
                                        // และมาจาก scan หน้า home
                                        // จะ popup กลับหน้าหลัก
                                        if (fromAuto && context.canPop()) {
                                          context.safePop();
                                        }
                                      },
                                      child: AppText(
                                        context.wording.acknowledge,
                                      ),
                                    ),
                                    AppDims.vericalPadding_4,
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
                  top: -45.w,
                  child: Image.network(
                    type.getBannerDisplay(context.languageCode),
                    fit: BoxFit.cover,
                    width: 250.w,
                    errorBuilder: (_, _, _) => Image.asset(
                      bannerDisplay,
                      width: 250.w,
                    ),
                  ),
                  // child: Assets.png.brownyPromotion.image(width: 250.w),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
