import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/feature/authentication/screen/authentication_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/authentication_viewmodel.dart';
import 'package:browny_applications_new/feature/contacts/repository/contact_repo.dart';
import 'package:browny_applications_new/feature/home/screens/home_page.dart';
import 'package:browny_applications_new/feature/home/viewmodel/home_page_viewmodel.dart';
import 'package:browny_applications_new/feature/invit_friend/screen/invit_friend_page.dart';
import 'package:browny_applications_new/feature/map/screens/map_page.dart';
import 'package:browny_applications_new/feature/profile/repository/notification_preferences_repo.dart';
import 'package:browny_applications_new/feature/profile/repository/profile_repo.dart';
import 'package:browny_applications_new/feature/profile/screen/profile_page.dart';
import 'package:browny_applications_new/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:browny_applications_new/feature/scaner/screen/scanner_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/history_transaction_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MyProfileAndPreferencesPage extends StatelessWidget {
  const MyProfileAndPreferencesPage({super.key});

  static const pagePath = '/my_profile_and_preferences';
  static const pageName = 'MyProfileAndPreferencesPage';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(
        context: context,
        repo: ProfileRepo(),
        contactRepo: ContactRepo(),
        notificationPreferencesRepo: NotificationPreferencesRepo(),
      ),
      child: MyProfileAndPreferencesContent(),
    );
  }
}

class MyProfileAndPreferencesContent extends StatefulWidget {
  const MyProfileAndPreferencesContent({super.key});

  static const pagePath = '/my_profile_and_preferences';
  static const pageName = 'MyProfileAndPreferencesPage';

  @override
  State<MyProfileAndPreferencesContent> createState() =>
      _MyProfileAndPreferencesContentState();
}

