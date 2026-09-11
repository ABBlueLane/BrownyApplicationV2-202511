import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_detail_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_programs_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/payment_method_response.dart';
import 'package:browny_applications_new/feature/transactions/models/coupon_detail_model.dart';

class MachineProgramModel extends MachineProgramsResponse {
  MachineProgramModel({
    super.machineId,
    super.machineNo,
    super.capacityKg,
    super.machineName,
    super.machineType,
    super.firebaseRef,
    super.storeName,
    super.machineImage,
    super.programs,
    super.addTimes,
    super.availableCoupons,
    super.paymentMethods,
    this.selectedProgram,
    this.selectedAddTime,
    this.selectedCoupon,
    this.machineDetail,
  });

  /// Program ที่ถูกเลือกจาก List programs
  final ProgramData? selectedProgram;

  /// Program ที่ถูกเลือกจาก List addTimes (เพิ่มเวลา)
  final ProgramData? selectedAddTime;

  /// Coupon/E-Voucher ที่ถูกเลือกจาก List availableCoupons
  final AvailableCouponData? selectedCoupon;

  /// เอาไว้เก็บค่า finishDateTime, remainingTime
  final MachineDetailResponse? machineDetail;

  factory MachineProgramModel.fromResponse(MachineProgramsResponse data) {
    // Map index ให้กับ programs และ addTimes
    final programsWithIndex = data.programs
        ?.asMap()
        .entries
        .map((e) => e.value.copyWith(index: e.key))
        .toList();
    final addTimesWithIndex = data.addTimes
        ?.asMap()
        .entries
        .map((e) => e.value.copyWith(index: e.key))
        .toList();

    return MachineProgramModel(
      machineId: data.machineId,
      machineNo: data.machineNo,
      capacityKg: data.capacityKg,
      machineName: data.machineName,
      machineType: data.machineType,
      firebaseRef: data.firebaseRef,
      storeName: data.storeName,
      machineImage: data.machineImage,
      programs: programsWithIndex,
      addTimes: addTimesWithIndex,
      availableCoupons: data.availableCoupons,
      paymentMethods: data.paymentMethods,
      selectedCoupon: null,
    );
  }

  /// ตรวจสอบว่า Coupon/E-Voucher ที่เลือกใช้งานได้หรือไม่ คืนข้อความ error ถ้าใช้ไม่ได้
  ///
  /// [availablePaymentMethods] — รายการช่องทางชำระที่คำนวณสิทธิ์แล้ว (จาก viewmodel)
  /// ใช้ตรวจว่าคูปองใบนี้ยังมีช่องทางชำระให้ใช้อยู่หรือไม่ ถ้าไม่ส่งมาจะข้ามการตรวจข้อนี้
  String? validSelectedCouponAndMessageError(
    BuildContext context, {
    List<PaymentMethodModel>? availablePaymentMethods,
  }) {
    if (selectedCoupon == null) {
      return null;
    }

    // ตรวจสอบเงื่อนไขว่าร่วมรายการกับสาขาหรือไม่
    final couponIndex = availableCoupons?.indexWhere(
      (coupon) => coupon.id == selectedCoupon!.id,
    );
    if (couponIndex == -1) {
      return '${selectedCoupon!.getCouponTypeDisplay(context.languageCode)} ${context.wording.couponNotEligible}';
    }
    // ตรวจสอบเงื่อนไขว่ายอดรวมถึงขั้นต่ำหรือไม่
    if (totalSelectedPrice < selectedCoupon!.minValue) {
      return context.wording.couponMinimumAmountRequired(
        formatCurrency(leadingSign: '฿', value: selectedCoupon!.minValue),
      );
    }
    // ตรวจสอบว่ายังมีช่องทางชำระที่ใช้กับคูปองใบนี้ได้อยู่หรือไม่
    if (availablePaymentMethods != null &&
        availablePaymentMethods.isNotEmpty &&
        !hasAnyActivePaymentMethod(availablePaymentMethods)) {
      return context.wording.noPaymentMethodForCoupon;
    }
    return null;
  }

