import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:browny_applications_new/core/data/cache/app_local_storage.dart';
import 'package:browny_applications_new/core/data/cache/app_local_secure_storage.dart';
import 'package:browny_applications_new/core/data/cache/biometric_helper.dart';
import 'package:browny_applications_new/core/data/remote/models/request/update_notification_preferences_request.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/repository/pin_biometric_repository.dart';
import 'package:browny_applications_new/feature/authentication/screen/app_pin_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/pin_biometric_viewmodel.dart';
import 'package:browny_applications_new/core/data/remote/models/request/update_profile_request.dart';
import 'package:browny_applications_new/core/data/remote/models/response/birthday_promo_info_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/contact_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/customer_qr_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/notification_preferences_response.dart';
import 'package:browny_applications_new/core/utils/location_helper.dart';
import 'package:browny_applications_new/core/utils/social_auth_helper.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/feature/contacts/repository/contact_repo.dart';
import 'package:browny_applications_new/feature/profile/repository/notification_preferences_repo.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:geolocator/geolocator.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/ui_result.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:browny_applications_new/feature/profile/repository/profile_repo.dart';
import 'package:browny_applications_new/models/avatar_data.dart';
import 'package:browny_applications_new/models/user_model.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileViewModel extends AppViewModelFormFieldValidation {
  ProfileViewModel({
    required super.context,
    required this.repo,
    required this.contactRepo,
    required this.notificationPreferencesRepo,
  });

  // ========== Repository ==========
  final ProfileRepo repo;
  final ContactDataSourceMixin contactRepo;
  final PinBioMetricRepository pinBioMetricRepository =
      PinBioMetricRepository();
  final NotificationPreferencesDataSourceMixin notificationPreferencesRepo;

  // ========== Notifier, Controller ==========
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dateOfBirth = TextEditingController();
  // สำหรับ parseDate กรณีที่มีข้อมูลมาอยู่แล้วหรือเลือกใหม่
  DateTime initialCalendarDate() {
    final initDate = dateOfBirth.text;
    var initialDate = DateTime.now();
    if (initDate.isNotEmpty) {
      initialDate = DateFormat('dd/MM/yyyy').parse(initDate);
    }
    return initialDate;
  }

  /// ข้อมูล info จาก Gateway (null = ใช้ fallback hardcode)
  BirthdayPromoInfoResponse? _birthdayPromoInfo;

  String titlePopupBirthDayOffers(BuildContext context) {
    final remote = _birthdayPromoInfo?.title?.getText(context).trim();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }
    return _fallbackTitlePopupBirthDayOffers(context);
  }

  String descriptionPopupBirthDayOffers(BuildContext context) {
    final remote = _birthdayPromoInfo?.description?.getText(context).trim();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }
    return _fallbackDescriptionPopupBirthDayOffers(context);
  }

  /// URL รูปจาก API ตามภาษา — ว่างถ้าไม่มี ให้ UI ใช้ asset fallback
  String imageUrlPopupBirthDayOffers(BuildContext context) {
    return _birthdayPromoInfo?.image?.getText(context).trim() ?? '';
  }

  String _fallbackTitlePopupBirthDayOffers(BuildContext context) {
    switch (context.languageCode) {
      case 'en':
        return 'Special birthday privileges are waiting for you!';
      case 'zh':
        return '特别的生日优惠正在等着您!';
      default:
        return 'สิทธิพิเศษวันเกิดสุดพิเศษ รอคุณอยู่!';
    }
  }

  String _fallbackDescriptionPopupBirthDayOffers(BuildContext context) {
    switch (context.languageCode) {
      case 'en':
        return '''
<p>Terms and Conditions</p>
<ul>
<li>Receive special gifts and exclusive member promotions during your birth month</li>
<li>To ensure benefit accuracy, birthdate cannot be self-edited. If you need to change it, please contact admin with your ID card attached</li>
<li>If birthday privileges have already been used, birthdate cannot be modified</li>
</ul>
''';
      case 'zh':
        return '''
<p>条款和条件</p>
<ul>
<li>在您的生日月份获得特别礼物和会员专属促销</li>
<li>为确保福利的准确性，生日日期无法自行编辑。如需更改，请联系管理员并附上您的身份证</li>
<li>如果已使用生日特权，则无法修改生日日期</li>
</ul>
''';
      default:
        return '''
<p>เงื่อนไข</p>
<ul>
<li>รับของขวัญพิเศษ และโปรลับเฉพาะสมาชิกในเดือนเกิด</li>
<li>เพื่อความถูกต้องของสิทธิประโยชน์ วันเกิดจะไม่สามารถแก้ไขได้เอง หากต้องการเปลี่ยน โปรดติดต่อแอดมินพร้อมแนบรูปบัตรประชาชน</li>
<li>ถ้าหากใช้สิทธิพิเศษวันเกิดไปแล้ว จะไม่สามารถแก้ไขวันเกิดได้</li>
</ul>
''';
    }
  }

  late final CarouselSliderController carouselController =
      CarouselSliderController();

  late final UnmodifiableListView<UnmodifiableMapView<String, String>> genders =
      UnmodifiableListView(
        repo.genders.mapIndex((index, e) {
          switch (index) {
            case 1:
              // เพศชาย
              return UnmodifiableMapView({
                e: context.wording.male,
              });
            case 2:
              // เพศหญิง
              return UnmodifiableMapView({
                e: context.wording.female,
              });
            default:
              // ไม่ระบุ
              return UnmodifiableMapView({
                e: context.wording.genderNotSpecified,
              });
          }
        }),
      );

  late final ValueNotifier<UiResult<ContactResponse>>
  _contactAndSupportLinkNotifier = ValueNotifier(UiResult.loading());
  ValueListenable<UiResult<ContactResponse>>
  get contactAndSupportLinkNotifier => _contactAndSupportLinkNotifier;

  late final ValueNotifier<int> _currentSliderIndexNotifier = ValueNotifier(0);
  ValueListenable<int> get currentSliderIndexNotifier =>
      _currentSliderIndexNotifier;
  int get currentAvatarIndex => _currentSliderIndexNotifier.value;
  set updateIndex(int value) {
    _currentSliderIndexNotifier.value = value;
  }

  final ValueNotifier<UiResult<UserModel>> _profileDataNotifier = ValueNotifier(
    UiResult.loading(),
  );
  ValueListenable<UiResult<UserModel>> get profileData => _profileDataNotifier;

  // Notification Preferences
  final ValueNotifier<UiResult<NotificationPreferencesData>>
  _notificationPreferencesNotifier = ValueNotifier(UiResult.loading());
  ValueListenable<UiResult<NotificationPreferencesData>>
  get notificationPreferencesNotifier => _notificationPreferencesNotifier;

  // User Preferences (Biometric, Save Slip Auto, Location)
  final ValueNotifier<bool> _biometricEnabledNotifier = ValueNotifier(false);
  ValueListenable<bool> get biometricEnabledNotifier =>
      _biometricEnabledNotifier;

  final ValueNotifier<bool> _saveSlipAutoNotifier = ValueNotifier(false);
  ValueListenable<bool> get saveSlipAutoNotifier => _saveSlipAutoNotifier;

  final ValueNotifier<bool> _locationPermissionNotifier = ValueNotifier(false);
  ValueListenable<bool> get locationPermissionNotifier =>
      _locationPermissionNotifier;

  // Helper instances
  final _secureStorage = AppLocalSecureStorage.instance();
  final _localStorage = AppLocalStorage.instance();
  final _biometricHelper = BiometricHelper.instance();
  final _imagePicker = ImagePicker();

  /// fetch ข้อมูลช่องทางการติดต่อต่างๆ
  Future<void> fetchContactAndSupportLink() async {
    try {
      final result = await contactRepo.fetchContact();
      if (result.hasError || result.isEmpty) {
        _contactAndSupportLinkNotifier.value = UiResult.empty();
      }

      _contactAndSupportLinkNotifier.value = UiResult.success(
        data: result.data,
      );
    } catch (_) {
      _contactAndSupportLinkNotifier.value = UiResult.empty();
    }
  }

  /// DONG 2026-03-01
  ///
  /// Fetch ข้อมูลการตั้งค่าการแจ้งเตือน
  Future<void> fetchNotificationPreferences() async {
    _notificationPreferencesNotifier.value = UiResult.loading();

    final uuid = currentCustomerProvider.current.id;
    if (uuid == null || uuid.isEmpty) {
      _notificationPreferencesNotifier.value = UiResult.empty();
      return;
    }

    try {
      final result = await notificationPreferencesRepo
          .fetchNotificationPreferences(uuid);

      if (result.hasError) {
        _notificationPreferencesNotifier.value = UiResult.error(
          error: result.error,
        );
        return;
      }

      if (result.isEmpty || result.data.data == null) {
        _notificationPreferencesNotifier.value = UiResult.empty();
        return;
      }

      _notificationPreferencesNotifier.value = UiResult.success(
        data: result.data.data!,
      );
    } on Exception catch (e) {
      _notificationPreferencesNotifier.value = UiResult.error(error: e);
    } catch (e) {
      _notificationPreferencesNotifier.value = UiResult.error(
        error: Exception(e.toString()),
      );
    }
  }

  /// DONG 2026-03-01
  ///
  /// อัพเดทการตั้งค่าการแจ้งเตือน
  Future<void> updateNotificationPreferences({
    bool? notifyGeneral,
    bool? notifyPromotion,
    bool? notifyNews,
    bool? notifyMachineDone,
  }) async {
    final uuid = currentCustomerProvider.current.id;
    if (uuid == null || uuid.isEmpty) {
      return;
    }

    final currentData = _notificationPreferencesNotifier.value.data;
    if (currentData == null) {
      AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        message: context.wording.errorUi,
      );
      return;
    }

    // สร้าง request จากค่าปัจจุบัน + ค่าที่ต้องการอัพเดท
    final request = UpdateNotificationPreferencesRequest(
      notifyGeneral: notifyGeneral ?? (currentData.notifyGeneral == 1),
      notifyPromotion: notifyPromotion ?? (currentData.notifyPromotion == 1),
      notifyNews: notifyNews ?? (currentData.notifyNews == 1),
      notifyMachineDone:
          notifyMachineDone ?? (currentData.notifyMachineDone == 1),
    );

    try {
      final result = await notificationPreferencesRepo
          .updateNotificationPreferences(uuid, request);

      if (context.mounted && result.hasError) {
        // แสดง error แต่ไม่ต้อง update UI (เก็บค่าเดิมไว้)
        AppOverlays.showBrownyErrorDialog(
          context,
          title: context.wording.errorOccurred,
          error: result.error,
        );
        return;
      }

      // Update UI ด้วยค่าใหม่
      final updatedData = NotificationPreferencesData(
        notifyGeneral: request.notifyGeneral ? 1 : 0,
        notifyPromotion: request.notifyPromotion ? 1 : 0,
        notifyNews: request.notifyNews ? 1 : 0,
        notifyMachineDone: request.notifyMachineDone ? 1 : 0,
      );

      _notificationPreferencesNotifier.value = UiResult.success(
        data: updatedData,
      );
    } catch (e) {
      // ถ้า error ให้เก็บค่าเดิมไว้
      debugPrint('Error updating notification preferences: $e');
    }
  }

  // ========== User Preferences (Biometric, Save Slip Auto, Location) ==========

  /// DONG 2026-03-01
  ///
  /// Load ค่า preferences ทั้งหมด (เรียกใน initState)
  Future<void> loadUserPreferences() async {
    // 1. Biometric
    final biometricEnabled = await _secureStorage.isBiometricEnabled();
    _biometricEnabledNotifier.value = biometricEnabled;

    // 2. Save Slip Auto (Hive เป็น sync)
    final saveSlipAuto = _localStorage.isSaveSlipAutoEnabled();
    _saveSlipAutoNotifier.value = saveSlipAuto;

    // 3. Location Permission
    final locationPermission = await LocationHelper.checkLocationPermission();
    _locationPermissionNotifier.value =
        locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always;
  }

  /// DONG 2026-03-01
  ///
  /// Toggle Biometric Authentication
  /// - ต้องมี PIN ก่อนจึงจะเปิดได้
  Future<void> toggleBiometric(bool value) async {
    if (value) {
      // เปิด Biometric → ต้องเช็ค PIN ก่อน
      final hasPin = await _secureStorage.hasPin();

      if (!hasPin) {
        // ไม่มี PIN → ต้องไปตั้ง PIN ก่อน
        if (context.mounted) {
          // แสดง dialog แจ้งให้ไปตั้ง PIN
          await _showPinRequiredDialog();
        }
        return;
      }

      // มี PIN แล้ว → เช็คว่า device รองรับ biometric หรือไม่
      final isAvailable = await _biometricHelper.isBiometricAvailable();

      if (!isAvailable) {
        if (context.mounted) {
          // แสดง dialog แจ้งว่า device ไม่รองรับ
          await _showBiometricNotAvailableDialog();
        }
        return;
      }
      if (context.mounted) {
        final verified = await TransactionAuthenPage.goToPage(
          context,
          process: PinBiometricPross.verifyByPin,
        );
        if (verified) {
          // หลอกเพื่อให้ระบบ authen
          await _secureStorage.setBiometricEnabled(true);

          final result = await pinBioMetricRepository.authenticateWithBiometric(
            reason: 'กรุณายืนยันตัวตนเพื่อดำเนินการต่อ',
          );

          if (!context.mounted) return;
          if (result.hasError) {
            AppOverlays.showBrownyErrorDialog(
              context,
              title: context.wording.errorOccurred,
              error: result.error,
            );
            return;
          }
          // รองรับ → เปิด biometric
          await _secureStorage.setBiometricEnabled(result.data.isSuccess);
          _biometricEnabledNotifier.value = result.data.isSuccess;
        }
      }
    } else {
      final verified = await TransactionAuthenPage.goToPage(
        context,
        process: PinBiometricPross.verifyByPin,
      );
      if (verified) {
        // ปิด Biometric
        await _secureStorage.setBiometricEnabled(false);
        _biometricEnabledNotifier.value = false;
      }
    }
  }

  /// DONG 2026-03-01
  ///
  /// Toggle Save Slip Auto
  Future<void> toggleSaveSlipAuto(bool value) async {
    _localStorage.setSaveSlipAutoEnabled(value);
    _saveSlipAutoNotifier.value = value;
  }

  /// DONG 2026-03-01
  ///
  /// Toggle Location Permission
  Future<void> toggleLocationPermission(bool value) async {
    if (value) {
      // เปิด → ขอ permission
      final hasPermission = await LocationHelper.ensureLocationPermission();

      if (hasPermission) {
        _locationPermissionNotifier.value = true;
      } else {
        // ถ้า denied forever → แสดง dialog พาไป settings
        if (context.mounted) {
          final permission = await LocationHelper.checkLocationPermission();
          if (permission == LocationPermission.deniedForever) {
            await _showLocationDeniedForeverDialog();
          }
        }
        _locationPermissionNotifier.value = false;
      }
    } else {
      // ปิด → แสดง dialog ยืนยัน และพาไป settings
      if (context.mounted) {
        await _showDisableLocationDialog();
      }
    }
  }

  // ========== Dialog Helpers ==========

  /// แสดง dialog แจ้งให้ตั้ง PIN ก่อน
  Future<void> _showPinRequiredDialog() async {
    if (!context.mounted) return;

    await AppOverlays.showBrownyDialog(
      context,
      // กรุณาตั้งค่า PIN
      title: context.wording.pinRequiredTitle,
      // คุณต้องตั้งค่ารหัส PIN ก่อนจึงจะสามารถเปิดใช้งาน Biometric ได้
      message: context.wording.pinRequiredMessage,
      // ไปตั้งค่า PIN
      confirmText: context.wording.pinRequiredConfirm,
      onConfirm: () async {
        if (context.mounted) {
          await CreateAppPinPage.goToPage(
            context,
            process: PinBiometricPross.create,
          );
          // หลังจากกลับมา ลอง toggle biometric อีกครั้ง
          // เผื่อ user ไปตั้ง PIN เสร็จแล้ว
          if (context.mounted) {
            await toggleBiometric(true);
          }
        }
      },
      cancelText: context.wording.cancel,
      onCancel: () {
        // User cancelled
      },
    );
  }

  /// แสดง dialog แจ้งว่า device ไม่รองรับ biometric
  Future<void> _showBiometricNotAvailableDialog() async {
    if (!context.mounted) return;

    await AppOverlays.showBrownyDialog(
      context,
      // ไม่รองรับ Biometric
      title: context.wording.biometricNotAvailableTitle,
      // อุปกรณ์ของคุณไม่รองรับการยืนยันตัวตนด้วย Biometric
      message: context.wording.biometricNotAvailableMessage,
      confirmText: context.wording.confirm,
      onConfirm: () {
        // User acknowledged
      },
    );
  }

  /// แสดง dialog แจ้งว่า location permission denied forever
  Future<void> _showLocationDeniedForeverDialog() async {
    if (!context.mounted) return;

    await AppOverlays.showBrownyDialog(
      context,
      imageAsset: Assets.png.brownyMoto.path,
      // เข้าถึงตำแหน่ง
      title: context.wording.requestLocation,
      // กรุณาไปเปิดสิทธิ์เข้าถึงตำแหน่งในการตั้งค่าของอุปกรณ์
      message: context.wording.locationPermissionMessage,

      confirmText: context.wording.openSettings,
      onConfirm: () async {
        await LocationHelper.openLocationSettings();
      },
      cancelText: context.wording.cancel,
      onCancel: () {
        // User cancelled
      },
    );
  }

  /// แสดง dialog ยืนยันการปิด location permission
  Future<void> _showDisableLocationDialog() async {
    if (!context.mounted) return;

    await AppOverlays.showBrownyDialog(
      context,
      // ปิดการเข้าถึงตำแหน่ง
      title: context.wording.disableLocationTitle,
      // หากต้องการปิดสิทธิ์ การเข้าถึงตำแหน่ง กรุณาไปปิดในการตั้งค่าของอุปกรณ์
      message: context.wording.disableLocationMessage,
      confirmText: context.wording.openSettings,
      onConfirm: () async {
        await LocationHelper.openLocationSettings();
      },
      cancelText: context.wording.cancel,
      onCancel: () {
        // User cancelled
      },
    );
  }

  /// DONG 2026-02-21
  ///
  /// Fetch ข้อมูล QRCode ของลูกค้า
  Future<UiResult<CustomerQRResponse>> fetchCustomerQRCode() async {
    final result = await repo.fetchCustomerQR(
      currentCustomerProvider.current.id!,
    );

    if (result.isEmpty || result.hasError) {
      return UiResult.empty();
    }

    return UiResult.success(data: result.data);
  }

  /// หา index ของ avatar ท้ ตรงกับ imageUrl จาก avatarDataList
  /// จะข้าม picked image เพราะเป็น file ไม่ใช่ URL
  int _findAvatarIndex(String imageUrl, List<AvatarData> avatarDataList) {
    if (imageUrl.isEmpty || avatarDataList.isEmpty) return 0;

    // หาใน avatarDataList ที่ URL ตรงกับ imageUrl
    final index = avatarDataList.indexWhere(
      (avatar) => avatar.isFromUrl && avatar.url == imageUrl,
    );

    return index != -1 ? index : 0;
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        // Set/Replace picked image ใน avatarDataList (จะอยู่ที่ index 0 เสมอ)
        final updatedUser = _profileDataNotifier.value.data!.setPickedAvatar(
          image,
        );
        _profileDataNotifier.value = UiResult.success(data: updatedUser);
        scheduleMicrotask(() {
          // Reset index ไปที่ 0 เพื่อแสดงรูปที่ pick มาใหม่
          carouselController.animateToPage(
            0,
            duration: Duration(milliseconds: 1_000),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        // Set/Replace picked image ใน avatarDataList (จะอยู่ที่ index 0 เสมอ)
        final updatedUser = _profileDataNotifier.value.data!.setPickedAvatar(
          image,
        );
        _profileDataNotifier.value = UiResult.success(data: updatedUser);
        scheduleMicrotask(() {
          // Reset index ไปที่ 0 เพื่อแสดงรูปที่ pick มาใหม่
          carouselController.animateToPage(
            0,
            duration: Duration(milliseconds: 1_000),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// โหลด Birthday Promo Info จาก Gateway ใหม่ทุกครั้ง
  ///
  /// ใช้ตอนเข้า Profile และก่อนเปิด popup เพื่อให้เห็นค่าที่แก้ใน Admin ทันที
  /// API คืน null / error → เคลียร์แล้วให้ UI ใช้ hardcode fallback
  Future<void> fetchBirthdayPromoInfo() async {
    final promoResult = await repo.fetchBirthdayPromoInfo();
    if (promoResult.isSuccess) {
      _birthdayPromoInfo = promoResult.data;
    } else {
      _birthdayPromoInfo = null;
    }
  }

  Future<void> fetchProfileData() async {
    // โหลด birthday promo info คู่กับ profile (ไม่บล็อกถ้า error)
    final profileFuture = repo.fetchProfile('');
    final promoFuture = fetchBirthdayPromoInfo();

    final profileResult = await profileFuture;
    await promoFuture;

    if (profileResult.isEmpty) {
      if (profileResult.hasError) {
        _profileDataNotifier.value = UiResult.empty(
          error: profileResult.error,
        );
      } else {
        _profileDataNotifier.value = UiResult.empty();
      }
      return;
    }

    if (profileResult.hasError) {
      _profileDataNotifier.value = UiResult.error(error: profileResult.error);
      return;
    }

    final userModel = UserModel.fromCustomerProfileData(
      profileResult.data.data,
    );
    // fetch กลับเก็บค่าใหม่ที่ provider ด้วย
    currentCustomerProvider.newUser = userModel;

    // หา index ของรูป profile ที่เลือกไว้ (จาก avatarDataList)
    final currentImageUrl = _profileDataNotifier.value.data == null
        ? userModel.image.orEmpty
        : _profileDataNotifier.value.data!.image.orEmpty;

    final mFindIndexAvatar = _findAvatarIndex(
      currentImageUrl,
      userModel.avatarDataList,
    );

    // update Avatar index เพื่อให้แสดงรูปที่เลือกไว้
    updateIndex = mFindIndexAvatar;
    // updaet Email ที่ fetch มา
    emailController.text = userModel.email.orEmpty;
    // updaet name ที่ fetch มา
    nameController.text = userModel.name.orEmpty;
    // update Gender ที่ fetch มา
    genderController.text = userModel.gender.ifNullOrEmpty(
      genders.first.keys.first,
    );
    // update Birthday ที่ fetch มา
    try {
      dateOfBirth.text = DateTime.parse(
        userModel.birthday.orEmpty,
      ).formatForShow();
    } on Exception catch (_) {
      dateOfBirth.text = '';
    }

    _profileDataNotifier.value = UiResult.success(
      data: userModel,
    );
  }

  void onPhoneUpdate(String phone) {
    _profileDataNotifier.value = UiResult.success(
      data: _profileDataNotifier.value.data!.copyWith(
        phone: phone,
      ),
    );
  }

  void onBirthDayUpdate(DateTime pickedDate) {
    // เอาเข้า format สำหรับแสดงหน้า UI
    String formattedDateShow = pickedDate.formatForShow();
    dateOfBirth.text = formattedDateShow;

    // เอาเข้า format สำหรับส่งกลับหลังบ้านผ่าน API
    String formattedDateForSend = pickedDate.formatForAPI();
    _profileDataNotifier.value = UiResult.success(
      data: _profileDataNotifier.value.data!.copyWith(
        birthday: formattedDateForSend,
      ),
    );
  }

  /// DONG 2026-01-06
  ///
  /// บันทึกข้อมูล Profile
  /// เมื่อ success จะ update ข้อมูลใน LocalStorage และ CustomerProvider
  Future<UiResult<UserModel>> onSaveProfile() async {
    if (formKey.currentState?.validate() != true) {
      return UiResult.empty();
    }

    final currentUser = _profileDataNotifier.value.data;
    if (currentUser == null) {
      return UiResult.error(
        error: Exception('No user data available'),
      );
    }

    // ดึงข้อมูลรูปจาก index ปัจจุบันที่เลือกอยู่
    AvatarData avatarData = currentUser.avatarDataList[currentAvatarIndex];

    // - ถ้าเป็น index = 0 มีโอกาสที่จะเป็นการเพิ่มรูปใหม่
    // - ถ้าเป็น isFromPicker จะแสดงว่าเลือกรูปหรือถ่ายใหม่มา
    String? profileImage64Update =
        (currentAvatarIndex == 0 && avatarData.isFromPicker)
        // เอารูปมาแปลงเป็น Base64 ก่อนจะส่ง
        ? base64Encode(File(avatarData.path).readAsBytesSync())
        : null;

    // - ถ้า profileImage64Update = null มีโอกาสที่จะเลือกรูปที่มีให้
    // - ถ้า currentAvatarIndex != 0 แสดงว่าเลือกรูปที่มีให้และไม่ใช่ที่ default จะการ fetch
    String? profileImageUrlUpdate =
        (profileImage64Update == null && currentAvatarIndex != 0)
        // ส่ง path url กลับไป
        ? avatarData.path
        : null;

    // สร้าง request body
    final request = UpdateProfileRequest(
      id: currentUser.id ?? '',
      name: nameController.text.trim().isEmpty
          ? null
          : nameController.text.trim(),
      gender: genderController.text.trim().isEmpty
          ? null
          : genderController.text.trim(),
      birthdate: currentUser.birthday?.trim().isEmpty == true
          ? null
          : currentUser.birthday,
      profileImageBase64: profileImage64Update,
      profileImageUrl: profileImageUrlUpdate,
      email: emailController.text.ifNullOrEmpty(currentUser.email.orEmpty),
      phone: phoneController.text.ifNullOrEmpty(currentUser.phone.orEmpty),
    );

    try {
      final result = await repo.updateProfile(request);

      if (result.isSuccess && result.data.success) {
        final fetchProfileResult = await repo.fetchProfile(
          result.data.data.id!,
        );
        if (fetchProfileResult.isEmpty && fetchProfileResult.hasError) {
          return UiResult.empty(error: fetchProfileResult.error);
        }
        if (fetchProfileResult.hasError) {
          return UiResult.error(error: fetchProfileResult.error);
        }

        // สร้าง UserModel จาก response
        final updatedUser = UserModel.fromCustomerProfileData(
          fetchProfileResult.data.data,
        );

        // Update CustomerProvider
        currentCustomerProvider.newUser = updatedUser;

        // Update ViewModel state
        _profileDataNotifier.value = UiResult.success(data: updatedUser);

        return UiResult.success(data: updatedUser);
      }

      // ดัก error UserDuplicated เพิ่ม ให้แสดง wordig
      // เตือนว่าใช้ เบอร์ / อีเมล์ซ้ำกันในระบบ
      if (context.mounted &&
          result.hasError &&
          result.error is UserDuplicated) {
        return UiResult.error(
          error: UserDuplicated(
            // อีเมล / เบอร์โทรศัพท์ มีผู้ใช้งานอยู่ในระบบแล้ว
            '${context.wording.emailOrPhone}\n${context.wording.userDuplicated}',
          ),
        );
      }

      // ดัก error Unprocessable เพิ่ม ให้แสดง wordig
      // เตือนถ้าเป็น error contactCallCenterType ให้ติดต่อ Call Center
      if (context.mounted && result.hasError && result.error is Unprocessable) {
        if (result.error.toString() ==
            ContactCallCenterException.contactCallCenterType) {
          return UiResult.error(
            error: ContactCallCenterException(),
          );
        }
      }

      return UiResult.error(
        error: Exception(result.error.toString()),
      );
    } catch (e) {
      return UiResult.error(error: Exception(e.toString()));
    }
  }

  FutureOr<UiResult<UserModel>> logout() async {
    final logoutResult = await repo.logout();
    // if necessary
    await Future.wait([
      SocialAuthHelper.signOutGoogle(),
      SocialAuthHelper.signOutLINE(),
      SocialAuthHelper.signOutFacebook(),
    ]);

    if (!context.mounted) return UiResult.empty();

    if (logoutResult.isSuccess) {
      return UiResult.success(
        data: currentCustomerProvider.logout(),
      );
    }

    return UiResult.error(error: logoutResult.error);
  }

  // ============ dispose ============
  @override
  void dispose() {
    unawaited(
      // คืนค่ากลับ เผื่อกรณี user ปัดแอพทิ้ง
      _secureStorage.setBiometricEnabled(_biometricEnabledNotifier.value),
    );
    _contactAndSupportLinkNotifier.dispose();
    _currentSliderIndexNotifier.dispose();
    _profileDataNotifier.dispose();
    _notificationPreferencesNotifier.dispose();
    _biometricEnabledNotifier.dispose();
    _saveSlipAutoNotifier.dispose();
    _locationPermissionNotifier.dispose();
    phoneController.dispose();
    emailController.dispose();
    nameController.dispose();
    genderController.dispose();
    dateOfBirth.dispose();
    super.dispose();
  }
}
