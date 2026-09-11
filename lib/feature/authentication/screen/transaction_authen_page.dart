part of 'app_pin_page.dart';

/// หน้าสำหรับ authen process ต่างๆ ด้วย Biometric, PIN
class TransactionAuthenPage extends StatelessWidget {
  const TransactionAuthenPage({
    super.key,
    required this.process,
  });
  final PinBiometricPross process;

  static final pagePath = '/transaction_authen_page';
  static final pageName = 'TransactionAuthenPage';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    PinBiometricPross process = PinBiometricPross.verify,
  }) async {
    return await context.pushNamed(
      TransactionAuthenPage.pageName,
      extra: process,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PinBiometricViewModel(
        context: context,
        repository: PinBioMetricRepository(),
      ),
      child: _TransactionAuthenContent(
        // process: PinBiometricPross.verify,
        process: process,
      ),
    );
  }
}

class _TransactionAuthenContent extends _CreateAppPinContent {
  const _TransactionAuthenContent({
    required super.process,
  });

  @override
  _CreateAppPinContentState createState() => __TransactionAuthenContentState();
}

class __TransactionAuthenContentState extends _CreateAppPinContentState {
  bool _isBiometricEnabled = false;
  bool _showPinWidget = false;
  late PinBiometricViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = context.read<PinBiometricViewModel>();
    _initializeAuthentication();
  }

  /// เริ่มต้น Authentication process
  Future<void> _initializeAuthentication() async {
    // ตรวจสอบว่ามี PIN หรือไม่
    final hasPin = await _authViewModel.hasPin();
    if (!hasPin) {
      // ไม่มี PIN - แสดง error และ pop กลับ
      if (mounted && context.mounted) {
        AppOverlays.showBrownyDialog(
          context,
          imageAsset: Assets.png.brownyError2.path,
          // ไม่พบการตั้งค่า PIN
          title: context.wording.pinSetupNotFound,
          // กรุณาตั้งค่า PIN ก่อนใช้งานฟีเจอร์นี้
          message: context.wording.pleaseSetupPinFirst,
          // ตั้งค่า PIN
          confirmText: context.wording.setupPin,
          // ยกเลิก
          cancelText: context.wording.cancel,
          onConfirm: () {
            if (context.mounted) {
              CreateAppPinPage.goToPage(
                context,
                process: PinBiometricPross.create,
              ).then((_) async {
                await _initializeAuthentication();
              });
              // context
              //     .pushNamed(
              //       // Transaction Create PIN
              //       CreateAppPinPage.pageName,
              //       extra: {
              //         // ไม่ใช้การ signup ใหม่
              //         CreateAppPinPage.kFirstSignup: false,
              //         // Map<Type, PinBiometricPross>
              //         CreateAppPinPage.kPinBiometricProcess: {
              //           PinBiometricPross: PinBiometricPross.create,
              //         },
              //       },
              //     )
              //     .then((_) async {
              //       await _initializeAuthentication();
              //     });
            }
          },
        );
      }
      return;
    }

    // ตรวจสอบว่าเปิด Biometric หรือไม่
    _isBiometricEnabled = await _authViewModel.isBiometricEnabled();
    if (widget.process == PinBiometricPross.verifyByPin) {
      // Force แสดง PIN widget เลย
      setState(() {
        _showPinWidget = true;
      });
    } else if (_isBiometricEnabled) {
      // พยายาม authenticate ด้วย Biometric ก่อน
      await _attemptBiometricAuth();
    } else {
      // ไม่มี Biometric - แสดง PIN widget
      setState(() {
        _showPinWidget = true;
      });
    }
  }

  /// พยายาม authenticate ด้วย Biometric
  Future<void> _attemptBiometricAuth() async {
    final result = await _authViewModel.authenticateWithBiometric(
      // กรุณายืนยันตัวตนเพื่อดำเนินการต่อ
      reason: context.wording.verifyIdentityToContinue,
    );

    if (result.isSuccess && result.data!.isSuccess) {
      // Biometric สำเร็จ - pop กลับพร้อม result
      if (mounted && context.mounted) {
        context.safePop(true);
      }
    } else {
      // Biometric ไม่สำเร็จ - แสดง PIN widget
      if (mounted) {
        setState(() {
          _showPinWidget = true;
        });
      }
    }
  }

  @override
  String _getTitleText(BuildContext context, PinBiometricViewModel viewModel) {
    return context.wording.pleaseConfirmPin;
  }

  @override
  Widget build(BuildContext context) {
    // ถ้ายังไม่แสดง PIN widget ให้แสดงหน้าจอสีขาว
    if (!_showPinWidget) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    // แสดง PIN widget
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header: ปุ่มย้อนกลับ
            _buildHeader(context, _viewModel),

            // ระยะห่าง
            SizedBox(height: AppDims.size_32.h),

            // Logo Browny
            _buildLogo(),

            // ระยะห่าง
            SizedBox(height: AppDims.size_24.h),

            // ข้อความ Title
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
            if (_authViewModel.isLoading)
              Padding(
                padding: EdgeInsets.only(bottom: AppDims.size_24.h),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),

            // Numpad (0-9) และปุ่มลบ + Biometric
            if (!_authViewModel.isLoading)
              _buildNumpadWithBiometric(_authViewModel),

            // ระยะห่างด้านล่าง
            SizedBox(height: AppDims.size_24.h),
          ],
        ),
      ),
    );
  }

  /// Override header เพื่อ pop กลับเมื่อกดย้อนกลับ
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
              if (context.canPop()) {
                context.pop(false);
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

  /// Numpad พร้อมปุ่ม Biometric
  Widget _buildNumpadWithBiometric(PinBiometricViewModel viewModel) {
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

          // แถวที่ 4: biometric 0 ลบ
          _buildNumpadRowWithBiometric(viewModel),
        ],
      ),
    );
  }

  /// แถวสุดท้ายของ Numpad (มีปุ่ม Biometric)
  Widget _buildNumpadRowWithBiometric(PinBiometricViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // ปุ่ม Biometric (ถ้าเปิดใช้งาน)
        Expanded(
          child: _isBiometricEnabled
              ? _buildNumpadButton(
                  onTap: () async {
                    await _attemptBiometricAuth();
                  },
                  child: Assets.svg.icFaceId.svg(
                    width: 28.w,
                    height: 28.h,
                  ),
                )
              : SizedBox(),
        ),

        // ปุ่ม 0
        Expanded(
          child: _buildNumpadButton(
            onTap: () async {
              viewModel.addDigit('0', () {});
              // ตรวจสอบถ้ากรอกครบ 6 หลัก
              if (viewModel.pin.length == 6) {
                await _verifyPinAndPop();
              }
            },
            child: AppText(
              '0',
              style: AppTextNumberStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),

        // ปุ่มลบ
        Expanded(
          child: _buildNumpadButton(
            onTap: () => viewModel.removeDigit(),
            child: Assets.svg.icBackspace.svg(
              width: 20.w,
              height: 20.h,
            ),
          ),
        ),
      ],
    );
  }

  /// Override _buildNumpadRow เพื่อเพิ่ม verify logic
  Widget _buildNumpadRow(
    PinBiometricViewModel viewModel,
    List<String> numbers,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return Expanded(child: SizedBox());
        } else {
          return Expanded(
            child: _buildNumpadButton(
              onTap: () async {
                viewModel.addDigit(number, () {});
                // ตรวจสอบถ้ากรอกครบ 6 หลัก
                if (viewModel.pin.length == 6) {
                  await _verifyPinAndPop();
                }
              },
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

  /// ตรวจสอบ PIN และ pop กลับ
  Future<void> _verifyPinAndPop() async {
    await Future.delayed(Duration(milliseconds: 200));
    final bool success = await _authViewModel.verifyPinForAuth();

    if (success && mounted && context.mounted) {
      // PIN ถูกต้อง - pop กลับพร้อม result
      if (context.canPop()) {
        context.pop(true);
      }
    }
    // ถ้าไม่ถูกต้อง error message จะแสดงโดย viewModel
  }
}
