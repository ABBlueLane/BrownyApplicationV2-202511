import 'dart:async';
import 'dart:io';

import 'package:browny_applications_new/core/data/remote/models/api_model_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/social_auth_helper.dart';
import 'package:browny_applications_new/feature/contacts/repository/contact_repo.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:browny_applications_new/core/utils/ui_result.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/models/otp_model.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:browny_applications_new/feature/authentication/repository/otp_data_repo.dart';
import 'package:browny_applications_new/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:go_router/go_router.dart';

enum SignUpRequiredConditions {
  valideEmalOrPhone,
  passwordHasLowercase,
  passwordHasDigit,
  acceptTermOfPolicy,
}

enum ResetPasswordConditions {
  samePassword,
  atleastLength,
}

enum AuthenProcess {
  login,
  signup,
  signupOTP,
  forgotPassword,
  forgotPasswordOTP,
  forgotPasswordNewPassword,
  changePassword,
  changePasswordOTP,
  changePasswordNewPassword,
  referral,
}

class AuthenticationViewModel extends AppViewModelFormFieldValidation {
  AuthenticationViewModel({
    required super.context,
    required this.authenProcess,
    required this.customerDataRepo,
    required this.contactRepo,
  });

  final CustomerDataSourceMixin customerDataRepo;
  final ContactDataSourceMixin contactRepo;
  OTPDataSourceMixin get otpDataRepo => customerDataRepo as OTPDataSourceMixin;

  final AuthenProcess authenProcess;

  // =========== Page Navigation ===========
  late final PageController pageController;
  final ValueNotifier<int> _currentPageIndexNotifier = ValueNotifier(0);
  ValueNotifier<int> get currentPageIndex => _currentPageIndexNotifier;

  // กำหนด flow ของหน้า authentication
  final List<AuthenProcess> _pageFlow = AuthenProcess.values.toList();

  AuthenProcess get currentProcess =>
      _pageFlow[_currentPageIndexNotifier.value];
  bool get canGoBack => _currentPageIndexNotifier.value > 0;

  void goToPage(int index, {bool animate = true}) {
    if (index >= 0 && index < _pageFlow.length) {
      if (animate) {
        pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        pageController.jumpToPage(index);
      }
      _currentPageIndexNotifier.value = index;
    }
  }

  void goToProcess(AuthenProcess process, {bool animate = true}) {
    final index = _pageFlow.indexOf(process);
    if (index != -1) {
      switch (process) {
        case AuthenProcess.login:
          _validations.addAll(SignUpRequiredConditions.values);
          usernameController.text = '';
          passwordController.text = '';
          break;
        case AuthenProcess.signup:
          // clear text ที่เคยกรอกไว้
          usernameController.text = '';
          passwordController.text = '';
          break;
        case AuthenProcess.changePasswordOTP:
        case AuthenProcess.forgotPasswordOTP:
        case AuthenProcess.signupOTP:
          // do nothing
          break;
        case AuthenProcess.forgotPassword:
          // clear text ที่เคยกรอกไว้
          usernameController.text = '';
          passwordController.text = '';
        case AuthenProcess.changePasswordNewPassword:
          if (!isObscure.value) {
            onObscureChange();
          }
          passwordController.text = '';
          confirmPasswordController.text = '';
          _resetValidationNotifier.value = {
            ResetPasswordConditions.atleastLength: false,
          };
          _resetValidation.clear();
          _resetValidation.add(ResetPasswordConditions.atleastLength);
          _onResetPasswordValidatorTriggle();
          break;
        case AuthenProcess.forgotPasswordNewPassword:
          // do nothing
          if (!isObscure.value) {
            onObscureChange();
          }
          passwordController.text = '';
          confirmPasswordController.text = '';
          _resetValidationNotifier.value = {
            ResetPasswordConditions.samePassword: false,
            ResetPasswordConditions.atleastLength: false,
          };
          _onResetPasswordValidatorTriggle();
          break;

        case AuthenProcess.referral:
          _validations.clear();
          _validations.add(SignUpRequiredConditions.valideEmalOrPhone);
          _validatorTriggleNotifier.value = false;
          _otpTimer?.cancel();
          _otpTimer = null;
          usernameController.text = '';
          passwordController.text = '';
          break;
        case AuthenProcess.changePassword:
          passwordController.clear();
          confirmPasswordController.clear();
          break;
      }
      goToPage(index, animate: animate);
    }
  }

  void goBack() {
    if (canGoBack) {
      switch (currentProcess) {
        case AuthenProcess.login:
          // do nothing
          break;
        case AuthenProcess.signup:
          // do nothing
          break;
        case AuthenProcess.forgotPasswordOTP:
          // clear error verify otp
          _verifyOTPMessageErrorNotifier.value = null;
          // cancel Timer
          _otpTimer?.cancel();
          break;
        case AuthenProcess.signupOTP:
          _verifyOTPMessageErrorNotifier.value = null;
          break;
        case AuthenProcess.forgotPassword:
          goToProcess(AuthenProcess.login, animate: false);
          return;
        case AuthenProcess.forgotPasswordNewPassword:
          if (!isObscure.value) {
            onObscureChange();
          }
          _resetValidationNotifier.value = {
            ResetPasswordConditions.samePassword: false,
            ResetPasswordConditions.atleastLength: false,
          };
          break;

        case AuthenProcess.referral:
          goToProcess(AuthenProcess.login, animate: false);
          return;
        case AuthenProcess.changePassword:
          if (context.canPop()) {
            context.safePop();
          }
          return;
        case AuthenProcess.changePasswordOTP:
          // do nothing
          break;
        case AuthenProcess.changePasswordNewPassword:
          goToProcess(AuthenProcess.changePassword, animate: false);
          return;
      }
      goToPage(_currentPageIndexNotifier.value - 1);
    }
  }

