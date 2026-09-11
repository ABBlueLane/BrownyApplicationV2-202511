import 'dart:io';

import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/widgets/app_container_radius.dart';
import 'package:browny_applications_new/feature/contacts/repository/contact_repo.dart';
import 'package:browny_applications_new/feature/home/screens/home_page.dart';
import 'package:browny_applications_new/feature/profile/repository/notification_preferences_repo.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/ui_result.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/core/widgets/locale_toggle_widget.dart';
import 'package:browny_applications_new/feature/profile/repository/profile_repo.dart';
import 'package:browny_applications_new/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:browny_applications_new/models/user_model.dart';
import 'package:browny_applications_new/res/styles/app_text_style.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.isFirstSignup = false,
  });

  static final pagePath = '/profile_page';
  static final pageName = 'profile_page';
  static final kFirstSignup = 'first_signup';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    bool isFirstSignup = false,
  }) async {
    return await context.pushNamed(
      ProfilePage.pageName,
      extra: {
        ProfilePage.kFirstSignup: isFirstSignup,
      },
    );
  }

  final bool isFirstSignup;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(
        context: context,
        repo: ProfileRepo(),
        contactRepo: ContactRepo(),
        notificationPreferencesRepo: NotificationPreferencesRepo(),
      ),
      child: ProfileWidget(
        isFirstSignup: isFirstSignup,
      ),
    );
  }
}

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({
    super.key,
    this.isFirstSignup = false,
  });
  final bool isFirstSignup;
  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late final ProfileViewModel _viewModel;
  final FocusNode _birthDatefocusNode = FocusNode();

  // int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ProfileViewModel>();
    _viewModel.attachContext(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppOverlays.showLoading(context);
      await _viewModel.fetchProfileData();

      if (mounted && widget.isFirstSignup) {
        await _showBirthDayOffers(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          context.wording.updateYourProfile,
          style: context.textTheme.titleMedium!.copyWith(
            color: AppColors.textPrimary,
            fontSize: AppDims.size_16.sp,
          ),
        ),
        centerTitle: true,
        leadingWidth: 100.w,
        leading: !widget.isFirstSignup
            ? TextButton.icon(
                onPressed: () {
                  context.safePop();
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                label: AppText(
                  context.wording.back,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(50.w, 40.h),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ValueListenableBuilder<UiResult<UserModel>>(
            valueListenable: _viewModel.profileData,
            builder: (context, profile, _) {
              AppOverlays.hideLoading();

              if (profile.isLoading) {
                return SizedBox();
              }
              if (profile.hasError) {
                AppOverlays.showBrownyErrorDialog(
                  context,
                  title: context.wording.somethingWrong,
                  error: profile.error,
                  onConfirm: () {
                    context.safePop();
                  },
                );
                return SizedBox();
              }

              final data = profile.data!;

              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildProfileImage(data),

                  AppDims.vericalPadding_10,

                  // Field แสดงเบอร์
                  _buildPhoneField(data, context),
                  AppDims.vericalPadding_16,

                  // Toggle ภาษา
                  Center(
                    child: LocaleToggleWidget(),
                  ),

                  AppDims.vericalPadding_16,

                  // Profile Form
                  _buildProfileForm(context),

                  AppDims.vericalPadding_16,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
      ),
      child: Form(
        key: _viewModel.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Field
            AppText(
              context.wording.email,
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDims.size_8.h),
            AppTextFormField(
              controller: _viewModel.emailController,
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Browny1234@gmail.com',
                hintStyle: context.inputTextStyle.copyWith(
                  color: AppColors.gray500,
                ),
                fillColor: AppColors.background,
                prefixIcon: SizedBox.shrink(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value.orEmpty.isEmpty ||
                    _viewModel.isValidEmail(value.orEmpty)) {
                  return null;
                }
                return context.wording.pleaseEnterValidEmail;
              },
            ),
            SizedBox(height: AppDims.size_16.h),

            // Name Field
            AppText(
              context.wording.nameSurname,
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDims.size_8.h),
            AppTextFormField(
              controller: _viewModel.nameController,
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: context.wording.nameSurname,
                hintStyle: context.inputTextStyle.copyWith(
                  color: AppColors.gray500,
                ),
                fillColor: AppColors.background,
                prefixIcon: SizedBox.shrink(),
              ),
            ),
            SizedBox(height: AppDims.size_16.h),

            // Gender Field
            AppText(
              context.wording.gender,
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDims.size_8.h),
            DropdownButtonFormField<String>(
              borderRadius: BorderRadius.circular(AppDims.size_8.r),
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
              icon: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppDims.size_10.w,
                  horizontal: AppDims.size_4.h,
                ),
                child: Assets.svg.icArrowDown.svg(
                  width: AppDims.size_20.sp,
                  height: AppDims.size_20.sp,
                ),
              ),
              decoration: InputDecoration(
                hintStyle: context.inputTextStyle.copyWith(
                  color: AppColors.gray500,
                ),
                fillColor: AppColors.background,
                hintText: context.wording.gender,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDims.size_12.w,
                  vertical: AppDims.size_12.h,
                ),
              ),
              initialValue: _viewModel.genderController.text,
              items: _viewModel.genders
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.keys.first,
                      child: AppText(
                        e.values.first,
                        style: context.textTheme.labelLarge!.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                _viewModel.genderController.text = value!;
              },
            ),
            AppDims.vericalPadding_16,

            // Date of Birth Field
            AppText(
              context.wording.dateOfBirth,
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppDims.vericalPadding_8,

            AppTextFormField(
              // enabled: widget.isFirstSignup,
              focusNode: _birthDatefocusNode,
              controller: _viewModel.dateOfBirth,
              readOnly: true,
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                fillColor: widget.isFirstSignup
                    ? AppColors.background
                    : AppColors.gray500,
                hintText: context.wording.ddMMyy,
                hintStyle: context.inputTextStyle.copyWith(
                  color: AppColors.gray500,
                ),
                suffixIcon: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppDims.size_10.w,
                    horizontal: AppDims.size_14.w,
                  ),
                  child: Assets.svg.icCalendarToday.svg(
                    width: AppDims.size_20.sp,
                    height: AppDims.size_20.sp,
                  ),
                ),
                prefixIcon: SizedBox.shrink(),
              ),
              onTap: _onbirthDateFieldTap,
            ),

            // เงื่อนไขวันเกิด
            TextButton.icon(
              onPressed: () async {
                await _showBirthDayOffers(context);
                // showOverlappingDialog(context);
              },
              style: context.appTheme.textButtonTheme.style!.copyWith(
                minimumSize: WidgetStatePropertyAll(
                  Size(AppDims.size_50.w, AppDims.size_18.h),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStatePropertyAll(
                  EdgeInsets.only(top: AppDims.size_2.h),
                ),
              ),
              icon: Icon(
                Icons.info_outline_rounded,
                color: AppColors.gray500,
              ),
              label: AppText(
                context.wording.birthdaySpecialConditions,
                style: context.textTheme.labelMedium!.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
            SizedBox(height: AppDims.size_16.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  AppOverlays.showLoading(context);

                  final result = await _viewModel.onSaveProfile();

                  AppOverlays.hideLoading();

                  if (context.mounted) {
                    if (result.isSuccess) {
                      await AppOverlays.showBrownyDialog(
                        context,
                        title: context.wording.done,
                        message: context.wording.profileSavedSuccessfully,
                        confirmText: context.wording.close,
                        imageAsset: Assets.png.brownyCreatePin.path,
                        onConfirm: () {
                          if (widget.isFirstSignup) {
                            context.pushNamedAndClear(HomePage.pageName);
                          }
                        },
                      );
                    } else if (result.isError) {
                      await AppOverlays.showBrownyErrorDialog(
                        context,
                        title: context.wording.somethingWrong,
                        error: result.error,
                        imageAsset: Assets.png.brownyError1.path,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDims.size_8.r,
                    ),
                  ),
                ),
                child: Text(
                  // บันทึก
                  context.wording.save,
                  style: context.textTheme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppDims.size_4.h),

            // Skip Button
            if (widget.isFirstSignup)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    AppOverlays.showBrownyDialog(
                      context,
                      // ยืนยันการข้าม
                      title: ContentLocalizeData(
                        en: 'Confirm Skip',
                        zh: '确认跳过',
                        th: 'ยืนยันการข้าม',
                      ).getTextByLocale(context.languageCode),
                      // คุณต้องการข้ามการบันทึกข้อมูลโปรไฟล์?
                      message: ContentLocalizeData(
                        en: 'Are you sure you want to skip saving your profile?',
                        zh: '确定要跳过保存个人资料吗？',
                        th: 'คุณต้องการข้ามการบันทึกข้อมูลโปรไฟล์?',
                      ).getTextByLocale(context.languageCode),
                      confirmText: context.wording.confirm,
                      cancelText: context.wording.cancel,
                      imageAsset: Assets.png.brownyCreatePin.path,
                      onConfirm: () {
                        context.pushNamedAndClear(HomePage.pageName);
                      },
                    );
                  },
                  child: Text(
                    context.wording.skip,
                    style: context.textTheme.labelLarge!,
                  ),
                ),
              ),
            SizedBox(height: AppDims.size_8.h),
            // Submit Button
            // if (!widget.isFirstSignup)
            //   ElevatedButton(
            //     onPressed: () async {
            //       await AppOverlays.showBrownyDialog(
            //         context,
            //         imageAsset: Assets.png.brownyError1.path,
            //         title: context.wording.logout,
            //         message: context.wording.confirmLogoutMessage,
            //         confirmText: context.wording.confirm,
            //         cancelText: context.wording.cancel,
            //         onConfirm: () async {
            //           AppOverlays.showLoading(
            //             context,
            //             timeout: Duration(seconds: 3),
            //             onTimeout: () {
            //               ScaffoldMessenger.of(
            //                 context,
            //               ).showSnackBar(
            //                 SnackBar(content: Text('Time out')),
            //               );
            //             },
            //           );
            //           final result = await _viewModel.logout();
            //           AppOverlays.hideLoading();
            //           if (result.isSuccess && context.mounted) {
            //             context.pop();
            //             // context.pushNamedAndClear(
            //             //   OnBoardingPage.pageName,
            //             // );
            //           }
            //         },
            //       );
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: AppColors.error,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(
            //           AppDims.size_8.r,
            //         ),
            //       ),
            //     ),
            //     child: Text(
            //       context.wording.logout,
            //       style: context.textTheme.bodyMedium!.copyWith(
            //         color: Colors.white,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //   ),
            // SizedBox(height: AppDims.size_8.h),
          ],
        ),
      ),
    );
  }

  Future<void> _onbirthDateFieldTap() async {
    final locale = Localizations.localeOf(context);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _viewModel.initialCalendarDate(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: locale,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.promptTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      _viewModel.onBirthDayUpdate(pickedDate);
    }
  }

  Widget _buildPhoneField(UserModel data, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: AppDims.size_14.w,
        ),
        Builder(
          builder: (context) {
            String? phone = data.phone;
            return AppText(
              phone.orEmpty.isEmpty
                  // ไม่มีค่า default wording
                  ? context.wording.addPhoneNumber
                  // มีค่าแสดงแบบ format 081 123 4567
                  : _formToUi(phone.orEmpty),
              style: context.textTheme.headlineMedium!.copyWith(
                fontSize: AppDims.size_20.sp,
                color: phone.orEmpty.isEmpty
                    ? AppColors.gray500
                    : AppColors.textPrimary,
              ),
            );
          },
        ),

        IconButton(
          onPressed: () async {
            _viewModel.phoneController.text = data.phone.orEmpty;
            await _showBottomSheetDialog(context);
          },
          padding: EdgeInsets.zero,
          icon: Assets.svg.icEdit.svg(
            height: AppDims.size_16.h,
            width: AppDims.size_14.w,
          ),
        ),
      ],
    );
  }

  Future<void> _showBottomSheetDialog(BuildContext context) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
            ),
            width: double.infinity,
            child: Padding(
              padding: EdgeInsetsGeometry.all(
                AppDims.size_16.h,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    AppTextFormField(
                      controller: _viewModel.phoneController,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value.orEmpty.isEmpty ||
                            _viewModel.isValidPhoneThai(
                              value.orEmpty,
                            )) {
                          return null;
                        }
                        return dialogContext
                            .wording
                            .pleaseEnterValidEmailOrPhone;
                      },

                      decoration: InputDecoration(
                        hint: AppText(
                          context.wording.addPhoneNumber,
                          style: DefaultTextStyle.of(context).style.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        prefixIcon: SizedBox.shrink(),
                        counterText: '',
                      ),
                    ),
                    AppDims.vericalPadding_12,
                    ElevatedButton(
                      onPressed: () {
                        final phone = _viewModel.phoneController.text;
                        if (phone.orEmpty.isEmpty ||
                            _viewModel.isValidPhoneThai(phone)) {
                          _viewModel.onPhoneUpdate(phone);
                          dialogContext.safePop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDims.size_8.r,
                          ),
                        ),
                      ),
                      child: Text(
                        context.wording.save,
                        style: context.textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(
    UserModel profile,
  ) {
    // ใช้ avatarDataList ที่รวมทั้ง URL จาก API และ XFile จาก picker
    final allImages = profile.avatarDataList;

    return ValueListenableBuilder(
      valueListenable: _viewModel.currentSliderIndexNotifier,
      builder: (context, currentIndex, _) {
        return Column(
          children: [
            AppDims.vericalPadding_24,

            Stack(
              alignment: Alignment.center,
              children: [
                CarouselSlider.builder(
                  carouselController: _viewModel.carouselController,
                  itemCount: allImages.length,
                  itemBuilder: (context, index, realIndex) {
                    final isCenter = index == currentIndex;
                    final avatarData = allImages[index];
                    return _buildAvatarItem(
                      context,
                      avatarData.path,
                      isCenter: isCenter,
                      isFile: avatarData.isFromPicker,
                    );
                  },
                  options: CarouselOptions(
                    initialPage: currentIndex,
                    height: 140.h,
                    viewportFraction: 0.35,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.3,
                    enableInfiniteScroll: false,
                    onPageChanged: (index, reason) {
                      _viewModel.updateIndex = index;
                    },
                  ),
                ),
                // // Left arrow
                (currentIndex == 0)
                    ? SizedBox()
                    : Positioned(
                        left: 80.w,
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            size: AppDims.size_40.w,
                            color: AppColors.gray500,
                          ),
                          onPressed: () {
                            _viewModel.carouselController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                // // Right arrow
                Positioned(
                  right: 80.w,
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: AppDims.size_40.w,
                      color: AppColors.gray500,
                    ),
                    onPressed: () {
                      _viewModel.carouselController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDims.size_16.h),
            // Dot indicators
            _buildDotIndicators(profile, currentIndex),
          ],
        );
      },
    );
  }

  Widget _buildAvatarItem(
    BuildContext context,
    String src, {
    required bool isCenter,
    bool isFile = false,
  }) {
    final size = isCenter ? 140.0 : 85.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size.w,
          height: size.h,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.green400),
            shape: BoxShape.circle,
            image: DecorationImage(
              image: isFile
                  ? FileImage(File(src)) as ImageProvider
                  : NetworkImage(src),
              // fit: isFile ? BoxFit.cover : BoxFit.contain,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Green overlay with + icon for center image
        if (isCenter)
          Positioned(
            bottom: 15.h,
            right: 9.w,
            child: Container(
              width: AppDims.size_20.w,
              height: AppDims.size_20.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: () async {
                  await _showImageSourceBottomSheet(context);
                },
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: AppDims.size_16.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showImageSourceBottomSheet(BuildContext context) async {
    return await showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            child: Column(
              // spacing: 16.sp,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDims.vericalPadding_16,
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: AppText(
                    context.wording.gallery,
                    style: context.textTheme.labelLarge,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await _viewModel.pickImageFromGallery();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: AppText(
                    context.wording.camera,
                    style: context.textTheme.labelLarge,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await _viewModel.pickImageFromCamera();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotIndicators(
    UserModel profile,
    int currentIndex,
  ) {
    return AnimatedSmoothIndicator(
      activeIndex: currentIndex,
      count: profile.avatarDataList.length,
      effect: ScrollingDotsEffect(
        dotWidth: AppDims.size_8.w,
        dotHeight: AppDims.size_8.h,
        activeDotColor: AppColors.primary,
        dotColor: AppColors.gray400,
      ),
    );
  }

  String _formToUi(String data) {
    if (data.isEmpty) {
      return '';
    }
    if (data.length < 10) {
      return data;
    }
    final result = StringBuffer()
      ..write(data.substring(0, 3))
      ..write(' ')
      ..write(data.substring(3, 6))
      ..write(' ')
      ..write(data.substring(6, 10));

    return result.toString();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showBirthDayOffers(BuildContext context) async {
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
                                      _viewModel.titlePopupBirthDayOffers(
                                        context,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: context.textTheme.headlineLarge!
                                          .copyWith(
                                            fontSize: AppDims.size_24.sp,
                                            color: AppColors.primary,
                                          ),
                                    ),
                                    AppDims.vericalPadding_10,
                                    // ข้อความใน Popup
                                    // รายละเอียดเงื่อนไข
                                    Html(
                                      data: _viewModel
                                          .descriptionPopupBirthDayOffers(
                                            context,
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
                                      },
                                      child: AppText(
                                        context.wording.acknowledge,
                                      ),
                                    ),
                                    AppDims.vericalPadding_4,
                                    if (widget.isFirstSignup)
                                      ElevatedButton(
                                        onPressed: () {
                                          _birthDatefocusNode.requestFocus();
                                          dialogContext.safePop();
                                          _onbirthDateFieldTap();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.ci3,
                                          foregroundColor: AppColors.primary,
                                        ),
                                        child: AppText(
                                          // เปลี่ยวันเกิด
                                          context.wording.changeBirthday,
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
                  top: -45.w,
                  child: Assets.png.brownyPromotion.image(width: 250.w),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