  /// เช็คว่าเป็นเครื่องซักหรือไม่
  bool get isWasher => machineType!.en.orEmpty.toLowerCase() == 'washer';

  /// เช็คว่าเป็นเครื่องอบหรือไม่
  bool get isDryer => machineType!.en.orEmpty.toLowerCase() == 'dryer';

  @override
  String getMachineTypeDisplay(String locale) {
    if (isWasher) {
      // โปรแกรมซัก
      return ContentLocalizeData(
        en: 'Washing Program',
        zh: '洗衣程序',
        th: 'โปรแกรมซัก',
      ).getTextByLocale(locale);
    } else {
      // โปรแกรมอบ
      return ContentLocalizeData(
        en: 'Drying Program',
        zh: '烘干程序',
        th: 'โปรแกรมอบ',
      ).getTextByLocale(locale);
    }
  }

  String getSummaryMachineTypeDisplay(String locale) {
    if (isWasher) {
      // ราคาเครื่องซัก
      return ContentLocalizeData(
        en: 'Washing Machine Price',
        zh: '洗衣机价格',
        th: 'ราคาเครื่องซัก',
      ).getTextByLocale(locale);
    } else {
      // ราคาเครื่องอบ
      return ContentLocalizeData(
        en: 'Drying Machine Price',
        zh: '烘干机价格',
        th: 'ราคาเครื่องอบ',
      ).getTextByLocale(locale);
    }
  }

  /// code ของช่องทางชำระที่ Coupon/E-Voucher ที่เลือกอนุญาต
  /// normalize เป็นตัวพิมพ์เล็กและตัดช่องว่างแล้ว
  List<String> get allowedPaymentMethodCodes =>
      selectedCoupon?.allowedPaymentMethods
          ?.map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const [];

  /// เช็คว่า [code] ผ่านเงื่อนไขของ Coupon/E-Voucher ที่เลือกหรือไม่
  ///
  /// - ไม่ได้เลือกคูปอง → ผ่านทุกช่องทาง (ไม่มีการจำกัด)
  /// - เลือกคูปองแล้วแต่ allowed_payment_methods เป็น null หรือว่าง
  ///   → ไม่อนุญาตช่องทางใดเลย (backend ยืนยันว่าจะไม่ส่งค่าแบบนี้มา แต่ handle ไว้)
  bool isPaymentMethodAllowedByCoupon(String code) {
    if (selectedCoupon == null) return true;
    final codes = allowedPaymentMethodCodes;
    if (codes.isEmpty) return false;
    return codes.contains(code.trim().toLowerCase());
  }

  /// เช็คว่า [code] เลือกมาชำระได้หรือไม่ ผ่าน 2 ชั้น
  /// 1. flag เปิด/ปิดของเครื่องนี้ (payment_methods จาก API)
  /// 2. ช่องทางที่ Coupon/E-Voucher ที่เลือกอนุญาต
  bool isPaymentMethodActive(String code) =>
      (paymentMethods?.isMethodActive(code) ?? true) &&
      isPaymentMethodAllowedByCoupon(code);

  /// เช็คว่ามีช่องทางชำระที่ใช้ได้อย่างน้อย 1 ช่องหรือไม่
  bool hasAnyActivePaymentMethod(List<PaymentMethodModel> methods) =>
      methods.any((e) => e.isActive);

