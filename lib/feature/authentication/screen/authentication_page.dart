// ignore_for_file: unused_element_parameter

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/utils/social_auth_helper.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/pin_biometric_viewmodel.dart';
import 'package:browny_applications_new/feature/contacts/repository/contact_repo.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:browny_applications_new/feature/authentication/screen/app_pin_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/authentication_viewmodel.dart';
import 'package:flutter/gestures.dart';
import 'package:pinput/pinput.dart';

/// หน้าหลักสำหรับการ Authentication (Login, Sign Up, Forgot Password, OTP)
///
/// ใช้ PageView เพื่อจัดการหลายหน้าภายใน widget เดียว
/// - รักษา state ของ ViewModel ตลอดการทำงาน (SharedViewModel pattern)
/// - ใช้ PageController ควบคุมการเปลี่ยนหน้าแทน navigation routing
/// - Background, Logo, และปุ่ม Back ใช้ร่วมกันทุกหน้า
class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({
    super.key,
    required AuthenProcess authenProcess,
  }) : _authenProcess = authenProcess;

  static final pagePath = '/authentication_page';
  static final pageName = 'authentication';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    required AuthenProcess process,
  }) async {
    if (context.read<CustomerProvider>().current.isGuest) {
      if ([
        AuthenProcess.changePassword,
        AuthenProcess.forgotPassword,
      ].contains(process)) {
        return await context.pushNamed(
          AuthenticationPage.pageName,
          extra: {
            AuthenProcess: AuthenProcess.login,
          },
        );
      }
    }
    return await context.pushNamed(
      AuthenticationPage.pageName,
      extra: {
        AuthenProcess: process,
      },
    );
  }

  final AuthenProcess _authenProcess;

  @override
  Widget build(BuildContext context) {
    // สร้าง ViewModel และ provide ให้ทั้ง widget tree
    return ChangeNotifierProvider(
      create: (context) => AuthenticationViewModel(
        context: context,
        authenProcess: _authenProcess,
        customerDataRepo: CustomerDataRepo(),
        contactRepo: ContactRepo(),
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: _AuthenticationWidget(),
      ),
    );
  }
}

class _AuthenticationWidget extends StatefulWidget {
  const _AuthenticationWidget();

  @override
  State<_AuthenticationWidget> createState() => _AuthenticationWidgetState();
}

class _AuthenticationWidgetState extends State<_AuthenticationWidget> {
  late final AuthenticationViewModel _viewmodel;