  void goNext() {
    goToPage(_currentPageIndexNotifier.value + 1);
  }

  late GlobalKey<FormState> _formKey;
  GlobalKey<FormState> initialFormKey(GlobalKey<FormState> key) {
    _formKey = key;
    return _formKey;
  }

  // =========== Validator ===========
  late final GlobalKey<FormState> formKeyLogin = GlobalKey();
  late final GlobalKey<FormState> formKeySignup = GlobalKey();
  late final GlobalKey<FormState> formKeyForgetPasswordUsername = GlobalKey();
  late final GlobalKey<FormState> formKeyForgetPasswordReset = GlobalKey();
  late final GlobalKey<FormState> formKeyReferral = GlobalKey();
  late final TextEditingController usernameController = TextEditingController();
  late final TextEditingController passwordController = TextEditingController();
  late final TextEditingController confirmPasswordController =
      TextEditingController();

  /// เก็บเงื่อนไข [SignUpRequiredConditions] ที่จำเป็นต้องทำให้ครบ ถึงจะสามารถ Process ต่อไป
  final Set<SignUpRequiredConditions> _validations = SignUpRequiredConditions
      .values
      .toSet();

  /// เก็บเงื่อนไข [ResetPasswordConditions] ที่จำเป็นต้องทำให้ครบ ถึงจะสามารถ Process ต่อไป
  late final Set<ResetPasswordConditions> _resetValidation =
      ResetPasswordConditions.values.toSet();
  late final ValueNotifier<Map<ResetPasswordConditions, bool>>
  _resetValidationNotifier = ValueNotifier({
    ResetPasswordConditions.samePassword: false,
    ResetPasswordConditions.atleastLength: false,
  });
  ValueListenable<Map<ResetPasswordConditions, bool>>
  get resetValidationNotifier => _resetValidationNotifier;

  late final ValueNotifier<bool> _validatorTriggleNotifier = ValueNotifier(
    false,
  );
  late final ValueNotifier<String?> _referralErrorMessageNotifier =
      ValueNotifier(
        null,
      );
  ValueListenable<bool> get validatorTriggle => _validatorTriggleNotifier;
  ValueListenable<String?> get referralErrorMessageNotifier =>
      _referralErrorMessageNotifier;

  // =========== OTP Timer ===========
  Timer? _otpTimer;
  late final ValueNotifier<bool> _otpButtonNextNotifier = ValueNotifier(false);
  late final ValueNotifier<String?> _verifyOTPMessageErrorNotifier =
      ValueNotifier(
        null,
      );
  late final ValueNotifier<RequestOTPModel> _requestOtpNotifier = ValueNotifier(
    RequestOTPModel(),
  );
  late final ValueNotifier<int> _remainingSecondsNotifier = ValueNotifier(60);
  late final ValueNotifier<bool> _canResendOtpNotifier = ValueNotifier(false);

  ValueListenable<bool> get otpButtonNextNotifier => _otpButtonNextNotifier;
  ValueListenable<String?> get verifyOTPMessageErrorNotifier =>
      _verifyOTPMessageErrorNotifier;
  ValueListenable<RequestOTPModel> get requestOtpNotifier =>
      _requestOtpNotifier;
  ValueListenable<int> get remainingSeconds => _remainingSecondsNotifier;
  ValueListenable<bool> get canResendOtp => _canResendOtpNotifier;

  // =========== getter ===========
  /// Getter สำหรับแสดงชื่อผู้ใช้แบบปิดบัง (obscure)
  /// - กรณีเป็น email: แสดงครึ่งแรกของ local part แล้วปิดบังที่เหลือด้วย ***
  /// - กรณีเป็นเบอร์โทร: แสดง 6 หลักแรก แล้วปิดบังที่เหลือด้วย ***
  String get usernameObscure {
    // ตัดช่องว่างหน้า-หลังของข้อความ
    final text = usernameController.text.trim();

    // ถ้าข้อความว่างเปล่า ให้คืนค่าเป็นข้อความว่าง
    if (text.isEmpty) {
      return '';
    }

    // ตรวจสอบว่าเป็น email (มีเครื่องหมาย @)
    if (text.contains('@')) {
      // แยกส่วน local part และ domain part ด้วยเครื่องหมาย @
      final parts = text.split('@');
      if (parts.length == 2) {
        final localPart = parts[0]; // ส่วนหน้า @ (เช่น username)
        final domainPart = parts[1]; // ส่วนหลัง @ (เช่น gmail.com)

        // ถ้า local part มีความยาวมากกว่า 3 ตัวอักษร
        // แสดงครึ่งแรกของ local part แล้วปิดบังที่เหลือด้วย ***
        if (localPart.length > 3) {
          final visiblePart = localPart.substring(0, localPart.length ~/ 2);
          return '$visiblePart***@$domainPart';
        }
        // ถ้า local part มีความยาวน้อยกว่าหรือเท่ากับ 3 ตัวอักษร
        // แสดง local part ทั้งหมด แล้วปิดบังด้วย ***
        return '$localPart***@$domainPart';
      }
    }

    // ตรวจสอบว่าเป็นเบอร์โทรศัพท์ของไทย (10 หลัก ขึ้นต้นด้วย 0)
    if (isValidPhoneThai(text)) {
      // แสดง 6 หลักแรก แล้วปิดบังที่เหลือด้วย ***
      try {
        return '***${text.substring(6, 10)}';
      } catch (e) {
        return '***';
      }
    }

    // ถ้าไม่ใช่ทั้ง email และเบอร์โทร ให้คืนค่าข้อความต้นฉบับ
    return text;
  }

