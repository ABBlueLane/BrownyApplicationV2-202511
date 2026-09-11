import 'package:browny_applications_new/feature/home/screens/home_page.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:browny_applications_new/res/styles/app_text_style.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/feature/authentication/repository/pin_biometric_repository.dart';
import 'package:browny_applications_new/feature/authentication/screen/biometric_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/pin_biometric_viewmodel.dart';
import 'package:browny_applications_new/feature/profile/screen/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

part 'transaction_authen_page.dart';

/// หน้าสร้างรหัส PIN 6 หลักสำหรับเข้าแอป
///
/// **การทำงาน:**
/// - ขั้นตอนที่ 1: ให้ผู้ใช้สร้างรหัส PIN 6 หลัก
/// - ขั้นตอนที่ 2: ให้ผู้ใช้กรอก PIN ซ้ำเพื่อยืนยัน
/// - ถ้า PIN ตรงกัน → บันทึกลง Secure Storage (Hashed + Salt)
/// - ถ้า PIN ไม่ตรงกัน → กลับไปขั้นตอนที่ 1
///
/// **Design:**
/// - ปุ่มย้อนกลับ (ซ้ายบน)
/// - Logo Browny (กลางบน)
/// - ข้อความ "สร้างรหัส PIN 6 หลัก" หรือ "ยืนยันรหัส PIN"
/// - วงกลม 6 วง (เติมเต็มเมื่อกรอก)
/// - Numpad 3x4 (1-9, 0, ลบ)
///
/// **Security:**
/// - ไม่เก็บ PIN จริง เก็บเฉพาะ Hash (SHA-256 + Salt)
/// - ใช้ flutter_secure_storage (Keychain/Keystore)
class CreateAppPinPage extends StatelessWidget {
  const CreateAppPinPage({
    super.key,
    required this.process,
    this.implementBackButton = true,
    this.isFirstSignup = false,
  });

  final bool implementBackButton;
  final bool isFirstSignup;
  final PinBiometricPross process;

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    bool isFirstSingup = false,
    bool implementBackButton = false,
    required PinBiometricPross process,
  }) async {
    return await context.pushNamed(
      // Transaction Create PIN
      CreateAppPinPage.pageName,
      extra: {
        CreateAppPinPage.kImplementBackButton: implementBackButton,
        // ไม่ใช้การ signup ใหม่
        CreateAppPinPage.kFirstSignup: isFirstSingup,
        // Map<Type, PinBiometricPross>
        CreateAppPinPage.kPinBiometricProcess: {
          PinBiometricPross: process,
        },
      },
    );
  }

  static void goReplacementPage<T>(
    BuildContext context, {
    bool isFirstSingup = false,
    bool implementBackButton = false,
    required PinBiometricPross process,
  }) async {
    context.pushReplacementNamed(
      // Transaction Create PIN
      CreateAppPinPage.pageName,
      extra: {
        CreateAppPinPage.kImplementBackButton: implementBackButton,
        // ไม่ใช้การ signup ใหม่
        CreateAppPinPage.kFirstSignup: isFirstSingup,
        // Map<Type, PinBiometricPross>
        CreateAppPinPage.kPinBiometricProcess: {
          PinBiometricPross: process,
        },
      },
    );
  }

  static final pagePath = '/create_app_pin';
  static final pageName = 'create_app_pin';
  static final kImplementBackButton = 'kImplementBackButton';
  static final kPinBiometricProcess = 'kPinBiometricProcess';
  static final kFirstSignup = 'first_signup';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ถ้าไม่แสดงปุ่มกลับ แสดงว่าจะไม่รองรับการ wipe ออกเหมือนกัน
      canPop: process != PinBiometricPross.create,
      child: ChangeNotifierProvider(
        create: (context) => PinBiometricViewModel(
          context: context,
          repository: PinBioMetricRepository(),
        ),
        child: _CreateAppPinContent(
          process: process,
          implementBackButton: process != PinBiometricPross.create,
          isFirstSignup: isFirstSignup,
        ),
      ),
    );
  }
}

class _CreateAppPinContent extends StatefulWidget {
  const _CreateAppPinContent({
    required this.process,
    this.implementBackButton = true,
    this.isFirstSignup = false,
  });