  @override
  void initState() {
    super.initState();
    _viewmodel = context.read();
    _viewmodel.attachContext(context);
    // เริ่มต้น PageController พร้อมกับกำหนดหน้าเริ่มต้นตาม authenProcess
    _viewmodel.initializePageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Layer 1: พื้นหลัง Gradient
              _buildGradientBackground(),

              // Layer 2: Container พื้นหลังสีขาวโค้งมน (ด้านล่าง 70%)
              _buildWhiteContainer(constraints),

              // Layer 3: PageView - เนื้อหาของแต่ละหน้า
              _buildPageView(),

              // Layer 4: ปุ่ม Back (บนสุด เพื่อให้กดได้)
              _buildBackButton(),
            ],
          );
        },
      ),
    );
  }

  /// สร้างพื้นหลัง Gradient ร่วมกันทุกหน้า
  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
    );
  }

  /// สร้าง Container สีขาวโค้งมนด้านล่าง (70% ของหน้าจอ)
  /// เป็น background สำหรับเนื้อหาของ PageView
  Widget _buildWhiteContainer(BoxConstraints constraints) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _viewmodel.currentPageIndex,
            builder: (context, pageIndex, _) {
              if (_viewmodel.currentProcess == AuthenProcess.referral) {
                return Assets.png.logoReferral.image(
                  width: 278.w,
                  fit: BoxFit.cover,
                );
              }
              return Padding(
                padding: EdgeInsets.only(bottom: AppDims.size_20.h),
                child: Assets.png.brownyHorizaontal.image(
                  width: 278.w,
                  height: 122.h,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          AppContainerRadius(
            height: constraints.maxHeight * 0.70,
            child: SizedBox(), // ไม่ใส่เนื้อหา เพราะ PageView จะอยู่ด้านบน
          ),
        ],
      ),
    );
  }

  /// สร้าง PageView สำหรับแสดงหน้าต่างๆ
  /// - ห้าม swipe (ใช้ NeverScrollableScrollPhysics)
  /// - เปลี่ยนหน้าผ่าน ViewModel เท่านั้น
  Widget _buildPageView() {
    return PageView(
      controller: _viewmodel.pageController,
      physics: NeverScrollableScrollPhysics(), // ปิดการ swipe
      onPageChanged: (index) {
        // อัพเดท currentPageIndex เมื่อหน้าเปลี่ยน
        _viewmodel.currentPageIndex.value = index;
      },
      children: AuthenProcess.values.map<Widget>((e) {
        switch (e) {
          case AuthenProcess.login:
            // หน้า 0
            return _LoginWidget();

          case AuthenProcess.signup:
            // หน้า 1
            return _SignUpWidget();

          case AuthenProcess.signupOTP:
            // หน้า 2 (OTP สำหรับ Sign Up)
            return _OTPWidget();

          case AuthenProcess.forgotPassword:
            // หน้า 3
            return _ForgotPasswordWidget();

          case AuthenProcess.forgotPasswordOTP:
            // หน้า 4 (OTP สำหรับ ForgotPassword)
            return _ForgotPasswordOTPWidget();

          case AuthenProcess.forgotPasswordNewPassword:
            // หน้า 5 Reset Password
            return _ResetPasswordWidget();

          case AuthenProcess.referral:
            return _ReferralWidget();

          // default:
          //   return SizedBox();
          case AuthenProcess.changePassword:
            // หน้าสำหรับเปลี่ยนรหัสผ่าน
            return _ChangePasswordWidget();
          case AuthenProcess.changePasswordOTP:
            // หน้าสำหรับกรอก OTP
            return _ChangePasswordOTPWidget();
          case AuthenProcess.changePasswordNewPassword:
            // หน้าสำหรับกรอกรหัสผ่านเก่าและรหัสผ่านใหม่
            return _ChangePasswordNewPasswordWidget();
        }
      }).toList(),
    );
  }

  /// สร้างปุ่ม Back แบบ Smart
  /// - ถ้าไม่ใช่หน้าแรกใน PageView → กดแล้วย้อนกลับหน้าก่อน (goBack)
  /// - ถ้าเป็นหน้าแรก → กดแล้ว pop ออกจากหน้านี้ (context.pop)
  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _viewmodel.currentPageIndex,
          builder: (context, pageIndex, _) {
            return ElevatedButton.icon(
              icon: Icon(
                Icons.arrow_back_ios_new,
              ),
              onPressed: () {
                if (_viewmodel.canGoBack) {
                  // กรณีไม่ใช่หน้าแรก → ย้อนกลับหน้าก่อนใน PageView
                  _viewmodel.goBack();
                } else {
                  // กรณีเป็นหน้าแรก → ออกจากหน้านี้
                  if (context.canPop()) {
                    context.safePop();
                  }
                }
              },
              label: AppText(context.wording.back),
              style: AppElevatedButtonStyle.buttomBackStyle.copyWith(
                minimumSize: WidgetStatePropertyAll(Size(50.w, 40.h)),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Base Widget สำหรับหน้า Authentication ทั้งหมด (Sign Up, Login, Forgot Password)
///
/// **โครงสร้างของหน้า:**
/// - เนื้อหาหลักแสดงในส่วนล่าง 70% ของหน้าจอ (ตรงกับ AppContainerRadius)
/// - ปรับ padding ด้านล่างอัตโนมัติเมื่อ keyboard แสดง (MediaQuery.viewInsets.bottom)
/// - ใช้ SingleChildScrollView เพื่อให้ scroll ได้เมื่อเนื้อหาเกิน
///
/// **ส่วนประกอบเนื้อหา:**
/// - Title และ Description (override ได้ใน subclass)
/// - Form กรอกข้อมูล (Email/Phone, Password, Checkbox)
/// - ปุ่ม Submit (เปิดใช้งานเมื่อ validation ผ่าน)
/// - ปุ่มลืมรหัสผ่าน (แสดงเฉพาะบางหน้า - override ได้)
/// - Social Login (Facebook, Google, Apple, Line)
/// - ข้อความชวนสมัครสมาชิก (แสดงเฉพาะบางหน้า - override ได้)
///
/// **การใช้งาน:**
/// - Extend class นี้สำหรับแต่ละหน้า (Login, Sign Up, Forgot Password)
/// - Override methods ที่จำเป็น เช่น contentButtonSummit, listOfFormAuth
/// - ใช้ helper methods: goToProcess(), viewmodel()
class _SignUpWidget extends StatelessWidget {
  const _SignUpWidget();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return buildContent(constrainedBox, context);
      },
    );
  }

  /// Helper: Navigate ไปยัง Process ที่กำหนด (ควบคุมการเปลี่ยนหน้าใน PageView)
  @protected
  void goToProcess(
    BuildContext context,
    AuthenProcess process, {
    bool animate = true,
  }) {
    context.read<AuthenticationViewModel>().goToProcess(
      process,
      animate: animate,
    );
  }

  /// Helper: เข้าถึง AuthenticationViewModel จาก context
  @protected
  AuthenticationViewModel viewmodel(BuildContext context) =>
      context.read<AuthenticationViewModel>();

  /// สร้างเนื้อหาหลักของหน้า (ด้านล่าง 70%)
  /// - จัดการ keyboard padding อัตโนมัติ
  /// - แสดง Title, Description, Form, Buttons ตามลำดับ
  @protected
  Widget buildContent(BoxConstraints constrainedBox, BuildContext context) {
    final vm = viewmodel(context);
    // ระยะที่ keyboard ดันขึ้นมา (เพื่อยก content ขึ้นให้เห็น TextField)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: constrainedBox.maxHeight * 0.70, // 70% ของหน้าจอ
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDims.size_24.w,
              vertical: AppDims.size_24.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวเรื่อง (เช่น "สมัครสมาชิก")
                  contentTitle(context, wording: context.wording.signUpTitle),

                  // คำอธิบาย (เช่น "กรอกข้อมูลเพื่อสมัครสมาชิก")
                  contentDescription(
                    context,
                    wording: context.wording.signUpDescription,
                  ),
                  AppDims.vericalPadding_24,

                  // ฟอร์มกรอกข้อมูล (Email/Phone, Password, Checkbox)
                  contentFormField(
                    context,
                    vm,
                    children: listOfFormAuth(context, vm),
                  ),
                  AppDims.vericalPadding_10,

                  // ปุ่ม Submit (สมัครสมาชิก/เข้าสู่ระบบ/ส่งรหัส OTP)
                  contentButtonSummit(context),
                  AppDims.vericalPadding_12,

                  // ปุ่มลืมรหัสผ่าน (แสดงเฉพาะหน้า Login)
                  contentButtonForgotPassword(context),
                  AppDims.vericalPadding_12,

                  // เส้นคั่น + ข้อความ "สมัครด้วย..."
                  contentSocialLoginSeparator(context),
                  AppDims.vericalPadding_20,

                  // ปุ่ม Social Login (Facebook, Google, Apple, Line)
                  contentSocialLogin(context),
                  AppDims.vericalPadding_20,

                  // ข้อความชวนสมัครสมาชิก (แสดงเฉพาะหน้า Login)
                  contentSignUpCheering(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ปุ่มลืมรหัสผ่าน (แสดงเฉพาะหน้า Login)
  /// - Default: ไม่แสดง
  /// - Override ใน _LoginWidget เพื่อแสดง
  @protected
  Widget contentButtonForgotPassword(BuildContext context) {
    return SizedBox();
  }

  /// ข้อความชวนสมัครสมาชิก (แสดงเฉพาะหน้า Login)
  /// - Default: ไม่แสดง
  /// - Override ใน _LoginWidget เพื่อแสดงข้อความ "ยังไม่มีบัญชีหรอ? สมัครเลย"
  @protected
  Widget contentSignUpCheering(BuildContext context) {
    return SizedBox();
  }

  /// ปุ่ม Social Login (Facebook, Google, Apple, Line)
  /// - แสดงเป็นแถวเดียว 4 ปุ่ม
  /// - กดแล้วยังไม่มีการทำงาน (TODO)
  @protected
  Widget contentSocialLogin(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () async {
            await _socialLogin(context, SocialLoginType.FACEBOOK);
          },
          icon: Assets.png.icFacebook.image(
            width: AppDims.size_26.w,
            height: AppDims.size_26.h,
          ),
        ),
        IconButton(
          onPressed: () async {
            await _socialLogin(context, SocialLoginType.GOOGLE);
          },
          icon: Assets.png.icGoogle.image(
            width: AppDims.size_26.w,
            height: AppDims.size_26.h,
          ),
        ),
        IconButton(
          onPressed: () async {
            await _socialLogin(context, SocialLoginType.Apple);
          },
          icon: Assets.png.icApple.image(
            width: AppDims.size_26.w,
            height: AppDims.size_26.h,
          ),
        ),
        IconButton(
          onPressed: () async {
            await _socialLogin(context, SocialLoginType.LINE);
          },
          icon: Assets.png.icLine.image(
            width: AppDims.size_26.w,
            height: AppDims.size_26.h,
          ),
        ),
      ],
    );
  }

  Future<void> _socialLogin(BuildContext context, SocialLoginType type) async {
    AppOverlays.showLoading(context);
    final loginResult = await viewmodel(context).socialLogin(type);
    if (!context.mounted) return;

    if (loginResult.isEmpty || loginResult.hasError) {
      _showErrorDialog(context, loginResult.error);
      return;
    }

    AppOverlays.hideLoading();
    // ถ้าเป็นการ Logic ครั้งแรก ต้องเข้าหน้ากรอกเพื่อนชวนเพื่อน
    if (loginResult.data!.firstLogin == true) {
      final referralEnabled = await viewmodel(context).isReferralEnabled();
      if (!context.mounted) return;
      if (referralEnabled) {
        viewmodel(context).goToProcess(AuthenProcess.referral, animate: false);
      } else {
        CreateAppPinPage.goReplacementPage(
          context,
          isFirstSingup: true,
          process: PinBiometricPross.create,
        );
      }
    } else {
      CreateAppPinPage.goReplacementPage(
        context,
        isFirstSingup: loginResult.data!.firstLogin == true,
        process: PinBiometricPross.create,
      );
      // context.pushReplacementNamed(
      //   // Signup
      //   CreateAppPinPage.pageName,
      //   extra: {
      //     CreateAppPinPage.kImplementBackButton: false,
      //     CreateAppPinPage.kFirstSignup: loginResult.data!.firstLogin == true,
      //     // Map<Type, PinBiometricPross>
      //     CreateAppPinPage.kPinBiometricProcess: {
      //       PinBiometricPross: PinBiometricPross.create,
      //     },
      //     // CreateAppPinPage.kFirstSignup: true,
      //   },
      // );
    }
  }

  @protected
  Key getFormKey(BuildContext context) => viewmodel(context).formKeySignup;

  /// สร้าง Form สำหรับกรอกข้อมูล
  /// - รับ List ของ Widget (children) ที่จะแสดงใน Column
  /// - ไม่ใช้ GlobalKey เพราะหลาย Widget อยู่ใน PageView พร้อมกัน (จะ Duplicate GlobalKey)
  /// - แทนที่จะใช้ autovalidateMode และ validator ใน TextFormField แทน
  @protected
  Form contentFormField(
    BuildContext context,
    AuthenticationViewModel vm, {
    required List<Widget> children,
  }) {
    return Form(
      key: getFormKey(context),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// สร้าง List ของ Widget สำหรับใช้ในฟอร์ม
  /// - ช่องกรอกอีเมล/เบอร์โทรศัพท์
  /// - ช่องกรอกรหัสผ่าน (พร้อมปุ่มแสดง/ซ่อน)
  /// - Checkbox ยอมรับข้อตกลง
  ///
  /// Override ใน subclass ถ้าต้องการเปลี่ยนแปลง field ที่แสดง
  @protected
  List<Widget> listOfFormAuth(
    BuildContext context,
    AuthenticationViewModel vm,
  ) => [
    textFormFieldEmailOrPhone(context),
    AppDims.vericalPadding_12,
    textFormFieldPasswordWithObscure(context),
    contentCheckboxTermOfPolicy(context),
  ];

  /// ช่องกรอกรหัสผ่าน พร้อมปุ่มแสดง/ซ่อนรหัสผ่าน
  /// - ใช้ Consumer + ValueListenableBuilder เพื่อ update UI เมื่อ obscure เปลี่ยน
  /// - มี validator และ onChange callback
  @protected
  Widget textFormFieldPasswordWithObscure(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.isObscure,
          builder: (context, isObscured, _) {
            return AppTextFormField(
              controller: vm.passwordController,
              textInputAction: TextInputAction.done,
              obscureText: isObscured,
              decoration: InputDecoration(
                hint: AppText(
                  context.wording.password,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                prefixIcon: SizedBox.shrink(),
                suffixIcon: IconButton(
                  onPressed: vm.onObscureChange,
                  icon: isObscured
                      ? Assets.svg.icObscureOff.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        )
                      : Assets.svg.icObscureOn.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        ),
                ),
              ),
              autovalidateMode: AutovalidateMode.onUnfocus,
              validator: (value) => getValidatorPassword(context, value),
              onChanged: vm.validatorPassword,
            );
          },
        );
      },
    );
  }

  /// Validator สำหรับรหัสผ่าน (เรียกผ่าน ViewModel)
  String? getValidatorPassword(BuildContext context, String? value) =>
      viewmodel(context).validatorPassword(value);

  /// ช่องกรอกอีเมลหรือเบอร์โทรศัพท์
  /// - ใช้ Consumer เพื่อเข้าถึง ViewModel
  /// - มี validator และ onChange callback
  @protected
  Widget textFormFieldEmailOrPhone(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return AppTextFormField(
          controller: vm.usernameController, // signUp
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hint: AppText(
              context.wording.emailOrPhone,
              style: DefaultTextStyle.of(context).style.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            prefixIcon: SizedBox.shrink(),
          ),
          autovalidateMode: AutovalidateMode.onUnfocus,
          validator: (value) => getValidatorEmailOrPhone(context, value),
          onChanged: vm.validatorEmailOrPhone,
        );
      },
    );
  }

  /// Validator สำหรับอีเมล/เบอร์โทร (เรียกผ่าน ViewModel)
  String? getValidatorEmailOrPhone(BuildContext context, String? value) =>
      viewmodel(context).validatorEmailOrPhone(value);

  /// เส้นคั่นแนวนอน + ข้อความตรงกลาง "สมัครด้วย..." หรือ "เข้าสู่ระบบด้วย..."
  /// - ใช้แบ่งระหว่างฟอร์มกับ Social Login
  @protected
  Widget contentSocialLoginSeparator(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.productStroke)),
        Expanded(
          child: Center(
            child: AppText(
              wordingAlternateAuthen(context),
              style: DefaultTextStyle.of(context).style.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.productStroke)),
      ],
    );
  }

  /// ข้อความสำหรับ Social Login (เช่น "สมัครด้วย", "เข้าสู่ระบบด้วย")
  /// - Override ใน subclass เพื่อเปลี่ยนข้อความตาม Process
  @protected
  String wordingAlternateAuthen(BuildContext context) =>
      context.wording.signUpWith;

  /// ปุ่ม Submit สำหรับแต่ละ Process
  /// - Login: เรียก vm.onLogin()
  /// - Sign Up: เรียก vm.onSignUp()
  /// - Forgot Password: เรียก vm.onForgotPassword()
  ///
  /// เปิดใช้งานเมื่อ validation ผ่าน (vm.validatorTriggle)
  /// Override ใน subclass เพื่อเปลี่ยน logic
  @protected
  Widget contentButtonSummit(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.validatorTriggle, // Signup
          builder: (context, isValid, _) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid
                    ? () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        AppOverlays.showLoading(context);
                        // Signup
                        vm.onSummitForm().then((result) {
                          if (!context.mounted) return;
                          AppOverlays.hideLoading();

                          if (result.hasError) {
                            _showErrorDialog(
                              context,
                              result.error,
                            );
                            return;
                          }

                          if (result.isEmpty) {
                            return;
                          }
                          // สำเร็จ → ไปหน้ากรอก OTP
                          goToProcess(context, AuthenProcess.signupOTP);
                        });
                      }
                    : null,
                child: AppText(context.wording.signUp),
              ),
            );
          },
        );
      },
    );
  }

  /// แสดง Error Dialog
  /// - ถ้าเป็น AuthenExceptions → แสดงข้อความที่ถูกต้อง
  /// - ถ้าไม่ใช่ → แสดงข้อความ error ทั่วไป
  void _showErrorDialog(BuildContext context, dynamic error) {
    AppOverlays.hideLoading();
    // final message = error is AuthenExceptions
    //     ? error.toUiMessage(context)
    //     : context.wording.errorUi;

    AppOverlays.showBrownyErrorDialog(
      context,
      title: context.wording.somethingWrong,
      error: error,
      confirmText: context.wording.tryAgain,
    );
  }

  /// Checkbox สำหรับยอมรับข้อตกลงและนโยบายความเป็นส่วนตัว
  /// - แสดงเฉพาะหน้า Sign Up
  @protected
  Widget contentCheckboxTermOfPolicy(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return FutureBuilder(
          future: vm.fetchTermsLink(),
          builder: (context, snapShot) {
            if (!snapShot.hasData) {
              return SizedBox(
                width: AppDims.size_12.w,
                child: CircularProgressIndicator(),
              );
            }
            final link = snapShot.data?.data?.registerTermsLink;
            return _CheckBoxTermOfPolicy(
              initialValue: vm.checkBoxTermOfPolicy,
              onChanged: vm.checkboxTermOfPolicyChanged,
              onTermsTap: () async {
                final launched = await LaunchHelper.openUrlInWebView(
                  link.orEmpty,
                );
                if (context.mounted && !launched) {
                  AppOverlays.showBrownyDialog(
                    context,
                    title: context.wording.errorOccurred,
                    // ข้อมูลติดต่อไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง
                    message: context.wording.invalidContactInfoError,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  /// หัวเรื่อง (เช่น "สมัครสมาชิก", "เข้าสู่ระบบ")
  @protected
  Widget contentTitle(BuildContext context, {required String wording}) {
    return AppText(
      wording,
      style: context.textTheme.titleLarge!.copyWith(
        fontSize: AppDims.size_24.sp,
      ),
    );
  }

  /// คำอธิบายใต้หัวเรื่อง
  @protected
  Widget contentDescription(BuildContext context, {required String wording}) {
    return AppText(
      wording,
      style: context.textTheme.bodyMedium!.copyWith(
        // ใช้ bodyMedium แต่เปลี่ยนสี Text
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// หน้ากรอก OTP (One-Time Password) สำหรับยืนยันตัวตน
///
/// **การทำงาน:**
/// - แสดงหลังจากผู้ใช้สมัครสมาชิกหรือลืมรหัสผ่าน
/// - เริ่ม OTP Timer ทันทีที่หน้าแสดง (วทีing.addPostFrameCallback)
/// - ให้ผู้ใช้กรอก PIN 6 หลัก (ใช้ Pinput widget)
/// - แสดง username ที่ปิดบัง (เช่น "09****1234")
/// - มีปุ่มขอ OTP ใหม่ (เปิดใช้งานเมื่อ Timer หมด)
/// - แสดงรหัสอ้างอิง (Reference Code) สำหรับติดต่อ Support
///
/// **ส่วนประกอบ:**
/// - Title และ Description พร้อม username ที่ปิดบัง
/// - PIN Input (6 หลัก)
/// - Reference Code
/// - ปุ่มขอ OTP ใหม่ / Timer นับถอยหลัง
/// - ปุ่ม Submit (ยังไม่ทำงาน - TODO)
class _OTPWidget extends StatefulWidget {
  const _OTPWidget();

  @override
  State<_OTPWidget> createState() => _OTPWidgetState();
}

class _OTPWidgetState extends State<_OTPWidget> {
  @override
  void initState() {
    super.initState();

    // เริ่ม OTP Timer เมื่อหน้าแสดง (หลัง build เสร็จ)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppOverlays.showLoading(context);
      await context.read<AuthenticationViewModel>().startOtpTimer();

      AppOverlays.hideLoading();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _OTPContent();
  }
}

/// DONG 2025-12-06
///
/// แยก Pin input Widget ออกมาอยู่เป็น child ของ [_OTPWidget] แก้ปัญหา
/// เวลาคีย์บอร์ดแสดงขึ้นบนหน้าจอ [_OTPContent] จะถูก rebuild ส่งผลให้ call API
/// OTP รัวๆ
class _OTPContent extends _SignUpWidget {
  const _OTPContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return _buildContent(constrainedBox, context);
      },
    );
  }

  /// สร้างเนื้อหาหลักของหน้า OTP (ต่างจาก _SignUpWidget)
  /// - ไม่ใช้ buildContent() เพราะโครงสร้างแตกต่างกัน
  /// - Layout พิเศษสำหรับ PIN Input
  Widget _buildContent(BoxConstraints constrainedBox, BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: constrainedBox.maxHeight * 0.70, // 70% ของหน้าจอ
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDims.size_24.w,
              vertical: AppDims.size_24.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวเรื่อง "ยืนยันรหัส OTP"
                  AppText(
                    // context.wording.confirmOTP,
                    // ยืนยัน OTP สำหรับสมัครบัญชี
                    // ยืนยันรหัสใช้ครั้งเดียว (OTP)
                    viewmodel(context).otpTitleByState,
                    style: context.textTheme.titleLarge!.copyWith(
                      fontSize: AppDims.size_24.sp,
                    ),
                  ),
                  AppDims.vericalPadding_8,

                  // คำอธิบาย + username ที่ปิดบัง
                  Consumer<AuthenticationViewModel>(
                    builder: (context, vm, _) {
                      return AppText(
                        '${context.wording.confirmOTPDescription} ${vm.usernameObscure}',
                        style: context.textTheme.bodyMedium!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                  AppDims.vericalPadding_32,

                  ValueListenableBuilder(
                    valueListenable: viewmodel(
                      context,
                    ).verifyOTPMessageErrorNotifier,
                    builder: (context, value, _) {
                      // PIN Input (OTP 6 หลัก)
                      return _PinputWidget(
                        forceErrorState: value != null,
                        onCompleted: (pin) async {
                          await onPinComplete(context, pin);
                        },
                      );
                    },
                  ),
                  AppDims.vericalPadding_24,

                  // ปุ่ม Submit
                  ValueListenableBuilder(
                    valueListenable: viewmodel(context).otpButtonNextNotifier,
                    builder: (context, value, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: value
                              ? () async {
                                  await _summitOtp(context);
                                }
                              : null,
                          child: AppText(context.wording.next),
                        ),
                      );
                    },
                  ),
                  AppDims.vericalPadding_24,

                  // รหัสอ้างอิง (Reference Code)
                  // TODO: Refactor to use context.wording - needs dynamic string with variable
                  ValueListenableBuilder(
                    valueListenable: viewmodel(context).requestOtpNotifier,
                    builder: (context, value, _) {
                      return Center(
                        child: AppText(
                          ContentLocalizeData(
                            en: 'Referral Code ${value.refCode}',
                            zh: '推荐码 ${value.refCode}',
                            th: 'รหัสอ้างอิง ${value.refCode}',
                          ).getTextByLocale(context.languageCode),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                  AppDims.vericalPadding_4,

                  // ปุ่มขอ OTP ใหม่ / Timer นับถอยหลัง
                  Center(child: _buildResendOtpButton(context)),
                  AppDims.vericalPadding_4,

                  // Text message ถ้า Error
                  ValueListenableBuilder(
                    valueListenable: viewmodel(
                      context,
                    ).verifyOTPMessageErrorNotifier,
                    builder: (context, value, _) {
                      if (value == null) return const SizedBox();

                      return Center(
                        child: AppText(
                          value,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      );
                    },
                  ),
                  AppDims.vericalPadding_32,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onPinComplete(BuildContext context, String pin) async {
    AppOverlays.showLoading(context);
    final validateResult = await viewmodel(
      context,
    ).verifyOTP(pin);

    if (!context.mounted) return;

    if (validateResult.hasError) {
      AppOverlays.hideLoading();
      // _showErrorDialog(context, validateResult.error!);
      return;
    }
    AppOverlays.hideLoading();
    // auto call ปุ่มต่อไป
    await _summitOtp(context);
  }

  Future<void> _summitOtp(BuildContext context) async {
    AppOverlays.showLoading(context);
    final result = await viewmodel(context).onSummitForm();
    if (!context.mounted) return;
    AppOverlays.hideLoading();

    if (result.hasError) {
      _showErrorDialog(context, result.error);
      return;
    }
    if (result.isEmpty) return;

    final referralEnabled = await viewmodel(context).isReferralEnabled();
    if (!context.mounted) return;

    if (referralEnabled) {
      goToProcess(context, AuthenProcess.referral);
    } else {
      CreateAppPinPage.goReplacementPage(
        context,
        isFirstSingup: true,
        process: PinBiometricPross.create,
      );
    }
  }

  /// ปุ่มขอ OTP ใหม่ / แสดง Timer นับถอยหลัง
  /// - ถ้า canResendOtp = true → แสดงปุ่ม "ขอรหัสใหม่"
  /// - ถ้า canResendOtp = false → แสดง "ขอรหัสใหม่ใน X วินาที"
  Widget _buildResendOtpButton(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.canResendOtp,
          builder: (context, canResend, _) {
            if (canResend) {
              // แสดงปุ่มกด "ขอรหัสใหม่"
              return TextButton(
                onPressed: vm.resendOtp,
                style: context.appTheme.textButtonTheme.style!.copyWith(
                  foregroundColor: WidgetStatePropertyAll(AppColors.primary),
                  textStyle: WidgetStatePropertyAll(
                    context.textTheme.bodyMedium,
                  ),
                ),
                child: AppText(
                  // ขอรหัสใหม่
                  context.wording.requestNewCode,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            // แสดง Timer นับถอยหลัง
            return ValueListenableBuilder<int>(
              valueListenable: vm.remainingSeconds,
              builder: (context, seconds, _) {
                return Padding(
                  padding: EdgeInsets.only(top: AppDims.size_8.h),
                  child: AppText(
                    // ขอรหัสใหม่ใน $seconds วินาที (resendIn)
                    ContentLocalizeData(
                      en: 'Resend in $seconds seconds',
                      zh: '$seconds 秒后可重发',
                      th: 'ขอรหัสใหม่ใน $seconds วินาที',
                    ).getTextByLocale(context.languageCode),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ForgotPasswordOTPWidget extends StatefulWidget {
  const _ForgotPasswordOTPWidget({super.key});

  @override
  State<_ForgotPasswordOTPWidget> createState() =>
      __ForgotPasswordOTPWidgetState();
}

class __ForgotPasswordOTPWidgetState extends State<_ForgotPasswordOTPWidget> {
  @override
  void initState() {
    super.initState();

    // เริ่ม OTP Timer เมื่อหน้าแสดง (หลัง build เสร็จ)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppOverlays.showLoading(context);
      await context.read<AuthenticationViewModel>().startOtpTimer();

      AppOverlays.hideLoading();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ForgotPasswordOTPContent();
  }
}

class _ForgotPasswordOTPContent extends _OTPContent {
  const _ForgotPasswordOTPContent();

  @override
  Future<void> _summitOtp(BuildContext context) async {
    // สำเร็จ → หน้าไป resetpassword
    goToProcess(
      context,
      AuthenProcess.forgotPasswordNewPassword,
    );
  }
}

/// Widget สำหรับ PIN Input (กรอกรหัส OTP 4 หลัก)
///
/// **ใช้ Pinput package:**
/// - กรอกตัวเลข 4 หลัก (สามารถเปลี่ยนเป็น 6 หลักได้ที่ length property)
/// - แสดง cursor กระพริบเมื่อ focus
/// - มี haptic feedback เมื่อกรอก
/// - มี 4 states: default, focused, submitted (filled), error
///
/// **Design:**
/// - Default: พื้นหลังสีเทาอ่อน, border สีเทา
/// - Focused: border สีหลัก (primary)
/// - Submitted: พื้นหลังสีหลักจาง 5%, border สีหลัก
/// - Error: border สีแดง
///
/// **Callback:**
/// - onCompleted: เรียกเมื่อกรอกครบ 4 หลัก
class _PinputWidget extends StatefulWidget {
  const _PinputWidget({
    required this.onCompleted,
    this.validator,
    this.forceErrorState = false,
  });

  final ValueChanged<String> onCompleted;
  final FormFieldValidator<String>? validator;
  final bool forceErrorState;

  @override
  State<_PinputWidget> createState() => _PinputWidgetState();
}

class _PinputWidgetState extends State<_PinputWidget> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme สำหรับแต่ละ state ของ PIN box

    // Default: ยังไม่กรอก, ไม่ได้ focus
    final defaultPinTheme = PinTheme(
      width: 72.w,
      height: 72.h,
      textStyle: AppTextNumberStyles.headlineLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.inputFieldDefaultBorder,
          width: 1,
        ),
      ),
    );

    // Focused: กำลัง focus อยู่
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.background,
        border: Border.all(
          color: AppColors.primary, // Border เปลี่ยนเป็นสีหลัก
          width: 1,
        ),
      ),
    );

    // Submitted: กรอกเสร็จแล้ว
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.primary.withValues(alpha: .05), // พื้นหลังสีหลักจาง 5%
        border: Border.all(
          color: AppColors.primary,
          width: 1,
        ),
      ),
    );

    // Error: มี error
    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.error.withValues(alpha: .05),
        border: Border.all(
          color: AppColors.error, // Border สีแดง
          width: 1,
        ),
      ),
    );

    return Pinput(
      length: 4, // จำนวนหลัก (เปลี่ยนเป็น 6 ถ้าต้องการ OTP 6 หลัก)
      controller: pinController,
      focusNode: focusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      errorPinTheme: errorPinTheme,
      showCursor: true,
      cursor: Container(
        width: 2,
        height: 30.h,
        color: AppColors.primary,
      ),
      onCompleted: widget.onCompleted, // เรียก callback เมื่อกรอกครบ
      autofocus: true, // Focus ทันทีเมื่อหน้าโหลด
      forceErrorState: widget.forceErrorState,
      validator: widget.validator,
      hapticFeedbackType: HapticFeedbackType.lightImpact, // Vibrate เบาๆ
      separatorBuilder: (index) => SizedBox(width: 12.w), // ระยะห่างระหว่าง box
    );
  }
}

/// หน้า Login (เข้าสู่ระบบ)
///
/// **Extends จาก [_SignUpWidget]:**
/// - ใช้โครงสร้างและ UI หลักร่วมกัน (Form, Social Login, etc.)
/// - Override เฉพาะส่วนที่แตกต่าง
///
/// **ความแตกต่างจาก Sign Up:**
/// - ไม่มี Checkbox ยอมรับข้อตกลง
/// - เปลี่ยน Title/Description เป็น "เข้าสู่ระบบ"
/// - เปลี่ยน Separator เป็น "เข้าสู่ระบบด้วย..."
/// - มีปุ่ม "ลืมรหัสผ่าน"
/// - มีข้อความชวนสมัครสมาชิก "ยังไม่มีบัญชีหรอ? สมัครเลย"
/// - ปุ่ม Submit เรียก vm.onLogin()
/// - Validator แบบเรียบง่าย (เช็คเฉพาะ null/empty)
class _LoginWidget extends _SignUpWidget {
  const _LoginWidget();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return buildContent(constrainedBox, context);
      },
    );
  }

  @override
  Key getFormKey(BuildContext context) => viewmodel(context).formKeyLogin;

  /// Validator แบบเรียบง่าย (เช็คเฉพาะ null/empty)
  /// - ไม่ validate format อีเมล/เบอร์โทร
  @override
  String? getValidatorEmailOrPhone(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.wording.pleaseEnterEmailOrPhone;
    }
    return null;
  }

  /// Validator แบบเรียบง่าย (เช็คเฉพาะ null/empty)
  /// - ไม่ validate ความซับซ้อนของรหัสผ่าน
  @override
  String? getValidatorPassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.wording.pleaseEnterPassword;
    }
    return null;
  }

  /// ข้อความชวนสมัครสมาชิก "ยังไม่มีบัญชีหรอ? สมัครเลย"
  /// - กดแล้วไปหน้า Sign Up (AuthenProcess.signup)
  @override
  Widget contentSignUpCheering(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: '${context.wording.dontHaveAccountYet} ',
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: context.wording.signUpNow,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  goToProcess(context, AuthenProcess.signup);
                },
            ),
          ],
        ),
      ),
    );
  }

  /// ปุ่ม "ลืมรหัสผ่าน"
  /// - กดแล้วไปหน้า Forgot Password (TODO: implement navigation)
  @override
  Widget contentButtonForgotPassword(BuildContext context) {
    return Center(
      child: TextButton(
        style: context.appTheme.textButtonTheme.style!.copyWith(
          foregroundColor: WidgetStatePropertyAll(AppColors.textPrimary),
          textStyle: WidgetStatePropertyAll(
            AppTextStyles.labelLarge,
          ),
        ),
        onPressed: () {
          goToProcess(context, AuthenProcess.forgotPassword, animate: false);
        },
        child: AppText(
          context.wording.forgotPassword,
        ),
      ),
    );
  }

  /// เปลี่ยนข้อความ Separator เป็น "เข้าสู่ระบบด้วย..."
  @override
  String wordingAlternateAuthen(BuildContext context) =>
      context.wording.loginWith;

  /// เปลี่ยน Title เป็น "เข้าสู่ระบบ"
  @override
  Widget contentTitle(BuildContext context, {required String wording}) {
    return super.contentTitle(context, wording: context.wording.login);
  }

  /// เปลี่ยน Description เป็นข้อความต้อนรับ
  @override
  Widget contentDescription(BuildContext context, {required String wording}) {
    return super.contentDescription(
      context,
      wording: context.wording.loginWelcomeDescription,
    );
  }

  /// ไม่แสดง Checkbox ยอมรับข้อตกลง (return spacing แทน)
  @override
  Widget contentCheckboxTermOfPolicy(BuildContext context) {
    return AppDims.vericalPadding_12;
  }

  /// ปุ่ม Submit สำหรับ Login
  /// - เรียก vm.onLogin()
  /// - แสดง error dialog ถ้า login ไม่สำเร็จ
  /// - pop ออกจากหน้าถ้า login สำเร็จ
  @override
  Widget contentButtonSummit(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return SizedBox(
          height: AppDims.size_40.h,
          width: double.infinity,
          child: ElevatedButton.icon(
            iconAlignment: IconAlignment.end,
            icon: Assets.svg.icLogin.svg(
              width: AppDims.size_20.w,
            ),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              AppOverlays.showLoading(context);
              final result = await vm.onLogin();
              if (!context.mounted) return;

              AppOverlays.hideLoading();

              if (result.hasError) {
                _showLoginErrorDialog(context, result.error);
                return;
              }

              // สำเร็จ → ออกจากหน้า Authentication
              if (result.isSuccess) {
                CreateAppPinPage.goReplacementPage(
                  context,
                  process: PinBiometricPross.create,
                );
                // context.pushReplacementNamed(
                //   // Login
                //   CreateAppPinPage.pageName,
                //   extra: {
                //     CreateAppPinPage.kImplementBackButton: false,
                //     CreateAppPinPage.kFirstSignup: false,
                //     // Map<Type, PinBiometricPross>
                //     CreateAppPinPage.kPinBiometricProcess: {
                //       PinBiometricPross: PinBiometricPross.create,
                //     },
                //   },
                // );
                // context.pop();
              }
            },
            // เข้าสู่ระบบ
            label: AppText(context.wording.login),
          ),
        );
      },
    );
  }

  /// แสดง Error Dialog สำหรับ Login
  /// - UserNotFound: ไม่พบผู้ใช้
  /// - UserUnauthorized: รหัสผ่านไม่ถูกต้อง
  /// - อื่นๆ: ข้อผิดพลาดทั่วไป
  void _showLoginErrorDialog(BuildContext context, dynamic error) {
    String message;
    String imageAsset = Assets.png.brownyError1.path;

    if (error is UserNotFound || error is UserUnauthorized) {
      message = (error as AuthenExceptions).toUiMessage(context);
    } else {
      message = context.wording.errorUi;
    }

    AppOverlays.showBrownyDialog(
      context,
      message: message,
      imageAsset: imageAsset,
      confirmText: context.wording.tryAgain,
    );
  }
}