  String get otpTitleByState {
    if (currentProcess == AuthenProcess.signupOTP) {
      return ContentLocalizeData(
        en: 'ยืนยัน OTP สำหรับสมัครบัญชี',
        zh: 'ยืนยัน OTP สำหรับสมัครบัญชี',
        th: 'ยืนยัน OTP สำหรับสมัครบัญชี',
      ).getTextByLocale(context.languageCode);
    }
    return context.wording.confirmOTP;
  }
  // =========== validation ===========

  String? validatorEmailOrPhone(String? value) {
    _validations.add(SignUpRequiredConditions.valideEmalOrPhone);
    // ตรวจสอบว่าค่าที่รับเข้ามาเป็นค่าว่างหรือไม่
    if (value == null || value.trim().isEmpty) {
      return context.wording.pleaseEnterEmailOrPhone;
    }

    // ตรวจสอบด้วย pattern จาก parent class
    if (value.contains('@') && !isValidEmail(value)) {
      return context.wording.pleaseEnterValidEmail;
    }

    if (value.startsWith('0') && !isValidPhoneThai(value)) {
      return context.wording.pleaseEnterValidPhoneNumber;
    }

    // ถ้าไม่ตรงกับรูปแบบอีเมลและไม่ตรงกับรูปแบบเบอร์โทร
    if (!isEmailOrPhone(value)) {
      return context.wording.pleaseEnterValidEmailOrPhone;
    }

    _validations.removeWhere(
      (e) => e == SignUpRequiredConditions.valideEmalOrPhone,
    );
    _onValidatorTriggle();
    return null; // ข้อมูลถูกต้อง ไม่ต้องแจ้งเตือน
  }

  String? validatorPhone(String? value) {
    _validations.add(SignUpRequiredConditions.valideEmalOrPhone);
    // ตรวจสอบว่าค่าที่รับเข้ามาเป็นค่าว่างหรือไม่
    _onValidatorTriggle();
    if (value == null || value.trim().isEmpty) {
      return context.wording.enterYourPhoneNumber;
    }

    // ตรวจสอบด้วย pattern จาก parent class
    if (!isValidPhoneThai(value)) {
      return context.wording.pleaseEnterCorrectPhoneFormat;
    }
    _validations.removeWhere(
      (e) => e == SignUpRequiredConditions.valideEmalOrPhone,
    );
    _onValidatorTriggle();
    return null;
  }

  /// validate สำหรับ Process
  /// [AuthenProcess.login]
  /// [AuthenProcess.signup]
  String? validatorPassword(String? value) {
    // ตรวจสอบว่าค่าที่รับเข้ามาเป็นค่าว่างหรือไม่
    if (value == null || value.trim().isEmpty) {
      return context.wording.pleaseEnterPassword;
    }

    if (value.length < 8) {
      return context.wording.passwordMustBeAtLeast8Characters;
    }

    // ตรวจสอบด้วย pattern จาก parent class
    final hasCharacter = passwordHasCharacter(value);
    final hasDigit = passwordHasDigit(value);

    _validations.addAll({
      SignUpRequiredConditions.passwordHasLowercase,
      SignUpRequiredConditions.passwordHasDigit,
    });
    _onValidatorTriggle();

    StringBuffer stringBuffer = StringBuffer();

    if (!hasCharacter) {
      stringBuffer
        ..write('- ${context.wording.passwordMustContainLowercase}')
        ..writeln();
    } else {
      _validations.removeWhere(
        (e) => e == SignUpRequiredConditions.passwordHasLowercase,
      );
    }
    if (!hasDigit) {
      stringBuffer
        ..write('- ${context.wording.passwordMustContainNumber}')
        ..writeln();
    } else {
      _validations.removeWhere(
        (e) => e == SignUpRequiredConditions.passwordHasDigit,
      );
    }
    if (!hasCharacter || !hasDigit) {
      return stringBuffer.toString();
    }
    _onValidatorTriggle();
    return null;
  }

