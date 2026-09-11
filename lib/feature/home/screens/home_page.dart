import 'dart:async';
import 'dart:ui';

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/widgets/invit_bottom_sheet_dialog.dart';
import 'package:browny_applications_new/core/widgets/popup_dialog.dart';
import 'package:browny_applications_new/feature/articles/models/article_detail_model.dart';
import 'package:browny_applications_new/feature/coin/screens/coin_page.dart';
import 'package:browny_applications_new/feature/contacts/models/contact_model.dart';
import 'package:browny_applications_new/feature/contacts/screens/contact_page.dart';
import 'package:browny_applications_new/feature/home/models/banner_model.dart';
import 'package:browny_applications_new/feature/home/models/customer_services_working_model.dart';
import 'package:browny_applications_new/feature/home/screens/app_notifications_page.dart';
// ignore: unused_import for debug mode
import 'package:browny_applications_new/feature/lucky_scan/screens/lucky_mockup.dart';
import 'package:browny_applications_new/feature/lucky_scan/screens/lucky_scan_page.dart';
import 'package:browny_applications_new/feature/map/screens/map_page.dart';
import 'package:browny_applications_new/feature/profile/screen/my_profile_and_preferences_page.dart';
import 'package:browny_applications_new/feature/scaner/screen/scanner_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/history_transaction_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/machines/machine_status_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/machines/machine_transaction_page_2.dart';
import 'package:browny_applications_new/feature/wallet/screen/wallet_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/authentication_viewmodel.dart';
import 'package:browny_applications_new/feature/home/repository/home_repo.dart';
import 'package:browny_applications_new/feature/home/viewmodel/home_page_viewmodel.dart';
import 'package:browny_applications_new/feature/authentication/screen/authentication_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final pagePath = '/home_page';
  static final pageName = 'HomePage';

  /// util function route to pageName
  static Future<T?> goToPage<T>(BuildContext context) async {
    return await context.pushNamed(HomePage.pageName);
  }

  static void goReplacementPage(
    BuildContext context,
  ) {
    context.pushReplacementNamed(
      HomePage.pageName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageViewmodel(
        context: context,
        repo: HomeRepo(),
      ),
      child: HomePageWidget(),
    );
  }
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({
    super.key,
  });

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with WidgetsBindingObserver {
  HomePageViewmodel get _viewmodel => context.read<HomePageViewmodel>();
  late final GoRouterDelegate _routerDelegate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routerDelegate = GoRouter.of(context).routerDelegate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewmodel.attachContext(context);
      _routerDelegate.addListener(_onRouteChanged);
      _initialFetch();
    });
  }

  Future<void> _initialFetch() async {
    // ดึง Banner
    await _viewmodel.fetchBannersHighlight();
    // ดึงเครื่องที่อาจจะกำลังทำงานอยู่ ของลูกค้ารายนี้
    await _viewmodel.fetchWorkingMachines();

    if (mounted) {
      // ดึงข้อมูลแสดง Popup เพื่อนเชิญเพื่อน ของวันนี้
      final showInvitFriendToday = await _viewmodel
          .fetchPopupInivitFriendForToday();
      if (mounted && showInvitFriendToday.data!) {
        await InvitBottomSheetDialog.showInvitBottomSheet(
          context,
          _viewmodel,
        );
        // flag ว่าวันนี้ขึ้น Popup เพื่อนเชิญเพื่อน ของวันนี้
        _viewmodel.dismissInvitFriendForToday();
      }

      if (!mounted) return;
      // ดึง Popup โฆษณา
      await _fetchPopups(context);
      // fetch count notification
      await _viewmodel.fetchCustomerNotifications();
    }
  }

  Future<void> _fetchPopups(BuildContext context) async {
    final popupResult = await _viewmodel.fetchPopups();

    if (popupResult.isSuccess && popupResult.data.orEmpty.isNotEmpty) {
      if (!context.mounted) return;
      await PopupDialog.show(
        context: context,
        popups: popupResult.data ?? [],
        locale: context.languageCode,
        onDismiss: (dismissPopupForToday) {
          if (dismissPopupForToday) {
            _viewmodel.dismissPopupsForToday(popupResult.data ?? []);
          }
        },
        onPopupImagePressed: (popup) {
          // TODO: Handle popup action based on programAction and autoClickTarget
          debugPrint('Popup pressed: ${popup.name}');
          debugPrint('Program action: ${popup.programAction}');
          debugPrint('Auto click target: ${popup.autoClickTarget}');
        },
      );
    }
  }

  void _onRouteChanged() {
    final location = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.path;
    if (location == HomePage.pagePath && mounted) {
      _viewmodel.fetchWorkingMachines();
    }
  }

  @override
  void dispose() {
    _routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state case AppLifecycleState.resumed) {
      debugPrint('AppLifecycleState.resumed');
      // ถ้ามีการพับแอพหรือไปแอพอื่นกลับมา จะทำการ fetch ใหม่
      if (mounted) {
        Future.microtask(_viewmodel.fetchWorkingMachines);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: 10.h,
      backgroundColor: AppColors.background,
      onRefresh: () async {
        await _viewmodel.refresh();
      },
      child: Scaffold(
        // extendBody: true,
        body: CustomScrollView(
          slivers: [
            // build AppBar
            _buildMyAppBar(),

            // ส่วนของ TP Wallet, Browny Coin
            SliverToBoxAdapter(
              child: _buildMyWalletAndCoinZone(),
            ),

            // _mySliverBox(
            //   child: _buildMyWalletAndCoinZone(),
            // ),

            // icon shortcut
            SliverToBoxAdapter(
              child: _buildRishIcons(context),
            ),

            // เก็บ Coupon
            SliverToBoxAdapter(
              child: _buildCollectCoupon(context),
            ),

            // สถานะบริการ ที่กำลังใช้งาน
            _buildServicesWorking(context),

            // สถานะบริการ
            SliverToBoxAdapter(
              child: _buildServices(context),
            ),
            SliverToBoxAdapter(
              child: AppDims.vericalPadding_24,
            ),
          ],
        ),
        bottomNavigationBar: BrownyBottomNav(
          currentIndex: 0,
          onCenterTap: () async {
            // Default ไปหน้า Scan
            await ScannerPage.goToPage(
              context,
              initialIndex: 0,
            );
            // if (mounted) {
            //   await _viewmodel.fetchWorkingMachines();
            // }
          },
          onTap: (context, index) async {
            debugPrint(index.toString());
            if (index == 1) {
              // context.pushNamed(CouponVoucherPage.pageName);
              await CouponVoucherPage.goToPage(
                context,
              );
              // if (mounted) {
              //   await _viewmodel.fetchWorkingMachines();
              // }
              return;
            }

            if (index == 2) {
              await context.pushNamed(MapPage.pageName);
              // if (mounted) {
              //   await _viewmodel.fetchWorkingMachines();
              // }
              return;
            }
          },
        ),
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDims.size_16.w,
        right: AppDims.size_16.w,
        // top: AppDims.size_8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: ElevatedButton.icon(
              onPressed: null,
              icon: Assets.svg.icPawRoundedGreen.svg(),
              label: Column(
                children: [
                  AppText(
                    // บริการ
                    context.wording.services,
                    style: _defaultTextTitleStyle,
                  ),
                ],
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
          ),
          SizedBox(
            height: AppDims.size_106.h,
            child: Builder(
              builder: (context) {
                List<AssetGenImage> services = [];
                switch (context.languageCode) {
                  case 'zh':
                    {
                      services.addAll([
                        Assets.services.aWasherZh,
                        Assets.services.bDryerZh,
                      ]);
                      break;
                    }
                  case 'en':
                    {
                      services.addAll([
                        Assets.services.aWasherEn,
                        Assets.services.bDryerEn,
                      ]);
                      break;
                    }
                  default:
                    {
                      services.addAll([
                        Assets.services.aWasher,
                        Assets.services.bDryer,
                      ]);
                      break;
                    }
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () async {
                      if (kDebugMode) {
                        final data = Uri.parse(
                          'http://brownypay.com/wash/dry/16',
                          // 'http://brownypay.com/wash/dry/1379',
                        );
                        if (data.pathSegments.isNotEmpty) {
                          await MachineTransactionPage2.goToPage(
                            context,
                            machineId: data.pathSegments.last,
                          );
                          // if (mounted) {
                          //   await _viewmodel.fetchWorkingMachines();
                          // }
                        }

                        // MachineStatusPage.goToPage(context, machineId: '13');
                        return;
                      }

                      // Default ไปหน้า Scan
                      await ScannerPage.goToPage(
                        context,
                        initialIndex: 0,
                      );
                    },
                    child: services[index].image(
                      width: AppDims.size_109.w,
                      height: AppDims.size_106.h,
                    ),
                  ),
                  separatorBuilder: (context, index) =>
                      AppDims.horizonPadding_8,
                  itemCount: 2,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _defaultTextTitleStyle => context.textTheme.labelLarge!;
  // context.textTheme.labelLarge!.copyWith(
  //   fontSize: AppDims.size_16.sp,
  // );
  Padding _buildCollectCoupon(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDims.size_16.w,
        right: AppDims.size_16.w,
        // top: AppDims.size_8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: ElevatedButton.icon(
              onPressed: null,
              icon: Assets.svg.icCouponRoundGreen.svg(),
              label: Column(
                children: [
                  AppText(
                    // เก็บคูปอง
                    context.wording.collectCoupon,
                    style: _defaultTextTitleStyle,
                  ),
                ],
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
          ),
          GestureDetector(
            onTap: () {
              // context.pushNamed(CouponVoucherPage.pageName);
              CouponVoucherPage.goToPage(
                context,
              );
              // _showInvitBottomSheet();
            },
            // banner เก็บคูปอง
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.1,
                  child: Assets.png.cardCouponEvoucher.image(
                    color: AppColors.black,
                  ),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 0.1,
                      sigmaY: 0.1,
                    ),
                    child: Assets.png.cardCouponEvoucher.image(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildServicesWorking(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          // top: AppDims.size_8.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              child: ElevatedButton.icon(
                onPressed: null,
                icon: Assets.svg.icRefreshRoundGreen.svg(),
                label: Column(
                  children: [
                    AppText(
                      // สถานะการทำงาน
                      context.wording.usageStatus,
                      style: _defaultTextTitleStyle,
                    ),
                  ],
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
            ),
            Align(
              alignment: Alignment.center,
              child: AppToggleWidget(
                data: [
                  // ทั้งหมด
                  AppToggleData(lable: context.wording.all, value: 0),
                  // ซักอบ
                  AppToggleData(lable: context.wording.washDry, value: 1),
                  // การสั่งซื้อ
                  AppToggleData(
                    lable: context.wording.orderPlacement,
                    value: 2,
                    enable: false,
                  ),
                ],
                onChange: (index) {},
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: ValueListenableBuilder(
                valueListenable: _viewmodel.workingMachinesNotifier,
                builder: (context, result, child) {
                  if (result.isLoading) {
                    return CircularProgressIndicator();
                  }

                  if (result.isEmpty || result.hasError) {
                    // เกิด Error
                    return Padding(
                      padding: EdgeInsets.only(top: AppDims.size_12.h),
                      child: Column(
                        children: [
                          Assets.png.brownyError1.image(
                            width: AppDims.size_60.w,
                          ),
                          AppDims.vericalPadding_8,

                          Align(
                            alignment: Alignment.center,
                            child: AppText(context.wording.errorUi),
                          ),
                        ],
                      ),
                    );
                  }

                  if (result.data!.data.orEmpty.isEmpty) {
                    // รักใครให้ซักผ้า
                    return Padding(
                      padding: EdgeInsets.only(top: AppDims.size_12.h),
                      child: Column(
                        children: [
                          Assets.png.brownyWashy.image(
                            width: AppDims.size_90.w,
                          ),
                          AppDims.vericalPadding_8,

                          Align(
                            alignment: Alignment.center,
                            // #รักใครให้ซักผ้า
                            child: AppText(context.wording.loveAnyoneDoLaundry),
                          ),
                        ],
                      ),
                    );
                  }

                  final workingList = result.data!.data.orEmpty;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        workingList.length,
                        (index) =>
                            // Single Item Card Service ที่กำลังทำงาน
                            CustomerServicesWorkingWidget(
                              data:
                                  CustomerServicesWorkingModel.fromWorkingMachineResponse(
                                    workingList[index],
                                  ),
                              onTap: () {
                                MachineStatusPage.goToPage(
                                  context,
                                  machineId: workingList[index].id!.toString(),
                                );
                              },
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // AppDims.vericalPadding_8,
          ],
        ),
      ),
    );
  }

  Widget _buildRishIcons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: EdgeInsets.only(
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          top: AppDims.size_16.h,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              FutureBuilder<UiResult<BrownyLiveResponse>>(
                future: _viewmodel.fetchBrownyLive(),
                builder: (context, snapshot) {
                  final hasData =
                      snapshot.hasData && snapshot.requireData.isSuccess;
                  if (!hasData || snapshot.requireData.data!.enabled == false) {
                    return SizedBox();
                  }
                  return GestureDetector(
                    onTap: hasData
                        ? () {
                            LaunchHelper.openUrlInBrowser(
                              snapshot.requireData.data!.link!,
                            );
                          }
                        : null,
                    child: Container(
                      padding: EdgeInsets.only(
                        left: AppDims.size_4.w,
                        right: AppDims.size_18.w,
                      ),
                      child: Column(
                        children: [
                          Assets.iconShortcut.iscBrownyLive.image(
                            width: AppDims.size_64.w,
                            height: AppDims.size_32.h,
                          ),
                          AppText(
                            'Browny\nLive',
                            textAlign: TextAlign.center,
                            style: context.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              GestureDetector(
                onTap: () => CouponVoucherPage.goToPage(
                  context,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDims.size_2.w,
                    // vertical: AppDims.size_8.h,
                  ),
                  child: _buldIconShortCut(
                    icon: Assets.iconShortcut.iscCoupon,
                    title: context.wording.rewards,
                    // children: [
                    //   Assets.iconShortcut.iscCoupon.image(
                    //     width: AppDims.size_74.w,
                    //     height: AppDims.size_42.h,
                    //   ),
                    //   AppText(
                    //     // คูปอง
                    //     context.wording.rewards,
                    //     textAlign: TextAlign.center,
                    //     style: context.textTheme.titleSmall,
                    //   ),
                    // ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDims.size_2.w,
                  // vertical: AppDims.size_8.h,
                ),
                child: GestureDetector(
                  onTap: () => onBrownyClubClick(highlight: null),
                  child: _buldIconShortCut(
                    icon: Assets.iconShortcut.iscBrownyClub,
                    title: 'Browny\nClub',
                    //  Column(
                    // children: [
                    //   Assets.iconShortcut.iscBrownyClub.image(
                    //     width: AppDims.size_74.w,
                    //     height: AppDims.size_42.h,
                    //   ),
                    //   AppText(
                    //     'Browny\nClub',
                    //     textAlign: TextAlign.center,
                    //     style: context.textTheme.titleSmall,
                    //   ),
                    // ],
                  ),
                ),
              ),

              Container(
                // foregroundDecoration: BoxDecoration(
                //   color: Colors.grey,
                //   backgroundBlendMode: BlendMode.saturation,
                // ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppDims.size_2.w,
                  // vertical: AppDims.size_8.h,
                ),
                child: _buldIconShortCut(
                  icon: Assets.iconShortcut.iscBrownyShop,
                  title: 'Browny\nShop',
                  // children: [
                  //   Assets.iconShortcut.iscBrownyShop.image(
                  //     width: AppDims.size_74.w,
                  //     height: AppDims.size_42.h,
                  //   ),
                  //   AppText(
                  //     'Browny\nShop',
                  //     textAlign: TextAlign.center,
                  //     style: context.textTheme.titleSmall,
                  //   ),
                  // ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  // if (kDebugMode) {
                  //   LuckyMockupPage.goToPage(context);
                  //   return;
                  // }
                  LuckyScanPage.goToPage(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDims.size_2.w,
                    // vertical: AppDims.size_8.h,
                  ),
                  child: _buldIconShortCut(
                    icon: Assets.iconShortcut.iscLuckyScan,
                    title: 'Lucky\nScan',
                    // children: [
                    //   Assets.iconShortcut.iscLuckyScan.image(
                    //     width: AppDims.size_74.w,
                    //     height: AppDims.size_42.h,
                    //   ),
                    //   AppText(
                    //     'Lucky\nScan',
                    //     textAlign: TextAlign.center,
                    //     style: context.textTheme.titleSmall,
                    //   ),
                    // ],
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  HistoryTransactionPage.goToPage(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDims.size_2.w,
                    // vertical: AppDims.size_8.h,
                  ),
                  child: _buldIconShortCut(
                    icon: Assets.iconShortcut.iscTransactionHistory,
                    // ประวัติ\nการใช้งาน
                    title: context.wording.usageHistory,
                    // children: [
                    //   Assets.iconShortcut.iscTransactionHistory.image(
                    //     width: AppDims.size_74.w,
                    //     height: AppDims.size_42.h,
                    //   ),
                    //   AppText(
                    //     // ประวัติ\nการใช้งาน
                    //     context.wording.usageHistory,
                    //     textAlign: TextAlign.center,
                    //     style: context.textTheme.titleSmall,
                    //   ),
                    // ],
                  ),
                ),
              ),

              GestureDetector(
                onTap: () => ContactPage.goToPage(
                  context,
                  ContactProvider.contacts,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDims.size_2.w,
                    // vertical: AppDims.size_8.h,
                  ),
                  child: _buldIconShortCut(
                    icon: Assets.iconShortcut.iscContact,
                    // ติดต่อ\nสอบถาม
                    title: context.wording.contactInquiry,
                    // children: [
                    //   Assets.iconShortcut.iscContact.image(
                    //     width: AppDims.size_74.w,
                    //     height: AppDims.size_42.h,
                    //   ),
                    //   AppText(
                    //     // ติดต่อ\nสอบถาม
                    //     context.wording.contactInquiry,
                    //     textAlign: TextAlign.center,
                    //     style: context.textTheme.titleSmall,
                    //   ),
                    // ],
                  ),
                ),
              ),

              GestureDetector(
                onTap: () => ScannerPage.goToPage(
                  context,
                  // เปิดหน้า QRCode
                  initialIndex: 1,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDims.size_2.w,
                    // vertical: AppDims.size_8.h,
                  ),
                  child: _buldIconShortCut(
                    icon: Assets.iconShortcut.iscBrownyId,
                    title: 'Browny ID',
                    // children: [
                    //   Assets.iconShortcut.iscBrownyId.image(
                    //     width: AppDims.size_74.w,
                    //     height: AppDims.size_42.h,
                    //   ),
                    //   AppText(
                    //     'Browny ID',
                    //     textAlign: TextAlign.center,
                    //     style: context.textTheme.titleSmall,
                    //   ),
                    // ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buldIconShortCut({
    required AssetGenImage icon,
    required String title,
  }) {
    return Column(
      children: [
        icon.image(
          width: AppDims.size_74.w,
          height: AppDims.size_42.h,
        ),
        AppText(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleSmall,
        ),
      ],
    );
  }

  void onBrownyClubClick({
    required BannerHighLightModel? highlight,
  }) {
    _viewmodel.onBannerHighLightSelected(
      context,
      highlight: highlight != null
          ? ArticleDetailModel.fromBannerHighlightData(highlight)
          : null,
    );
    // context.pushNamed(
    //   ArticlesPage.pageName,
    //   extra: _viewmodel,
    // );
  }

  Widget _buildMyAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      surfaceTintColor: AppColors.transparent,
      stretch: true,
      expandedHeight: (MediaQuery.of(context).size.width < 600) ? 150.h : 200.h,
      elevation: 0.0,
      flexibleSpace: FlexibleSpaceBar(
        // FlexibleSpaceBar: ส่วนที่ยืด-หดได้ของ AppBar=
        background: ValueListenableBuilder(
          valueListenable: _viewmodel.bannerHighlightNotifier,
          builder: (context, result, child) {
            if (!result.isSuccess) {
              return Container(
                color: AppColors.white,
              );
            }

            return CarouselSlider.builder(
              itemCount: result.requireData.length,
              itemBuilder: (context, index, realIndex) {
                final imageUrl = result.requireData[index].imageDisplay(
                  context,
                );
                return GestureDetector(
                  onTap: () {
                    final data = result.requireData[index];
                    final type = data.type;
                    if (type == 'article') {
                      onBrownyClubClick(highlight: result.requireData[index]);
                    } else if (type == 'external_link') {
                      LaunchHelper.openUrlInBrowser(data.target.orEmpty);
                    }
                  },
                  child: CachedNetworkImage(
                    width: MediaQuery.of(context).size.width,
                    // ใช้ ValueKey เพื่อให้ Flutter รู้ว่า widget เดิมยังคงเหมือนเดิม
                    // ไม่ต้อง rebuild ใหม่ตอน slide carousel
                    key: ValueKey(imageUrl),
                    cacheKey: imageUrl,
                    imageUrl: imageUrl,
                    // fit: BoxFit.cover,
                    fit: (MediaQuery.of(context).size.width < 600)
                        ? BoxFit.fitWidth
                        : BoxFit.cover,
                    // ตั้งเป็น Duration.zero เพื่อปิด fade animation
                    // แสดงรูปจาก cache ได้ทันทีโดยไม่มี delay
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    // Cache รูปใน memory (RAM) โดยคูณด้วย devicePixelRatio
                    // เพื่อให้รูปคมชัดบนหน้าจอความละเอียดสูง
                    memCacheWidth:
                        (MediaQuery.of(context).size.width *
                                MediaQuery.of(context).devicePixelRatio)
                            .round(),
                    memCacheHeight:
                        (200.h * MediaQuery.of(context).devicePixelRatio)
                            .round(),
                    // Cache รูปใน disk (storage) เพื่อไม่ต้องโหลดซ้ำตอนเปิด app ใหม่
                    maxWidthDiskCache: (MediaQuery.of(context).size.width * 2)
                        .round(),
                    maxHeightDiskCache: (200.h * 2).round(),
                    // ใช้ placeholder แทน progressIndicatorBuilder
                    // เพื่อแสดง loading เฉพาะตอนโหลดครั้งแรก
                    // ไม่แสดงซ้ำเมื่อ slide กลับมาที่รูปเดิม
                    placeholder: (context, url) => Container(
                      color: AppColors.ci3,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.ci3,
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                initialPage: 0,
                enlargeCenterPage: true,
                enableInfiniteScroll: result.requireData.length > 1,
                // enableInfiniteScroll: false,
                autoPlay: true,
                viewportFraction: 1,
                aspectRatio: 1,
                // onPageChanged: (index, reason) {
                //   _viewmodel.onBannerSliding();
                // },
              ),
            );
          },
        ),
        // background: Image.network(
        //   'https://dev.abgroup.co.th/storage/uploads/app_images/store_1757391567.jpg',
        //   fit: BoxFit.cover,
        // ),
        stretchModes: [
          StretchMode.blurBackground,
        ],
        expandedTitleScale: 6,
        title: AppContainerRadius(
          height: AppDims.size_2.h,
        ),
        // collapseMode: CollapseMode.none,
        titlePadding: EdgeInsets.all(0.0),
      ),
      actionsPadding: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
      ),
      actions: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.background,
              child: IconButton(
                onPressed: () async {
                  AppNotificationsPage.goToPage(context);
                },
                icon: ValueListenableBuilder(
                  valueListenable:
                      _viewmodel.customerNotificationsCountNotifier,
                  builder: (context, result, _) {
                    final int count;
                    if (result.isSuccess) {
                      count = result.data ?? 0;
                    } else {
                      count = 0;
                    }
                    return Badge(
                      alignment: AlignmentGeometry.topRight,
                      backgroundColor: AppColors.error,
                      smallSize: count > 0 ? 7.r : 0,
                      child: Assets.svg.icNotification.svg(
                        // เปลี่ยนสี svg
                        colorFilter: ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            AppDims.horizonPadding_10,
            Consumer<CustomerProvider>(
              builder: (context, customer, _) {
                return CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: IconButton(
                    onPressed: () => context.pushNamed(
                      MyProfileAndPreferencesPage.pageName,
                    ),
                    icon: customer.current.image.orEmpty.isEmpty
                        // ถ้าไม่มีรูป Profile ใช้รูป Default
                        ? Assets.svg.icPerson.svg(
                            // เปลี่ยนสี svg
                            colorFilter: ColorFilter.mode(
                              AppColors.primary,
                              BlendMode.srcIn,
                            ),
                          )
                        // มีรูป Profile ให้ไปโหลดมา
                        : Image.network(
                            customer.current.image!,
                            errorBuilder: (context, error, stackTrace) =>
                                Assets.svg.icPerson.svg(
                                  // เปลี่ยนสี svg
                                  colorFilter: ColorFilter.mode(
                                    AppColors.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyWalletAndCoinZone() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          bool isGuest = provider.current.isGuest;
          EdgeInsets? margin = isGuest
              ? null
              : EdgeInsets.only(top: AppDims.size_22.h);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppDims.horizonPadding_16,

              // TP+ Wallet Container
              Column(
                children: [
                  if (!isGuest) AppDims.vericalPadding_20,
                  Container(
                    // height: 84.h,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDims.size_12.w,
                      vertical: AppDims.size_16.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        width: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                    child: Row(
                      children: [
                        // AppDims.horizonPadding_12,
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Assets.svg.icTpWallet.svg(),
                            ),
                            // Widget หลอกเพื่อให้ได้ระดับของ Widget ซ้ายขวาเท่ากัน
                            Text(
                              '',
                              style: AppTextNumberStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        AppDims.horizonPadding_12,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                AppText(
                                  'TP+ Wallet',
                                  style: context.textTheme.titleSmall!.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                AppDims.horizonPadding_16,

                                // สร้าง button เข้าสู่ระบบ หรือ TP+ Wallet
                                _buildButtonLoginOrTopUp(isGuest, provider),
                              ],
                            ),
                            Selector<CustomerProvider, String>(
                              selector: (context, provider) =>
                                  provider.current.creditBalance ?? '0.00',
                              builder: (context, value, child) => AppText(
                                formatCurrency(string: value, leadingSign: '฿'),
                                style: context.textTheme.headlineSmall!
                                    .copyWith(
                                      fontSize: AppDims.size_16.sp,
                                    ),
                              ),
                            ),

                            AppDims.vericalPadding_2,
                          ],
                        ),
                        // AppDims.horizonPadding_12,
                      ],
                    ),
                  ),
                ],
              ),
              AppDims.horizonPadding_9,

              // Coin Container
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Text เก็บได้ทุกวัน และ Icon browny
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildDogAndBadgeGroup(isGuest),
                  ),

                  // Card แสดง Coin
                  InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppColors.ctaPrimaryClicked.withValues(
                          alpha: 0.1,
                        );
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return AppColors.ctaPrimaryClicked.withValues(
                          alpha: 0.2,
                        );
                      }
                      return null;
                    }),
                    onTap: () {
                      context.pushNamed(CoinPage.pageName);
                    },
                    child: Container(
                      margin: margin,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDims.size_12.w,
                        vertical: AppDims.size_16.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          width: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Coin
                              Image.asset(
                                Assets.png.brownyCoin.path,
                                width: AppDims.size_20.w,
                                height: AppDims.size_20.h,
                              ),
                              AppDims.horizonPadding_8,
                              AppText(
                                'Browny Coin',
                                style: context.textTheme.titleSmall!.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                          Selector<CustomerProvider, String>(
                            selector: (context, provider) =>
                                provider.current.brownyCoin ?? '0.00',
                            builder: (context, value, child) => AppText(
                              formatCurrency(
                                string: value,
                                trailingSign: ' ${context.wording.coin}',
                              ),
                              style: context.textTheme.titleSmall!.copyWith(
                                fontSize: AppDims.size_16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AppDims.horizonPadding_9,

              // Coupon
              Column(
                children: [
                  if (!isGuest) AppDims.vericalPadding_20,
                  InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppColors.ctaPrimaryClicked.withValues(
                          alpha: 0.1,
                        );
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return AppColors.ctaPrimaryClicked.withValues(
                          alpha: 0.2,
                        );
                      }
                      return null;
                    }),
                    onTap: () {
                      // context.pushNamed(CouponVoucherPage.pageName);
                      CouponVoucherPage.goToPage(
                        context,
                      );
                    },
                    child: Container(
                      // height: 84.h,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDims.size_12.w,
                        vertical: AppDims.size_16.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          width: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Coin
                              Assets.svg.icTicketFilled.svg(
                                width: AppDims.size_20.w,
                                height: AppDims.size_20.h,
                              ),
                              AppDims.horizonPadding_8,
                              AppText(
                                // คูปอง
                                context.wording.rewards,
                                style: context.textTheme.titleSmall!.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                          Selector<CustomerProvider, String>(
                            selector: (context, provider) =>
                                provider.current.totalCoupons?.toString() ??
                                '0',
                            builder: (context, value, child) => AppText(
                              formatCurrency(
                                string: value,
                                decimal: false,
                                trailingSign: ContentLocalizeData(
                                  en: ' Rewards',
                                  zh: ' 张',
                                  th: ' ใบ',
                                ).getByLocaleCode(context.languageCode),
                              ),
                              style: context.textTheme.titleSmall!.copyWith(
                                fontSize: AppDims.size_16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              AppDims.horizonPadding_16,
            ],
          );
        },
      ),
    );
  }

  Widget _buildButtonLoginOrTopUp(bool isGuest, CustomerProvider provider) {
    return Builder(
      builder: (context) {
        final icon = isGuest
            ? Assets.svg.icLogin.svg(
                width: AppDims.size_12.w,
                height: AppDims.size_12.h,
              )
            : Assets.svg.icPlus.svg(
                width: AppDims.size_12.w,
                height: AppDims.size_12.h,
              );

        final onPressed = provider.current.isGuest
            ? () => context.pushNamed(
                AuthenticationPage.pageName,
                extra: {
                  AuthenProcess: AuthenProcess.login,
                },
              )
            : () {
                context.pushNamed(
                  WalletPage.pageName,
                );
              };

        final label = provider.current.isGuest
            // เข้าสู่ระบบ
            ? context.wording.login
            // เติมเงิน
            : context.wording.topup;

        return ElevatedButton(
          onPressed: onPressed,
          style: context.appTheme.elevatedButtonTheme.style!.copyWith(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDims.size_4.r,
                ),
              ),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: AppDims.size_10.w,
              ),
            ),
            minimumSize: WidgetStatePropertyAll(
              Size(70.w, 20.h),
            ), // Set this
            textStyle: WidgetStatePropertyAll(
              context.textTheme.bodySmall!.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
          child: Row(
            spacing: AppDims.size_4.w,
            children: [
              AppText(
                label,
                style: context.textTheme.titleSmall!.copyWith(
                  color: AppColors.white,
                ),
              ),
              icon,
            ],
          ),
        );
      },
    );
  }

  Widget _buildDogAndBadgeGroup(bool isGuest) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ก้อนที่ 1 (ของกลุ่มย่อย): ป้ายแดง
        Container(
          padding: EdgeInsets.only(
            left: 8,
            top: 2,
            right: 8,
            bottom: 20,
          ),
          margin: EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            // ถ้าเป็น Guest ไม่แสดง
            color: isGuest ? null : AppColors.error,
          ),
          // ถ้าเป็น Guest ไม่แสดง
          child: isGuest
              ? null
              : AppText(
                  // เก็บเพิ่มได้ทุกวัน
                  context.wording.collectMoreDaily,
                  style: context.textTheme.labelSmall!.copyWith(
                    color: AppColors.white,
                  ),
                ),
        ),

        // ก้อนที่ 2 (ของกลุ่มย่อย): รูปตุ๊กตาหมา
        // วางไว้ที่พิกัด 0,0 ของกลุ่มย่อยนี้ สุนัขจะทับป้ายแดงในองศาเดิมเสมอ
        Positioned(
          left: -27.w,
          top: -1,
          child: isGuest
              ? SizedBox()
              : Assets.svg.icBrownySpeaker.svg(width: 35.w),
        ),
      ],
    );
  }
}

/// Widget แสดงสถานะการทำงานของเครื่องซักอบ
class CustomerServicesWorkingWidget extends StatefulWidget {
  const CustomerServicesWorkingWidget({
    super.key,
    required this.data,
    required this.onTap,
  });

  final CustomerServicesWorkingModel data;
  final VoidCallback onTap;

  @override
  State<CustomerServicesWorkingWidget> createState() =>
      _CustomerServicesWorkingWidgetState();
}

class _CustomerServicesWorkingWidgetState
    extends State<CustomerServicesWorkingWidget> {
  late final ValueNotifier<Duration> _countDownNotifier;
  late final ValueNotifier<bool> _finishedNotifier;

  Timer? _statusUpdateTimer;

  @override
  void dispose() {
    _countDownNotifier.dispose();
    _finishedNotifier.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _countDownNotifier = ValueNotifier(
      widget.data.remainingTimeDuration,
    );
    _finishedNotifier = ValueNotifier(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _statusUpdateTimer?.cancel();

      _statusUpdateTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          final currentDuration = _countDownNotifier.value;
          if (currentDuration.inSeconds > 0) {
            // อัพเดทเฉพาะ ValueNotifier ไม่ทำให้ rebuild ทั้ง widget
            _countDownNotifier.value = Duration(
              seconds: currentDuration.inSeconds - 1,
            );
          } else {
            _finishedNotifier.value = true;
            // หมดเวลาแล้ว หยุด timer
            timer.cancel();
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppDims.size_8.h,
      ),
      padding: EdgeInsets.all(12.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card แสดงรูปภาพ service
          Container(
            padding: EdgeInsets.symmetric(
              vertical: AppDims.size_5.h,
              horizontal: AppDims.size_12.w,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: AppColors.border,
            ),
            child: Image.network(
              // "https://dev.abgroup.co.th/storage/galleries/s3nbAR7QLSPpZ9aSTWSyGV9nXQZy6JhsPgVvaJKL.png",
              widget.data.machineImage,
              width: AppDims.size_50.w,
            ),
          ),
          AppDims.horizonPadding_8,

          // Detail การใช้งาน
          Expanded(
            child: Column(
              spacing: AppDims.size_4.h,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  widget.data.name.getTextByLocale(context.languageCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge,
                ),
                Row(
                  spacing: AppDims.size_8.w,
                  children: [
                    Expanded(
                      child: AppText(
                        // เวลาคงเหลือ
                        context.wording.remainingTime,
                        style: context.textTheme.labelMedium!.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _countDownNotifier,
                        builder: (context, duration, child) {
                          if (duration == Duration.zero) {
                            return AppText(
                              // เสร็จสิ้น
                              context.wording.done,
                              style: context.textTheme.labelMedium!.copyWith(
                                color: AppColors.primary,
                              ),
                            );
                          }
                          return AppText(
                            countDowntDisplay(duration),
                            style: context.textTheme.labelMedium!.copyWith(
                              color: AppColors.gray600,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: AppDims.size_8.w,
                  children: [
                    Expanded(
                      child: AppText(
                        // เสร็จโดยประมาณ
                        context.wording.estimatedCompletion,
                        style: context.textTheme.labelMedium!.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _finishedNotifier,
                        builder: (context, finished, child) {
                          if (finished) {
                            return AppText(
                              // เสร็จสิ้น
                              context.wording.done,
                              style: context.textTheme.labelMedium!.copyWith(
                                color: AppColors.primary,
                              ),
                            );
                          }
                          return AppText(
                            widget.data.finishTime,
                            style: context.textTheme.labelMedium!.copyWith(
                              color: AppColors.gray600,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppDims.horizonPadding_16,

          // Button ดู Detail
          ValueListenableBuilder(
            valueListenable: _finishedNotifier,
            builder: (context, finished, child) {
              return GestureDetector(
                onTap: finished ? null : widget.onTap,
                child: Container(
                  width: AppDims.size_26.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: finished ? SizedBox() : Assets.svg.arrowRight.svg(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String countDowntDisplay(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minute = (totalSeconds % 3600) ~/ 60;
    final second = totalSeconds % 60;
    String hourStr = hours < 10 ? '0$hours' : '$hours';
    String minuteStr = minute < 10 ? '0$minute' : '$minute';
    String secondStr = second < 10 ? '0$second' : '$second';

    return '$hourStr : $minuteStr : $secondStr';
  }
}