class _ReferralWidget extends _SignUpWidget {
  const _ReferralWidget();

  @override
  Widget build(BuildContext context) {
    // context.read<AuthenticationViewModel>().clearValidatorForReferral();
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return buildContent(constrainedBox, context);
      },
    );
  }

  @override
  Widget contentTitle(BuildContext context, {required String wording}) {
    return super.contentTitle(
      context,
      // กรอกเบอร์เพื่อนสมาชิก
      wording: context.wording.enterFriendPhoneNumber,
    );
  }

  @override
  Widget contentDescription(BuildContext context, {required String wording}) {
    return super.contentDescription(
      context,
      // กรอกเบอร์มือถือของเพื่อนที่แนะนำให้พี่รู้จักน้องบราวนี่
      wording: context.wording.friendReferralDescription,
    );
  }

  @override
  Key getFormKey(BuildContext context) {
    return viewmodel(context).formKeyReferral;
  }

  @override
  Widget contentButtonSummit(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.validatorTriggle, // referral
          builder: (context, isValid, _) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid
                    ? () async {
                        AppOverlays.showLoading(context);
                        // Save Referral
                        final result = await vm.onSummitForm();
                        AppOverlays.hideLoading();
                        if (context.mounted && result.isSuccess) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (result.hasError) {
                            // AppOverlays.showBrownyDialog(
                            //   context,
                            //   title: context.wording.errorOccurred,
                            //   message: result.error.toString(),
                            // );
                            _showErrorDialog(context, result.error);
                            return;
                          }

                          AppOverlays.showBrownyDialog(
                            context,
                            imageAsset: Assets.png.brownySuccess1.path,
                            // สำเร็จ
                            title: context.wording.success,
                            // บันทึกชวนเพื่อนเรียบร้อยแล้ว
                            message: context.wording.referralSavedSuccessfully,
                            onConfirm: () {
                              goToProcess(
                                context,
                                AuthenProcess.login,
                                animate: false,
                              );
                            },
                          );
                          CreateAppPinPage.goToPage(
                            context,
                            isFirstSingup: true,
                            process: PinBiometricPross.create,
                          );
                          // context.pushNamed(
                          //   // Save Referral summit
                          //   CreateAppPinPage.pageName,
                          //   extra: {
                          //     CreateAppPinPage.kImplementBackButton: false,
                          //     CreateAppPinPage.kFirstSignup: true,
                          //     // Map<Type, PinBiometricPross>
                          //     CreateAppPinPage.kPinBiometricProcess: {
                          //       PinBiometricPross: PinBiometricPross.create,
                          //     },
                          //   },
                          // );
                        } else {
                          if (context.mounted) {
                            // AppOverlays.showBrownyDialog(
                            //   context,
                            //   title: context.wording.errorOccurred,
                            //   message: result.error.toString(),
                            // );
                            _showErrorDialog(context, result.error);
                          }
                        }
                      }
                    : null,
                child: AppText(context.wording.confirm),
              ),
            );
          },
        );
      },
    );
  }

  /// ใช้เป็นปุ่ม Skip
  @override
  Widget contentButtonForgotPassword(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          CreateAppPinPage.goReplacementPage(
            context,
            isFirstSingup: true,
            process: PinBiometricPross.create,
          );
          // context.pushReplacementNamed(
          //   // Save Referral Skip
          //   CreateAppPinPage.pageName,
          //   extra: {
          //     CreateAppPinPage.kImplementBackButton: false,
          //     CreateAppPinPage.kFirstSignup: true,
          //     // Map<Type, PinBiometricPross>
          //     CreateAppPinPage.kPinBiometricProcess: {
          //       PinBiometricPross: PinBiometricPross.create,
          //     },
          //   },
          // );
        },
        child: AppText(
          '${context.wording.skip} ',
          style: context.textTheme.labelLarge?.copyWith(),
        ),
      ),
    );
  }

  @override
  Widget textFormFieldEmailOrPhone(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return AppTextFormField(
          controller: vm.usernameController, // save referral
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hint: AppText(
              context.wording.phoneNumber,
              style: DefaultTextStyle.of(context).style.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            prefixIcon: SizedBox.shrink(),
          ),
          autovalidateMode: AutovalidateMode.onUnfocus,
          validator: vm.validatorPhone,
          onChanged: vm.validatorPhone,
        );
      },
    );
  }

  @override
  Widget textFormFieldPasswordWithObscure(BuildContext context) =>
      const SizedBox();

  @override
  Widget contentCheckboxTermOfPolicy(BuildContext context) => const SizedBox();

  @override
  // Widget contentSocialLoginSeparator(BuildContext context) => const SizedBox();
  Widget contentSocialLoginSeparator(BuildContext context) =>
      Consumer<AuthenticationViewModel>(
        builder: (context, viewModel, _) {
          return ValueListenableBuilder<String?>(
            valueListenable: viewModel.referralErrorMessageNotifier,
            builder: (context, message, _) {
              if (message != null) {
                return Center(
                  child: AppText(
                    message,
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              }

              return const SizedBox();
            },
          );
        },
      );

  @override
  Widget contentSocialLogin(BuildContext context) => const SizedBox();

  @override
  Widget contentSignUpCheering(BuildContext context) => const SizedBox();
}

/// หน้า Forgot Password (ลืมรหัสผ่าน)
///
/// **Extends จาก [_SignUpWidget]:**
/// - ใช้โครงสร้างและ UI หลักร่วมกัน
/// - Override เฉพาะส่วนที่แตกต่าง
///
/// **ความแตกต่างจาก Sign Up:**
/// - เปลี่ยน Title/Description เป็น "ลืมรหัสผ่านใช่ไหม"
/// - ฟอร์มมีเฉพาะช่องกรอกอีเมล/เบอร์โทรศัพท์
/// - ไม่มีช่องกรอกรหัสผ่าน
/// - ไม่มี Checkbox ยอมรับข้อตกลง
/// - ไม่มี Social Login และ Separator
/// - ปุ่ม Submit ข้อความ "ถัดไป" (Next)
/// - ปุ่ม Submit เรียก vm.onSignUp() (TODO: should be vm.onForgotPassword)
class _ForgotPasswordWidget extends _SignUpWidget {
  const _ForgotPasswordWidget();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return buildContent(constrainedBox, context);
      },
    );
  }

  /// ปุ่ม Submit สำหรับ Forgot Password
  /// - ข้อความ "ถัดไป" (Next)
  @override
  Widget contentButtonSummit(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              AppOverlays.showLoading(context);
              final result = await vm.onSummitForm();

              if (!context.mounted) return;
              FocusManager.instance.primaryFocus?.unfocus();
              AppOverlays.hideLoading();

              if (result.isEmpty && !result.hasError) {
                AppOverlays.showBrownyDialog(
                  context,
                  title: context.wording.errorOccurred,
                  // ไม่พบบัญชีผู้ใช้ที่ตรงกับข้อมูลนี้
                  message: context.wording.userNotFound,
                  confirmText: context.wording.signUpNow,
                  onConfirm: () {
                    goToProcess(context, AuthenProcess.signup);
                  },
                  cancelText: context.wording.tryAgain,
                );
                return;
              }

              if (!result.isSuccess) {
                AppOverlays.showBrownyDialog(
                  context,
                  title: context.wording.errorOccurred,
                  message: context.wording.errorUi,
                );
                return;
              }
              FocusManager.instance.primaryFocus?.unfocus();
              goToProcess(context, AuthenProcess.forgotPasswordOTP);
            },
            child: AppText(context.wording.next),
          ),
        );
      },
    );
  }

  @override
  Key getFormKey(BuildContext context) {
    return viewmodel(context).formKeyForgetPasswordUsername;
  }

  /// ไม่แสดง Social Login
  @override
  Widget contentSocialLogin(BuildContext context) => SizedBox();

  /// ไม่แสดง Separator
  @override
  Widget contentSocialLoginSeparator(BuildContext context) => SizedBox();

  /// ฟอร์มมีเฉพาะช่องกรอกอีเมล/เบอร์โทรศัพท์
  /// - ไม่มีช่องรหัสผ่าน
  /// - ไม่มี Checkbox
  @override
  List<Widget> listOfFormAuth(
    BuildContext context,
    AuthenticationViewModel vm,
  ) => [
    textFormFieldEmailOrPhone(context),
    AppDims.vericalPadding_12,
  ];

  /// ไม่แสดง Checkbox ยอมรับข้อตกลง (return spacing แทน)
  @override
  Widget contentCheckboxTermOfPolicy(BuildContext context) {
    return AppDims.vericalPadding_12;
  }

  /// เปลี่ยน Title เป็น "ลืมรหัสผ่านใช่ไหม"
  @override
  Widget contentTitle(BuildContext context, {required String wording}) {
    return super.contentTitle(
      context,
      // ลืมรหัสผ่าน
      wording: context.wording.forgotPassword,
    );
  }

  /// เปลี่ยน Description เป็นคำอธิบายการลืมรหัสผ่าน
  @override
  Widget contentDescription(BuildContext context, {required String wording}) {
    return super.contentDescription(
      context,
      wording: context.wording.forgotPasswordDescription,
    );
  }
}

