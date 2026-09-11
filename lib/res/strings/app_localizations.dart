import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'strings/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
    Locale('zh'),
  ];

  /// No description provided for @signUpWith.
  ///
  /// In en, this message translates to:
  /// **'Sign up with'**
  String get signUpWith;

  /// No description provided for @signUpDescription.
  ///
  /// In en, this message translates to:
  /// **'Become a member with Browny and enjoy many exclusive privileges.'**
  String get signUpDescription;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Browny ID account'**
  String get signUpTitle;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email / Phone number'**
  String get emailOrPhone;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @coin.
  ///
  /// In en, this message translates to:
  /// **'Coin'**
  String get coin;

  /// No description provided for @brownyClub.
  ///
  /// In en, this message translates to:
  /// **'Browny Club'**
  String get brownyClub;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get validUntil;

  /// No description provided for @evouchersAndPromotions.
  ///
  /// In en, this message translates to:
  /// **'E-vouchers and Promotions'**
  String get evouchersAndPromotions;

  /// No description provided for @laundryInProgress.
  ///
  /// In en, this message translates to:
  /// **'Laundry in Progress'**
  String get laundryInProgress;

  /// No description provided for @startWashing.
  ///
  /// In en, this message translates to:
  /// **'Start Washing'**
  String get startWashing;

  /// No description provided for @startDrying.
  ///
  /// In en, this message translates to:
  /// **'Start Drying'**
  String get startDrying;

  /// No description provided for @enterDiscountCodeOrPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a discount code or promo code.'**
  String get enterDiscountCodeOrPromoCode;

  /// No description provided for @displayExpiredOrFullyRedeemedCoupons.
  ///
  /// In en, this message translates to:
  /// **'Display expired or fully redeemed coupons.'**
  String get displayExpiredOrFullyRedeemedCoupons;

  /// No description provided for @redemptionCoupons.
  ///
  /// In en, this message translates to:
  /// **'Redemption Coupons'**
  String get redemptionCoupons;

  /// No description provided for @discountCoupons.
  ///
  /// In en, this message translates to:
  /// **'Discount Coupons'**
  String get discountCoupons;

  /// No description provided for @pleaseScanQR.
  ///
  /// In en, this message translates to:
  /// **'Please scan QR code on the machines.'**
  String get pleaseScanQR;

  /// No description provided for @typeStoreName.
  ///
  /// In en, this message translates to:
  /// **'Type store name'**
  String get typeStoreName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @scanPay.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanPay;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @washerAvai.
  ///
  /// In en, this message translates to:
  /// **'Washer'**
  String get washerAvai;

  /// No description provided for @dryerAvai.
  ///
  /// In en, this message translates to:
  /// **'Dryer'**
  String get dryerAvai;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get storeName;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @washer.
  ///
  /// In en, this message translates to:
  /// **'Washer'**
  String get washer;

  /// No description provided for @dryer.
  ///
  /// In en, this message translates to:
  /// **'Dryer'**
  String get dryer;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining time'**
  String get remainingTime;

  /// No description provided for @estimatedFinishTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated finish time'**
  String get estimatedFinishTime;

  /// No description provided for @thb.
  ///
  /// In en, this message translates to:
  /// **'THB'**
  String get thb;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @availableCoupons.
  ///
  /// In en, this message translates to:
  /// **'Available coupons'**
  String get availableCoupons;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportAnIssue;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changePasswordHam.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get changePasswordHam;

  /// No description provided for @referralRewards.
  ///
  /// In en, this message translates to:
  /// **'Referral rewards'**
  String get referralRewards;

  /// No description provided for @getReward.
  ///
  /// In en, this message translates to:
  /// **'Get reward'**
  String get getReward;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @biometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuthentication;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @termsOfUseAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use and Privacy Policy'**
  String get termsOfUseAndPrivacy;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @youHaveToInputTheSamePass.
  ///
  /// In en, this message translates to:
  /// **'You have to input the same password twice to confirm the new password.'**
  String get youHaveToInputTheSamePass;

  /// No description provided for @passwordMatches.
  ///
  /// In en, this message translates to:
  /// **'The new password matches.'**
  String get passwordMatches;

  /// No description provided for @atleast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atleast8Characters;

  /// No description provided for @continued.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continued;

  /// No description provided for @forgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotYourPassword;

  /// No description provided for @changePasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Change Password?'**
  String get changePasswordQuestion;

  /// No description provided for @becomeFriendsWithBrowny.
  ///
  /// In en, this message translates to:
  /// **'Become Friends with Browny'**
  String get becomeFriendsWithBrowny;

  /// No description provided for @yourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get yourPhoneNumber;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @numberOfSuccessfulReferrals.
  ///
  /// In en, this message translates to:
  /// **'Number of successful referrals'**
  String get numberOfSuccessfulReferrals;

  /// No description provided for @numberOfCouponsReceived.
  ///
  /// In en, this message translates to:
  /// **'Number of coupons received'**
  String get numberOfCouponsReceived;

  /// No description provided for @termsOfUseCap.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUseCap;

  /// No description provided for @updateYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Your Profile'**
  String get updateYourProfile;

  /// No description provided for @nameSurname.
  ///
  /// In en, this message translates to:
  /// **'Name - Surname'**
  String get nameSurname;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get genderNotSpecified;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @enterTheCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the current PIN'**
  String get enterTheCurrentPin;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN'**
  String get forgotPin;

  /// No description provided for @createNewPin.
  ///
  /// In en, this message translates to:
  /// **'Create new 6-digit PIN'**
  String get createNewPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get confirmNewPin;

  /// No description provided for @enterPin6Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter your 6-digit PIN'**
  String get enterPin6Digits;

  /// No description provided for @enableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Authentication'**
  String get enableBiometric;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @referralSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Referral saved successfully'**
  String get referralSavedSuccessfully;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @invalidContactInfoError.
  ///
  /// In en, this message translates to:
  /// **'Invalid contact information. Please try again.'**
  String get invalidContactInfoError;

  /// No description provided for @requestNewCode.
  ///
  /// In en, this message translates to:
  /// **'Request new code'**
  String get requestNewCode;

  /// No description provided for @eVouchers.
  ///
  /// In en, this message translates to:
  /// **'E-Voucher'**
  String get eVouchers;

  /// No description provided for @chooseStore.
  ///
  /// In en, this message translates to:
  /// **'Choose store'**
  String get chooseStore;

  /// No description provided for @typeStoreNameOrScanQR.
  ///
  /// In en, this message translates to:
  /// **'Type store name or scan QR'**
  String get typeStoreNameOrScanQR;

  /// No description provided for @choosePackage.
  ///
  /// In en, this message translates to:
  /// **'Choose package'**
  String get choosePackage;

  /// No description provided for @pleaseChooseStoreFirst.
  ///
  /// In en, this message translates to:
  /// **'Please choose store first'**
  String get pleaseChooseStoreFirst;

  /// No description provided for @iHaveReadAndAcceptedThe.
  ///
  /// In en, this message translates to:
  /// **'I have read and accepted the'**
  String get iHaveReadAndAcceptedThe;

  /// No description provided for @termsOfUseSmall.
  ///
  /// In en, this message translates to:
  /// **'terms of use.'**
  String get termsOfUseSmall;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @normalPrice.
  ///
  /// In en, this message translates to:
  /// **'Normal price'**
  String get normalPrice;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @washingCount.
  ///
  /// In en, this message translates to:
  /// **'#Washing'**
  String get washingCount;

  /// No description provided for @dryingCount.
  ///
  /// In en, this message translates to:
  /// **'#Drying'**
  String get dryingCount;

  /// No description provided for @totalPayment.
  ///
  /// In en, this message translates to:
  /// **'Total payment'**
  String get totalPayment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number.'**
  String get enterYourPhoneNumber;

  /// No description provided for @iHaveAccepted.
  ///
  /// In en, this message translates to:
  /// **'I have accepted'**
  String get iHaveAccepted;

  /// No description provided for @termsOfUseAndPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'term of use and privacy policy'**
  String get termsOfUseAndPrivacyPolicy;

  /// No description provided for @ofBrowny24hrWashAndDry.
  ///
  /// In en, this message translates to:
  /// **'of Browny 24hr Wash & Dry'**
  String get ofBrowny24hrWashAndDry;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @pleaseEnterThe6DigitsOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit OTP code sent to the number'**
  String get pleaseEnterThe6DigitsOtp;

  /// No description provided for @requestOtpAgain.
  ///
  /// In en, this message translates to:
  /// **'Request OTP again'**
  String get requestOtpAgain;

  /// No description provided for @setYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set your new password'**
  String get setYourNewPassword;

  /// No description provided for @setNewPasswordReady.
  ///
  /// In en, this message translates to:
  /// **'Just set a new password and you\'re ready to go! Let\'s get started'**
  String get setNewPasswordReady;

  /// No description provided for @inputPassword.
  ///
  /// In en, this message translates to:
  /// **'Input password'**
  String get inputPassword;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPassword;

  /// No description provided for @enterPhoneNumberOfaReferrer.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number of a referrer.'**
  String get enterPhoneNumberOfaReferrer;

  /// No description provided for @enterFriendPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Friend\'s Phone Number'**
  String get enterFriendPhoneNumber;

  /// No description provided for @friendReferralDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number of the friend who referred you to Browny'**
  String get friendReferralDescription;

  /// No description provided for @thisNumberDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'This number does not exist.'**
  String get thisNumberDoesNotExist;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get pleaseTryAgain;

  /// No description provided for @set6digitPin.
  ///
  /// In en, this message translates to:
  /// **'Set a 6-digit PIN'**
  String get set6digitPin;

  /// No description provided for @chooseProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Choose a profile picture'**
  String get chooseProfilePicture;

  /// No description provided for @estFinishTime.
  ///
  /// In en, this message translates to:
  /// **'Est. finish time'**
  String get estFinishTime;

  /// No description provided for @addDryingTime.
  ///
  /// In en, this message translates to:
  /// **'Add drying time'**
  String get addDryingTime;

  /// No description provided for @machineNo.
  ///
  /// In en, this message translates to:
  /// **'Machine No.'**
  String get machineNo;

  /// No description provided for @theMachineIsWorking.
  ///
  /// In en, this message translates to:
  /// **'The machine is working.'**
  String get theMachineIsWorking;

  /// No description provided for @chooseWashProgram.
  ///
  /// In en, this message translates to:
  /// **'Choose wash program'**
  String get chooseWashProgram;

  /// No description provided for @chooseCoupon.
  ///
  /// In en, this message translates to:
  /// **'Choose coupon'**
  String get chooseCoupon;

  /// No description provided for @viewAllCoupons.
  ///
  /// In en, this message translates to:
  /// **'View all coupons'**
  String get viewAllCoupons;

  /// No description provided for @selectTheAppropriateTemp.
  ///
  /// In en, this message translates to:
  /// **'Select the appropriate temperature setting for your laundry.'**
  String get selectTheAppropriateTemp;

  /// No description provided for @enterCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get enterCouponCode;

  /// No description provided for @washingPrice.
  ///
  /// In en, this message translates to:
  /// **'Washing'**
  String get washingPrice;

  /// No description provided for @dryingPrice.
  ///
  /// In en, this message translates to:
  /// **'Drying'**
  String get dryingPrice;

  /// No description provided for @storePromotion.
  ///
  /// In en, this message translates to:
  /// **'Store promotion'**
  String get storePromotion;

  /// No description provided for @discountCoupon.
  ///
  /// In en, this message translates to:
  /// **'Discount coupon'**
  String get discountCoupon;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @payByDebitOrCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Pay by debit or credit card'**
  String get payByDebitOrCreditCard;

  /// No description provided for @yourFinancialInformation.
  ///
  /// In en, this message translates to:
  /// **'Your financial information will always remain confidential and will not be shared with any third parties.'**
  String get yourFinancialInformation;

  /// No description provided for @storeTheCard.
  ///
  /// In en, this message translates to:
  /// **'Store the card information for future payments.'**
  String get storeTheCard;

  /// No description provided for @iConfirmThatMyCard.
  ///
  /// In en, this message translates to:
  /// **'I confirm that my card information has been stored in my Browny account for future transactions.'**
  String get iConfirmThatMyCard;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @extraDrying.
  ///
  /// In en, this message translates to:
  /// **'Extra drying'**
  String get extraDrying;

  /// No description provided for @remainingDay.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingDay;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @useCoupon.
  ///
  /// In en, this message translates to:
  /// **'Use Coupon'**
  String get useCoupon;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @fullyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Fully redeemed'**
  String get fullyRedeemed;

  /// No description provided for @doNotShowThisDialogAgain.
  ///
  /// In en, this message translates to:
  /// **'Do not show this dialog again.'**
  String get doNotShowThisDialogAgain;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @numberOfCoupon.
  ///
  /// In en, this message translates to:
  /// **'Number of coupon'**
  String get numberOfCoupon;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date / Time'**
  String get dateTime;

  /// No description provided for @saveTheReceipt.
  ///
  /// In en, this message translates to:
  /// **'Save the receipt'**
  String get saveTheReceipt;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @collectGift.
  ///
  /// In en, this message translates to:
  /// **'Collect gift'**
  String get collectGift;

  /// No description provided for @termsOfReceivingPrizes.
  ///
  /// In en, this message translates to:
  /// **'Terms of receiving prizes.'**
  String get termsOfReceivingPrizes;

  /// No description provided for @alwaysFun.
  ///
  /// In en, this message translates to:
  /// **'Always fun'**
  String get alwaysFun;

  /// No description provided for @withBrowny.
  ///
  /// In en, this message translates to:
  /// **'with Browny!'**
  String get withBrowny;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @machineType.
  ///
  /// In en, this message translates to:
  /// **'Machine type'**
  String get machineType;

  /// No description provided for @machineNumber.
  ///
  /// In en, this message translates to:
  /// **'Machine number'**
  String get machineNumber;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @backToMainPage.
  ///
  /// In en, this message translates to:
  /// **'Back to main page'**
  String get backToMainPage;

  /// No description provided for @deliveryInformation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Information'**
  String get deliveryInformation;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @tel.
  ///
  /// In en, this message translates to:
  /// **'Tel'**
  String get tel;

  /// No description provided for @addressInfo.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressInfo;

  /// No description provided for @applyCoupon.
  ///
  /// In en, this message translates to:
  /// **'Apply Coupon'**
  String get applyCoupon;

  /// No description provided for @readyToUse.
  ///
  /// In en, this message translates to:
  /// **'Ready to use'**
  String get readyToUse;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @addDryingTimeHead.
  ///
  /// In en, this message translates to:
  /// **'Add drying time'**
  String get addDryingTimeHead;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No Content.'**
  String get noContent;

  /// No description provided for @myAddress.
  ///
  /// In en, this message translates to:
  /// **'My addresses'**
  String get myAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add new address'**
  String get addNewAddress;

  /// No description provided for @manageAddress.
  ///
  /// In en, this message translates to:
  /// **'Manage Address'**
  String get manageAddress;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// No description provided for @creditAndDebit.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit'**
  String get creditAndDebit;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Error, Something went wrong.'**
  String get somethingWrong;

  /// No description provided for @pleaseEnterCorrectPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter correct phone number format'**
  String get pleaseEnterCorrectPhoneFormat;

  /// No description provided for @requestOtpAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Request OTP again in'**
  String get requestOtpAgainIn;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @notSpecifiedNameSurname.
  ///
  /// In en, this message translates to:
  /// **'Not specified Name-Surname'**
  String get notSpecifiedNameSurname;

  /// No description provided for @notSpecifiedDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Not specified date of birth'**
  String get notSpecifiedDateOfBirth;

  /// No description provided for @notSpecifiedEmail.
  ///
  /// In en, this message translates to:
  /// **'Not specified email'**
  String get notSpecifiedEmail;

  /// No description provided for @skipNow.
  ///
  /// In en, this message translates to:
  /// **'Skip now'**
  String get skipNow;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startNow;

  /// No description provided for @everyTimeOfUse.
  ///
  /// In en, this message translates to:
  /// **'Every spend'**
  String get everyTimeOfUse;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @seeAllPrize.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllPrize;

  /// No description provided for @viewYourProfile.
  ///
  /// In en, this message translates to:
  /// **'View your profile'**
  String get viewYourProfile;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @creditBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit Balance'**
  String get creditBalance;

  /// No description provided for @savedItems.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get savedItems;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @thai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get thai;

  /// No description provided for @allowBiometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Allow Biometric Authentication'**
  String get allowBiometricAuth;

  /// No description provided for @autoSaveReceipt.
  ///
  /// In en, this message translates to:
  /// **'Auto Save Receipt'**
  String get autoSaveReceipt;

  /// No description provided for @locationAccess.
  ///
  /// In en, this message translates to:
  /// **'Location Access'**
  String get locationAccess;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @generalNotifications.
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get generalNotifications;

  /// No description provided for @workOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Work/Order Status'**
  String get workOrderStatus;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @contactBrownyCare.
  ///
  /// In en, this message translates to:
  /// **'Contact Browny Care'**
  String get contactBrownyCare;

  /// No description provided for @callPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callPhoneNumber;

  /// No description provided for @contactViaLine.
  ///
  /// In en, this message translates to:
  /// **'Inquiry via LINE Browny Official'**
  String get contactViaLine;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery details'**
  String get deliveryDetails;

  /// No description provided for @recipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient name'**
  String get recipientName;

  /// No description provided for @recipientTel.
  ///
  /// In en, this message translates to:
  /// **'Recipient tel'**
  String get recipientTel;

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemDetails;

  /// No description provided for @specialPrice.
  ///
  /// In en, this message translates to:
  /// **'Special price'**
  String get specialPrice;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get netAmount;

  /// No description provided for @editDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Delivery Address'**
  String get editDeliveryAddress;

  /// No description provided for @recipientDetails.
  ///
  /// In en, this message translates to:
  /// **'Recipient Details'**
  String get recipientDetails;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @nameS.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameS;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @telS.
  ///
  /// In en, this message translates to:
  /// **'Telephone'**
  String get telS;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCode;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @subDistrict.
  ///
  /// In en, this message translates to:
  /// **'Sub-district'**
  String get subDistrict;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get streetAddress;

  /// No description provided for @messageToDeliveryPerson.
  ///
  /// In en, this message translates to:
  /// **'Message to a delivery person.'**
  String get messageToDeliveryPerson;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromPrice;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @pleaseEnterEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or phone number'**
  String get pleaseEnterEmailOrPhone;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @pleaseEnterValidEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email or phone number'**
  String get pleaseEnterValidEmailOrPhone;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMustBeAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordMustBeAtLeast8Characters;

  /// No description provided for @passwordMustContainUppercase.
  ///
  /// In en, this message translates to:
  /// **'Contain at least one uppercase letter'**
  String get passwordMustContainUppercase;

  /// No description provided for @passwordMustContainLowercase.
  ///
  /// In en, this message translates to:
  /// **'Contain at least one lowercase letter'**
  String get passwordMustContainLowercase;

  /// No description provided for @passwordMustContainNumber.
  ///
  /// In en, this message translates to:
  /// **'Contain at least one number'**
  String get passwordMustContainNumber;

  /// No description provided for @loginWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Browny welcomes you, let\'s do laundry together!'**
  String get loginWelcomeDescription;

  /// No description provided for @loginWith.
  ///
  /// In en, this message translates to:
  /// **'Login with'**
  String get loginWith;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email/phone number'**
  String get forgotPasswordDescription;

  /// No description provided for @dontHaveAccountYet.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account yet?'**
  String get dontHaveAccountYet;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now!'**
  String get signUpNow;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @errorUi.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorUi;

  /// No description provided for @topup.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topup;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User account not found for this information.'**
  String get userNotFound;

  /// No description provided for @userUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get userUnauthorized;

  /// No description provided for @userDuplicated.
  ///
  /// In en, this message translates to:
  /// **'This user already exists.'**
  String get userDuplicated;

  /// No description provided for @confirmOTP.
  ///
  /// In en, this message translates to:
  /// **'Confirm One-Time Password (OTP)'**
  String get confirmOTP;

  /// No description provided for @confirmOTPDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit one-time password to verify your account'**
  String get confirmOTPDescription;

  /// No description provided for @otpUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect OTP code. Please request a new password.'**
  String get otpUnauthorizedError;

  /// No description provided for @otpExpiredError.
  ///
  /// In en, this message translates to:
  /// **'OTP has expired'**
  String get otpExpiredError;

  /// No description provided for @ddMMyy.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YY'**
  String get ddMMyy;

  /// No description provided for @addPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get addPhoneNumber;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @balanceRemaining.
  ///
  /// In en, this message translates to:
  /// **'Balance Remaining'**
  String get balanceRemaining;

  /// No description provided for @reportIssueOrRefundMessage.
  ///
  /// In en, this message translates to:
  /// **'*If you encounter any usage problems or wish to request a refund, please click here'**
  String get reportIssueOrRefundMessage;

  /// No description provided for @specifyAmount.
  ///
  /// In en, this message translates to:
  /// **'Specify Amount'**
  String get specifyAmount;

  /// No description provided for @minimumTopUp.
  ///
  /// In en, this message translates to:
  /// **'Minimum top-up 100 THB'**
  String get minimumTopUp;

  /// No description provided for @payWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payWith;

  /// No description provided for @promptPayQRCode.
  ///
  /// In en, this message translates to:
  /// **'PromptPay QR Code'**
  String get promptPayQRCode;

  /// No description provided for @minimumTopUpValidation.
  ///
  /// In en, this message translates to:
  /// **'Minimum top-up 100 THB'**
  String get minimumTopUpValidation;

  /// No description provided for @maximumTopUpValidation.
  ///
  /// In en, this message translates to:
  /// **'Maximum top-up 2,000 THB'**
  String get maximumTopUpValidation;

  /// No description provided for @qrCodeSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'QR Code saved successfully'**
  String get qrCodeSavedSuccessfully;

  /// No description provided for @cannotSaveQRCode.
  ///
  /// In en, this message translates to:
  /// **'Cannot save QR Code'**
  String get cannotSaveQRCode;

  /// No description provided for @pleaseAllowPhotoLibraryAccess.
  ///
  /// In en, this message translates to:
  /// **'Please allow photo library access in settings'**
  String get pleaseAllowPhotoLibraryAccess;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorOccurred;

  /// No description provided for @cancelTransaction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Transaction'**
  String get cancelTransaction;

  /// No description provided for @confirmCancelTransaction.
  ///
  /// In en, this message translates to:
  /// **'Do you want to cancel the transaction?'**
  String get confirmCancelTransaction;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @transactionReceipt.
  ///
  /// In en, this message translates to:
  /// **'Transaction Receipt'**
  String get transactionReceipt;

  /// No description provided for @backToTopUpPage.
  ///
  /// In en, this message translates to:
  /// **'Back to Top-up Page'**
  String get backToTopUpPage;

  /// No description provided for @transactionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Transaction Successful'**
  String get transactionSuccessful;

  /// No description provided for @youReceivedBonus.
  ///
  /// In en, this message translates to:
  /// **'You received a bonus'**
  String get youReceivedBonus;

  /// No description provided for @transactionNumber.
  ///
  /// In en, this message translates to:
  /// **'Transaction Number'**
  String get transactionNumber;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @noTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'No Transaction History'**
  String get noTransactionHistory;

  /// No description provided for @topUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Top-up Failed'**
  String get topUpFailed;

  /// No description provided for @topUpFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Due to a problem with the destination bank or insufficient account balance. Please check the transaction again.'**
  String get topUpFailedMessage;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// No description provided for @brownyID.
  ///
  /// In en, this message translates to:
  /// **'Browny ID'**
  String get brownyID;

  /// No description provided for @inviteFriendsForCoupons.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends for Coupons'**
  String get inviteFriendsForCoupons;

  /// No description provided for @rewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewardsTitle;

  /// No description provided for @termsAndConditions2.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions2;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// No description provided for @noRewardsFound.
  ///
  /// In en, this message translates to:
  /// **'No rewards found'**
  String get noRewardsFound;

  /// No description provided for @cannotEnableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Cannot enable Biometric'**
  String get cannotEnableBiometric;

  /// No description provided for @qrCodeNotFoundInImage.
  ///
  /// In en, this message translates to:
  /// **'QR Code not found in image'**
  String get qrCodeNotFoundInImage;

  /// No description provided for @makePayment.
  ///
  /// In en, this message translates to:
  /// **'Make Payment'**
  String get makePayment;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @collectCoupon.
  ///
  /// In en, this message translates to:
  /// **'Collect Coupon'**
  String get collectCoupon;

  /// No description provided for @scanCoupon.
  ///
  /// In en, this message translates to:
  /// **'Scan Coupon'**
  String get scanCoupon;

  /// No description provided for @sakob.
  ///
  /// In en, this message translates to:
  /// **'Wash-Dry'**
  String get sakob;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @orderPlacement.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orderPlacement;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get mine;

  /// No description provided for @eVoucherDetails.
  ///
  /// In en, this message translates to:
  /// **'E-Voucher Details'**
  String get eVoucherDetails;

  /// No description provided for @buyEVoucher.
  ///
  /// In en, this message translates to:
  /// **'Buy E-Voucher Coupon'**
  String get buyEVoucher;

  /// No description provided for @birthdaySpecialConditions.
  ///
  /// In en, this message translates to:
  /// **'Birthday Special Conditions'**
  String get birthdaySpecialConditions;

  /// No description provided for @profileSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileSavedSuccessfully;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogoutMessage;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @changeBirthday.
  ///
  /// In en, this message translates to:
  /// **'Change Birthday'**
  String get changeBirthday;

  /// No description provided for @searchStoreParticipating.
  ///
  /// In en, this message translates to:
  /// **'Search for participating stores'**
  String get searchStoreParticipating;

  /// No description provided for @storeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No stores found'**
  String get storeNotFound;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @myCoins.
  ///
  /// In en, this message translates to:
  /// **'My Coins'**
  String get myCoins;

  /// No description provided for @availableCoins.
  ///
  /// In en, this message translates to:
  /// **'Available Coins'**
  String get availableCoins;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @allHistory.
  ///
  /// In en, this message translates to:
  /// **'All History'**
  String get allHistory;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @usageStatus.
  ///
  /// In en, this message translates to:
  /// **'Working Status'**
  String get usageStatus;

  /// No description provided for @loveAnyoneDoLaundry.
  ///
  /// In en, this message translates to:
  /// **'#Love Anyone Do Laundry'**
  String get loveAnyoneDoLaundry;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @usageHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction\nHistory'**
  String get usageHistory;

  /// No description provided for @contactInquiry.
  ///
  /// In en, this message translates to:
  /// **'Contact\nUs'**
  String get contactInquiry;

  /// No description provided for @collectMoreDaily.
  ///
  /// In en, this message translates to:
  /// **'Collect Daily'**
  String get collectMoreDaily;

  /// No description provided for @pleaseTryAnotherMachine.
  ///
  /// In en, this message translates to:
  /// **'Please try another machine.'**
  String get pleaseTryAnotherMachine;

  /// No description provided for @machineUnavailableAtTheMoment.
  ///
  /// In en, this message translates to:
  /// **'Machine is currently unavailable.'**
  String get machineUnavailableAtTheMoment;

  /// No description provided for @machineTemporarilyDisabled.
  ///
  /// In en, this message translates to:
  /// **'This machine is temporarily disabled.'**
  String get machineTemporarilyDisabled;

  /// No description provided for @systemTemporarilyUnderMaintenance.
  ///
  /// In en, this message translates to:
  /// **'The system is temporarily under maintenance.'**
  String get systemTemporarilyUnderMaintenance;

  /// No description provided for @orderCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order has been completed.'**
  String get orderCompletedMessage;

  /// No description provided for @orderNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFoundTitle;

  /// No description provided for @orderNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This order was not found.'**
  String get orderNotFoundMessage;

  /// No description provided for @insufficientWalletBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient TP+ Wallet balance'**
  String get insufficientWalletBalanceTitle;

  /// No description provided for @insufficientWalletBalanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Please top up or change your payment method.'**
  String get insufficientWalletBalanceMessage;

  /// No description provided for @cannotCreateOrder.
  ///
  /// In en, this message translates to:
  /// **'Unable to create order.'**
  String get cannotCreateOrder;

  /// No description provided for @paymentReferenceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Payment reference not found.'**
  String get paymentReferenceNotFound;

  /// No description provided for @totalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Total discount'**
  String get totalDiscount;

  /// No description provided for @machineDataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Machine data not found or an error occurred.\nPlease check and try again.'**
  String get machineDataLoadError;

  /// No description provided for @couponAndEVoucher.
  ///
  /// In en, this message translates to:
  /// **'Coupon / E-Voucher'**
  String get couponAndEVoucher;

  /// No description provided for @addOrSelect.
  ///
  /// In en, this message translates to:
  /// **'Add/Select'**
  String get addOrSelect;

  /// No description provided for @participatingStoresOnly.
  ///
  /// In en, this message translates to:
  /// **'Participating stores only'**
  String get participatingStoresOnly;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @startOperation.
  ///
  /// In en, this message translates to:
  /// **'Start operation'**
  String get startOperation;

  /// No description provided for @estimatedCompletion.
  ///
  /// In en, this message translates to:
  /// **'Estimated Completion'**
  String get estimatedCompletion;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @selectedService.
  ///
  /// In en, this message translates to:
  /// **'Selected Service'**
  String get selectedService;

  /// No description provided for @approximateRemainingTime.
  ///
  /// In en, this message translates to:
  /// **'Approximate Remaining Time'**
  String get approximateRemainingTime;

  /// No description provided for @startMachineOperation.
  ///
  /// In en, this message translates to:
  /// **'Start Machine Operation'**
  String get startMachineOperation;

  /// No description provided for @pleasePressMachineButton.
  ///
  /// In en, this message translates to:
  /// **'Please press the button on the machine to start.'**
  String get pleasePressMachineButton;

  /// No description provided for @checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get checkStatus;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report Problem'**
  String get reportProblem;

  /// No description provided for @continueWithoutCoupon.
  ///
  /// In en, this message translates to:
  /// **'Continue without coupon'**
  String get continueWithoutCoupon;

  /// No description provided for @couponAndVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon and Voucher Code'**
  String get couponAndVoucherCode;

  /// No description provided for @codeAndScan.
  ///
  /// In en, this message translates to:
  /// **'Code and Scan'**
  String get codeAndScan;

  /// No description provided for @enterYourCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your coupon code here'**
  String get enterYourCouponCode;

  /// No description provided for @washerCoupon.
  ///
  /// In en, this message translates to:
  /// **'Washer Coupon'**
  String get washerCoupon;

  /// No description provided for @dryerCoupon.
  ///
  /// In en, this message translates to:
  /// **'Dryer Coupon'**
  String get dryerCoupon;

  /// No description provided for @washerDryerCoupon.
  ///
  /// In en, this message translates to:
  /// **'Washer & Dryer Coupon'**
  String get washerDryerCoupon;

  /// No description provided for @couponNotFoundOf.
  ///
  /// In en, this message translates to:
  /// **'No {title} found'**
  String couponNotFoundOf(String title);

  /// No description provided for @collapseMore.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseMore;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showNearbyEVoucherPackages.
  ///
  /// In en, this message translates to:
  /// **'Show E-Voucher packages near me within 25 km.'**
  String get showNearbyEVoucherPackages;

  /// No description provided for @evoucherNotFound.
  ///
  /// In en, this message translates to:
  /// **'E-Voucher not found'**
  String get evoucherNotFound;

  /// No description provided for @startService.
  ///
  /// In en, this message translates to:
  /// **'Start service'**
  String get startService;

  /// No description provided for @afterPurchaseEVoucher.
  ///
  /// In en, this message translates to:
  /// **'{expireDate} after purchasing {type}'**
  String afterPurchaseEVoucher(String expireDate, String type);

  /// No description provided for @useWithin.
  ///
  /// In en, this message translates to:
  /// **'Use within\n{dateLeft}'**
  String useWithin(String dateLeft);

  /// No description provided for @washRemainLabel.
  ///
  /// In en, this message translates to:
  /// **'Wash\n{washRemain}'**
  String washRemainLabel(String washRemain);

  /// No description provided for @dryRemainLabel.
  ///
  /// In en, this message translates to:
  /// **'Dry\n{dryRemain}'**
  String dryRemainLabel(String dryRemain);

  /// No description provided for @cannotLoadCouponData.
  ///
  /// In en, this message translates to:
  /// **'Cannot load coupon data'**
  String get cannotLoadCouponData;

  /// No description provided for @dataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Data not found'**
  String get dataNotFound;

  /// No description provided for @washTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Wash\n{count} times'**
  String washTimesLabel(String count);

  /// No description provided for @washAndDryTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Wash/Dry\n{count} times'**
  String washAndDryTimesLabel(String count);

  /// No description provided for @dryTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dry\n{count} times'**
  String dryTimesLabel(String count);

  /// No description provided for @facilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get facilities;

  /// No description provided for @locationAccessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location access unavailable'**
  String get locationAccessDeniedTitle;

  /// No description provided for @locationAccessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please allow location access before using this feature'**
  String get locationAccessDeniedMessage;

  /// No description provided for @voiceSearchNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Your device does not support voice search'**
  String get voiceSearchNotSupported;

  /// No description provided for @machineAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get machineAvailable;

  /// No description provided for @machineOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get machineOccupied;

  /// No description provided for @conditionsAndDetails.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditionsAndDetails;

  /// No description provided for @otherCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Other Campaigns'**
  String get otherCampaigns;

  /// No description provided for @scanQrActivity.
  ///
  /// In en, this message translates to:
  /// **'Scan QR In-Store Activity'**
  String get scanQrActivity;

  /// No description provided for @noLuckyScanActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Lucky Scan'**
  String get noLuckyScanActivityTitle;

  /// No description provided for @noLuckyScanActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned for the next activity'**
  String get noLuckyScanActivityMessage;

  /// No description provided for @luckyScanHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'All Lucky Scan History'**
  String get luckyScanHistoryTitle;

  /// No description provided for @noLuckyScanHistory.
  ///
  /// In en, this message translates to:
  /// **'No Lucky Scan History Found'**
  String get noLuckyScanHistory;

  /// No description provided for @luckyScanWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get luckyScanWon;

  /// No description provided for @luckyScanNotWon.
  ///
  /// In en, this message translates to:
  /// **'Not Won'**
  String get luckyScanNotWon;

  /// No description provided for @viewCoupon.
  ///
  /// In en, this message translates to:
  /// **'View Coupon'**
  String get viewCoupon;

  /// No description provided for @washDry.
  ///
  /// In en, this message translates to:
  /// **'Wash-Dry'**
  String get washDry;

  /// No description provided for @hideForToday.
  ///
  /// In en, this message translates to:
  /// **'Hide for today'**
  String get hideForToday;

  /// No description provided for @receiptNotFound.
  ///
  /// In en, this message translates to:
  /// **'Receipt not found'**
  String get receiptNotFound;

  /// No description provided for @operationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get operationSuccessful;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get totalAmount;

  /// No description provided for @qrCodeForSupportOnly.
  ///
  /// In en, this message translates to:
  /// **'QR Code for Browny Support only'**
  String get qrCodeForSupportOnly;

  /// No description provided for @rateStoreCleanlinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate the store cleanliness'**
  String get rateStoreCleanlinessTitle;

  /// No description provided for @reviewVeryBad.
  ///
  /// In en, this message translates to:
  /// **'Very bad'**
  String get reviewVeryBad;

  /// No description provided for @reviewDissatisfied.
  ///
  /// In en, this message translates to:
  /// **'Dissatisfied'**
  String get reviewDissatisfied;

  /// No description provided for @reviewNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get reviewNeutral;

  /// No description provided for @reviewGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewGood;

  /// No description provided for @reviewExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get reviewExcellent;

  /// No description provided for @brownyReceipt.
  ///
  /// In en, this message translates to:
  /// **'Browny Receipt'**
  String get brownyReceipt;

  /// No description provided for @backToEvoucher.
  ///
  /// In en, this message translates to:
  /// **'Back to E-Voucher'**
  String get backToEvoucher;

  /// No description provided for @orderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderLabel;

  /// No description provided for @savedAmount.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedAmount;

  /// No description provided for @disableLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable location access'**
  String get disableLocationTitle;

  /// No description provided for @disableLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'To disable location access, please go to the device settings'**
  String get disableLocationMessage;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @conditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditions;

  /// No description provided for @collectCoins.
  ///
  /// In en, this message translates to:
  /// **'Collect Coins'**
  String get collectCoins;

  /// No description provided for @collectTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Collect Tomorrow'**
  String get collectTomorrow;

  /// No description provided for @collectCoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Browny Coin Collected Successfully'**
  String get collectCoinSuccess;

  /// No description provided for @collectCoinMotivation.
  ///
  /// In en, this message translates to:
  /// **'Keep collecting every day, great benefits await!'**
  String get collectCoinMotivation;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @makeOrder.
  ///
  /// In en, this message translates to:
  /// **'Make Order'**
  String get makeOrder;

  /// No description provided for @processingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Processing, please wait...'**
  String get processingPleaseWait;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @productDiscount.
  ///
  /// In en, this message translates to:
  /// **'Product Discount'**
  String get productDiscount;

  /// No description provided for @coinValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get coinValue;

  /// No description provided for @insufficientCoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Browny Coin Insufficient'**
  String get insufficientCoinTitle;

  /// No description provided for @changePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please change payment method'**
  String get changePaymentMethod;

  /// No description provided for @incompletePaymentData.
  ///
  /// In en, this message translates to:
  /// **'Incomplete payment data, please try again'**
  String get incompletePaymentData;

  /// No description provided for @alreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'Already Claimed'**
  String get alreadyClaimed;

  /// No description provided for @claimExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get claimExpired;

  /// No description provided for @claimsFullyAllocated.
  ///
  /// In en, this message translates to:
  /// **'Fully Allocated'**
  String get claimsFullyAllocated;

  /// No description provided for @claimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get claimReward;

  /// No description provided for @claimSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward Successfully'**
  String get claimSuccessMessage;

  /// No description provided for @noArticlesData.
  ///
  /// In en, this message translates to:
  /// **'No Articles Found'**
  String get noArticlesData;

  /// No description provided for @noArticlesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No Articles in This Category'**
  String get noArticlesInCategory;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @invalidCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Your coupon code is invalid'**
  String get invalidCouponCode;

  /// No description provided for @couponAlreadyCollected.
  ///
  /// In en, this message translates to:
  /// **'You have already collected this coupon'**
  String get couponAlreadyCollected;

  /// No description provided for @invalidOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old password is incorrect'**
  String get invalidOldPassword;

  /// No description provided for @newPasswordSameAsOld.
  ///
  /// In en, this message translates to:
  /// **'New password must not be the same as old password'**
  String get newPasswordSameAsOld;

  /// No description provided for @contactCallCenterForPhoneOrEmailChange.
  ///
  /// In en, this message translates to:
  /// **'To change your phone number / email, please contact the Call Center'**
  String get contactCallCenterForPhoneOrEmailChange;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// No description provided for @userCancelledBiometric.
  ///
  /// In en, this message translates to:
  /// **'You cancelled authentication'**
  String get userCancelledBiometric;

  /// No description provided for @biometricLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts\nPlease wait a moment or use PIN'**
  String get biometricLockedOut;

  /// No description provided for @biometricPermanentlyLocked.
  ///
  /// In en, this message translates to:
  /// **'Biometric permanently locked\nPlease use PIN'**
  String get biometricPermanentlyLocked;

  /// No description provided for @biometricAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get biometricAuthFailed;

  /// No description provided for @verifyIdentityToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please verify your identity to continue'**
  String get verifyIdentityToContinue;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @cannotSelfInvite.
  ///
  /// In en, this message translates to:
  /// **'Cannot enter your own phone number'**
  String get cannotSelfInvite;

  /// No description provided for @unsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get unsupported;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotifications;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @scannedActivityAlready.
  ///
  /// In en, this message translates to:
  /// **'You have already scanned this activity'**
  String get scannedActivityAlready;

  /// No description provided for @tryActivityNextDay.
  ///
  /// In en, this message translates to:
  /// **'Please try this activity again tomorrow'**
  String get tryActivityNextDay;

  /// No description provided for @scanToStart.
  ///
  /// In en, this message translates to:
  /// **'Scan to Start'**
  String get scanToStart;

  /// No description provided for @confirmSkip.
  ///
  /// In en, this message translates to:
  /// **'Confirm Skip'**
  String get confirmSkip;

  /// No description provided for @confirmSkipMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to skip saving profile information?'**
  String get confirmSkipMessage;

  /// No description provided for @requestLocation.
  ///
  /// In en, this message translates to:
  /// **'Request Location'**
  String get requestLocation;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable location access in device settings'**
  String get locationPermissionMessage;

  /// No description provided for @cameraAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Cannot open camera'**
  String get cameraAccessDenied;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please grant camera permission before using this feature'**
  String get cameraPermissionRequired;

  /// No description provided for @locationForNearestBranch.
  ///
  /// In en, this message translates to:
  /// **'Please grant location access to show nearest branches'**
  String get locationForNearestBranch;

  /// No description provided for @machineInUse.
  ///
  /// In en, this message translates to:
  /// **'Machine is in use'**
  String get machineInUse;

  /// No description provided for @tryOtherMachine.
  ///
  /// In en, this message translates to:
  /// **'Please try another machine'**
  String get tryOtherMachine;

  /// No description provided for @machineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Machine is not available at this time'**
  String get machineUnavailable;

  /// No description provided for @extendDryingTime.
  ///
  /// In en, this message translates to:
  /// **'Extend Drying Time'**
  String get extendDryingTime;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @priceSummary.
  ///
  /// In en, this message translates to:
  /// **'Price Summary'**
  String get priceSummary;

  /// No description provided for @branchPromotion.
  ///
  /// In en, this message translates to:
  /// **'Branch Promotion'**
  String get branchPromotion;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @startMachine.
  ///
  /// In en, this message translates to:
  /// **'Start Machine'**
  String get startMachine;

  /// No description provided for @washerProgram.
  ///
  /// In en, this message translates to:
  /// **'Washer Program'**
  String get washerProgram;

  /// No description provided for @dryerProgram.
  ///
  /// In en, this message translates to:
  /// **'Dryer Program'**
  String get dryerProgram;

  /// No description provided for @washerPrice.
  ///
  /// In en, this message translates to:
  /// **'Washer Price'**
  String get washerPrice;

  /// No description provided for @dryerPrice.
  ///
  /// In en, this message translates to:
  /// **'Dryer Price'**
  String get dryerPrice;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select Branch'**
  String get selectBranch;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service and Privacy Policy'**
  String get termsAndPrivacy;

  /// No description provided for @selectPaymentMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get selectPaymentMethodRequired;

  /// No description provided for @userDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'User data not found'**
  String get userDataNotFound;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations'**
  String get congratulations;

  /// No description provided for @couponAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Coupon added successfully'**
  String get couponAddedSuccessfully;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @inviteFriendsToBrowny.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends to Laundry with Browny'**
  String get inviteFriendsToBrowny;

  /// No description provided for @pinSetupNotFound.
  ///
  /// In en, this message translates to:
  /// **'PIN settings not found'**
  String get pinSetupNotFound;

  /// No description provided for @pleaseSetupPinFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set up your PIN before using this feature'**
  String get pleaseSetupPinFirst;

  /// No description provided for @setupPin.
  ///
  /// In en, this message translates to:
  /// **'Set Up PIN'**
  String get setupPin;

  /// No description provided for @pleaseConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Please verify your PIN'**
  String get pleaseConfirmPin;

  /// No description provided for @brownyShop.
  ///
  /// In en, this message translates to:
  /// **'Browny Shop'**
  String get brownyShop;

  /// No description provided for @selectEVoucherPackage.
  ///
  /// In en, this message translates to:
  /// **'Select E-Voucher Package'**
  String get selectEVoucherPackage;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Please Update Application'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateDescription.
  ///
  /// In en, this message translates to:
  /// **'Version v{appVersion} is no longer supported.\nPlease update to the latest version\nfor the best experience.'**
  String forceUpdateDescription(String appVersion);

  /// No description provided for @forceUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get forceUpdateButton;

  /// No description provided for @pinRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Please Set Up PIN'**
  String get pinRequiredTitle;

  /// No description provided for @pinRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You must set up a PIN before enabling Biometric authentication.'**
  String get pinRequiredMessage;

  /// No description provided for @pinRequiredConfirm.
  ///
  /// In en, this message translates to:
  /// **'Set Up PIN'**
  String get pinRequiredConfirm;

  /// No description provided for @biometricNotAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Not Supported'**
  String get biometricNotAvailableTitle;

  /// No description provided for @biometricNotAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Your device does not support Biometric authentication.'**
  String get biometricNotAvailableMessage;

  /// No description provided for @couponMinimumAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum order amount of {minAmount} is required.'**
  String couponMinimumAmountRequired(String minAmount);

  /// No description provided for @noCouponEligible.
  ///
  /// In en, this message translates to:
  /// **'No eligible coupon found'**
  String get noCouponEligible;

  /// No description provided for @couponNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Not eligible for this promotion'**
  String get couponNotEligible;

  /// No description provided for @cannotUseCouponType.
  ///
  /// In en, this message translates to:
  /// **'Cannot use {couponType}'**
  String cannotUseCouponType(String couponType);

  /// No description provided for @orderHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistoryTitle;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @noOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'No order history found'**
  String get noOrderHistory;

  /// No description provided for @orderHistoryReceiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt No.'**
  String get orderHistoryReceiptNo;

  /// No description provided for @orderHistoryStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get orderHistoryStore;

  /// No description provided for @orderHistoryMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get orderHistoryMachine;

  /// No description provided for @orderHistoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get orderHistoryPayment;

  /// No description provided for @orderHistoryAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get orderHistoryAmount;

  /// No description provided for @unavailableCoupons.
  ///
  /// In en, this message translates to:
  /// **'Unavailable Coupons'**
  String get unavailableCoupons;

  /// No description provided for @unavailableEVouchers.
  ///
  /// In en, this message translates to:
  /// **'Unavailable E-Vouchers'**
  String get unavailableEVouchers;

  /// No description provided for @couponExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get couponExpired;

  /// No description provided for @couponFullyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Fully Redeemed'**
  String get couponFullyRedeemed;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get changePhone;

  /// No description provided for @addEmail.
  ///
  /// In en, this message translates to:
  /// **'Add Email'**
  String get addEmail;

  /// No description provided for @currentContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentContactLabel;

  /// No description provided for @currentContactNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get currentContactNone;

  /// No description provided for @newEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmailPlaceholder;

  /// No description provided for @emailPlaceholderAdd.
  ///
  /// In en, this message translates to:
  /// **'Email (ex001@browny.com)'**
  String get emailPlaceholderAdd;

  /// No description provided for @newPhonePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'New phone number (08xxxxxxxx)'**
  String get newPhonePlaceholder;

  /// No description provided for @phonePlaceholderAdd.
  ///
  /// In en, this message translates to:
  /// **'Phone number (08xxxxxxxx)'**
  String get phonePlaceholderAdd;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOldContactOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP on current contact'**
  String get verifyOldContactOtp;

  /// No description provided for @confirmAndSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm and Save'**
  String get confirmAndSave;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to'**
  String get otpSentTo;

  /// No description provided for @pleaseEnterNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new email'**
  String get pleaseEnterNewEmail;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterValidOtp4Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 4-digit OTP'**
  String get pleaseEnterValidOtp4Digits;

  /// No description provided for @contactChangeSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get contactChangeSuccessTitle;

  /// No description provided for @contactChangeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsuccessful'**
  String get contactChangeErrorTitle;

  /// No description provided for @pleaseAddEmailFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Please add an email first'**
  String get pleaseAddEmailFirstTitle;

  /// No description provided for @pleaseAddEmailFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Please add an email on this page before changing email'**
  String get pleaseAddEmailFirstMessage;

  /// No description provided for @emailChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email changed successfully'**
  String get emailChangedSuccessfully;

  /// No description provided for @phoneChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Phone number changed successfully'**
  String get phoneChangedSuccessfully;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