  /// validate password สำหรับ Process
  /// [AuthenProcess.forgotPassword]
  String? resetPasswordValidator(String? value) {
    _resetValidationNotifier.removeListener(_onResetPasswordValidatorTriggle);
    _resetValidationNotifier.addListener(_onResetPasswordValidatorTriggle);
    if (value == null || value.trim().isEmpty) {
      return context.wording.pleaseEnterPassword;
    }

    _resetValidation.addAll(ResetPasswordConditions.values.toSet());

    if (value.length < 8) {
      _resetValidationNotifier.value = {
        ResetPasswordConditions.atleastLength: false,
        ResetPasswordConditions.samePassword: !_resetValidation.contains(
          ResetPasswordConditions.atleastLength,
        ),
      };
      return context.wording.passwordMustBeAtLeast8Characters;
    }

    // ตรวจสอบด้วย pattern จาก parent class
    final hasCharacter = passwordHasCharacter(value);
    final hasDigit = passwordHasDigit(value);

    if (!hasDigit) {
      _resetValidationNotifier.value = {
        ResetPasswordConditions.atleastLength: false,
        ResetPasswordConditions.samePassword: !_resetValidation.contains(
          ResetPasswordConditions.atleastLength,
        ),
      };
      return context.wording.passwordMustContainNumber;
    }

    if (!hasCharacter) {
      _resetValidationNotifier.value = {
        ResetPasswordConditions.atleastLength: false,
        ResetPasswordConditions.samePassword: !_resetValidation.contains(
          ResetPasswordConditions.samePassword,
        ),
      };
      return context.wording.passwordMustContainLowercase;
    }

    _resetValidation.remove(ResetPasswordConditions.atleastLength);
    _resetValidationNotifier.value = {
      ResetPasswordConditions.atleastLength: true,
      ResetPasswordConditions.samePassword: !_resetValidation.contains(
        ResetPasswordConditions.samePassword,
      ),
    };

    return null;
  }

  /// validate confirmPassword สำหรับ Process
  /// [AuthenProcess.forgotPassword]
  String? resetConfirmPasswordValidator(String? value) {
    _resetValidationNotifier.removeListener(_onResetPasswordValidatorTriggle);
    _resetValidationNotifier.addListener(_onResetPasswordValidatorTriggle);
    if (value == null || value.trim().isEmpty) {
      return context.wording.pleaseEnterPassword;
    }
    _resetValidation.add(ResetPasswordConditions.samePassword);

    String password = passwordController.text;
    if (value != password) {
      _resetValidationNotifier.value = {
        ResetPasswordConditions.atleastLength: !_resetValidation.contains(
          ResetPasswordConditions.atleastLength,
        ),
        ResetPasswordConditions.samePassword: false,
      };
      // รหัสผ่านไม่ตรงกัน
      return context.wording.passwordMismatch;
    }

    _resetValidation.remove(ResetPasswordConditions.samePassword);
    _resetValidationNotifier.value = {
      ResetPasswordConditions.atleastLength: !_resetValidation.contains(
        ResetPasswordConditions.atleastLength,
      ),
      ResetPasswordConditions.samePassword: true,
    };

    return null;
  }

  /// validate password สำหรับ Process
  /// [AuthenProcess.forgotPassword]
  String? changePasswordValidator(String? value) {
    _resetValidationNotifier.removeListener(_onResetPasswordValidatorTriggle);
    _resetValidationNotifier.addListener(_onResetPasswordValidatorTriggle);
    if (value == null || value.trim().isEmpty) {
      return context.wording.pleaseEnterPassword;
    }

    _resetValidation.add(ResetPasswordConditions.atleastLength);

    if (value.length < 8) {
      _resetValidationNotifier.value = {
        ResetPasswordConditions.atleastLength: false,
      };
      return context.wording.passwordMustBeAtLeast8Characters;
    }

    // ตรวจสอบด้วย pattern จาก parent class
    final hasCharacter = passwordHasCharacter(value);
    final hasDigit = passwordHasDigit(value);

    if (!hasDigit) {
      _resetValidationNotifier.value = {
        ResetPasswordConditions.atleastLength: false,
      };
      return context.wording.passwordMustContainNumber;
    }

    if (!hasCharacter) {
      _resetValidationNotifier.value = {
        ResetPasswordConditions.atleastLength: false,
      };
      return context.wording.passwordMustContainLowercase;
    }

    _resetValidation.remove(ResetPasswordConditions.atleastLength);
    _resetValidationNotifier.value = {
      ResetPasswordConditions.atleastLength: true,
    };

    return null;
  }

  /// validate confirmPassword สำหรับ Process
  /// [AuthenProcess.forgotPassword]
  String? changePasswordConfirmPasswordValidator(String? value) {
    _resetValidationNotifier.removeListener(_onResetPasswordValidatorTriggle);
    _resetValidationNotifier.addListener(_onResetPasswordValidatorTriggle);
    if (value == null || value.trim().isEmpty) {
      return context.wording.pleaseEnterPassword;
    }

    return null;
  }

  void _onResetPasswordValidatorTriggle() {
    _validatorTriggleNotifier.value = _resetValidation.isEmpty;
  }

  bool get checkBoxTermOfPolicy => !_validations.contains(
    SignUpRequiredConditions.acceptTermOfPolicy,
  );
  void checkboxTermOfPolicyChanged(bool? value) {
    if (value == null || !value) {
      _validations.add(SignUpRequiredConditions.acceptTermOfPolicy);
      _onValidatorTriggle();
      return;
    }
    _validations.removeWhere(
      (e) => e == SignUpRequiredConditions.acceptTermOfPolicy,
    );
    _onValidatorTriggle();
  }