class _ResetPasswordWidget extends _SignUpWidget {
  const _ResetPasswordWidget();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return buildContent(constrainedBox, context);
      },
    );
  }

  @override
  Key getFormKey(BuildContext context) =>
      viewmodel(context).formKeyForgetPasswordReset;

  @override
  Widget contentTitle(BuildContext context, {required String wording}) {
    return super.contentTitle(
      context,
      // กำหนดรหัสผ่านใหม่
      wording: context.wording.setYourNewPassword,
    );
  }

  @override
  Widget contentDescription(BuildContext context, {required String wording}) {
    return super.contentDescription(
      context,
      // แค่ตั้งรหัสผ่านใหม่ก็พร้อมไปต่อ! มาเริ่มกันเลย
      wording: context.wording.setNewPasswordReady,
    );
  }

  @override
  Widget textFormFieldPasswordWithObscure(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.isObscure,
          builder: (context, isObscured, _) {
            return AppTextFormField(
              controller: vm.passwordController,
              textInputAction: TextInputAction.done,
              obscureText: isObscured,
              decoration: InputDecoration(
                hint: AppText(
                  context.wording.newPassword,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                prefixIcon: SizedBox.shrink(),
                suffixIcon: IconButton(
                  onPressed: vm.onObscureChange,
                  icon: isObscured
                      ? Assets.svg.icObscureOff.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        )
                      : Assets.svg.icObscureOn.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        ),
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => getValidatorPassword(context, value),
              onChanged: vm.resetPasswordValidator,
            );
          },
        );
      },
    );
  }

  /// สร้าง TextFormField ใหม่ เพื่อเป็นการยืินยันรหัสผ่าน ต่อจาก [textFormFieldPasswordWithObscure]
  Widget textFormFieldConfirmPasswordWithObscure(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.isObscure,
          builder: (context, isObscured, _) {
            return AppTextFormField(
              controller: vm.confirmPasswordController,
              textInputAction: TextInputAction.done,
              obscureText: isObscured,
              decoration: InputDecoration(
                hint: AppText(
                  context.wording.confirmNewPassword,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                prefixIcon: SizedBox.shrink(),
                suffixIcon: IconButton(
                  onPressed: vm.onObscureChange,
                  icon: isObscured
                      ? Assets.svg.icObscureOff.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        )
                      : Assets.svg.icObscureOn.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        ),
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) =>
                  viewmodel(context).resetConfirmPasswordValidator(value),
              onChanged: viewmodel(context).resetConfirmPasswordValidator,
            );
          },
        );
      },
    );
  }

  @override
  List<Widget> listOfFormAuth(
    BuildContext context,
    AuthenticationViewModel vm,
  ) => [
    textFormFieldPasswordWithObscure(context),
    AppDims.vericalPadding_12,
    textFormFieldConfirmPasswordWithObscure(context),
    AppDims.vericalPadding_8,

    ValueListenableBuilder(
      valueListenable: viewmodel(context).resetValidationNotifier,
      builder: (context, value, child) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 0,
          horizontalTitleGap: 0,
          minTileHeight: 0,
          leading: (value[ResetPasswordConditions.samePassword] ?? false)
              ? Assets.svg.icChecked.svg(width: 14.w)
              : Assets.svg.icUnchecked.svg(width: 14.w),
          title: AppText(
            context.wording.passwordMatches,
            style: context.textTheme.bodySmall,
          ),
        );
      },
    ),
    AppDims.vericalPadding_4,
    ValueListenableBuilder(
      valueListenable: viewmodel(context).resetValidationNotifier,
      builder: (context, value, child) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 0,
          horizontalTitleGap: 0,
          minTileHeight: 0,
          leading: (value[ResetPasswordConditions.atleastLength] ?? false)
              ? Assets.svg.icChecked.svg(width: 14.w)
              : Assets.svg.icUnchecked.svg(width: 14.w),
          title: AppText(
            context.wording.atleast8Characters,
            style: context.textTheme.bodySmall,
          ),
        );
      },
    ),

    AppDims.vericalPadding_24,
  ];

  @override
  String? getValidatorPassword(BuildContext context, String? value) =>
      viewmodel(context).resetPasswordValidator(
        value,
      );

  /// reset password
  @override
  Widget contentButtonSummit(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.validatorTriggle, // Signup
          builder: (context, isValid, _) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid
                    ? () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        AppOverlays.showLoading(context);
                        vm.onSummitForm().then((result) {
                          if (!context.mounted) return;
                          AppOverlays.hideLoading();

                          if (result.hasError) {
                            _showErrorDialog(
                              context,
                              result.error,
                            );
                            return;
                          }

                          if (result.isEmpty) {
                            return;
                          }

                          AppOverlays.showBrownyDialog(
                            context,
                            imageAsset: Assets.png.brownySuccess1.path,
                            // เปลี่ยนรหัสผ่านสำเร็จ
                            message:
                                context.wording.passwordChangedSuccessfully,
                            onConfirm: () {
                              goToProcess(
                                context,
                                AuthenProcess.login,
                                animate: false,
                              );
                            },
                          );
                        });
                      }
                    : null,
                child: AppText(context.wording.repeatPassword),
              ),
            );
          },
        );
      },
    );
  }

  /// reset password
  @override
  Widget contentSocialLoginSeparator(BuildContext context) => SizedBox();

  /// reset password
  @override
  Widget contentSocialLogin(BuildContext context) => SizedBox();
}

