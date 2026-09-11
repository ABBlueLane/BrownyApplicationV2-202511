import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:browny_applications_new/res/styles/app_text_style.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/authentication/repository/pin_biometric_repository.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/pin_biometric_viewmodel.dart';
import 'package:browny_applications_new/feature/profile/screen/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// หน้าตั้งค่าเปิดใช้งาน Biometric
///
/// **การทำงาน:**
/// - แสดง UI สำหรับให้ผู้ใช้เลือกเปิดใช้งาน Biometric
/// - ถ้าผู้ใช้กดยืนยัน → เปิดใช้งาน Biometric → Navigate to Profile
/// - ถ้าผู้ใช้กดข้าม → Navigate to Profile ทันที
///
/// **Security:**
/// - ต้องมี PIN ตั้งไว้ก่อนถึงจะเปิด Biometric ได้
/// - บันทึกลง Secure Storage
class BiometricPage extends StatelessWidget {
  const BiometricPage({
    super.key,
    this.isFirstSignup = false,
  });

  final bool isFirstSignup;

  static final kFirstSignup = 'first_signup';
  static final pagePath = '/biometric';
  static final pageName = 'biometric';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PinBiometricViewModel(
        context: context,
        repository: PinBioMetricRepository(),
      ),
      child: _BiometricContent(
        isFirstSignup: isFirstSignup,
      ),
    );
  }
}

class _BiometricContent extends StatefulWidget {
  const _BiometricContent({
    this.isFirstSignup = false,
  });

  final bool isFirstSignup;

  @override
  State<_BiometricContent> createState() => _BiometricContentState();
}

class _BiometricContentState extends State<_BiometricContent> {
  late final PinBiometricViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read();
    _viewModel.attachContext(context);
  }

  /// เปิดใช้งาน Biometric
  Future<void> _enableBiometric() async {
    AppOverlays.showLoading(context);

    try {
      final success = await _viewModel.setBiometricEnabled(true);

      if (!mounted) return;

      AppOverlays.hideLoading();

      if (success) {
        final authenBiometricResult = await _viewModel
            .authenticateWithBiometric();

        if (!mounted) return;

        if (authenBiometricResult.isSuccess) {
          // Navigate to Profile
          // context.pushNamedAndClear(ProfilePage.pageName);
          if (widget.isFirstSignup) {
            ProfilePage.goToPage(context, isFirstSignup: true);
            // context.pushNamed(
            //   ProfilePage.pageName,
            //   extra: {
            //     ProfilePage.kFirstSignup: true,
            //   },
            // );
          } else {
            context.safePop();
          }
        }
      } else {
        // แสดง Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(context.wording.cannotEnableBiometric),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppOverlays.hideLoading();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(context.wording.errorOccurred),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// ข้ามการตั้งค่า Biometric
  void _skipBiometric() {
    if (widget.isFirstSignup) {
      context.pushNamedAndClear(ProfilePage.pageName);
    } else {
      context.safePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header: ปุ่มย้อนกลับ
            // _buildHeader(),

            // Spacer
            SizedBox(height: AppDims.size_24.h),

            // Icon Biometric (Face ID + Fingerprint)
            _buildBiometricIcon(),

            SizedBox(height: AppDims.size_24.h),

            // Title: "เปิดการใช้งานด้วย Biometric"
            _buildTitle(),

            SizedBox(height: AppDims.size_32.h),

            // ปุ่มยืนยัน (สีเขียว)
            _buildConfirmButton(),

            SizedBox(height: AppDims.size_16.h),

            // ข้อความ "ข้าม"
            _buildSkipButton(),

            SizedBox(height: AppDims.size_24.h),
          ],
        ),
      ),
    );
  }

  /// Icon Biometric (Face ID + Fingerprint)
  Widget _buildBiometricIcon() {
    return Center(
      child: Assets.svg.icBiometric.svg(
        width: AppDims.size_100.w,
        height: AppDims.size_100.h,
      ),
    );
  }

  /// Title: "เปิดการใช้งานด้วย Biometric"
  Widget _buildTitle() {
    return AppText(
      context.wording.enableBiometric,
      style: context.textTheme.headlineMedium!.copyWith(
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// ปุ่มยืนยัน (สีเขียว)
  Widget _buildConfirmButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDims.size_24.w),
      child: SizedBox(
        width: double.infinity,
        height: AppDims.size_40.h,
        child: ElevatedButton(
          onPressed: _enableBiometric,
          child: AppText(
            context.wording.confirm,
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// ข้อความ "ข้าม" (ด้านล่าง)
  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _skipBiometric,
      child: AppText(
        context.wording.skip,
        style: context.textTheme.labelLarge!.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