  void _onValidatorTriggle() {
    if (currentProcess == AuthenProcess.signup) {
      _validatorTriggleNotifier.value = !_validations.contains(
        SignUpRequiredConditions.acceptTermOfPolicy,
      );
    } else {
      _validatorTriggleNotifier.value = _validations.isEmpty;
    }
  }

  Future<UiResult<bool>> verifyOTP(String otp) async {
    if (kDebugMode) {
      await Future.delayed(Duration(seconds: 2));
      // // _verifyOTPMessageErrorNotifier.value = context.wording.otpUnauthorizedError;
      // _verifyOTPMessageErrorNotifier.value = null;
      // await onSignUp();
      // return UiResult.success(data: true);
      // _otpButtonNextNotifier.value = true;
      return UiResult.success(data: true);
    }

    _verifyOTPMessageErrorNotifier.value = null;
    _otpButtonNextNotifier.value = false;
    final validateResult = await otpDataRepo.verifyOTP(
      VerifyOTP(
        username: usernameController.text,
        refCode: _requestOtpNotifier.value.refCode,
        otp: otp,
      ),
    );

    if (!context.mounted) return UiResult.empty();

    if (validateResult.hasError) {
      if (validateResult.error is AuthenExceptions) {
        final message = (validateResult.error as AuthenExceptions).toUiMessage(
          context,
        );
        // เกิด Error ขึ้น จะ notfi ไปแสดงที่ UI ด้วย
        _verifyOTPMessageErrorNotifier.value = message;
        return UiResult.empty(
          error: validateResult.error,
        );
      }

      return UiResult.error(error: validateResult.error);
    }
    if (validateResult.data.customerId == null) {
      _verifyOTPMessageErrorNotifier.value = UserNotFound().message;
      return UiResult.empty();
    }
    // clear error verify otp
    _verifyOTPMessageErrorNotifier.value = null;
    // เปิดการทำงานปุ่ม ต่อไป
    _otpButtonNextNotifier.value = true;

    // update uuid ของ customer เอาไว้ กรณี process forgotpassword จะต้องใช้
    currentCustomerProvider.newUser = currentCustomerProvider.current.copyWith(
      id: validateResult.data.customerId,
    );

    return UiResult.success(data: true);
  }

  // =========== event login, logout, regist ===========

  /// DONG 2026-02-21
  ///
  /// fetch ข้อมูลช่องทางการติดต่อต่างๆ
  Future<UiResult<ContactResponse>> fetchTermsLink() async {
    try {
      final result = await contactRepo.fetchContact();
      if (result.hasError || result.isEmpty) {
        return UiResult.empty();
      }

      return UiResult.success(data: result.data);
    } catch (_) {
      return UiResult.empty();
    }
  }