class _ChangePasswordOTPWidget extends StatefulWidget {
  const _ChangePasswordOTPWidget({super.key});

  @override
  State<_ChangePasswordOTPWidget> createState() =>
      __ChangePasswordOTPWidgetState();
}

class __ChangePasswordOTPWidgetState extends State<_ChangePasswordOTPWidget> {
  @override
  void initState() {
    super.initState();

    // เริ่ม OTP Timer เมื่อหน้าแสดง (หลัง build เสร็จ)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppOverlays.showLoading(context);
      await context.read<AuthenticationViewModel>().startOtpTimer();

      AppOverlays.hideLoading();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ChangePasswordOTPContent();
  }
}

class _ChangePasswordOTPContent extends _OTPContent {
  const _ChangePasswordOTPContent();

  @override
  Future<void> _summitOtp(BuildContext context) async {
    // สำเร็จ → หน้าไป resetpassword
    goToProcess(
      context,
      AuthenProcess.changePasswordNewPassword,
    );
  }
}

/// หน้า Change Password (เปลี่ยนรหัสผ่าน)
///
/// **Extends จาก [_SignUpWidget]:**
/// - ใช้โครงสร้างและ UI หลักร่วมกัน
/// - Override เฉพาะส่วนที่แตกต่าง
///
/// **ความแตกต่างจาก Sign Up:**
/// - เปลี่ยน Title/Description เป็น "เปลี่ยนรหัสผ่าน"
/// - ฟอร์มมีเฉพาะช่องกรอกอีเมล/เบอร์โทรศัพท์
/// - ไม่มีช่องกรอกรหัสผ่าน
/// - ไม่มี Checkbox ยอมรับข้อตกลง
/// - ไม่มี Social Login และ Separator
/// - ปุ่ม Submit ข้อความ "ถัดไป" (Next)
/// - ปุ่ม Submit เรียก vm.onSignUp() (TODO: should be vm.onChangePassword)
class _ChangePasswordWidget extends _SignUpWidget {
  const _ChangePasswordWidget();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return buildContent(constrainedBox, context);
      },
    );
  }

  /// ปุ่ม Submit สำหรับ Change Password
  /// - ข้อความ "ถัดไป" (Next)
  @override
  Widget contentButtonSummit(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              AppOverlays.showLoading(context);
              final result = await vm.onSummitForm();

              if (!context.mounted) return;
              AppOverlays.hideLoading();

              if (result.isEmpty && !result.hasError) {
                return;
              }

              if (result.hasError) {
                _showErrorDialog(context, result.error);
                return;
              }

              if (!result.isSuccess) {
                AppOverlays.showBrownyDialog(
                  context,
                  title: context.wording.errorOccurred,
                  message: context.wording.errorUi,
                );
                return;
              }

              goToProcess(context, AuthenProcess.changePasswordOTP);
            },
            child: AppText(context.wording.next),
          ),
        );
      },
    );
  }

  @override
  Key getFormKey(BuildContext context) {
    return viewmodel(context).formKeyForgetPasswordUsername;
  }

  /// ไม่แสดง Social Login
  @override
  Widget contentSocialLogin(BuildContext context) => SizedBox();

  /// ไม่แสดง Separator
  @override
  Widget contentSocialLoginSeparator(BuildContext context) => SizedBox();

  /// ฟอร์มมีเฉพาะช่องกรอกอีเมล/เบอร์โทรศัพท์
  /// - ไม่มีช่องรหัสผ่าน
  /// - ไม่มี Checkbox
  @override
  List<Widget> listOfFormAuth(
    BuildContext context,
    AuthenticationViewModel vm,
  ) => [
    textFormFieldEmailOrPhone(context),
    AppDims.vericalPadding_12,
  ];

  /// ไม่แสดง Checkbox ยอมรับข้อตกลง (return spacing แทน)
  @override
  Widget contentCheckboxTermOfPolicy(BuildContext context) {
    return AppDims.vericalPadding_12;
  }

  /// เปลี่ยน Title เป็น "เปลี่ยนรหัสผ่าน"
  @override
  Widget contentTitle(BuildContext context, {required String wording}) {
    return super.contentTitle(
      context,
      // เปลี่ยนรหัสผ่าน?
      wording: context.wording.changePasswordQuestion,
    );
  }

  /// เปลี่ยน Description เป็นคำอธิบายการลืมรหัสผ่าน
  @override
  Widget contentDescription(BuildContext context, {required String wording}) {
    return super.contentDescription(
      context,
      wording: context.wording.forgotPasswordDescription,
    );
  }
}