  /// [methods] — รายการ payment methods จาก API /payment-methods (Payment Master)
  ///
  /// คืน **ทุก** ช่องทางที่อยู่ใน Master เสมอ ห้ามกรองรายการทิ้ง
  /// สถานะใช้ได้/ไม่ได้บอกผ่าน isActive อย่างเดียว
  ///
  /// เรียงช่องทางที่ใช้ได้ขึ้นก่อน ช่องที่ปิดอยู่ท้ายลิสต์เสมอ โดยคงลำดับของ
  /// Master ภายในแต่ละกลุ่ม แล้ว mark ช่องทางที่ใช้ได้ตัวแรกเป็น isSelected
  List<PaymentMethodModel> paymentMethodsAvailable(
    String locale,
    List<PaymentMethodData> methods,
  ) {
    try {
      final mapped = methods.map((m) {
        final code = m.code ?? '';
        return PaymentMethodModel(
          method: code,
          name: m.name ?? '',
          imageUrl: m.image,
          isSelected: false,
          isActive: isPaymentMethodActive(code),
        );
      }).toList();

      final sorted = <PaymentMethodModel>[
        ...mapped.where((e) => e.isActive),
        ...mapped.where((e) => !e.isActive),
      ];

      final firstActiveIndex = sorted.indexWhere((e) => e.isActive);
      if (firstActiveIndex == -1) {
        return sorted;
      }

      return sorted.mapIndex((index, e) {
        if (index == firstActiveIndex) return e.copyWith(isSelected: true);
        return e;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// สร้าง copy ของ model พร้อมอัปเดตค่าที่ต้องการ
  MachineProgramModel copyWith({
    int? machineId,
    int? machineNo,
    int? capacityKg,
    ContentLocalizeData? machineName,
    ContentLocalizeData? machineType,
    String? firebaseRef,
    ContentLocalizeData? storeName,
    String? machineImage,
    List<ProgramData>? programs,
    List<ProgramData>? addTimes,
    List<AvailableCouponData>? availableCoupons,
    PaymentMethodsData? paymentMethods,
    ProgramData? selectedProgram,
    bool clearSelectedProgram = false,
    ProgramData? selectedAddTime,
    bool clearSelectedAddTime = false,
    AvailableCouponData? selectedCoupon,
    bool clearSelectedCoupon = false,
    MachineDetailResponse? machineDetail,
  }) {
    return MachineProgramModel(
      machineId: machineId ?? this.machineId,
      machineNo: machineNo ?? this.machineNo,
      capacityKg: capacityKg ?? this.capacityKg,
      machineName: machineName ?? this.machineName,
      machineType: machineType ?? this.machineType,
      firebaseRef: firebaseRef ?? this.firebaseRef,
      storeName: storeName ?? this.storeName,
      machineImage: machineImage ?? this.machineImage,
      programs: programs ?? this.programs,
      addTimes: addTimes ?? this.addTimes,
      availableCoupons: availableCoupons ?? this.availableCoupons,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedProgram: clearSelectedProgram
          ? null
          : (selectedProgram ?? this.selectedProgram),
      selectedAddTime: clearSelectedAddTime
          ? null
          : (selectedAddTime ?? this.selectedAddTime),
      selectedCoupon: clearSelectedCoupon
          ? null
          : (selectedCoupon ?? this.selectedCoupon),
      machineDetail: machineDetail ?? this.machineDetail,
    );
  }

  /// เลือก Program จาก List programs ตาม index
  MachineProgramModel selectProgram(int index) {
    if (programs == null || index < 0 || index >= programs!.length) {
      return this;
    }
    return copyWith(selectedProgram: programs![index]);
  }

  /// เลือก AddTime Program จาก List addTimes ตาม index
  MachineProgramModel selectAddTime(int index) {
    if (addTimes == null || index < 0 || index >= addTimes!.length) {
      return this;
    }
    return copyWith(selectedAddTime: addTimes![index]);
  }

  /// ยกเลิกการเลือก Program
  MachineProgramModel clearSelectedProgram() {
    return copyWith(clearSelectedProgram: true);
  }

  /// ยกเลิกการเลือก AddTime
  MachineProgramModel clearSelectedAddTime() {
    return copyWith(clearSelectedAddTime: true);
  }

  /// เลือก Coupon/E-Voucher จาก List availableCoupons ตาม index
  MachineProgramModel selectCoupon(int index) {
    if (availableCoupons == null ||
        index < 0 ||
        index >= availableCoupons!.length) {
      return this;
    }
    return copyWith(selectedCoupon: availableCoupons![index]);
  }

  /// ยกเลิกการเลือก Coupon/E-Voucher
  MachineProgramModel clearSelectedCoupon() {
    return copyWith(clearSelectedCoupon: true);
  }

  /// เช็คว่ามีการเลือก Program หรือไม่
  bool get hasSelectedProgram => selectedProgram != null;

  /// เช็คว่ามีการเลือก AddTime หรือไม่
  bool get hasSelectedAddTime => selectedAddTime != null;

  /// เช็คว่ามีการเลือก Coupon/E-Voucher หรือไม่
  bool get hasSelectedCoupon => selectedCoupon != null;

  /// เช็คว่า Program ที่ระบุถูกเลือกหรือไม่
  bool isProgramSelected(int index) {
    if (programs == null ||
        index < 0 ||
        index >= programs!.length ||
        selectedProgram == null) {
      return false;
    }
    return programs![index].id == selectedProgram!.id;
  }

  /// เช็คว่า AddTime ที่ระบุถูกเลือกหรือไม่
  bool isAddTimeSelected(int index) {
    if (addTimes == null ||
        index < 0 ||
        index >= addTimes!.length ||
        selectedAddTime == null) {
      return false;
    }
    return addTimes![index].index == selectedAddTime!.index;
  }

  /// เช็คว่า Coupon/E-Voucher ที่ระบุถูกเลือกหรือไม่
  bool isCouponSelected(int index) {
    if (availableCoupons == null ||
        index < 0 ||
        index >= availableCoupons!.length ||
        selectedCoupon == null) {
      return false;
    }
    return availableCoupons![index].id == selectedCoupon!.id;
  }

  /// ดึงชื่อ Program ที่เลือก
  String getSelectedProgramName(String locale) {
    if (selectedProgram == null) return '';
    return selectedProgram!.getProgramNameDisplay(locale);
  }

  /// ดึงชื่อ AddTime ที่เลือก
  String getSelectedAddTimeName(String locale) {
    if (selectedAddTime == null) return '';
    return selectedAddTime!.getProgramNameDisplay(locale);
  }

  /// ดึงราคา Program ที่เลือก
  String get selectedProgramPrice => selectedProgram?.price ?? '0.00';

  /// ดึงราคา AddTime ที่เลือก
  String get selectedAddTimePrice => selectedAddTime?.price ?? '0.00';

  /// ดึงราคาสุทธิ Program ที่เลือก
  String get selectedProgramNet => selectedProgram?.net ?? '0.00';

  /// ดึงราคาสุทธิ AddTime ที่เลือก
  String get selectedAddTimeNet => selectedAddTime?.net ?? '0.00';

  /// คำนวณราคารวมของ Program และ AddTime ที่เลือก
  double get totalSelectedPrice {
    double programPrice = double.tryParse(selectedProgramPrice) ?? 0.0;
    double addTimePrice = double.tryParse(selectedAddTimePrice) ?? 0.0;
    return programPrice + addTimePrice;
  }

  /// คำนวณส่วนลดจาก Program ที่เลือก
  double getProgramDiscount() {
    if (selectedProgram?.discount == null) return 0.0;
    return double.tryParse(selectedProgram!.discount!.amount ?? '0') ?? 0.0;
  }

  /// คำนวณส่วนลดจาก AddTime ที่เลือก
  double getAddTimeDiscount() {
    if (selectedAddTime?.discount == null) return 0.0;
    return double.tryParse(selectedAddTime!.discount!.amount ?? '0') ?? 0.0;
  }

  /// คำนวณส่วนลดจาก Coupon/E-Voucher ที่เลือก (ทั้งสองประเภท)
  /// subtotal คือราคารวมก่อนหักส่วนลดจาก coupon (program + addTime - program discount - addTime discount)
  double getCouponDiscount(double subtotal) {
    if (selectedCoupon == null) return 0.0;

    // เช็คว่าราคารวมเป็นไปตามเงื่อนไขขั้นต่ำหรือไม่
    final minRequired = double.tryParse(selectedCoupon!.min ?? '0') ?? 0.0;
    if (subtotal < minRequired) return 0.0;

    final value = double.tryParse(selectedCoupon!.value ?? '0') ?? 0.0;
    final unit = selectedCoupon!.unit ?? '';
    final maxDiscount = double.tryParse(selectedCoupon!.max ?? '0') ?? 0.0;

    double discount = 0.0;

    if (unit.toLowerCase() == 'percent') {
      // ส่วนลดแบบเปอร์เซ็นต์
      discount = subtotal * (value / 100);
      // จำกัดส่วนลดสูงสุด
      if (maxDiscount > 0 && discount > maxDiscount) {
        discount = maxDiscount;
      }
    } else {
      // ส่วนลดแบบจำนวนเงินคงที่
      discount = value;
    }

    return discount;
  }

  /// คำนวณส่วนลดจาก E-Voucher เท่านั้น
  /// subtotal คือราคารวมก่อนหักส่วนลดจาก coupon
  double getEVoucherDiscount(double subtotal) {
    if (selectedCoupon == null || !isSelectedCouponEVoucher) return 0.0;
    return getCouponDiscount(subtotal);
  }

  /// คำนวณส่วนลดจาก Coupon เท่านั้น (ไม่ใช่ E-Voucher)
  /// subtotal คือราคารวมก่อนหักส่วนลดจาก coupon
  double getCouponOnlyDiscount(double subtotal) {
    if (selectedCoupon == null || !isSelectedCouponCoupon) return 0.0;
    return getCouponDiscount(subtotal);
  }

  /// คำนวณส่วนลดรวมทั้งหมด (program + addTime + coupon/e-voucher)
  double getTotalDiscount() {
    final programDiscount = getProgramDiscount();
    final addTimeDiscount = getAddTimeDiscount();
    final subtotal = totalSelectedPrice - programDiscount - addTimeDiscount;
    final couponDiscount = getCouponDiscount(subtotal);

    return programDiscount + addTimeDiscount + couponDiscount;
  }

  /// คำนวณส่วนลดของสาขา (program + addTime) ไม่รวม coupon
  double getTotalDiscountStore() {
    final programDiscount = getProgramDiscount();
    final addTimeDiscount = getAddTimeDiscount();
    return programDiscount + addTimeDiscount;
  }

  /// คำนวณส่วนลดที่มาจาก E-Voucher
  double getTotalEVoucherDiscount() {
    final programDiscount = getProgramDiscount();
    final addTimeDiscount = getAddTimeDiscount();
    final subtotal = totalSelectedPrice - programDiscount - addTimeDiscount;
    return getEVoucherDiscount(subtotal);
  }

  /// คำนวณส่วนลดที่มาจาก Coupon (ไม่ใช่ E-Voucher)
  double getTotalCouponOnlyDiscount() {
    final programDiscount = getProgramDiscount();
    final addTimeDiscount = getAddTimeDiscount();
    final subtotal = totalSelectedPrice - programDiscount - addTimeDiscount;
    return getCouponOnlyDiscount(subtotal);
  }

  /// คำนวณราคาสุทธิหลังหักส่วนลดทั้งหมด
  double getNetPrice() {
    final totalAfterDiscount = totalSelectedPrice - getTotalDiscount();
    if (totalAfterDiscount < 0) {
      return 0.0;
    }
    return totalAfterDiscount;
  }

  /// เช็คว่า Coupon ที่เลือกเป็น E-Voucher หรือไม่
  bool get isSelectedCouponEVoucher {
    if (selectedCoupon == null) return false;
    final typeEn = selectedCoupon!.type?.en ?? '';
    return typeEn.toLowerCase().contains('e-voucher') ||
        typeEn.toLowerCase().contains('evoucher');
  }

  /// เช็คว่า Coupon ที่เลือกเป็น Coupon หรือไม่
  bool get isSelectedCouponCoupon {
    if (selectedCoupon == null) return false;
    final typeEn = selectedCoupon!.type?.en ?? '';
    return typeEn.toLowerCase() == 'discount';
  }

  /// ดึงประเภทของ Coupon ที่เลือก (E-Voucher หรือ Coupon)
  String getSelectedCouponType(String locale) {
    if (selectedCoupon == null) return '';
    return selectedCoupon!.getCouponTypeDisplay(locale);
  }

  /// ดึงชื่อ Coupon ที่เลือก
  String getSelectedCouponName(String locale) {
    if (selectedCoupon == null) return '';
    return selectedCoupon!.getCouponNameDisplay(locale);
  }
}
