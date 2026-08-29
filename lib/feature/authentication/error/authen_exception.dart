import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:flutter/widgets.dart';

sealed class AuthenExceptions implements Exception {
  final String? message;

  AuthenExceptions([this.message]);

  String toUiMessage(BuildContext context) {
    return message.orEmpty;
  }

  @override
  String toString() {
    return message ?? 'Exception';
  }
}

class Unprocessable extends AuthenExceptions {
  Unprocessable([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    return super.message ?? context.wording.errorUi;
  }

  @override
  String toString() {
    return super.message ?? 'Unprocessable';
  }
}

class UserNotFound extends AuthenExceptions {
  UserNotFound([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    return context.wording.userNotFound;
  }

  @override
  String toString() {
    return super.message ?? 'UserNotFound';
  }
}

class UserUnauthorized extends AuthenExceptions {
  UserUnauthorized([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    return super.message ?? context.wording.userUnauthorized;
  }

  @override
  String toString() {
    return super.message ?? 'UserUnauthorized';
  }
}

class UserDuplicated extends AuthenExceptions {
  UserDuplicated([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    return super.message ?? context.wording.userDuplicated;
  }

  @override
  String toString() {
    return super.message ?? 'UserDuplicated';
  }
}

class UserConsentTermOfPolicy extends AuthenExceptions {
  UserConsentTermOfPolicy([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    return context.wording.userDuplicated;
  }

  @override
  String toString() {
    return super.message ?? 'UserConsentTermOfPolicy';
  }
}

class OTPUnauthorized extends AuthenExceptions {
  OTPUnauthorized([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    return context.wording.otpUnauthorizedError;
  }

  @override
  String toString() {
    return super.message ?? 'OTPUnauthorized';
  }
}

class OTPExpired extends AuthenExceptions {
  OTPExpired([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    return context.wording.otpUnauthorizedError;
  }

  @override
  String toString() {
    return super.message ?? 'OTPExpired';
  }
}

class CollectCouponNotFound extends AuthenExceptions {
  CollectCouponNotFound([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    // รหัสคูปองของคุณไม่ถูกต้อง
    return context.wording.invalidCouponCode;
  }

  @override
  String toString() {
    return super.message ?? 'Coupon Not Found';
  }
}

class CollectCouponCollected extends AuthenExceptions {
  CollectCouponCollected([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    // คุณได้รับคูปองนี้ไปแล้ว
    return context.wording.couponAlreadyCollected;
  }

  @override
  String toString() {
    return super.message ?? 'Coupon Collected';
  }
}

class ChangePasswordInvalidOldPassword extends AuthenExceptions {
  ChangePasswordInvalidOldPassword([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    // รหัสผ่านเดิมไม่ถูกต้อง
    return context.wording.invalidOldPassword;
  }

  @override
  String toString() {
    return super.message ?? 'Invalid old password!';
  }
}

class ChangePasswordReused extends AuthenExceptions {
  ChangePasswordReused([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    // รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม
    return context.wording.newPasswordSameAsOld;
  }

  @override
  String toString() {
    return super.message ?? 'Password re-used!';
  }
}

class ContactCallCenterException extends AuthenExceptions {
  static const contactCallCenterType = 'contact_call_center';
  ContactCallCenterException([super.message]);

  @override
  String toUiMessage(BuildContext context) {
    // กรณีเปลี่ยนเบอร์โทรศัพท์ / อีเมล กรุณาติดต่อ Call Center
    return context.wording.contactCallCenterForPhoneOrEmailChange;
  }

  @override
  String toString() {
    return super.message ?? 'Please contact Call Center';
  }
}