/// DONG 2026-03-07
///
/// หน้าสำหรับเปลี่ยนรหัสผ่านไม่ จะไม่เหมือนลืมรหัสผ่าน ต้องกรอก รหัสผ่านเดิม และรหัสผ่านใหม่
class _ChangePasswordNewPasswordWidget extends _SignUpWidget {
  const _ChangePasswordNewPasswordWidget();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrainedBox) {
        return buildContent(constrainedBox, context);
      },
    );
  }

  @override
  Key getFormKey(BuildContext context) =>
      viewmodel(context).formKeyForgetPasswordReset;

  @override
  Widget contentTitle(BuildContext context, {required String wording}) {
    return super.contentTitle(
      context,
      // กำหนดรหัสผ่านใหม่
      wording: context.wording.setYourNewPassword,
    );
  }

  @override
  Widget contentDescription(BuildContext context, {required String wording}) {
    return super.contentDescription(
      context,
      // แค่ตั้งรหัสผ่านใหม่ก็พร้อมไปต่อ! มาเริ่มกันเลย
      wording: context.wording.setNewPasswordReady,
    );
  }

  @override
  Widget textFormFieldPasswordWithObscure(BuildContext context) {
    // TextField ใช้าสำหรับ กรอกรหัสปัจจุบัน
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.isObscure,
          builder: (context, isObscured, _) {
            return AppTextFormField(
              controller: vm.passwordController,
              textInputAction: TextInputAction.done,
              obscureText: isObscured,
              decoration: InputDecoration(
                hint: AppText(
                  // รหัสผ่านปัจจุบัน
                  context.wording.currentPassword,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                prefixIcon: SizedBox.shrink(),
                suffixIcon: IconButton(
                  onPressed: vm.onObscureChange,
                  icon: isObscured
                      ? Assets.svg.icObscureOff.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        )
                      : Assets.svg.icObscureOn.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        ),
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              // validator: (value) => getValidatorPassword(context, value),
              // onChanged: vm.resetPasswordValidator,
            );
          },
        );
      },
    );
  }

  /// สร้าง TextFormField ใหม่ เพื่อใส่รหัสใหม่ที่ต้องการจะเปลี่ยน ต่อจาก [textFormFieldPasswordWithObscure]
  Widget textFormFieldConfirmPasswordWithObscure(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.isObscure,
          builder: (context, isObscured, _) {
            return AppTextFormField(
              controller: vm.confirmPasswordController,
              textInputAction: TextInputAction.done,
              obscureText: isObscured,
              decoration: InputDecoration(
                hint: AppText(
                  // รหัสผ่านใหม่
                  context.wording.newPassword,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                prefixIcon: SizedBox.shrink(),
                suffixIcon: IconButton(
                  onPressed: vm.onObscureChange,
                  icon: isObscured
                      ? Assets.svg.icObscureOff.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        )
                      : Assets.svg.icObscureOn.svg(
                          width: AppDims.size_16.w,
                          height: AppDims.size_16.h,
                        ),
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => viewmodel(
                context,
              ).changePasswordConfirmPasswordValidator(value),
              onChanged: viewmodel(context).changePasswordValidator,
            );
          },
        );
      },
    );
  }

  @override
  List<Widget> listOfFormAuth(
    BuildContext context,
    AuthenticationViewModel vm,
  ) => [
    textFormFieldPasswordWithObscure(context),
    AppDims.vericalPadding_12,
    textFormFieldConfirmPasswordWithObscure(context),
    AppDims.vericalPadding_8,

    ValueListenableBuilder(
      valueListenable: viewmodel(context).resetValidationNotifier,
      builder: (context, value, child) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 0,
          horizontalTitleGap: 0,
          minTileHeight: 0,
          leading: (value[ResetPasswordConditions.atleastLength] ?? false)
              ? Assets.svg.icChecked.svg(width: 14.w)
              : Assets.svg.icUnchecked.svg(width: 14.w),
          title: AppText(
            context.wording.atleast8Characters,
            style: context.textTheme.bodySmall,
          ),
        );
      },
    ),

    AppDims.vericalPadding_24,
  ];

  @override
  String? getValidatorPassword(BuildContext context, String? value) =>
      viewmodel(context).resetPasswordValidator(
        value,
      );

  /// Change password
  @override
  Widget contentButtonSummit(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, vm, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: vm.validatorTriggle, // Signup
          builder: (context, isValid, _) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid
                    ? () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        AppOverlays.showLoading(context);
                        // Change Password
                        vm.onSummitForm().then((result) {
                          if (!context.mounted) return;
                          AppOverlays.hideLoading();

                          if (result.hasError) {
                            _showErrorDialog(
                              context,
                              result.error,
                            );
                            return;
                          }

                          if (result.isEmpty) {
                            return;
                          }

                          AppOverlays.showBrownyDialog(
                            context,
                            imageAsset: Assets.png.brownySuccess1.path,
                            // เปลี่ยนรหัสผ่านสำเร็จ,
                            message:
                                context.wording.passwordChangedSuccessfully,
                            onConfirm: () {
                              context.safePop();
                            },
                          );
                        });
                      }
                    : null,
                child: AppText(context.wording.repeatPassword),
              ),
            );
          },
        );
      },
    );
  }

  /// reset password
  @override
  Widget contentSocialLoginSeparator(BuildContext context) => SizedBox();

  /// reset password
  @override
  Widget contentSocialLogin(BuildContext context) => SizedBox();
}

