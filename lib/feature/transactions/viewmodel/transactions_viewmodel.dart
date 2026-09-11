import 'dart:async';

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/api_model_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/data/remote/models/request/payment_check.dart';
import 'package:browny_applications_new/core/utils/crashlytics_helper.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/transactions/models/machine_program_model.dart';
import 'package:browny_applications_new/feature/transactions/models/payment_transaction_state.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_detail_model.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_list_model.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_receipt_model.dart';
import 'package:browny_applications_new/feature/transactions/models/customer_coupon_model.dart';
import 'package:browny_applications_new/feature/transactions/repository/coupon_voucher_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/machine_transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_selected_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/purchase_coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/coupon_voucher_selected_viewmodel_delegate.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/purchase_coupon_viewmodel_delegate.dart';
import 'package:browny_applications_new/models/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

part 'machine_transaction_viewmodel.dart';

class TransactionsViewmodel extends AppViewModel
    with
        // viewmodel สำหรับคุมการทำงานจังหวะสั่งซื้อ e-voucher
        PurchaseCouponViewmodelDelegate,
        // viewmodel สำหรับควบคุมการทำงานเมื่อเลือก coupon, e-voucher ที่ซื้อแล้ว
        CouponVoucherSelectedViewmodelDelegate {
  TransactionsViewmodel({
    required super.context,
    required CouponVoucherDataSourceMixin couponRepo,
    required TransactionDataSourceMixin transactionRepo,
    required this.machineRepo,
  }) : _couponRepo = couponRepo,
       _transactionRepo = transactionRepo;

  // ========== Repository ==========
  final CouponVoucherDataSourceMixin _couponRepo;
  final TransactionDataSourceMixin _transactionRepo;
  final MachineTransactionDataSourceMixin machineRepo;

  @override
  CouponVoucherDataSourceMixin get repoDelegate => _couponRepo;

  @override
  UserModel get currentUserDelegate => currentCustomerProvider.current;

  /// Flag สำหรับตรวจสอบว่ามาจากหน้าประวัติหรือไม่ (เพื่อเปลี่ยน nav บนหน้าใบเสร็จ)
  bool get isFromHistory => false;

  @override
  void dispose() {
    _paymentMethodNotifier.dispose();
    _showNearbyStoresNotifier.dispose();
    _evoucherForSellNotifier.dispose();
    _evoucherNotifier.dispose();
    _discountNotifier.dispose();
    _transactionStateNotifier.dispose();
    _inputCollectCouponNotifier.dispose();
    _inputCollectCouponControler.dispose();
    super.dispose();
  }

  // ========== Notifier, Controller ==========

  late final ValueNotifier<bool> _showNearbyStoresNotifier = ValueNotifier(
    true,
  );
  ValueListenable<bool> get showNearbyStoresNotifier =>
      _showNearbyStoresNotifier;

  late final ValueNotifier<UiResult<Map<String, List<CustomerCouponModel>>>>
  _evoucherNotifier = ValueNotifier(
    UiResult.loading(),
  );
  ValueListenable<UiResult<Map<String, List<CustomerCouponModel>>>>
  get evoucherNotifier => _evoucherNotifier;

  late final ValueNotifier<UiResult<Map<String, List<CustomerCouponModel>>>>
  _discountNotifier = ValueNotifier(
    UiResult.loading(),
  );
  ValueListenable<UiResult<Map<String, List<CustomerCouponModel>>>>
  get discountNotifier => _discountNotifier;

  late final ValueNotifier<UiResult<CouponListModel>> _evoucherForSellNotifier =
      ValueNotifier(
        UiResult.loading(),
      );
  ValueListenable<UiResult<CouponListModel>> get evoucherForSellNotifier =>
      _evoucherForSellNotifier;

  late final ValueNotifier<UiResult<List<PaymentMethodModel>>>
  _paymentMethodNotifier = ValueNotifier(UiResult.loading());
  ValueListenable<UiResult<List<PaymentMethodModel>>>
  get paymentMethodNotifier => _paymentMethodNotifier;

  /// DONG 2026-02-23
  ///
  /// เก็บ State ที่เปิดหน้า coupon
  /// จะไม่เป็น null แต่ทำเป็น nullable เพื่อไม่ให้ถูกบังคับส่งจาก constructor
  CouponVoucherState? couponState;
  CustomerCouponModel? customerCouponModelSelected;

  /// Callback ให้ [CouponVoucherPage] เลื่อน TabBar กลับไป tab แรก —
  /// เรียกหลัง collectCoupon สำเร็จ เฉพาะกรณีที่ไม่ได้มาจาก auto-scan QR
  VoidCallback? onCouponCollected;

  /// MachineProgramModel จาก MachineTransactionPage
  /// เป็น single source of truth สำหรับ:
  /// - filter coupon ที่ร่วมรายการ (availableCoupons)
  /// - restore selected state (selectedCoupon)
  /// - re-fetch หลัง collectCoupon สำเร็จ
  MachineProgramModel? machineProgram;

  /// เก็บประเภทชำระที่เลือก
  PaymentMethodModel? _paymentSelected;
  PaymentMethodModel? get paymentSelected => _paymentSelected;
  // เก็บค่า payment ก่อนที่จะเข้าหน้าแก้ไข (สำหรับ cancel)
  PaymentMethodModel? _paymentSelectedBeforeEdit;

  /// cache รายการ payment methods จาก API /payment-methods
  List<PaymentMethodData> _cachedPaymentMethods = [];

  /// Unified state สำหรับจัดการ Payment Transaction (payment status + receipt)
  /// แทนที่การใช้ paymentStatusNotifier และ couponReceiptNotifier แยกกัน
  late final ValueNotifier<UiResult<PaymentTransactionState>>
  _transactionStateNotifier = ValueNotifier(
    UiResult.success(data: PaymentTransactionState.idle()),
  );
  ValueListenable<UiResult<PaymentTransactionState>>
  get transactionStateNotifier => _transactionStateNotifier;

  /// Notifier สำหรับเก็บสถานะการ เปิด/ปิด ปุ่มรหัสคูปอง
  late final ValueNotifier<bool> _inputCollectCouponNotifier = ValueNotifier(
    false,
  );
  ValueListenable<bool> get inputCollectCouponNotifier =>
      _inputCollectCouponNotifier;
  late final TextEditingController _inputCollectCouponControler =
      TextEditingController();
  TextEditingController get inputCollectCouponControler =>
      _inputCollectCouponControler;

  // ========== function, Logic ==========

  /// ใช้สำหรับตรวจสอบว่าสถานะปัจจุบันเป็น 'using' (กำลังใช้งาน)
  bool get isUsing => couponState == CouponVoucherState.using;

  /// ใช้สำหรับตรวจสอบว่าสถานะปัจจุบันเป็น 'purshasing' (กำลังซื้อ)
  bool get isPurshasing => couponState == CouponVoucherState.purshasing;

  /// ใช้สำหรับตรวจสอบว่าสถานะปัจจุบันเป็น 'redeeming' (กำลังแลกของ)
  bool get isRedeeming => couponState == CouponVoucherState.redeeming;

  /// ใช้สำหรับตรวจสอบว่าสถานะปัจจุบันเป็น 'brownyShop' (ร้านค้า Browny)
  bool get isBrownyShop => couponState == CouponVoucherState.brownyShop;

  late CouponPackageItem _selectedCoupon;
  @override
  CouponPackageItem get selectedCoupon => _selectedCoupon;

  Future<UiResult<CustomerProfileData>> fetchCustomerCredit() async {
    final resultCredit = await _couponRepo.fetchCustomerCredit(
      currentCustomerProvider.current.id!,
    );

    if (resultCredit.isEmpty || resultCredit.hasError) {
      try {
        return UiResult.error(
          error: Unprocessable(resultCredit.error.toString()),
        );
      } catch (_) {
        return UiResult.error(error: Unprocessable());
      }
    }
    // update ข้อมูล User ด้วย
    currentCustomerProvider.updateCreditAndCoinBalance(resultCredit.data);
    return UiResult.success(data: resultCredit.data);
  }

  void goPurchasePage(BuildContext context, CouponPackageItem selected) {
    _selectedCoupon = selected;
    storeListNotifier = ValueNotifier(UiResult.loading());
    context
        .pushNamed(
          PurchaseCouponVoucherPage.pageName,
          extra: this,
        )
        .then((_) async {
          if (!context.mounted) return;

          AppOverlays.showLoading(context);
          await initializeLocationAndFetchCoupons();
          AppOverlays.hideLoading();
        });
  }

  void goSelectedPage(BuildContext context, CustomerCouponModel selected) {
    setCustomerCouponSelectedDelegate = selected;
    context
        .pushNamed(
          CouponVoucherSelected.pageName,
          extra: this,
        )
        .then((_) async {
          if (!context.mounted) return;

          AppOverlays.showLoading(context);
          await initializeLocationAndFetchCoupons();
          AppOverlays.hideLoading();
        });
  }

  /// ดึงข้อมูล Payment Methods ที่มีให้เลือก
  ///
  /// [fetchAll] = true: แสดงทั้งหมด, false: แสดงแค่ 3 ตัวแรก
  ///
  /// กลไก:
  /// - ดึง payment methods จาก couponDetail
  /// - ถ้ามีการเลือกไว้แล้ว (_paymentSelected != null) จะเอาตัวที่เลือกมาไว้ index 0
  /// - ถ้ายังไม่เคยเลือก จะเลือกตัวแรกเป็น default
  Future<void> fetchPaymentMethod(
    BuildContext context, {
    bool fetchAll = false,
  }) async {
    // Set loading state ถ้ายังไม่ได้ loading อยู่
    if (!_paymentMethodNotifier.value.isLoading) {
      _paymentMethodNotifier.value = UiResult.loading();
    }

    // ตรวจสอบว่า couponDetail พร้อมใช้งานหรือยัง
    if (!couponDetailNotifier!.value.isSuccess) {
      _paymentMethodNotifier.value = UiResult.empty(
        error: couponDetailNotifier!.value.error,
      );
      return;
    }
    final locale = context.languageCode;
    // ดึง payment methods จาก /payment-methods API แล้ว cache ไว้
    final paymentMethodsResult = await repoDelegate.fetchPaymentMethods();
    _cachedPaymentMethods = paymentMethodsResult.data.payments ?? [];

    // ดึง payment methods จาก couponDetail กรองตาม cached methods
    final listPayment = couponDetailNotifier!.value.data!
        .paymentMethodsAvailable(locale, _cachedPaymentMethods);

    // ถ้าไม่มี payment method ให้เลือก
    if (listPayment.isEmpty) {
      _paymentMethodNotifier.value = UiResult.empty();
      return;
    }

    // Fetch ข้อมูล profile เพื่ออัพเดท credit balance (สำหรับ TP Wallet)
    final profileResult = await repoDelegate.fetchProfile('');
    if (profileResult.isEmpty || profileResult.isError) {
      _paymentMethodNotifier.value = UiResult.empty();
      return;
    }

    final userModel = UserModel.fromCustomerProfileData(
      profileResult.data.data,
    );
    // อัพเดทข้อมูล user ใหม่ใน provider
    currentCustomerProvider.newUser = userModel;

    // Copy list เพื่อไม่ให้กระทบ original
    var finalList = listPayment.toList();

    // ถ้ามีการเลือก payment ไว้แล้วก่อนหน้านี้
    if (_paymentSelected != null) {
      // หาตำแหน่งของ payment ที่เลือกไว้
      final selectedIndex = finalList.indexWhere(
        (e) => e.method == _paymentSelected!.method,
      );

      if (selectedIndex != -1) {
        // Mark ทั้งหมดเป็น unselected ก่อน
        finalList = finalList
            .map((e) => e.copyWith(isSelected: false))
            .toList();

        // เอาตัวที่เลือกออกจาก list
        final selected = finalList.removeAt(selectedIndex);

        // ใส่กลับไปที่ index 0 และ mark เป็น selected
        finalList.insert(0, selected.copyWith(isSelected: true));
        // เอาตัวที่เลือก หรือ TPWallet ขึ้นด้านบน
        // finalList.sort((l, r) {
        //   if (l.isSelected) return 0;
        //   if (l.isTpWallet) return 0;
        //   return 1;
        // });
      }
    } else {
      // เอา TPWallet ขึ้นตัวแรกเสมอ
      // finalList.sort((l, r) {
      //   if (l.isTpWallet) {
      //     return 0;
      //   }
      //   return 1;
      // });

      // ถ้ายังไม่เคยเลือก ให้เลือกตัวแรกเป็น default
      finalList = finalList.asMap().entries.map((entry) {
        // ตัวแรก (index 0) จะถูก mark เป็น selected
        return entry.value.copyWith(isSelected: entry.key == 0);
      }).toList();
      // เก็บตัวแรกไว้ใน _paymentSelected
      if (finalList.isNotEmpty) {
        _paymentSelected = finalList.first;
      }
    }

    // Update notifier พร้อมจำกัดจำนวนตามค่า fetchAll
    // fetchAll = true: ส่งทั้งหมด, false: ส่งแค่ 3 ตัว
    _paymentMethodNotifier.value = UiResult.success(
      data: finalList.take(fetchAll ? finalList.length : 3).toList(),
    );
  }

  /// เรียกเมื่อ User เลือก payment method
  ///
  /// [payment]: payment ที่เลือก
  /// [fetchAll]: true = อัพเดทแสดงทั้งหมด, false = แสดงแค่ 3 ตัว
  ///
  /// กลไก:
  /// - ดึง payment methods ทั้งหมดจาก couponDetail (ไม่ใช่จาก notifier เพราะอาจมีแค่ 3 ตัว)
  /// - เอา payment ที่เลือกมาไว้ index 0 และ mark เป็น selected
  /// - payment อื่นๆ จะถูก mark เป็น unselected
  void onPaymentChanged(
    PaymentMethodModel payment, {
    bool fetchAll = false,
  }) {
    // ตรวจสอบว่า couponDetail พร้อมใช้งาน
    if (!couponDetailNotifier!.value.isSuccess) return;

    // ดึง payment methods ทั้งหมดจาก couponDetail กรองตาม cached methods
    final fullList = couponDetailNotifier!.value.data!.paymentMethodsAvailable(
      context.languageCode,
      _cachedPaymentMethods,
    );

    // Mark ทุกตัวเป็น unselected ก่อน
    var newList = fullList.map((e) => e.copyWith(isSelected: false)).toList();

    // หาตำแหน่งของ payment ที่เลือก
    final selectedIndex = newList.indexWhere((e) => e.method == payment.method);

    if (selectedIndex != -1) {
      // เอา payment ที่เลือกออกจาก list
      final selected = newList.removeAt(selectedIndex);

      // ใส่กลับไปที่ index 0 และ mark เป็น selected
      newList.insert(0, selected.copyWith(isSelected: true));

      // เก็บค่าไว้ใน _paymentSelected เพื่อใช้ตอน fetch ครั้งถัดไป
      _paymentSelected = newList.first;
    }

    // Update notifier พร้อมจำกัดจำนวนตาม fetchAll
    // fetchAll = true: ส่งทั้งหมด (ใช้ใน available_payment_method_page)
    // fetchAll = false: ส่งแค่ 3 ตัว (ใช้ใน transaction_selected_page)
    _paymentMethodNotifier.value = UiResult.success(
      data: newList.take(fetchAll ? newList.length : 3).toList(),
    );
  }

  /// ข้อความอธิบายว่าทำไมช่องทางชำระนี้ถึงเลือกไม่ได้
  /// คืน null ถ้าช่องทางนี้เลือกได้ปกติ
  String? paymentMethodDisabledReason(
    BuildContext context,
    PaymentMethodModel payment,
  ) {
    if (payment.isActive) return null;
    return context.wording.paymentMethodUnavailable;
  }

  /// Initialize location permission and fetch coupon packages
  Future<void> initializeLocationAndFetchCoupons() async {
    // Check location permission
    final hasPermission = await PermissionHelper.hasLocationPermission();

    if (!hasPermission) {
      // Request permission
      final granted = await PermissionHelper.requestLocationPermission();

      if (context.mounted && granted != handler.PermissionStatus.granted) {
        // User denied permission
        AppOverlays.showBrownyDialog(
          context,
          // ไม่สามารถเข้าถึงตำแหน่งได้,
          title: context.wording.locationAccessDeniedTitle,
          // กรุณาให้สิทธิ์เข้าถึงตำแหน่งเพื่อแสดงสาขาใกล้คุณ
          message: ContentLocalizeData(
            en: 'Please grant location access to show nearest branches',
            zh: '请授予位置权限以显示最近的分支机构',
            th: 'กรุณาให้สิทธิ์เข้าถึงตำแหน่งเพื่อแสดงสาขาใกล้คุณ',
          ).getTextByLocale(context.languageCode),
          // เปิด Setting
          confirmText: ContentLocalizeData(
            en: 'Open Settings',
            zh: '打开设置',
            th: 'เปิด Setting',
          ).getTextByLocale(context.languageCode),
          onConfirm: () async {
            await PermissionHelper.openAppSettings();
            // Retry after opening settings
            await initializeLocationAndFetchCoupons();
          },
          cancelText: context.wording.cancel,
          onCancel: () async {
            // User cancelled - fetch without location
            _showNearbyStoresNotifier.value = false;
            await fetchCouponPackageListDependsOn(currentLocation: null);
          },
        );
        return;
      }
    }

    // Permission granted - get location and fetch
    try {
      final position = await LocationHelper.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      await fetchCouponPackageListDependsOn(currentLocation: latLng);
    } catch (e) {
      if (!context.mounted) return;
      // print('Error getting location: $e');
      // Fallback to fetch without location
      try {
        _showNearbyStoresNotifier.value = false;
        await fetchCouponPackageListDependsOn(currentLocation: null);
      } catch (_) {}
    }
  }

  /// Handle nearby stores switch change
  Future<void> onNearbyStoresSwitchChanged(bool value) async {
    _showNearbyStoresNotifier.value = value;

    if (value) {
      // User turned on - request location permission and fetch
      await initializeLocationAndFetchCoupons();
    } else {
      // User turned off - fetch without location
      await fetchCouponPackageListDependsOn(currentLocation: null);
    }
  }

  /// fetch E-Voucher All-Store ทั้งหมดมา
  Future<void> fetchCouponPackageListDependsOn({
    LatLng? currentLocation,
  }) async {
    if (!_evoucherForSellNotifier.value.isLoading) {
      _evoucherForSellNotifier.value = UiResult.loading();
    }

    final customerId = currentCustomerProvider.current.id;
    final result = await _couponRepo.fetchCouponPackageList(
      customerId: customerId,
      latitude: currentLocation?.latitude.toString(),
      longitude: currentLocation?.longitude.toString(),
    );

    if (result.isEmpty || result.hasError) {
      _evoucherForSellNotifier.value = UiResult.empty();
      return;
    }

    _evoucherForSellNotifier.value = UiResult.success(
      data: CouponListModel.fromResponse(result.data),
    );
  }

  /// Fetch ข้อมูล EVoucher ของ Customer
  /// Returns Map grouped by couponId
  Future<void> fetchCustomerEVoucher() async {
    if (!evoucherNotifier.value.isLoading) {
      _evoucherNotifier.value = UiResult.loading();
    }

    String id = currentCustomerProvider.current.id!;
    final result = await _couponRepo.fetchCouponEVoucher(id);
    if (result.isEmpty || result.data.data.orEmpty.isEmpty) {
      // ไม่ข้อมูล noti ด้วย empty
      _evoucherNotifier.value = UiResult.empty();
      return;
    }

    if (result.hasError) {
      // มี error
      _evoucherNotifier.value = UiResult.error(error: result.error);
      return;
    }

    final availableIds = machineProgram?.availableCoupons;
    final selectedId = machineProgram?.selectedCoupon?.id;

    // Filter และ map เป็น CustomerCouponModel ก่อน
    final filteredCoupons = result.data.data!
        .where(
          (e) => availableIds?.isNotEmpty == true
              ? availableIds!.any((a) => a.id == e.customerCouponId)
              // ถ้ามาจากหน้าใช้งานเครื่อง และ availableIds ว่าง จะต้องไม่แสดง
              : (isUsing ? false : true),
        )
        .map(
          (e) => CustomerCouponModel.fromCouponData(
            e,
            customerCouponModelSelected != null
                ? customerCouponModelSelected!.customerCouponId ==
                      e.customerCouponId
                : selectedId != null && selectedId == e.customerCouponId,
          ),
        )
        .toList();

    // Restore customerCouponModelSelected จาก machineProgram.selectedCoupon
    if (customerCouponModelSelected == null && selectedId != null) {
      final matched = filteredCoupons.where(
        (e) => e.customerCouponId == selectedId,
      );
      if (matched.isNotEmpty) {
        customerCouponModelSelected = matched.first;
      }
    }

    // Group by typeLabel.en
    final groupedMap = <String, List<CustomerCouponModel>>{};
    for (var coupon in filteredCoupons) {
      // Skip if typeLabel.en is null or empty
      final key = coupon.typeLabel?.en;
      if (key == null || key.isEmpty) continue;
      groupedMap.putIfAbsent(key, () => []).add(coupon);
    }

    _evoucherNotifier.value = UiResult.success(data: groupedMap);
  }

  void onCustomerEVoucherSelected(CustomerCouponModel customerEVoucher) {
    customerCouponModelSelected = customerEVoucher;

    // ถ้าไม่มี data ให้ return
    if (!_evoucherNotifier.value.isSuccess ||
        _evoucherNotifier.value.data == null) {
      return;
    }

    final currentMap = _evoucherNotifier.value.data!;
    final newMap = <String, List<CustomerCouponModel>>{};

    // Iterate through each group and update isSelected
    currentMap.forEach((typeKey, coupons) {
      final updatedCoupons = coupons.map((e) {
        return e.copyWith(
          isSelected:
              e.customerCouponId ==
              customerCouponModelSelected!.customerCouponId,
        );
      }).toList();

      newMap[typeKey] = updatedCoupons;
    });

    _evoucherNotifier.value = UiResult.success(data: newMap);
  }

  /// Fetch ข้อมูล Discount Coupon ของ Customer
  /// Returns Map grouped by appliesTo (washer, dryer, both)
  Future<void> fetchCustomerDiscount() async {
    if (!discountNotifier.value.isLoading) {
      _discountNotifier.value = UiResult.loading();
    }

    String id = currentCustomerProvider.current.id!;
    final result = await _couponRepo.fetchCouponDiscount(id);
    if (result.isEmpty || result.data.data.orEmpty.isEmpty) {
      // ไม่ข้อมูล noti ด้วย empty
      _discountNotifier.value = UiResult.empty();
      return;
    }

    if (result.hasError) {
      // มี error
      _discountNotifier.value = UiResult.error(error: result.error);
      return;
    }

    final availableIds = machineProgram?.availableCoupons;
    final selectedId = machineProgram?.selectedCoupon?.id;

    // Filter และ map เป็น CustomerCouponModel ก่อน
    final filteredCoupons = result.data.data!
        .where(
          (e) => availableIds?.isNotEmpty == true
              ? availableIds!.any((a) => a.id == e.customerCouponId)
              // ถ้ามาจากหน้าใช้งานเครื่อง และ availableIds ว่าง จะต้องไม่แสดง
              : (isUsing ? false : true),
        )
        .map(
          (e) => CustomerCouponModel.fromCouponData(
            e,
            customerCouponModelSelected != null
                ? customerCouponModelSelected!.customerCouponId ==
                      e.customerCouponId
                : selectedId != null && selectedId == e.customerCouponId,
          ),
        )
        .toList();

    // Restore customerCouponModelSelected จาก machineProgram.selectedCoupon
    if (customerCouponModelSelected == null && selectedId != null) {
      final matched = filteredCoupons.where(
        (e) => e.customerCouponId == selectedId,
      );
      if (matched.isNotEmpty) {
        customerCouponModelSelected = matched.first;
      }
    }

    // Group by appliesTo (washer, dryer, both)
    final groupedMap = <String, List<CustomerCouponModel>>{};
    for (var coupon in filteredCoupons) {
      // Skip if appliesTo is null or empty
      final key = coupon.appliesTo;
      if (key == null || key.isEmpty) continue;
      groupedMap.putIfAbsent(key, () => []).add(coupon);
    }

    _discountNotifier.value = UiResult.success(data: groupedMap);
  }

  void onCustomerDiscountSelected(CustomerCouponModel customerDiscount) {
    customerCouponModelSelected = customerDiscount;

    // ถ้าไม่มี data ให้ return
    if (!_discountNotifier.value.isSuccess ||
        _discountNotifier.value.data == null) {
      return;
    }

    final currentMap = _discountNotifier.value.data!;
    final newMap = <String, List<CustomerCouponModel>>{};

    // Iterate through each group and update isSelected
    currentMap.forEach((appliesTo, coupons) {
      final updatedCoupons = coupons.map((e) {
        return e.copyWith(
          isSelected:
              e.customerCouponId ==
              customerCouponModelSelected!.customerCouponId,
        );
      }).toList();

      newMap[appliesTo] = updatedCoupons;
    });

    _discountNotifier.value = UiResult.success(data: newMap);
  }

  /// dispose สำหรับหน้า [transaction_selecte_page]
  void disposeTransaction() {
    _paymentMethodNotifier.value = UiResult.loading();
    _paymentSelected = null;
    _paymentSelectedBeforeEdit = null;
  }

  /// เริ่มต้นการแก้ไข payment method (เก็บค่าเดิมไว้สำหรับ cancel)
  void startEditingPaymentMethod() {
    _paymentSelectedBeforeEdit = _paymentSelected;
  }

  /// ยืนยันการเลือก payment method ใหม่ (ไม่ต้องทำอะไร เพราะค่าถูกเก็บไว้แล้วใน onPaymentChanged)
  void confirmPaymentMethodEdit() {
    _paymentSelectedBeforeEdit = null;
  }

  /// ยกเลิกการเลือก payment method - restore ค่าเดิมกลับมา
  Future<void> cancelPaymentMethodEdit(BuildContext context) async {
    if (_paymentSelectedBeforeEdit != null) {
      _paymentSelected = _paymentSelectedBeforeEdit;
      _paymentSelectedBeforeEdit = null;
      // Fetch ใหม่เพื่อให้ payment เดิมกลับมาเป็น index 0
      await fetchPaymentMethod(context, fetchAll: false);
    }
  }

  /// สร้างคำสั่งซื้อคูปอง
  ///
  /// Returns:
  /// - UiResult.success: สำเร็จ พร้อม CouponOrderResponse
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: ไม่มี payment method ที่เลือก หรือ API ไม่สำเร็จ
  Future<UiResult<CouponOrderResponse>> createCouponOrder() async {
    // ตรวจสอบว่ามี payment method ที่เลือกหรือไม่
    if (_paymentSelected == null) {
      return UiResult.empty(
        error: Exception(context.wording.selectPaymentMethodRequired),
      );
    }

    // ตรวจสอบว่ามี customer ID หรือไม่
    final customerId = currentCustomerProvider.current.id;
    if (customerId == null || customerId.isEmpty) {
      return UiResult.error(
        error: Exception(context.wording.userDataNotFound),
      );
    }

    if (_selectedCoupon.data.packageId == null) {
      return UiResult.error(
        error: Exception(
          'เกิดข้อผิดพลาดในการสร้างคำสั่งซื้อ: ไม่พบ package id',
        ),
      );
    }

    try {
      // สร้าง request
      final request = CouponOrderRequest(
        customerId: customerId,
        couponPackageId: selectedPackageNotifier?.value?.packageId ?? 0,
        quantity: 1,
        paymentMethod: _paymentSelected!.method,
      );

      // เรียก API
      final result = await _transactionRepo.createCouponOrder(request);

      // Handle result
      if (result.isSuccess) {
        return UiResult.success(data: result.data);
      } else if (result.isEmpty) {
        return UiResult.empty(error: result.error);
      } else {
        return UiResult.error(error: result.error);
      }
    } catch (e) {
      unawaited(
        CrashlyticsHelper.recordError(
          e,
          fatal: true,
          customKeys: {
            'customer_id': customerId,
          },
        ),
      );
      return UiResult.error(
        error: Exception('เกิดข้อผิดพลาดในการสร้างคำสั่งซื้อ: ${e.toString()}'),
      );
    }
  }

  /// ตรวจสอบสถานะการชำระเงิน
  ///
  /// อัพเดท transaction state เป็น checkingPayment -> paymentSuccess
  ///
  /// Returns:
  /// - UiResult.success: สำเร็จ พร้อม PaymentStatusCheckResponse
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: API ไม่สำเร็จ
  Future<UiResult<PaymentStatusCheckResponse>> checkPaymentStatus(
    CouponOrderData orderData,
  ) async {
    try {
      // อัพเดท state เป็น checking
      _transactionStateNotifier.value = UiResult.success(
        data: PaymentTransactionState.checkingPayment(),
      );

      // สร้าง PaymentCheck จาก orderData.paymentRef
      final paymentCheck = PaymentCheck(
        paymentRef: orderData.paymentRef ?? '',
      );

      final result = await _transactionRepo.checkPaymentStatus(paymentCheck);

      if (result.isSuccess) {
        // อัพเดท state เป็น payment success
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.paymentSuccess(result.data),
        );
        return UiResult.success(data: result.data);
      } else if (result.isEmpty) {
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.error(
            result.error,
          ),
        );
        return UiResult.empty(error: result.error);
      } else {
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.error(
            result.error,
          ),
        );
        return UiResult.error(error: result.error);
      }
    } catch (e) {
      final exception = Exception(
        'เกิดข้อผิดพลาดในการตรวจสอบสถานะ: ${e.toString()}',
      );
      _transactionStateNotifier.value = UiResult.success(
        data: PaymentTransactionState.error(exception),
      );
      return UiResult.error(error: exception);
    }
  }

  /// ดึงข้อมูลใบเสร็จคูปอง/e-voucher
  ///
  /// ใช้ orderId จาก transaction state ที่เก็บไว้
  /// อัพเดท transaction state เป็น loadingReceipt -> receiptLoaded
  ///
  /// Returns:
  /// - UiResult.success: สำเร็จ พร้อม CouponReceiptModel
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: ไม่มี orderId หรือ API ไม่สำเร็จ
  Future<UiResult<CouponReceiptModel>> fetchCouponReceipt() async {
    final currentState = _transactionStateNotifier.value;

    // ตรวจสอบว่า state พร้อมดึงใบเสร็จหรือไม่
    if (!currentState.isSuccess || !currentState.data!.canFetchReceipt) {
      final error = Exception(
        'ไม่สามารถดึงใบเสร็จได้ กรุณาตรวจสอบสถานะการชำระเงินก่อน',
      );
      _transactionStateNotifier.value = UiResult.success(
        data: PaymentTransactionState.error(
          error,
          paymentStatus: currentState.data?.paymentStatus,
        ),
      );
      return UiResult.empty(error: error);
    }

    final state = currentState.data!;
    final orderId = state.orderId;

    // ตรวจสอบว่ามี orderId หรือไม่ (double check)
    if (orderId == null) {
      final error = Exception('ไม่พบ Order ID');
      _transactionStateNotifier.value = UiResult.success(
        data: PaymentTransactionState.error(
          error,
          paymentStatus: state.paymentStatus,
        ),
      );
      return UiResult.empty(error: error);
    }

    try {
      // อัพเดท state เป็น loading receipt
      _transactionStateNotifier.value = UiResult.success(
        data: PaymentTransactionState.loadingReceipt(state.paymentStatus!),
      );

      final result = await _transactionRepo.fetchCouponReceipt(
        orderId.toString(),
      );

      if (result.isSuccess) {
        final receiptModel = CouponReceiptModel.fromCouponReceiptData(
          result.data.data!,
        );

        // refresh machine program ด้วย ถ้ามาจากหน้าการใช้งานเครื่อง
        await refreshMachineProgram();
        // รีเฟรชรายการคูปองหลังจากรับสำเร็จ
        await fetchCustomerEVoucher();
        await fetchCustomerDiscount();

        // อัพเดท state เป็น receipt loaded (transaction complete)
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.receiptLoaded(
            state.paymentStatus!,
            receiptModel,
          ),
        );

        return UiResult.success(data: receiptModel);
      } else if (result.isEmpty) {
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.error(
            result.error,
            paymentStatus: state.paymentStatus,
          ),
        );
        return UiResult.empty(error: result.error);
      } else {
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.error(
            result.error,
            paymentStatus: state.paymentStatus,
          ),
        );
        return UiResult.error(error: result.error);
      }
    } catch (e) {
      final exception = Exception(
        'เกิดข้อผิดพลาดในการดึงข้อมูลใบเสร็จ: ${e.toString()}',
      );
      _transactionStateNotifier.value = UiResult.success(
        data: PaymentTransactionState.error(
          exception,
          paymentStatus: state.paymentStatus,
        ),
      );
      return UiResult.error(error: exception);
    }
  }

  /// Fetch ใบเสร็จคูปอง/e-voucher โดยตรงจาก orderId (ใช้สำหรับดูจากประวัติ)
  Future<UiResult<CouponReceiptModel>> fetchCouponReceiptByOrderId(
    String orderId,
  ) async {
    _transactionStateNotifier.value = UiResult.success(
      data: PaymentTransactionState(step: TransactionStep.loadingReceipt),
    );
    try {
      final result = await _transactionRepo.fetchCouponReceipt(orderId);
      if (result.isSuccess) {
        final receiptModel = CouponReceiptModel.fromCouponReceiptData(
          result.data.data!,
        );
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState(
            receipt: receiptModel,
            step: TransactionStep.receiptLoaded,
          ),
        );
        return UiResult.success(data: receiptModel);
      } else if (result.isEmpty) {
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.error(result.error),
        );
        return UiResult.empty(error: result.error);
      } else {
        _transactionStateNotifier.value = UiResult.success(
          data: PaymentTransactionState.error(result.error),
        );
        return UiResult.error(error: result.error);
      }
    } catch (e) {
      final error = Exception(
        'เกิดข้อผิดพลาดในการดึงข้อมูลใบเสร็จ: ${e.toString()}',
      );
      _transactionStateNotifier.value = UiResult.success(
        data: PaymentTransactionState.error(error),
      );
      return UiResult.error(error: error);
    }
  }

  Future<UiResult<void>> verifyOrder() async {
    try {
      if (paymentSelected?.isTpWallet == true ||
          paymentSelected?.isCoin == true) {
        final result = await fetchCustomerCredit();

        if (result.isEmpty || result.hasError) {
          try {
            return UiResult.error(
              error: Unprocessable(result.error.toString()),
            );
          } catch (_) {
            return UiResult.error(error: Unprocessable());
          }
        }
        // update ข้อมูล User ด้วย
        currentCustomerProvider.updateCreditAndCoinBalance(result.data!);

        final double balance;
        if (paymentSelected?.isTpWallet == true) {
          balance = double.tryParse(
            result.data!.creditBalance!.replaceAll(',', ''),
          )!;
        } else {
          balance = double.tryParse(
            result.data!.currentCoin!.replaceAll(',', ''),
          )!;
        }

        final packgaePrice = double.tryParse(
          selectedPackageNotifier!.value!.price!.replaceAll(',', ''),
        )!;
        if (balance >= packgaePrice) {
          return UiResult.success(data: null);
        }

        return UiResult.empty();
      } else {
        return UiResult.success(data: null);
      }
    } catch (e) {
      return UiResult.error(error: Unprocessable(e.toString()));
    }
  }

  /// รับคูปองจาก code หรือ QR
  ///
  /// [type]: ประเภท (code/qr)
  /// [data]: ข้อมูล URL หรือ QR code data
  ///
  /// Returns:
  /// - UiResult.success: สำเร็จพร้อม CouponCollectResponse
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: Customer ID ไม่พบหรือ API ไม่สำเร็จ
  Future<void> collectCoupon([
    String? data,
    String type = 'code',
    bool fromAuto = false,
  ]) async {
    FocusManager.instance.primaryFocus?.unfocus();
    AppOverlays.showLoading(context);

    final customerId = currentCustomerProvider.current.id;
    if (customerId == null || customerId.isEmpty) {
      // return UiResult.error(
      //   error: Exception('Customer ID not found'),
      // );
      AppOverlays.hideLoading();
      AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        message: '${context.wording.errorUi} : Customer ID not found',
      );
      return;
    }

    final result = await _couponRepo.collectCoupon(
      type,
      data ?? _inputCollectCouponControler.text,
      customerId,
    );

    if (!context.mounted) return;

    if (result.hasError) {
      AppOverlays.hideLoading();
      // return UiResult.error(error: result.error);
      if (result.error is AuthenExceptions) {
        AppOverlays.showBrownyDialog(
          context,
          title: context.wording.errorOccurred,
          message: (result.error as AuthenExceptions).toUiMessage(context),
        );
      }

      return;
    }

    if (result.isEmpty) {
      AppOverlays.hideLoading();
      AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        message: context.wording.errorUi,
      );
    }

    // collect สำเร็จ + ไม่ได้มาจาก auto-scan → เลื่อน TabBar หน้า coupon กลับ tab แรก
    if (result.isSuccess && !fromAuto) {
      onCouponCollected?.call();
    }

    try {
      if (isUsing && result.data.couponCustomer != null) {
        // refresh machine program ด้วย ถ้ามาจากหน้าการใช้งานเครื่อง
        await refreshMachineProgram();
      }
    } catch (_) {}

    // รีเฟรชรายการคูปองหลังจากรับสำเร็จ
    await fetchCustomerEVoucher();
    await fetchCustomerDiscount();

    // clear text
    _inputCollectCouponControler.text = '';
    if (context.mounted) {
      await AppOverlays.showBrownyDialog(
        context,
        imageAsset: Assets.png.brownySuccess2.path,
        // ยินดีด้วย,
        title: context.wording.congratulations,
        // คุณได้ทำการเพิ่มคูปองสำเร็จ,
        message: context.wording.couponAddedSuccessfully,
        onConfirm: () {
          // ถ้ามาจาก auto และ scan สำเร็จ เมื่อกดรับทราบจะ pop ออก
          if (fromAuto) {
            if (context.canPop()) {
              context.pop();
            }
          }
        },
      );
    }

    AppOverlays.hideLoading();
    // return UiResult.success(data: result.data);
  }

  void onInputCouponChange(String value) {
    _inputCollectCouponNotifier.value = value.isNotEmpty;
  }

  Future<void> refreshMachineProgram() async {
    if (machineProgram != null) {
      // re-fetch machine programs เพื่ออัพเดท availableCoupons ให้ตรงกับสถานะล่าสุด
      // หลังจาก collect coupon หรือ ซื้อ E-Vocher สำเร็จ
      // coupon, E-Vocher ใหม่อาจถูกเพิ่มใน availableCoupons
      final refreshResult = await machineRepo.fetchMachinePrograms(
        machineProgram!.machineId.toString(),
        currentCustomerProvider.current.id.orEmpty,
      );
      if (refreshResult.isSuccess) {
        machineProgram = MachineProgramModel.fromResponse(
          refreshResult.data,
        );
      }
    }
  }
}
