import 'package:browny_applications_new/core/env/app_evnironment.dart';
import 'package:browny_applications_new/core/providers/customer_provider.dart';
import 'package:browny_applications_new/core/viewmodels/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class AppViewModel extends ChangeNotifier {
  @protected
  BuildContext context;

  @protected
  late final AppPreferences appPreferences;

  /// เก็บ instance ไว้ตอนสร้าง ViewModel (context ยัง mounted แน่นอน) แทนการ
  /// `context.read<CustomerProvider>()` ใหม่ทุกครั้งที่เรียก [currentCustomerProvider]
  ///
  /// เพราะ CustomerProvider ถูก provide แค่ครั้งเดียวที่ root ของแอป (main.dart)
  /// เป็น singleton ตลอดอายุแอป (ดู DevEnvironment._current: final field)
  /// ไม่เคยถูกสร้างใหม่มาแทนที่แม้ตอน login/logout ก็แค่แก้ field ข้างในตัวเดิม
  ///
  /// ก่อนหน้านี้ getter นี้ไป context.read() ใหม่ทุกครั้ง ทำให้ถ้าเรียกหลัง await
  /// ในตอนที่หน้าจอถูก pop ไปแล้ว (context unmount) จะ throw
  /// "Null check operator used on a null value" ใน Provider._inheritedElementOf
  /// (ดู Crashlytics: MachineTransactionViewmodel.fetchPaymentMethod)
  @protected
  late final CustomerProvider _customerProvider;

  AppViewModel({required this.context}) {
    appPreferences = context.read<AppEvnironment>().appPreferences;
    _customerProvider = context.read<CustomerProvider>();
  }

  CustomerProvider get currentCustomerProvider => _customerProvider;

  void attachContext(BuildContext context) {
    this.context = context;
  }
}

mixin AppViewModelDelegateMixin {
  void disposeDelegate();
}

class AppViewModelObscureHandler extends AppViewModel {
  AppViewModelObscureHandler({
    required super.context,
    this.initIsObscure = true,
  });

  final bool initIsObscure;

  @protected
  late final ValueNotifier<bool> isObscureNotifier = ValueNotifier(
    initIsObscure,
  );
  ValueNotifier<bool> get isObscure => isObscureNotifier;
  void onObscureChange() {
    isObscureNotifier.value = !isObscureNotifier.value;
  }

  @override
  void dispose() {
    isObscureNotifier.dispose();
    super.dispose();
  }
}

class AppViewModelFormFieldValidation extends AppViewModelObscureHandler {
  AppViewModelFormFieldValidation({required super.context});

  // =========== Regex Patterns ===========

  /// Pattern สำหรับตรวจสอบอีเมล
  /// - ครอบคลุม RFC 5322 ส่วนใหญ่
  /// - รองรับ special characters ทั่วไป (+, ., -, _, etc.)
  /// - TLD อย่างน้อย 2 ตัวอักษร
  /// - Domain ต้องขึ้นต้นและลงท้ายด้วย alphanumeric
  static final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  /// Pattern สำหรับตรวจสอบเบอร์โทรศัพท์ไทย
  /// - 10 หลัก
  /// - ขึ้นต้นด้วย 0
  static final RegExp phoneThaiRegex = RegExp(r'^0\d{9}$');

  /// Pattern สำหรับตรวจสอบรหัสผ่าน - ตัวอักษร
  static final RegExp passwordCharacterRegex = RegExp(r'[a-zA-Z]');

  /// Pattern สำหรับตรวจสอบรหัสผ่าน - ตัวเลข
  static final RegExp passwordDigitRegex = RegExp(r'\d');

  /// Pattern สำหรับตรวจสอบรหัสผ่าน - uppercase
  static final RegExp passwordUppercaseRegex = RegExp(r'[A-Z]');

  /// Pattern สำหรับตรวจสอบรหัสผ่าน - lowercase
  static final RegExp passwordLowercaseRegex = RegExp(r'[a-z]');

  // =========== Validation Helper Methods ===========

  /// ตรวจสอบว่าเป็น email ที่ถูกต้องหรือไม่
  bool isValidEmail(String value) => emailRegex.hasMatch(value);

  /// ตรวจสอบว่าเป็นเบอร์โทรศัพท์ไทยที่ถูกต้องหรือไม่
  bool isValidPhoneThai(String value) => phoneThaiRegex.hasMatch(value);

  /// ตรวจสอบว่ารหัสผ่านมีตัวอักษรหรือไม่
  bool passwordHasCharacter(String value) =>
      passwordCharacterRegex.hasMatch(value);

  /// ตรวจสอบว่ารหัสผ่านมีตัวเลขหรือไม่
  bool passwordHasDigit(String value) => passwordDigitRegex.hasMatch(value);

  /// ตรวจสอบว่ารหัสผ่านมี uppercase หรือไม่
  bool passwordHasUppercase(String value) =>
      passwordUppercaseRegex.hasMatch(value);

  /// ตรวจสอบว่ารหัสผ่านมี lowercase หรือไม่
  bool passwordHasLowercase(String value) =>
      passwordLowercaseRegex.hasMatch(value);

  /// ตรวจสอบว่าเป็น email หรือ phone
  bool isEmailOrPhone(String value) {
    return isValidEmail(value) || isValidPhoneThai(value);
  }
}