class _MyProfileAndPreferencesContentState
    extends State<MyProfileAndPreferencesContent>
    with WidgetsBindingObserver {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read();
    _viewModel.attachContext(context);

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.fetchContactAndSupportLink();
      await _viewModel.fetchNotificationPreferences();
      await _viewModel.loadUserPreferences();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      await _viewModel.loadUserPreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // 1. User Info Section with Quick Action Buttons (Pasted Image 2)
          _buildUserInfoSection(),

          // 2. Banner Cards (Pasted Image 3)
          _buildBannerCardsSection(),

          // 4. Favorites Section
          _buildFavoritesSection(),

          // 5. App Preferences Section (Pasted Image 4)
          _buildAppPreferencesSection(),

          // 6. Notifications Section
          _buildNotificationsSection(),

          // 7. Terms and Conditions Section
          _buildTermsSection(),

          // 8. Contact Support Section
          _buildContactSection(),

          // 9. Logout Section
          _buildLogoutSection(),

          // 10. Social Media Section
          _buildSocialMediaSection(),

          // 11. Version Section
          _buildVersionSection(),

          // Bottom padding
          SliverToBoxAdapter(
            child: AppDims.vericalPadding_46,
          ),
        ],
      ),
    );
  }

  // ========== Pasted Image 2: User Info Section ==========
  Widget _buildUserInfoSection() {
    return SliverToBoxAdapter(
      child: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          // เพิ่มการโหลด notification เพิ่มถ้า Provider ของ User ถูก noti
          Future.microtask(() {
            _viewModel.fetchNotificationPreferences();
            _viewModel.loadUserPreferences();
          });

          final isGuest = provider.current.isGuest;
          final customer = provider.current;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Background with user info
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: Assets.png.bgProfile.provider(),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + AppDims.size_6.h,
                  left: AppDims.size_16.w,
                  right: AppDims.size_16.w,
                  bottom: AppDims
                      .size_60
                      .h, // เผื่อพื้นที่สำหรับ Quick Action Buttons
                ),
                child: Column(
                  children: [
                    // Top row with profile icon, name, and actions
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (context.canPop()) {
                              context.safePop();
                              return;
                            }
                            HomePage.goReplacementPage(context);
                          },
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.background,
                          ),
                        ),
                        AppDims.horizonPadding_12,
                        // Profile Icon
                        CircleAvatar(
                          radius: AppDims.size_24.w,
                          backgroundColor: AppColors.background,
                          child: IconButton(
                            onPressed: null,
                            icon: customer.image.orEmpty.isEmpty
                                // ถ้าไม่มีรูป Profile ใช้รูป Default
                                ? Assets.svg.icPerson.svg(
                                    width: AppDims.size_26.w,
                                    // เปลี่ยนสี svg
                                    colorFilter: ColorFilter.mode(
                                      AppColors.primary,
                                      BlendMode.srcIn,
                                    ),
                                  )
                                // มีรูป Profile ให้ไปโหลดมา
                                : Image.network(
                                    customer.image!,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Assets.svg.icPerson.svg(
                                              // เปลี่ยนสี svg
                                              colorFilter: ColorFilter.mode(
                                                AppColors.primary,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                  ),
                          ),
                        ),
                        AppDims.horizonPadding_12,

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (context) {
                                  if (isGuest) {
                                    final label = provider.current.isGuest
                                        ? context.wording.login
                                        : context.wording.topup;

                                    return ElevatedButton.icon(
                                      icon: Assets.svg.icLogin.svg(
                                        width: AppDims.size_16.w,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.primary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      // icon: Icon(Icons.login),
                                      iconAlignment: IconAlignment.end,
                                      onPressed: () {
                                        _goAuthenPage(context);
                                      },
                                      style: context
                                          .appTheme
                                          .elevatedButtonTheme
                                          .style!
                                          .copyWith(
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppDims.size_4,
                                                    ),
                                              ),
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            padding: WidgetStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                vertical: AppDims.size_4.h,
                                                horizontal: AppDims.size_8.w,
                                              ),
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                              Size(70.w, 22.h),
                                            ),
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                  AppColors.background,
                                                ),
                                          ),
                                      label: AppText(
                                        label,
                                        style: context.textTheme.titleSmall!
                                            .copyWith(
                                              color: AppColors.primary,
                                            ),
                                      ),
                                    );
                                  }
                                  return AppText(
                                    provider.current.name ?? '',
                                    style: context.textTheme.labelLarge!
                                        .copyWith(
                                          color: AppColors.white,
                                          fontSize: AppDims.size_16.sp,
                                        ),
                                  );
                                },
                              ),
                              AppDims.vericalPadding_4,
                              AppText(
                                // provider.current.phone ?? '',
                                context.wording.viewYourProfile,
                                style: context.textTheme.titleMedium!.copyWith(
                                  color: AppColors.white.withValues(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // QR Code and Edit buttons
                        // ต้องไม่ใช่ Guest
                        if (!isGuest)
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  ScannerPage.goToPage(
                                    context,
                                    // เปิด QR
                                    initialIndex: 1,
                                  );
                                  // _showQrCustomer(context);
                                },
                                child: Assets.svg.icQrDummy.svg(
                                  width: AppDims.size_24.h,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              AppDims.horizonPadding_8,

                              GestureDetector(
                                onTap: () {
                                  ProfilePage.goToPage(context);
                                  // context.pushNamed(ProfilePage.pageName);
                                },
                                child: Assets.svg.icEditReg.svg(
                                  width: AppDims.size_24.h,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    AppDims.vericalPadding_16,

                    // Balance Section
                    Row(
                      children: [
                        // Wallet Balance
                        Expanded(
                          child: Column(
                            children: [
                              AppText(
                                formatCurrency(
                                  leadingSign: '฿',
                                  string: provider.current.creditBalance,
                                ),
                                style: context.textTheme.headlineLarge!
                                    .copyWith(
                                      color: AppColors.white,
                                      fontSize: AppDims.size_24.sp,
                                    ),
                              ),
                              AppDims.vericalPadding_4,
                              AppText(
                                context.wording.creditBalance,
                                style: context.textTheme.labelMedium!.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Coin Balance
                        Expanded(
                          child: Column(
                            children: [
                              AppText(
                                formatCurrency(
                                  string: provider.current.brownyCoin,
                                ),
                                style: context.textTheme.headlineLarge!
                                    .copyWith(
                                      color: AppColors.white,
                                      fontSize: AppDims.size_24.sp,
                                    ),
                              ),
                              AppDims.vericalPadding_4,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Assets.png.brownyCoin.image(
                                    width: AppDims.size_20.w,
                                  ),
                                  AppDims.horizonPadding_8,

                                  AppText(
                                    context.wording.coin,
                                    style: context.textTheme.labelMedium!
                                        .copyWith(color: AppColors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Action Buttons (ซ้อนทับด้านบนของ background)
              Positioned(
                bottom: -AppDims.size_40.h, // ยื่นออกมาครึ่งหนึ่ง
                left: AppDims.size_16.w,
                right: AppDims.size_16.w,
                child: Container(
                  padding: EdgeInsets.all(AppDims.size_16.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppDims.size_8.r),
                    boxShadow: AppColors.defatultShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionButton(
                        icon: Assets.profileQuickAction.icCoupon.svg(
                          width: AppDims.size_32.w,
                        ),
                        label: context.wording.rewards,
                        onTap: () {
                          CouponVoucherPage.goToPage(
                            context,
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Assets.profileQuickAction.icScan.svg(
                          width: AppDims.size_28.w,
                        ),
                        label: context.wording.scan,
                        onTap: () {
                          ScannerPage.goToPage(context);
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Assets.profileQuickAction.icRefreshDouble.svg(),
                        // สถานะ
                        label: context.wording.status,
                        onTap: () async {
                          // TODO: Navigate to status page
                          await _showDialogComingSoon(context.wording.status);
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Assets.profileQuickAction.icHistory.svg(
                          width: AppDims.size_28.w,
                        ),
                        // ประวัติ
                        label: context.wording.history,
                        onTap: () async {
                          // TODO: Navigate to history page
                          // await _showDialogComingSoon(context.wording.history);
                          HistoryTransactionPage.goToPage(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          AppDims.vericalPadding_4,
          AppText(
            label,
            style: context.textTheme.labelLarge!.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ========== Pasted Image 3: Banner Cards Section ==========
  Widget _buildBannerCardsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: AppDims.size_50.h,
        ), // เผื่อพื้นท้ี่สำหรับ Quick Action Buttons ที่ยื่นออกมา
        child: Column(
          children: [
            // E-Voucher Card
            GestureDetector(
              onTap: () {
                CouponVoucherPage.goToPage(
                  context,
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppDims.size_16.w,
                  vertical: AppDims.size_8.h,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDims.size_12.r),
                  child: Assets.png.cardCouponEvoucher2.image(
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),

            // Invite Friend Card
            GestureDetector(
              onTap: () {
                context
                    .pushNamed<Map<Type, HomePageState>>(
                      InvitFriendPage.pageName,
                    )
                    .then((bypass) {
                      if (!mounted) return;
                      if (context.mounted && bypass != null) {
                        context.safePop();
                        switch (bypass.values.first) {
                          case HomePageState.home:
                            break;
                          case HomePageState.couponVoucher:
                            // context.pushNamed(
                            //   CouponVoucherPage.pageName,
                            // );
                            CouponVoucherPage.goToPage(
                              context,
                            );
                            break;
                          case HomePageState.scan:
                            // ไปหน้า Scan
                            ScannerPage.goToPage(context, initialIndex: 0);
                            break;
                          case HomePageState.branches:
                            context.pushNamed(
                              MapPage.pageName,
                            );
                            break;
                          case HomePageState.brownyShop:
                            break;
                        }
                      }
                    });
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: AppDims.size_8.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDims.size_12.r),
                  child: Assets.png.cardInvitFriend.image(
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _defaultPreferencesTextStyle =>
      context.textTheme.labelLarge!.copyWith(
        color: AppColors.textBare,
        fontSize: AppDims.size_16.sp,
      );

  // ========== Favorites Section ==========
  Widget _buildFavoritesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: AppDims.size_16.h,
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          bottom: AppDims.size_8.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              context.wording.activities,
              style: _defaultPreferencesTextStyle,
            ),
            AppDims.vericalPadding_8,
            _buildPreferenceItem(
              icon: Icons.favorite_border,
              // สินค้าที่บันทึกไว้
              title: context.wording.savedItems,
              suffixWidget: Assets.svg.icArrowForward.svg(),
              onTap: () async {
                // TODO: Navigate to favorites page
                await _showDialogComingSoon(context.wording.savedItems);
              },
            ),
            AppDims.vericalPadding_12,
            Divider(),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _showDialogComingSoon(String title) async {
    return await showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            // สินค้าที่บันทึกไว้
            title: AppText(
              // สินค้าที่บันทึกไว้
              // context.wording.savedItems,
              title,
            ),
            leading: BackButton(
              color: AppColors.darkBrown,
            ),
          ),
          body: SafeArea(
            child: SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                    child: Assets.png.brownySuccess1.image(
                      width: 145.w,
                      height: 100.h,
                    ),
                  ),
                  AppDims.vericalPadding_16,

                  AppText(
                    ContentLocalizeData(
                      en: 'Coming Soon.',
                      zh: '敬请期待',
                      th: 'พบกันเร็ว ๆ นี้',
                    ).getTextByLocale(context.languageCode),
                    style: context.textTheme.labelLarge!.copyWith(
                      fontSize: AppDims.size_16.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== Pasted Image 4: App Preferences Section ==========
  Widget _buildAppPreferencesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: AppDims.size_8.h,
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          bottom: AppDims.size_8.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              context.wording.appSettings,
              style: _defaultPreferencesTextStyle,
            ),
            AppDims.vericalPadding_8,

            // Language Selection
            Consumer<AppEvnironment>(
              builder: (context, env, child) {
                final currentLocale = env.appPreferences.getLanguage();

                return _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icTranslate,
                  title: context.wording.language,
                  trailing: null,
                  suffixWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageButton(
                        context: context,
                        localeCode: 'th',
                        flagAsset: Assets.svg.icFlagTh,
                        label: 'ไทย',
                        isSelected: currentLocale == 'th',
                      ),
                      // SizedBox(width: 4.w),
                      _buildLanguageButton(
                        context: context,
                        localeCode: 'en',
                        flagAsset: Assets.svg.icFlagEn,
                        label: 'Eng',
                        isSelected: currentLocale == 'en',
                      ),
                      // SizedBox(width: 4.w),
                      _buildLanguageButton(
                        context: context,
                        localeCode: 'zh',
                        flagAsset: Assets.svg.icFlagZh,
                        label: '中文',
                        isSelected: currentLocale == 'zh',
                      ),
                    ],
                  ),
                  onTap: null,
                );
              },
            ),

            // Biometric Authentication
            ValueListenableBuilder<bool>(
              valueListenable: _viewModel.biometricEnabledNotifier,
              builder: (context, isBiometricEnabled, _) {
                return _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icFace,
                  title: context.wording.allowBiometricAuth,
                  trailing: null,
                  suffixWidget: _buildSwitch(
                    value: isBiometricEnabled,
                    onChanged: (value) {
                      _viewModel.toggleBiometric(value);
                    },
                  ),
                  onTap: null,
                );
              },
            ),

            // Save Slip Auto
            ValueListenableBuilder<bool>(
              valueListenable: _viewModel.saveSlipAutoNotifier,
              builder: (context, isSaveSlipAutoEnabled, _) {
                return _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icImport,
                  title: context.wording.autoSaveReceipt,
                  trailing: null,
                  suffixWidget: _buildSwitch(
                    value: isSaveSlipAutoEnabled,
                    onChanged: (value) {
                      _viewModel.toggleSaveSlipAuto(value);
                    },
                  ),
                  onTap: null,
                );
              },
            ),

            // Location Permission
            ValueListenableBuilder<bool>(
              valueListenable: _viewModel.locationPermissionNotifier,
              builder: (context, isLocationEnabled, _) {
                return _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icLocation,
                  title: context.wording.locationAccess,
                  trailing: null,
                  suffixWidget: _buildSwitch(
                    value: isLocationEnabled,
                    onChanged: (value) {
                      _viewModel.toggleLocationPermission(value);
                    },
                  ),
                  onTap: null,
                );
              },
            ),

            // Email Settings
            _buildPreferenceItem(
              leadingSvg: Assets.iconProfilePreferences.mail,
              // เปลี่ยน e-mail
              title: context.wording.changeEmail,
              suffixWidget: Assets.svg.icArrowForward.svg(),
              onTap: () {
                ProfilePage.goToPage(context);
              },
            ),

            // Password Settings
            _buildPreferenceItem(
              leadingSvg: Assets.iconProfilePreferences.icLock,
              // เปลี่ยนรหัสผ่าน
              title: context.wording.changePassword,
              suffixWidget: Assets.svg.icArrowForward.svg(),
              onTap: () {
                // ไป Process เปลี่ยน Password
                AuthenticationPage.goToPage(
                  context,
                  process: AuthenProcess.changePassword,
                );
              },
            ),
            AppDims.vericalPadding_12,
            Divider(),
          ],
        ),
      ),
    );
  }

  // Widget _buildLanguageChip(String label, bool isSelected) {
  //   return Container(
  //     margin: EdgeInsets.only(left: 4.w),
  //     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
  //     decoration: BoxDecoration(
  //       color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
  //       border: Border.all(
  //         color: isSelected ? AppColors.primary : AppColors.gray400,
  //       ),
  //       borderRadius: BorderRadius.circular(16.r),
  //     ),
  //     child: AppText(
  //       label,
  //       style: context.textTheme.bodySmall!.copyWith(
  //         color: isSelected ? AppColors.primary : AppColors.gray600,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLanguageButton({
    required BuildContext context,
    // required AppEvnironment env,
    required String localeCode,
    required SvgGenImage flagAsset,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<AppEvnironment>().onLocaleChange(localeCode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_12.w,
          vertical: AppDims.size_8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDims.size_20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            flagAsset.svg(
              width: AppDims.size_20.w,
              height: AppDims.size_20.h,
            ),
            SizedBox(width: AppDims.size_4.w),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              style: context.textTheme.bodySmall!.copyWith(
                fontSize: AppDims.size_12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // ========== Notifications Section ==========
  Widget _buildNotificationsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: AppDims.size_8.h,
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          bottom: AppDims.size_8.h,
        ),
        child: ValueListenableBuilder(
          valueListenable: _viewModel.notificationPreferencesNotifier,
          builder: (context, result, _) {
            // แสดง loading หรือ error ไม่ต้องทำอะไร ให้แสดง UI ปกติ
            final data = result.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  context.wording.notifications,
                  style: _defaultPreferencesTextStyle,
                ),
                AppDims.vericalPadding_8,

                // General Notifications (การแจ้งเตือนทั่วไป)
                _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icNotification,
                  title: context.wording.generalNotifications,
                  trailing: null,
                  suffixWidget: _buildSwitch(
                    value: data?.notifyGeneral == 1,
                    onChanged: (value) {
                      _viewModel.updateNotificationPreferences(
                        notifyGeneral: value,
                      );
                    },
                  ),
                  onTap: null,
                ),

                // Promotions (โปรโมชั่น)
                _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icDiscount,
                  title: context.wording.promotions,
                  trailing: null,
                  suffixWidget: _buildSwitch(
                    value: data?.notifyPromotion == 1,
                    onChanged: (value) {
                      _viewModel.updateNotificationPreferences(
                        notifyPromotion: value,
                      );
                    },
                  ),
                  onTap: null,
                ),

                // News (ข่าวสาร)
                _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icAnnouncement,
                  title: context.wording.updates,
                  trailing: null,
                  suffixWidget: _buildSwitch(
                    value: data?.notifyNews == 1,
                    onChanged: (value) {
                      _viewModel.updateNotificationPreferences(
                        notifyNews: value,
                      );
                    },
                  ),
                  onTap: null,
                ),

                // Order Status (สถานะคำสั่งซื้อ / เครื่องทำงานเสร็จ)
                _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icRefreshCircular,
                  title: context.wording.workOrderStatus,
                  trailing: null,
                  suffixWidget: _buildSwitch(
                    value: data?.notifyMachineDone == 1,
                    onChanged: (value) {
                      _viewModel.updateNotificationPreferences(
                        notifyMachineDone: value,
                      );
                    },
                  ),
                  onTap: null,
                ),

                AppDims.vericalPadding_12,
                Divider(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ========== Terms Section ==========
  Widget _buildTermsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: AppDims.size_8.h,
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          bottom: AppDims.size_8.h,
        ),
        child: ValueListenableBuilder(
          valueListenable: _viewModel.contactAndSupportLinkNotifier,
          builder: (context, result, child) {
            // ข้อมูล Contact
            final data = result.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  // ข้อกำหนดและเงื่อไข
                  context.wording.termsAndConditions2,
                  style: _defaultPreferencesTextStyle,
                ),
                AppDims.vericalPadding_8,
                _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icPage,
                  title: context.wording.termsOfUseAndPrivacy,
                  titleStyle: context.textTheme.labelLarge!.copyWith(
                    color: AppColors.textBare,
                    fontSize: AppDims.size_14.sp,
                  ),
                  suffixWidget: Assets.svg.icArrowForward.svg(),
                  onTap: result.isSuccess
                      ? () async {
                          // เปิด Link Terms
                          await _openLink(data!.registerTermsLink.orEmpty);
                        }
                      : null,
                ),
                AppDims.vericalPadding_12,
                Divider(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ========== Contact Support Section ==========
  Widget _buildContactSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: AppDims.size_8.h,
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          bottom: AppDims.size_8.h,
        ),
        child: ValueListenableBuilder(
          valueListenable: _viewModel.contactAndSupportLinkNotifier,
          builder: (context, result, child) {
            // ข้อมูล Contact
            final data = result.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  context.wording.helpAndSupport,
                  style: _defaultPreferencesTextStyle,
                ),
                AppDims.vericalPadding_8,

                // Phone Contact
                _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icCalling,
                  // ติดต่อ Browny Care
                  title: context.wording.contactBrownyCare,
                  subtitle:
                      '${context.wording.callPhoneNumber} ${data?.brownyCareContact.orEmpty}',
                  titleStyle: context.textTheme.labelLarge!.copyWith(
                    color: AppColors.textBare,
                    fontSize: AppDims.size_14.sp,
                  ),
                  subtitleStyle: context.textTheme.labelMedium!.copyWith(
                    color: AppColors.gray500,
                    fontSize: AppDims.size_14.sp,
                  ),
                  suffixWidget: Assets.svg.icArrowForward.svg(),
                  onTap: result.isSuccess
                      ? () async {
                          // โทรออกเบอร์สายด่วน
                          await _openCall(data!.brownyCareContact.orEmpty);
                        }
                      : null,
                ),

                // LINE Contact
                _buildPreferenceItem(
                  leadingSvg: Assets.iconProfilePreferences.icLine,
                  // สอบถามผ่าน LINE Browny Official
                  title: context.wording.contactViaLine,
                  suffixWidget: Assets.svg.icArrowForward.svg(),
                  titleStyle: context.textTheme.labelLarge!.copyWith(
                    color: AppColors.textBare,
                    fontSize: AppDims.size_14.sp,
                  ),
                  onTap: result.isSuccess
                      ? () async {
                          // เปิด App LINE
                          await _openLink(data!.lineLink.orEmpty);
                        }
                      : null,
                ),
                AppDims.vericalPadding_12,
                Divider(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ========== Logout Section ==========
  Widget _buildLogoutSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
        ),
        child: Column(
          children: [
            Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                final customer = provider.current;
                return _buildPreferenceItem(
                  leadingSvg: customer.isGuest
                      ? Assets.iconProfilePreferences.icLogin
                      : Assets.iconProfilePreferences.icLogout,
                  title: customer.isGuest
                      // เข้าสู่ระบบ
                      ? context.wording.login
                      // ออกจากระบบ
                      : context.wording.logout,
                  trailing: null,
                  onTap: () async {
                    if (customer.isGuest) {
                      _goAuthenPage(context);
                    } else {
                      await AppOverlays.showBrownyDialog(
                        context,
                        imageAsset: Assets.png.brownyError1.path,
                        title: context.wording.logout,
                        message: context.wording.confirmLogoutMessage,
                        confirmText: context.wording.confirm,
                        cancelText: context.wording.cancel,
                        onConfirm: () async {
                          AppOverlays.showLoading(
                            context,
                            timeout: Duration(seconds: 3),
                            onTimeout: () {
                              if (!mounted) return;
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(content: Text('Time out')),
                              );
                            },
                          );
                          final result = await _viewModel.logout();
                          AppOverlays.hideLoading();
                          if (result.isSuccess && context.mounted) {
                            context.safePop();
                            // context.pushNamedAndClear(
                            //   OnBoardingPage.pageName,
                            // );
                          }
                        },
                      );
                    }
                  },
                );
              },
            ),
            AppDims.vericalPadding_8,
            Divider(),
          ],
        ),
      ),
    );
  }

  void _goAuthenPage(BuildContext context) {
    AuthenticationPage.goToPage(context, process: AuthenProcess.login);
    // context.pushNamed(
    //   AuthenticationPage.pageName,
    //   extra: {
    //     AuthenProcess: AuthenProcess.login,
    //   },
    // );
  }

  // ========== Social Media Section ==========
  Widget _buildSocialMediaSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: AppDims.size_8.h,
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          bottom: AppDims.size_8.h,
        ),
        child: ValueListenableBuilder(
          valueListenable: _viewModel.contactAndSupportLinkNotifier,
          builder: (context, result, child) {
            // ข้อมูล Contact
            final data = result.data;

            return Column(
              children: [
                AppDims.vericalPadding_8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialMediaButton(
                      icon: Assets.iconProfilePreferences.facebook.image(),
                      onTap: result.isSuccess
                          ? () async {
                              // เปิด App LINE
                              await _openLink(data!.facebookLink.orEmpty);
                            }
                          : null,
                    ),
                    AppDims.horizonPadding_9,
                    _buildSocialMediaButton(
                      icon: Assets.iconProfilePreferences.instragram.image(),
                      onTap: result.isSuccess
                          ? () async {
                              // เปิด App IG
                              // TODO บอกปาร์คว่าไม่มี LINK IG
                              await _openLink(
                                'https://www.instagram.com/brownywash?igsh=MTg0YmtvNDN4dnN1ZA==',
                              );
                            }
                          : null,
                    ),
                    AppDims.horizonPadding_9,
                    _buildSocialMediaButton(
                      icon: Assets.iconProfilePreferences.line.image(
                        width: AppDims.size_2.w,
                      ),
                      onTap: result.isSuccess
                          ? () async {
                              // เปิด App LINE
                              await _openLink(data!.lineLink.orEmpty);
                            }
                          : null,
                    ),
                    AppDims.horizonPadding_9,
                    _buildSocialMediaButton(
                      icon: Assets.iconProfilePreferences.tiktok.image(),
                      onTap: result.isSuccess
                          ? () async {
                              // เปิด App TikTok
                              await _openLink(data!.tiktokLink.orEmpty);
                            }
                          : null,
                    ),
                    AppDims.horizonPadding_9,
                    _buildSocialMediaButton(
                      icon: Assets.iconProfilePreferences.youtube.image(),
                      onTap: result.isSuccess
                          ? () async {
                              // เปิด App Youtube
                              await _openLink(data!.youtubeLink.orEmpty);
                            }
                          : null,
                    ),
                  ],
                ),
                AppDims.vericalPadding_16,
                Divider(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openLink(String source) async {
    // เปิด LINK จาก Source ที่ส่งเข้ามา
    final launched = await LaunchHelper.openUrlInBrowser(
      source,
    );

    if (mounted && !launched) {
      AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        // ข้อมูลติดต่อไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง
        message: context.wording.invalidContactInfoError,
      );
    }
  }

  Future<void> _openCall(String source) async {
    // โทรออกเบอร์สายด่วน
    final launched = await LaunchHelper.makePhoneCall(
      source,
    );
    if (mounted && !launched) {
      AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        // ข้อมูลติดต่อไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง
        message: context.wording.invalidContactInfoError,
      );
    }
  }

  Widget _buildSocialMediaButton({
    // required IconData icon,
    required Widget icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: AppDims.size_40.w,
        height: AppDims.size_40.h,
        padding: EdgeInsets.all(AppDims.size_7.r),
        decoration: BoxDecoration(
          color: AppColors.transparent,
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }

  // ========== Version Section ==========
  Widget _buildVersionSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: AppDims.size_8.h,
          left: AppDims.size_16.w,
          right: AppDims.size_16.w,
          bottom: AppDims.size_8.h,
        ),
        child: Center(
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, asyncSnapshot) {
              return AppText(
                // '${context.wording.version} 3.0.0',
                '${context.wording.version} ${asyncSnapshot.data?.version ?? ''}',
                style: context.textTheme.bodySmall!.copyWith(
                  color: AppColors.gray500,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ========== Common Preference Item Widget ==========
  Widget _buildPreferenceItem({
    IconData? icon,
    required String title,
    SvgGenImage? leadingSvg,
    AssetGenImage? leadingPng,
    String? subtitle,
    IconData? trailing,
    Widget? suffixWidget,
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        child: ListTile(
          // horizontalTitleGap: 0,
          minVerticalPadding: 0,
          contentPadding: EdgeInsets.symmetric(vertical: AppDims.size_8.h),
          minTileHeight: AppDims.size_26.h,
          leading:
              leadingSvg?.svg() ??
              leadingPng?.image() ??
              Icon(
                icon,
                size: AppDims.size_24.r,
                color: iconColor ?? AppColors.gray600,
              ),
          title: AppText(
            title,
            style: titleStyle ?? _defaultPreferencesTextStyle,
          ),
          subtitle: subtitle == null
              ? null
              : AppText(
                  subtitle,
                  style:
                      subtitleStyle ??
                      context.textTheme.bodySmall!.copyWith(
                        color: AppColors.gray500,
                      ),
                ),

          trailing:
              suffixWidget ??
              (trailing == null
                  ? null
                  : Icon(
                      trailing,
                      size: AppDims.size_20.r,
                      color: AppColors.gray400,
                    )),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    ValueChanged<bool>? onChanged,
    required bool value,
  }) {
    return SizedBox(
      width: AppDims.size_35.w, // Desired width
      height: AppDims.size_30.h, // Desired height
      child: FittedBox(
        child: Switch(
          activeThumbColor: AppColors.white,
          activeTrackColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: value, // TODO: Bind to state
          onChanged: onChanged,
        ),
      ),
    );
  }
}