/// Checkbox สำหรับยอมรับข้อตกลงและนโยบายความเป็นส่วนตัว
///
/// **ใช้ในหน้า Sign Up เท่านั้น**
///
/// **การทำงาน:**
/// - แสดง Checkbox พร้อมข้อความ "ข้าพเจ้ายอมรับ ข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว ของ Browny 24hr Wash & Dry"
/// - ข้อความ "ข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว" มี underline และเป็นลิงก์
/// - กดแล้วแสดง SnackBar (TODO: เปลี่ยนเป็นเปิดหน้า Terms & Privacy Policy)
/// - เมื่อกด Checkbox จะเรียก callback onChanged ส่งค่า true/false กลับไป
class _CheckBoxTermOfPolicy extends StatefulWidget {
  const _CheckBoxTermOfPolicy({
    required this.onChanged,
    this.onTermsTap,
    this.initialValue = false,
  });

  final ValueChanged<bool?> onChanged;
  final VoidCallback? onTermsTap;
  final bool initialValue;

  @override
  State<_CheckBoxTermOfPolicy> createState() => _CheckBoxTermOfPolicyState();
}

class _CheckBoxTermOfPolicyState extends State<_CheckBoxTermOfPolicy> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _isChecked,
      titleAlignment: ListTileTitleAlignment.top,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.symmetric(vertical: AppDims.size_8.h),
      onChanged: (_) {
        setState(() {
          _isChecked = !_isChecked;
          widget.onChanged.call(_isChecked);
        });
      },
      title: RichText(
        text: TextSpan(
          text: '${context.wording.iHaveAccepted} ',
          style: context.textTheme.bodySmall!.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: context.wording.termsOfUseAndPrivacyPolicy,
              recognizer: TapGestureRecognizer()..onTap = widget.onTermsTap,
              style: context.textTheme.labelMedium!.copyWith(
                color: AppColors.primary,
              ),
            ),
            TextSpan(
              text: ' ${context.wording.ofBrowny24hrWashAndDry}',
              style: context.textTheme.bodySmall!.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