  Future<UiResult<void>> onSummitForm() async {
    // ขั้นตอนการสมัครสมาชิก
    if (currentProcess == AuthenProcess.signup) {
      if (formKeySignup.currentState?.validate() == true &&
          _validations.isEmpty) {
        // validate ทุกอย่างผ่าน จะ call API เช็คก่อนว่ามี User นี้ในระบบแล้วหรือยัง
        final checkUserExists = await customerDataRepo.checkUsernameExists(
          usernameController.text,
        );

        if (checkUserExists.isEmpty) {
          return UiResult.error(error: checkUserExists.error);
        }

        return UiResult.success(data: null);
      }
      return UiResult.empty();
    }

    // ขั้นตอนกรอก OTP จังหวะสมัครสมาชิก
    if (currentProcess == AuthenProcess.signupOTP) {
      // TODO เอาจุดออกเวลาใช้จริง
      // ลงทะเบียนสำเร็จ จะ fetch Profile มาเก็บเอาไว้ใช้
      // final profileMockResult = await customerDataRepo.fetchProfile(
      //   '019b683f-9ea2-7242-82e1-6b27d2cf721d',
      // );
      // if (profileMockResult.isEmpty) {
      //   // handle ถ้าไม่สามารถ fetch Profile ได้
      //   return UiResult.empty(error: profileMockResult.error);
      // }
      // if (profileMockResult.isError) {
      //   // Error อื่นๆ ที่ไม่ได้ handle เอาไว้
      //   return UiResult.error(error: profileMockResult.error);
      // }

      // currentCustomerProvider.newUser = UserModel.fromCustomerProfileData(
      //   profileMockResult.data.data,
      // );
      // return UiResult.success(data: null);

      final response = await customerDataRepo.register(
        CustomerCredential(
          username: usernameController.text,
          password: passwordController.text,
        ),
      );

      if (response.isEmpty) {
        // เกิด Error จากการ call API register เช่น
        // - user ซ้ำ
        // - insert เข้า Database ไม่ได้
        return UiResult.empty(error: response.error);
      }

      if (response.isError) {
        // Error อื่นๆ ที่ไม่ได้ handle เอาไว้
        return UiResult.error(error: response.error);
      }

      // ลงทะเบียนสำเร็จ จะ fetch Profile มาเก็บเอาไว้ใช้
      final profileResult = await customerDataRepo.fetchProfile(
        response.data.data!.customerId!,
      );
      if (profileResult.isEmpty) {
        // handle ถ้าไม่สามารถ fetch Profile ได้
        return UiResult.empty(error: profileResult.error);
      }
      if (profileResult.isError) {
        // Error อื่นๆ ที่ไม่ได้ handle เอาไว้
        return UiResult.error(error: profileResult.error);
      }

      currentCustomerProvider.newUser = UserModel.fromCustomerProfileData(
        profileResult.data.data,
      );
      // return
      return UiResult.success(data: null);
    }

    if ([
      // ขั้นตอน ลืมพาสเวิร์ด
      AuthenProcess.forgotPassword,
      // ขั้นตอน เปลี่ยนรหัสผ่าน
      AuthenProcess.changePassword,
    ].contains(currentProcess)) {
      if (currentProcess == AuthenProcess.changePassword) {
        final userAuthorized = usernameController.text;
        final current = currentCustomerProvider.current;
        bool authorized = false;
        authorized =
            current.phone.orEmpty == userAuthorized ||
            current.email.orEmpty == userAuthorized;

        if (context.mounted && !authorized) {
          return UiResult.empty(
            error: UserUnauthorized(
              ContentLocalizeData(
                en: 'User information does not match.\nPlease verify and try again.',
                zh: '用户信息不匹配。\n请验证后重试。',
                th: 'ข้อมูลผู้ใช้ไม่ตรงกัน\nกรุณาตรวจสอบและลองอีกครั้ง',
              ).getTextByLocale(context.languageCode),
            ),
          );
        }
      }

      if (formKeyForgetPasswordUsername.currentState?.validate() == true) {
        final checkUserExists = await customerDataRepo.checkUsernameExists(
          usernameController.text,
        );

        if (checkUserExists.isEmpty && !checkUserExists.hasError) {
          return UiResult.empty(error: UserNotFound());
        }

        if (checkUserExists.hasError) {
          if (checkUserExists.error is! UserDuplicated) {
            return UiResult.empty(error: checkUserExists.error);
          }
        }

        if (currentProcess == AuthenProcess.forgotPassword) {
          if (checkUserExists.hasData && checkUserExists.data) {
            return UiResult.empty();
          }
        }

        return UiResult.success(data: null);
      }
    }

    // ขั้นตอน Resetpassword
    if (currentProcess == AuthenProcess.forgotPasswordNewPassword) {
      // สำหรับทดสอบต้องปิด
      // return UiResult.success(
      //   data: null,
      // );

      final updateResulse = await customerDataRepo.updatePassword({
        "id": currentCustomerProvider.current.id.orEmpty,
        "new_password": passwordController.text,
      });

      if (updateResulse.hasError) {
        return UiResult.empty(error: updateResulse.error);
      }

      return UiResult.success(
        data: null,
      );
    }

    // ขั้นตอน Changepassword
    if (currentProcess == AuthenProcess.changePasswordNewPassword) {
      // สำหรับทดสอบต้องปิด
      // return UiResult.success(
      //   data: null,
      // );

      final updateResulse = await customerDataRepo.changePassword(
        ChangePasswordRequest(
          id: currentCustomerProvider.current.id!,
          oldPassword: passwordController.text,
          newPassword: confirmPasswordController.text,
        ),
      );

      if (updateResulse.hasError) {
        return UiResult.empty(error: updateResulse.error);
      }

      return UiResult.success(
        data: null,
      );
    }

    // ขั้นตอน save referral
    if (currentProcess == AuthenProcess.referral) {
      _referralErrorMessageNotifier.value = null;
      if (formKeyReferral.currentState?.validate() == true) {
        // Get locale before async operations to avoid context crossing async gaps
        final locale = context.languageCode;
        final customerProfile = await customerDataRepo.customerProfileData();
        if (customerProfile.hasError) {
          return UiResult.error(error: customerProfile.error);
        }

        if (!customerProfile.hasData) {
          return UiResult.empty();
        }
        if (customerProfile.data.phone.orEmpty.isNotEmpty &&
            (usernameController.text == customerProfile.data.phone)) {
          return UiResult.error(
            // ไม่สามารถกรอกเบอร์ตัวเองได้
            error: OTPUnauthorized(
              ContentLocalizeData(
                en: 'Cannot enter your own phone number',
                zh: '无法输入您自己的电话号码',
                th: 'ไม่สามารถกรอกเบอร์ตัวเองได้',
              ).getTextByLocale(locale),
            ),
          );
        }

        final saveReferralResult = await customerDataRepo.saveReferral(
          CustomerCredential(
            referrerContact: usernameController.text,
            customerId: customerProfile.data.id,
            username: '',
            password: '',
          ),
        );

        if (saveReferralResult.isEmpty && saveReferralResult.hasError) {
          if (saveReferralResult.error is UserDuplicated) {
            _referralErrorMessageNotifier.value =
                (saveReferralResult.error as UserDuplicated).toUiMessage(
                  context,
                );
          } else if (saveReferralResult.error is AuthenExceptions) {
            _referralErrorMessageNotifier.value =
                (saveReferralResult.error as AuthenExceptions).toUiMessage(
                  context,
                );
          }
          return UiResult.empty(error: saveReferralResult.error);
        }
        if (saveReferralResult.hasError) {
          return UiResult.error(error: saveReferralResult.error);
        }

        return UiResult.success(data: null);
      }
      return UiResult.empty();
    }
    return UiResult.empty();
  }