  final bool implementBackButton;
  final bool isFirstSignup;
  final PinBiometricPross process;

  @override
  State<_CreateAppPinContent> createState() => _CreateAppPinContentState();
}

class _CreateAppPinContentState extends State<_CreateAppPinContent> {
  late final PinBiometricViewModel _viewModel;
  bool _isCheckingExistingPin = true;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read();

    // ถ้าเป็น Login/Register → เช็ค PIN จาก server ก่อน

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // if (widget.isFirstSignup) {
      if (widget.process == PinBiometricPross.create) {
        Future.delayed(Duration(seconds: 1), _checkExistingPinFromServer);
        return;
      }
      setState(() {
        _isCheckingExistingPin = false;
      });
    });
  }

  /// ตรวจสอบว่า server มี PIN หรือไม่ (สำหรับ Login/Register)
  Future<void> _checkExistingPinFromServer() async {
    // setState(() {
    //   _isCheckingExistingPin = true;
    // });

    try {
      // ดึง PIN จาก server
      final hasPin = await _viewModel.getPinFromServer();

      if (!mounted) return;

      if (hasPin) {
        // มี PIN จาก server แล้ว → ไปหน้า Biometric ทันที
        // _navigateToBiometric();
        _onSavedPin();
      } else {
        // ไม่มี PIN → ให้ user สร้าง PIN ใหม่
        setState(() {
          _isCheckingExistingPin = false;
        });
      }
    } catch (e) {
      // เกิด error → ให้ user สร้าง PIN ใหม่
      if (mounted) {
        setState(() {
          _isCheckingExistingPin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // final viewModel = context.read<PinViewModel>();
    // viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // แสดง Loading ถ้ากำลังเช็ค PIN จาก server
    if (_isCheckingExistingPin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header: ปุ่มย้อนกลับ
            if (widget.implementBackButton) _buildHeader(context, _viewModel),

            // ระยะห่าง
            SizedBox(height: AppDims.size_32.h),

            // Logo Browny
            _buildLogo(),

            // ระยะห่าง
            SizedBox(height: AppDims.size_24.h),

            // ข้อความ Title (เปลี่ยนตาม step)
            _buildTitle(),

            // Error Message (ถ้ามี)
            _buildErrorMessage(),

            // ระยะห่าง
            SizedBox(height: AppDims.size_32.h),

            // วงกลม 6 วง แสดงสถานะการกรอก
            _buildPinIndicators(),

            // Spacer ดันส่วนล่างลงไป
            Spacer(),

            // Loading (ถ้ากำลังบันทึก)
            if (_viewModel.isLoading)
              Padding(
                padding: EdgeInsets.only(bottom: AppDims.size_24.h),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),

            // Numpad (0-9) และปุ่มลบ
            if (!_viewModel.isLoading) _buildNumpad(_viewModel),

            // ระยะห่างด้านล่าง
            SizedBox(height: AppDims.size_24.h),
          ],
        ),
      ),
    );
  }

  /// Header: ปุ่มย้อนกลับ (ซ้ายบน)
  Widget _buildHeader(BuildContext context, PinBiometricViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
        vertical: AppDims.size_8.h,
      ),
      child: Row(
        children: [
          // ปุ่มย้อนกลับ
          ElevatedButton.icon(
            onPressed: () {
              if (viewModel.step == 2) {
                // ถ้าอยู่ขั้นตอนที่ 2 → กลับไปขั้นตอนที่ 1
                viewModel.reset();
              } else if (context.canPop()) {
                context.safePop();
              }
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
          ),
        ],
      ),
    );
  }

  /// Logo Browny (กลางบน)
  Widget _buildLogo() {
    return Center(
      child: Assets.png.brownyCreatePin.image(
        width: 90.w,
        height: 90.h,
      ),
    );
  }

  /// ข้อความ Title (เปลี่ยนตาม step)
  Widget _buildTitle() {
    return Consumer<PinBiometricViewModel>(
      builder: (context, viewModel, _) {
        final title = _getTitleText(context, viewModel);

        return AppText(
          title,
          style: context.textTheme.headlineMedium!.copyWith(
            color: AppColors.textPrimary,
            // fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  /// Get title text - สามารถ override ได้
  String _getTitleText(BuildContext context, PinBiometricViewModel viewModel) {
    if (widget.process == PinBiometricPross.verify ||
        widget.process == PinBiometricPross.verifyByPin) {
      // กรอกรหัส PIN 6 หลัก
      return context.wording.enterPin6Digits;
    } else {
      return viewModel.step == 1
          ? context.wording.createNewPin
          : context.wording.confirmNewPin;
    }
  }

  /// แสดง Error Message
  Widget _buildErrorMessage() {
    return Consumer<PinBiometricViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.errorMessage == null) {
          return SizedBox();
        }

        return Padding(
          padding: EdgeInsets.only(
            left: AppDims.size_24.w,
            right: AppDims.size_24.w,
            top: AppDims.size_16.w,
          ),
          child: AppText(
            viewModel.errorMessage!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  /// วงกลม 6 วง แสดงสถานะการกรอก PIN
  Widget _buildPinIndicators() {
    return Consumer<PinBiometricViewModel>(
      builder: (context, viewModel, _) {
        final currentPin = viewModel.step == 1
            ? viewModel.pin
            : viewModel.confirmPin;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            PinBiometricViewModel.pinLength,
            (index) {
              final isFilled = index < currentPin.length;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                width: 20.w,
                height: 20.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Numpad: ปุ่มตัวเลข 0-9 และปุ่มลบ
  Widget _buildNumpad(PinBiometricViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDims.size_32.w),
      child: Column(
        children: [
          // แถวที่ 1: 1 2 3
          _buildNumpadRow(viewModel, ['1', '2', '3']),
          SizedBox(height: AppDims.size_16.h),

          // แถวที่ 2: 4 5 6
          _buildNumpadRow(viewModel, ['4', '5', '6']),
          SizedBox(height: AppDims.size_16.h),

          // แถวที่ 3: 7 8 9
          _buildNumpadRow(viewModel, ['7', '8', '9']),
          SizedBox(height: AppDims.size_16.h),

          // แถวที่ 4: ว่าง 0 ลบ
          _buildNumpadRow(viewModel, ['', '0', 'delete']),
        ],
      ),
    );
  }

  /// สร้างแถวของ Numpad (3 ปุ่ม)
  Widget _buildNumpadRow(
    PinBiometricViewModel viewModel,
    List<String> numbers,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          // ช่องว่าง
          return Expanded(child: SizedBox());
        } else if (number == 'delete') {
          // ปุ่มลบ
          return Expanded(
            child: _buildNumpadButton(
              onTap: () => viewModel.removeDigit(),
              child: Assets.svg.icBackspace.svg(
                width: 20.w,
                height: 20.h,
              ),
            ),
          );
        } else {
          // ปุ่มตัวเลข
          return Expanded(
            child: _buildNumpadButton(
              onTap: () => viewModel.addDigit(number, _onSavedPin),
              child: AppText(
                number,
                style: AppTextNumberStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  void _onSavedPin() {
    // on Saved - ตรวจสอบว่า Device รองรับ Biometric หรือไม่
    AppOverlays.showLoading(context);
    _viewModel.isBiometricAvailable().then((available) {
      AppOverlays.hideLoading();

      if (!mounted) return;

      if (available) {
        // รองรับ Biometric → ไปหน้า Biometric
        context.pushReplacementNamed(
          BiometricPage.pageName,
          extra: {
            BiometricPage.kFirstSignup: widget.isFirstSignup,
          },
        );
      } else {
        // ถ้ามาจากการสมัครสมาชิก จะไปหน้า setup profile ต่อ แต่ถ้ามาจาก Login
        // จะ pop ออก
        if (widget.isFirstSignup) {
          // ไม่รองรับ → ไป Profile ทันที
          context.pushNamedAndClear(
            ProfilePage.pageName,
            extra: {
              ProfilePage.kFirstSignup: widget.isFirstSignup,
            },
          );
        } else {
          context.safePop();
        }
      }
    });
  }

  /// สร้างปุ่ม Numpad (วงกลมใส, กดแล้วมี ripple effect สีเขียว)
  Widget _buildNumpadButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Center(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.checkboxSelectedBg,
        borderRadius: BorderRadius.circular(40.r),
        child: Container(
          width: 80.w,
          height: 80.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
