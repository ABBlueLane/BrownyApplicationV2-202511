part of 'transactions_viewmodel.dart';

class MachineTransactionViewmodel extends TransactionsViewmodel {
  MachineTransactionViewmodel({
    required super.context,
    required super.couponRepo,
    required super.transactionRepo,
    required super.machineRepo,
  });

  // ========== Repo ==========

  // ========== Dispose ==========
  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _remainingDurationNotifier.dispose();
    _machineDetailNotifier.dispose();
    _machineProgramsNotifier.dispose();
    _machineTransactionStateNotifier.dispose();
    super.dispose();
  }

  // ========== ValueNotifier ==========
  final ValueNotifier<UiResult<MachineProgramModel>> _machineProgramsNotifier =
      ValueNotifier(UiResult.loading());
  ValueListenable<UiResult<MachineProgramModel>> get machineProgramsNotifier =>
      _machineProgramsNotifier;

  // ========== Varible ==========
  bool _isFirstReviewScore = true;
  bool get isFirstReviewed => _isFirstReviewScore;

  String get machineId =>
      machineProgramsNotifier.value.data!.machineId.toString();

  // ========== Machine Status Timer & Progress ==========
  Timer? _statusUpdateTimer;
  final ValueNotifier<Duration?> _remainingDurationNotifier = ValueNotifier(
    null,
  );
  ValueListenable<Duration?> get remainingDurationNotifier =>
      _remainingDurationNotifier;

  double _totalDurationInSeconds = 1.0;
  double get totalDurationInSeconds => _totalDurationInSeconds;

  final ValueNotifier<MachineDetailResponse?> _machineDetailNotifier =
      ValueNotifier(null);
  ValueListenable<MachineDetailResponse?> get machineDetailNotifier =>
      _machineDetailNotifier;

  /// State สำหรับจัดการ Machine Payment Transaction (payment status + receipt)
  /// แยกออกจาก parent class เพราะใช้ MachineOrderReceiptResponse แทน CouponReceiptModel
  late final ValueNotifier<UiResult<MachinePaymentTransactionState>>
  _machineTransactionStateNotifier = ValueNotifier(
    UiResult.success(data: MachinePaymentTransactionState.idle()),
  );
  ValueListenable<UiResult<MachinePaymentTransactionState>>
  get machineTransactionStateNotifier => _machineTransactionStateNotifier;

  // ========== Logic ==========
  /// API fetch รายละเอียดเครื่อง (machine detail)
  /// เรียกครั้งเดียวและเก็บใน ValueNotifier เพื่อหลีกเลี่ยงการ rebuild
  Future<UiResult<MachineDetailResponse>> fetchMachineDetail(
    String machineId,
  ) async {
    final result = await machineRepo.fetchMachineDetail(machineId);

    if (result.hasError) {
      return UiResult.error(error: result.error);
    }

    if (result.isEmpty) {
      return UiResult.empty();
    }

    // เก็บข้อมูลใน notifier
    _machineDetailNotifier.value = result.data;

    // คำนวณและเริ่ม timer
    _calculateSliderValues(result.data);

    return UiResult.success(data: result.data);
  }

  /// คำนวณค่าต่างๆ สำหรับ Slider จากข้อมูล MachineDetailResponse
  void _calculateSliderValues(MachineDetailResponse machineDetail) {
    try {
      // ใช้ startTime ที่เป็น DateTime โดยตรง
      final startTime = machineDetail.startTime;

      // แปลง finishDatatime จาก String เป็น DateTime
      final now = DateTime.now();
      final finishParts = machineDetail.finishDatatime.orEmpty.split(':');

      if (startTime != null && finishParts.length >= 2) {
        var finishTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(finishParts[0]),
          int.parse(finishParts[1]),
        );

        // ถ้าเวลาสิ้นสุดน้อยกว่าเวลาเริ่มต้น แสดงว่าข้ามวัน
        if (finishTime.isBefore(startTime)) {
          finishTime = finishTime.add(const Duration(days: 1));
        }

        // คำนวณเวลาทั้งหมด (วินาที)
        _totalDurationInSeconds = finishTime
            .difference(startTime)
            .inSeconds
            .toDouble();

        // แปลง remainingTime ("00:13:27") เป็น Duration
        final timeParts = machineDetail.remainingTime.orEmpty.split(':');
        if (timeParts.length == 3) {
          _remainingDurationNotifier.value = Duration(
            hours: int.parse(timeParts[0]),
            minutes: int.parse(timeParts[1]),
            seconds: int.parse(timeParts[2]),
          );

          // เริ่ม Timer เพื่ออัพเดท UI
          _startStatusTimer(machineDetail);
        }
      }
    } catch (e) {
      debugPrint('Error calculating slider values: $e');
    }
  }

  /// เริ่ม Timer สำหรับอัพเดท remaining time ทุก 1 วินาที
  void _startStatusTimer(MachineDetailResponse machineDetail) {
    _statusUpdateTimer?.cancel();

    if (!machineDetail.isBusy) {
      return;
    }

    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentDuration = _remainingDurationNotifier.value;
      if (currentDuration != null && currentDuration.inSeconds > 0) {
        // อัพเดทเฉพาะ ValueNotifier ไม่ทำให้ rebuild ทั้ง widget
        _remainingDurationNotifier.value = Duration(
          seconds: currentDuration.inSeconds - 1,
        );
      } else {
        // หมดเวลาแล้ว หยุด timer
        timer.cancel();
      }
    });
  }

  /// คำนวณ value ของ slider (เวลาที่ผ่านไปแล้ว)
  double getSliderValue(String locale) {
    final remainingDuration = _remainingDurationNotifier.value;
    if (remainingDuration == null || _totalDurationInSeconds <= 0) {
      return 0;
    }

    final elapsed = _totalDurationInSeconds - remainingDuration.inSeconds;
    return elapsed.clamp(0, _totalDurationInSeconds);
  }

  /// ดึง label สำหรับแสดงใน bubble ("21 นาที" หรือสถานะอื่นๆ)
  String getBubbleLabel(String locale) {
    final machineDetail = _machineDetailNotifier.value;
    if (machineDetail == null) return '';

    if (machineDetail.isFailed) {
      // แสดงสถานะสำหรับเครื่องขัดข้อง
      return machineDetail.getStatusDisplay(locale);
    }

    final remainingDuration = _remainingDurationNotifier.value;
    if (machineDetail.isBusy && remainingDuration != null) {
      // แสดงเวลาที่เหลือในรูปแบบ "mm นาที"
      final minutes = remainingDuration.inMinutes;
      return '$minutes นาที';
    }

    return '';
  }

  /// ดึงสีของ bubble ตามสถานะ
  Color getBubbleColor() {
    final machineDetail = _machineDetailNotifier.value;
    if (machineDetail == null) return AppColors.primary;

    if (machineDetail.isFailed) {
      return AppColors.error; // สีแดงสำหรับเครื่องขัดข้อง
    }

    return AppColors.primary; // สีเขียวปกติ
  }

  /// ฟอร์แมต remaining time สำหรับแสดงใน summary ("mm:ss")
  String getFormattedRemainingTime(String locale) {
    final remainingDuration = _remainingDurationNotifier.value;
    final machineDetail = _machineDetailNotifier.value;

    if (remainingDuration == null) {
      return machineDetail?.getRemainingTimeDisplay(locale) ?? '-';
    }

    final minutes = remainingDuration.inMinutes;
    final seconds = remainingDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// API fetch โปรแกรมของเครื่อง (machine programs)
  Future<void> fetchMachinePrograms(
    String machineId,
  ) async {
    final currentProgram = _machineProgramsNotifier.value.data;
    if (currentProgram == null) {
      _machineProgramsNotifier.value = UiResult.loading();
    }

    if (!context.mounted) return;

    final result = await machineRepo.fetchMachinePrograms(
      machineId,
      currentCustomerProvider.current.id.orEmpty,
    );

    if (result.hasError) {
      _machineProgramsNotifier.value = UiResult.error(error: result.error);
      return;
    }

    if (result.isEmpty) {
      _machineProgramsNotifier.value = UiResult.empty();
      return;
    }
    if (!context.mounted) return;

    // After scan, surface coupons from programs.available_coupons immediately.
    // Keep a previously selected coupon only if it is still in the fresh list;
    // otherwise auto-select the first usable coupon so the checkout card is not empty
    // until the user opens Add/Select.
    final fresh = MachineProgramModel.fromResponse(result.data);
    final previousSelected = currentProgram?.selectedCoupon;
    final previousStillValid = previousSelected != null &&
        (fresh.availableCoupons?.any((c) => c.id == previousSelected.id) ??
            false);

    final AvailableCouponData? nextSelected;
    if (previousStillValid) {
      nextSelected = previousSelected;
    } else if (fresh.availableCoupons?.isNotEmpty == true) {
      nextSelected = fresh.availableCoupons!.first;
    } else {
      nextSelected = null;
    }

    _machineProgramsNotifier.value = UiResult.success(
      data: fresh.copyWith(
        selectedProgram: currentProgram?.selectedProgram,
        selectedAddTime: currentProgram?.selectedAddTime,
        selectedCoupon: nextSelected,
        clearSelectedCoupon: nextSelected == null,
      ),
    );
    if (context.mounted) {
      await fetchPaymentMethod(context);
    }
  }

  @override
  Future<void> fetchPaymentMethod(
    BuildContext context, {
    bool fetchAll = false,
  }) async {
    final localed = context.languageCode;
    // ดึง payment methods จาก /payment-methods API แล้ว cache ไว้
    final paymentMethodsResult = await repoDelegate.fetchPaymentMethods();
    _cachedPaymentMethods = paymentMethodsResult.data.payments ?? [];

    // ดึง payment methods กรองตาม cached methods
    final listPayment = _machineProgramsNotifier.value.data!
        .paymentMethodsAvailable(localed, _cachedPaymentMethods);

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
        //   if (l.isTpWallet) return 1;
        //   if (l.isCoin) return 2;
        //   return 3;
        // });
      }
    } else {
      // เอา TPWallet ขึ้นตัวแรกเสมอ
      // finalList.sort((l, r) {
      //   if (l.isTpWallet) return 0;
      //   if (l.isCoin) return 1;
      //   return 2;
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

  @override
  void onPaymentChanged(
    PaymentMethodModel payment, {
    bool fetchAll = false,
  }) {
    // ตรวจสอบว่า couponDetail พร้อมใช้งาน
    if (!_machineProgramsNotifier.value.isSuccess) return;

    // ดึง payment methods ทั้งหมดกรองตาม cached methods
    final fullList = _machineProgramsNotifier.value.data!
        .paymentMethodsAvailable(
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

  /// เลือก Program จาก List programs ตาม index
  void selectProgram(int index) {
    if (!_machineProgramsNotifier.value.isSuccess) return;

    final currentModel = _machineProgramsNotifier.value.data!;
    final updatedModel = currentModel.selectProgram(index);
    _machineProgramsNotifier.value = UiResult.success(data: updatedModel);
  }

  /// เลือก AddTime Program จาก List addTimes ตาม index
  /// ถ้ากดที่ index เดิมที่กำลัง selected อยู่ จะยกเลิกการเลือก
  void selectAddTime(int index) {
    if (!_machineProgramsNotifier.value.isSuccess) return;

    final currentModel = _machineProgramsNotifier.value.data!;

    // ตรวจสอบว่า index ที่กดเป็นตัวที่ selected อยู่หรือไม่
    final isCurrentlySelected = currentModel.isAddTimeSelected(index);

    final updatedModel = isCurrentlySelected
        ? currentModel
              .clearSelectedAddTime() // ถ้ากดตัวเดิม ให้ยกเลิกการเลือก
        : currentModel.selectAddTime(index); // ถ้ากดตัวใหม่ ให้เลือกตัวนั้น

    _machineProgramsNotifier.value = UiResult.success(data: updatedModel);
  }

  /// เลือก Coupon/E-Voucher จาก CustomerCouponModel
  /// จะค้นหา AvailableCouponData ที่ id ตรงกับ customerCouponId
  /// ถ้ากดที่ coupon เดิมที่กำลัง selected อยู่ จะยกเลิกการเลือก
  /// ถ้าส่ง null เข้ามา จะยกเลิกการเลือก
  Future<void> onCustomerCouponSelected(
    CustomerCouponModel? customerCoupon,
  ) async {
    if (!_machineProgramsNotifier.value.isSuccess) return;

    // DONG 2026-04-18
    // เพิ่มการ fetch machine program ทุกครั้งที่มีการเลือก Coupon เพื่อรองรับการ collect
    // Coupon, E-Voucher ในจังหวะที่กำลังเลือก Coupon, E-Voucher มาใช้งาน
    // เก็บ availableCoupons ที่ fetch มาใหม่
    List<AvailableCouponData>? availableCouponsUpdate;
    if (customerCoupon != null) {
      final machineProgramResult = await machineRepo.fetchMachinePrograms(
        machineId,
        currentCustomerProvider.current.id.orEmpty,
      );
      if (machineProgramResult.isSuccess) {
        availableCouponsUpdate = machineProgramResult.data.availableCoupons;
      }
    }
    // update availableCoupons ให้ใหม่
    final currentModel = _machineProgramsNotifier.value.data!.copyWith(
      availableCoupons: availableCouponsUpdate,
    );

    // ถ้าส่ง null มา ให้ clear selection
    if (customerCoupon == null) {
      final updatedModel = currentModel.clearSelectedCoupon();
      _machineProgramsNotifier.value = UiResult.success(data: updatedModel);
      return;
    }

    // หา index ของ availableCoupon ที่ id ตรงกับ customerCouponId
    final availableCoupons = currentModel.availableCoupons ?? [];
    final couponIndex = availableCoupons.indexWhere(
      (coupon) => coupon.id == customerCoupon.customerCouponId,
    );

    // ถ้าไม่เจอ coupon ที่ตรงกัน ให้ return
    if (couponIndex == -1) {
      if (!context.mounted) return;
      AppOverlays.showBrownyDialog(
        context,
        // ไม่สามารถใช้งาน $couponType ได้
        title: context.wording.cannotUseCouponType(
          customerCoupon.getSelectedTypeNoDetailWordingDisplay(context),
        ),
        // ${getSelectedTypeNoDetailWordingDisplay} ${packageNameDisplay}
        // ไม่ร่วมรายการ
        message:
            '''
${customerCoupon.getSelectedTypeNoDetailWordingDisplay(context)} ${customerCoupon.packageNameDisplay(context)} ${context.wording.couponNotEligible}
      ''',
      );
      return;
    }

    // ตรวจสอบว่า coupon ที่เลือกเป็นตัวที่ selected อยู่หรือไม่
    final isCurrentlySelected = currentModel.isCouponSelected(couponIndex);

    MachineProgramModel updatedModel = isCurrentlySelected
        ? currentModel
              .clearSelectedCoupon() // ถ้ากดตัวเดิม ให้ยกเลิกการเลือก
        : currentModel.selectCoupon(
            couponIndex,
          ); // ถ้ากดตัวใหม่ ให้เลือกตัวนั้น

    _machineProgramsNotifier.value = UiResult.success(data: updatedModel);
  }

  @override
  Future<UiResult<double>> verifyOrder() async {
    try {
      if (paymentSelected?.isTpWallet == true ||
          paymentSelected?.isCoin == true) {
        final result = await _couponRepo.fetchCustomerCredit(
          currentCustomerProvider.current.id!,
        );

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
        currentCustomerProvider.updateCreditAndCoinBalance(result.data);
        final double balance;
        if (paymentSelected?.isTpWallet == true) {
          balance = double.tryParse(
            result.data.creditBalance!.replaceAll(',', ''),
          )!;
        } else {
          balance = double.tryParse(
            result.data.currentCoin!.replaceAll(',', ''),
          )!;
        }

        final machinePrice = _machineProgramsNotifier.value.data!.getNetPrice();
        if (balance >= machinePrice) {
          return UiResult.success(data: machinePrice);
        }

        return UiResult.empty();
      } else {
        return UiResult.success(
          data: _machineProgramsNotifier.value.data!.getNetPrice(),
        );
      }
    } catch (e) {
      return UiResult.error(error: Unprocessable(e.toString()));
    }
  }

  /// สร้างคำสั่งซื้อเครื่องซัก/อบ
  ///
  /// Parameters:
  /// - machineId: ID ของเครื่องที่จะใช้บริการ
  ///
  /// Returns:
  /// - UiResult.success: สำเร็จ พร้อม MachineOrderResponse (payment_ref, redirect_url)
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: ไม่มี payment method ที่เลือก, ไม่มี program ที่เลือก, หรือ API ไม่สำเร็จ
  Future<UiResult<MachineOrderResponse>> createMachineOrder(
    String machineId,
  ) async {
    // ตรวจสอบว่ามี payment method ที่เลือกหรือไม่
    if (_paymentSelected == null) {
      return UiResult.empty();
    }

    // ตรวจสอบว่ามี customer ID หรือไม่
    final customerId = currentCustomerProvider.current.id;
    if (customerId == null || customerId.isEmpty) {
      return UiResult.empty();
    }

    // ตรวจสอบว่า machineProgramsNotifier พร้อมใช้งาน
    if (!_machineProgramsNotifier.value.isSuccess) {
      return UiResult.empty();
    }

    final programData = _machineProgramsNotifier.value.data!;

    // ตรวจสอบว่ามี selectedProgram หรือไม่
    if (programData.selectedProgram == null) {
      return UiResult.empty();
    }

    // ดึงข้อมูลที่จำเป็น
    final selectedProgram = programData.selectedProgram!;
    final programCode = selectedProgram.programCode;

    if (programCode == null || programCode.isEmpty) {
      return UiResult.empty();
    }

    try {
      String fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (_) {
        fcmToken = '';
      }
      if (!context.mounted) return UiResult.empty();

      // add_time_value ใช้ค่า net จาก API machine/{id}/programs
      final addTimeValue = double.tryParse(
        programData.selectedAddTime?.net ?? '',
      )?.toInt();
      int? couponCustomerId;
      if (programData.validSelectedCouponAndMessageError(context) == null) {
        couponCustomerId = programData.selectedCoupon?.id;
      }

      // สร้าง request object
      final request = MachineOrderRequest(
        customerId: customerId,
        customerPhone: currentCustomerProvider.current.phone ?? '',
        storeMachineId: int.tryParse(machineId) ?? 0,
        programCode: programCode,
        addTimeValue: addTimeValue,
        paymentMethod: _paymentSelected!.method,
        couponCustomerId: couponCustomerId,
        discountId: programData.selectedProgram?.discount?.id,
        notificationToken: fcmToken,
      );

      // เรียก API
      final result = await machineRepo.createMachineOrder(request);

      if (result.hasError) {
        return UiResult.error(error: result.error);
      }

      if (result.isEmpty) {
        return UiResult.empty();
      }

      await fetchCustomerCredit();
      // Update ข้อมูลเครื่องเก็บเอาไว้ด้วย
      // final resultMachineDetail = await machineRepo.fetchMachineDetail(
      //   machineId,
      // );
      // currentCustomerProvider.userTransactions.addNewMachineTracsactions(
      //   _machineProgramsNotifier.value.data!.copyWith(
      //     machineDetail: resultMachineDetail.data,
      //   ),
      // );
      return UiResult.success(data: result.data);
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
        error: Exception('Failed to create machine order: ${e.toString()}'),
      );
    }
  }

  /// ตรวจสอบสถานะการชำระเงินเครื่องซัก/อบ
  ///
  /// [paymentRef] payment reference จาก MachineOrderResponse
  ///
  /// Returns:
  /// - UiResult.success: สำเร็จ พร้อม PaymentStatusCheckResponse
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: API ไม่สำเร็จ
  Future<UiResult<PaymentStatusCheckResponse>> checkMachineOrderPaymentStatus(
    String paymentRef,
  ) async {
    try {
      // อัพเดท state เป็น checking
      _machineTransactionStateNotifier.value = UiResult.success(
        data: MachinePaymentTransactionState.checkingPayment(),
      );

      // สร้าง PaymentCheck จาก paymentRef
      final paymentCheck = PaymentCheck(paymentRef: paymentRef);

      final result = await _transactionRepo.checkMachineOrderPaymentStatus(
        paymentCheck,
      );

      if (result.isSuccess) {
        // อัพเดท state เป็น payment success
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.paymentSuccess(result.data),
        );
        return UiResult.success(data: result.data);
      } else if (result.isEmpty) {
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.error(
            result.error,
          ),
        );
        return UiResult.empty(error: result.error);
      } else {
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.error(
            result.error,
          ),
        );
        return UiResult.error(error: result.error);
      }
    } catch (e) {
      unawaited(
        CrashlyticsHelper.recordError(e),
      );
      final exception = Exception(
        'เกิดข้อผิดพลาดในการตรวจสอบสถานะ: ${e.toString()}',
      );
      _machineTransactionStateNotifier.value = UiResult.success(
        data: MachinePaymentTransactionState.error(exception),
      );
      return UiResult.error(error: exception);
    }
  }

  /// ดึงข้อมูลใบเสร็จเครื่องซัก/อบ
  ///
  /// ใช้ orderId จาก machineTransactionState ที่เก็บไว้
  /// อัพเดท state เป็น loadingReceipt -> receiptLoaded
  ///
  /// Returns:
  /// - UiResult.success: สำเร็จ พร้อม MachineOrderReceiptResponse
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: ไม่มี orderId หรือ API ไม่สำเร็จ
  Future<UiResult<MachineOrderReceiptResponse>> fetchMachineReceipt() async {
    final currentState = _machineTransactionStateNotifier.value;

    // ตรวจสอบว่า state พร้อมดึงใบเสร็จหรือไม่
    if (!currentState.isSuccess || !currentState.data!.canFetchReceipt) {
      final error = Exception(
        'ไม่สามารถดึงใบเสร็จได้ กรุณาตรวจสอบสถานะการชำระเงินก่อน',
      );
      _machineTransactionStateNotifier.value = UiResult.success(
        data: MachinePaymentTransactionState.error(
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
      _machineTransactionStateNotifier.value = UiResult.success(
        data: MachinePaymentTransactionState.error(
          error,
          paymentStatus: state.paymentStatus,
        ),
      );
      return UiResult.empty(error: error);
    }

    try {
      // อัพเดท state เป็น loading receipt
      _machineTransactionStateNotifier.value = UiResult.success(
        data: MachinePaymentTransactionState.loadingReceipt(
          state.paymentStatus!,
        ),
      );

      final result = await _transactionRepo.fetchMachineOrderReceipt(
        orderId.toString(),
      );

      if (result.isSuccess) {
        final receiptResponse = result.data;

        // อัพเดท state เป็น receipt loaded (transaction complete)
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.receiptLoaded(
            state.paymentStatus!,
            receiptResponse,
          ),
        );
        // flag ว่ามีการ review มาแล้วหรือยัง(กรณีดูประวัติ) เช็ตจาก object != null
        _isFirstReviewScore = receiptResponse.reviewScore == null;

        return UiResult.success(data: receiptResponse);
      } else if (result.isEmpty) {
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.error(
            result.error,
            paymentStatus: state.paymentStatus,
          ),
        );
        return UiResult.empty(error: result.error);
      } else {
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.error(
            result.error,
            paymentStatus: state.paymentStatus,
          ),
        );
        return UiResult.error(error: result.error);
      }
    } catch (e) {
      unawaited(
        CrashlyticsHelper.recordError(e),
      );
      final exception = Exception(
        'เกิดข้อผิดพลาดในการดึงข้อมูลใบเสร็จ: ${e.toString()}',
      );
      _machineTransactionStateNotifier.value = UiResult.success(
        data: MachinePaymentTransactionState.error(
          exception,
          paymentStatus: state.paymentStatus,
        ),
      );
      return UiResult.error(error: exception);
    }
  }

  /// Fetch ใบเสร็จเครื่องซัก/อบ โดยตรงจาก orderId (ใช้สำหรับดูจากประวัติ)
  Future<UiResult<MachineOrderReceiptResponse>> fetchMachineReceiptByOrderId(
    String orderId,
  ) async {
    _machineTransactionStateNotifier.value = UiResult.success(
      data: MachinePaymentTransactionState(
        step: TransactionStep.loadingReceipt,
      ),
    );
    try {
      final result = await _transactionRepo.fetchMachineOrderReceipt(orderId);
      if (result.isSuccess) {
        final receiptResponse = result.data;
        _isFirstReviewScore = receiptResponse.reviewScore == null;
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState(
            // DONG 19-05-2026 แก้ไข Issue ไม่สามารถ submit review ร้านค้าได้
            // เพราะไม่มี OrderID
            paymentStatus: PaymentStatusCheckResponse(
              status: 'paid',
              orderId: orderId,
            ),
            receipt: receiptResponse,
            step: TransactionStep.receiptLoaded,
          ),
        );
        return UiResult.success(data: receiptResponse);
      } else if (result.isEmpty) {
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.error(result.error),
        );
        return UiResult.empty(error: result.error);
      } else {
        _machineTransactionStateNotifier.value = UiResult.success(
          data: MachinePaymentTransactionState.error(result.error),
        );
        return UiResult.error(error: result.error);
      }
    } catch (e) {
      final error = Exception(
        'เกิดข้อผิดพลาดในการดึงข้อมูลใบเสร็จ: ${e.toString()}',
      );
      _machineTransactionStateNotifier.value = UiResult.success(
        data: MachinePaymentTransactionState.error(error),
      );
      return UiResult.error(error: error);
    }
  }

  void onScoreTap(int scored) {
    // ถ้าเคย Review แล้ว จะไม่ให้แก้ไข
    if (!_isFirstReviewScore) return;

    final currentState = _machineTransactionStateNotifier.value.data;
    // ถ้าข้อมูลไม่พร้อมจะ return ออก
    if (currentState == null) return;

    _machineTransactionStateNotifier.value = UiResult.success(
      data: currentState.copyWith(
        receipt: currentState.receipt!.copyWith(reviewScore: scored.toString()),
      ),
    );
  }

  /// API ส่งคะแนนรีวิวคำสั่งซื้อเครื่องซัก/อบ
  ///
  /// [orderId] UUID ของคำสั่งซื้อ
  /// [score] คะแนนรีวิว (1-5)
  ///
  /// Returns:
  /// - UiResult.success: รีวิวสำเร็จ
  /// - UiResult.error: เกิด error
  /// - UiResult.empty: API ไม่สำเร็จ
  Future<UiResult<void>> submitMachineOrderReview() async {
    try {
      final orderId = _machineTransactionStateNotifier.value.data!.orderId;
      final score = int.tryParse(
        _machineTransactionStateNotifier
            .value
            .data!
            .receipt!
            .reviewScore
            .orEmpty,
      );

      if (score == null) return UiResult.empty();

      final request = MachineOrderReviewRequest(score: score);
      final result = await machineRepo.submitMachineOrderReview(
        orderId,
        request,
      );

      if (result.hasError) {
        return UiResult.error(error: result.error);
      }

      if (result.isEmpty) {
        return UiResult.empty(error: Unprocessable());
      }

      // รีวิวสำเร็จแล้ว ไม่ให้รีวิวซ้ำ
      _isFirstReviewScore = false;

      return UiResult.success(data: null);
    } catch (e) {
      return UiResult.error(
        error: Exception('เกิดข้อผิดพลาดในการส่งรีวิว: ${e.toString()}'),
      );
    }
  }
}