  /// ตรวจสอบว่าระบบแนะนำเพื่อนเปิดใช้งานอยู่หรือไม่
  /// ถ้า API ล้มเหลว จะ fallback เป็น true (แสดง referral ตามปกติ)
  Future<bool> isReferralEnabled() async {
    try {
      final result = await customerDataRepo.fetchReferralStatus(
        phone: usernameController.text.trim(),
      );
      if (result.isSuccess) {
        return result.data.isEnabled;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<UiResult<LoginCustomerData>> socialLogin(
    SocialLoginType provider,
  ) async {
    await Future.wait([
      SocialAuthHelper.signOutGoogle(),
      SocialAuthHelper.signOutLINE(),
      SocialAuthHelper.signOutFacebook(),
    ]);

    UiResult<LoginCustomerData> result;
    switch (provider) {
      case SocialLoginType.FACEBOOK:
        {
          try {
            final userCredential = await SocialAuthHelper.signInWithFacebook();
            if (userCredential == null) {
              return UiResult.empty();
            }

            if (userCredential.user == null) {
              return UiResult.empty();
            }
            final userData = userCredential.user!;
            final email =
                userData.email ?? userData.providerData.first.email ?? '';

            if (email.isEmpty) {
              return UiResult.empty(error: UserUnauthorized('Email is empty'));
            }
            final socialLoginResult = await customerDataRepo.socialLogin(
              SocialLoginRequest(
                provider: 'facebook',
                appId: userData.uid,
                name: userData.displayName!,
                email: email,
                profileImage: userData.photoURL.orEmpty,
              ),
            );

            if (socialLoginResult.isEmpty || socialLoginResult.hasError) {
              return UiResult.empty(error: socialLoginResult.error);
            }
            if (socialLoginResult.data.data == null) {
              return UiResult.empty();
            }

            result = UiResult.success(data: socialLoginResult.data.data!);
            break;
          } on Exception catch (e) {
            // DONG 2026-03-14
            // ถ้าตก catch และเป็น iOS จะดึงข้อมูลตรงจาก FacebookAuth.accessToken ตรง
            // มีปัญหากับ Firebase ไม่สามารถ login facebook ได้
            if (Platform.isIOS) {
              // ดึงข้อมูลจาก accessToken ตรง
              final directInfo = await SocialAuthHelper.getFacebookDirectInfo();
              if (directInfo != null) {
                final user = directInfo['userInfo'] as LimitedToken;
                // ถ้าไม่ได้ Email จะไม่ให้ลงทะเบียน
                if (user.userEmail.orEmpty.isEmpty) return UiResult.empty();
                // ดึงข้อมูลส่ง API สมัครสมาชิก
                final socialLoginResult = await customerDataRepo.socialLogin(
                  SocialLoginRequest(
                    provider: 'facebook',
                    appId: user.userId,
                    name: user.userName,
                    email: user.userEmail!,
                    profileImage: '',
                  ),
                );

                if (socialLoginResult.isEmpty || socialLoginResult.hasError) {
                  return UiResult.empty(error: socialLoginResult.error);
                }
                if (socialLoginResult.data.data == null) {
                  return UiResult.empty();
                }

                result = UiResult.success(data: socialLoginResult.data.data!);
                break;
              }
            }
            return UiResult.error(error: e);
          }
        }
      case SocialLoginType.GOOGLE:
        {
          try {
            final userCredential = await SocialAuthHelper.signInWithGoogle();
            if (userCredential == null) {
              return UiResult.empty();
            }

            if (userCredential.user == null) {
              return UiResult.empty();
            }
            final userData = userCredential.user!;
            final email =
                userData.email ?? userData.providerData.first.email ?? '';

            if (email.isEmpty) {
              return UiResult.empty(error: UserUnauthorized('Email is empty'));
            }
            final socialLoginResult = await customerDataRepo.socialLogin(
              SocialLoginRequest(
                provider: 'google',
                appId: userData.uid,
                name: userData.displayName!,
                email: email,
                profileImage: userData.photoURL.orEmpty,
              ),
            );

            if (socialLoginResult.isEmpty || socialLoginResult.hasError) {
              return UiResult.empty(error: socialLoginResult.error);
            }
            if (socialLoginResult.data.data == null) {
              return UiResult.empty();
            }

            result = UiResult.success(data: socialLoginResult.data.data!);
            break;
          } on Exception catch (e) {
            return UiResult.error(error: e);
          }
        }
      case SocialLoginType.Apple:
        {
          try {
            bool available = await SocialAuthHelper.isAppleSignInAvailable();

            if (!available) {
              return UiResult.error(
                // ไม่รองรับ
                error: Unprocessable('ไม่รองรับ'),
              );
            }

            final userCredential = await SocialAuthHelper.signInWithApple();
            if (userCredential == null) {
              return UiResult.empty();
            }

            if (userCredential.user == null) {
              return UiResult.empty();
            }
            final userData = userCredential.user!;
            final email =
                userData.email ?? userData.providerData.first.email ?? '';

            if (email.isEmpty) {
              return UiResult.empty(error: UserUnauthorized('Email is empty'));
            }
            final socialLoginResult = await customerDataRepo.socialLogin(
              SocialLoginRequest(
                provider: 'apple',
                appId: userData.uid,
                name: userData.displayName!,
                email: email,
                profileImage: userData.photoURL.orEmpty,
              ),
            );

            if (socialLoginResult.isEmpty || socialLoginResult.hasError) {
              return UiResult.empty(error: socialLoginResult.error);
            }
            if (socialLoginResult.data.data == null) {
              return UiResult.empty();
            }

            result = UiResult.success(data: socialLoginResult.data.data!);
          } on Exception catch (e) {
            return UiResult.error(error: e);
          }
        }
      case SocialLoginType.LINE:
        {
          try {
            final userCredential = await SocialAuthHelper.signInWithLINE();
            if (userCredential == null) {
              return UiResult.empty();
            }

            if (userCredential.userProfile == null) {
              return UiResult.empty();
            }
            if (userCredential.accessToken.email == null) {
              return UiResult.error(
                error: UserConsentTermOfPolicy('Email is required!'),
              );
            }

            final userData = userCredential.userProfile!;
            final socialLoginResult = await customerDataRepo.socialLogin(
              SocialLoginRequest(
                provider: 'line',
                appId: userData.userId,
                name: userData.displayName,
                email: userCredential.accessToken.email.orEmpty,
                profileImage: userData.pictureUrl.orEmpty,
              ),
            );

            if (socialLoginResult.isEmpty || socialLoginResult.hasError) {
              return UiResult.empty(error: socialLoginResult.error);
            }
            if (socialLoginResult.data.data == null) {
              return UiResult.empty();
            }

            result = UiResult.success(data: socialLoginResult.data.data!);
          } on Exception catch (e) {
            return UiResult.error(error: e);
          }
        }
    }

    final profileResult = await _fetchProfileAfterLogin();

    if (!context.mounted || profileResult == null) return UiResult.empty();

    // เปลี่ยนข้อมูล User เป็นที่ Login เข้ามา
    currentCustomerProvider.newUser = profileResult;
    return result;
  }

  Future<UiResult<LoginCustomerData>> onLogin() async {
    if (formKeyLogin.currentState?.validate() == true) {
      final loginResult = await customerDataRepo.login(
        username: usernameController.text,
        password: passwordController.text,
      );

      if (loginResult.isEmpty) {
        return UiResult.empty(error: loginResult.error);
      }

      if (loginResult.hasError) {
        return UiResult.error(error: loginResult.error);
      }

      final profileResult = await _fetchProfileAfterLogin();

      if (!context.mounted || profileResult == null) return UiResult.empty();

      // เปลี่ยนข้อมูล User เป็นที่ Login เข้ามา
      currentCustomerProvider.newUser = profileResult;

      return UiResult.success(
        data: loginResult.data.data!,
      );
    }
    return UiResult.empty();
  }

  Future<UserModel?> _fetchProfileAfterLogin() async {
    final profileResult = await customerDataRepo.customerProfileData();

    if (!context.mounted) return null;

    // เปลี่ยนข้อมูล User เป็นที่ Login เข้ามา
    return UserModel.fromCustomerProfileData(
      profileResult.data,
    );
  }

  // =========== OTP Timer Methods ===========

  Future<void> startOtpTimer() async {
    final needSendOtp =
        currentProcess == AuthenProcess.signupOTP ||
        currentProcess == AuthenProcess.changePasswordOTP ||
        currentProcess == AuthenProcess.forgotPasswordOTP;
    if (!needSendOtp) {
      return;
    }
    if (_otpTimer == null || !_otpTimer!.isActive || _otpRequestResend) {
      await _requestOTP();

      _remainingSecondsNotifier.value = 60;
      _canResendOtpNotifier.value = false;
      _otpRequestResend = false;

      _otpTimer?.cancel();
      _otpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_remainingSecondsNotifier.value > 0) {
          _remainingSecondsNotifier.value--;
        } else {
          _canResendOtpNotifier.value = true;
          timer.cancel();
        }
      });
    }
  }

  bool _otpRequestResend = false;
  Future<void> resendOtp() async {
    _otpRequestResend = true;
    startOtpTimer();
  }

  /// Call API เพื่อส่ง OTP ไปตาม username ที่กรอกเข้ามา
  /// ถ้า [_otpTimer] active อยู่ จะไม่ส่งซ้ำ
  Future<void> _requestOTP() async {
    // TODO เอาจุดออกเวลาใช้จริง
    // print('OTP Requested');
    if (kDebugMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('OTP Requested')),
      );
      return;
    }

    final requestOTPResult = await otpDataRepo.requestOTP(
      RequestOTP(username: usernameController.text),
    );
    if (requestOTPResult.isSuccess) {
      _requestOtpNotifier.value = RequestOTPModel(
        refCode: requestOTPResult.data.data?.refCode ?? '',
      );
    }
  }

  void initializePageController() {
    // หา index ของ authenProcess ที่ส่งเข้ามา
    final initialIndex = _pageFlow.indexOf(authenProcess);
    pageController = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
    _currentPageIndexNotifier.value = initialIndex >= 0 ? initialIndex : 0;
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    pageController.dispose();
    _resetValidationNotifier.dispose();
    _referralErrorMessageNotifier.dispose();
    _otpButtonNextNotifier.dispose();
    _verifyOTPMessageErrorNotifier.dispose();
    _requestOtpNotifier.dispose();
    _validatorTriggleNotifier.dispose();
    _remainingSecondsNotifier.dispose();
    _canResendOtpNotifier.dispose();
    _currentPageIndexNotifier.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
