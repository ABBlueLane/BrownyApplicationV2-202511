import 'dart:async';
import 'dart:ui' as ui;

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/response/machine_detail_response.dart';
import 'package:browny_applications_new/feature/contacts/models/contact_model.dart';
import 'package:browny_applications_new/feature/contacts/screens/contact_page.dart';
import 'package:browny_applications_new/feature/transactions/repository/coupon_voucher_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/machine_transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/transaction_repo.dart';
import 'package:browny_applications_new/feature/transactions/viewmodel/transactions_viewmodel.dart';
import 'package:flutter/services.dart';

class MachineStatusPage extends StatelessWidget {
  const MachineStatusPage({
    super.key,
    required this.machineId,
  });

  static final pagePath = '/machine_status_page';
  static final pageName = 'machine_status_page';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, {
    required String machineId,
  }) async {
    return await context.pushNamed(
      MachineStatusPage.pageName,
      extra: machineId,
    );
  }

  static void goReplacementPage(
    BuildContext context, {
    required String machineId,
  }) async {
    return context.pushReplacementNamed(
      MachineStatusPage.pageName,
      extra: machineId,
    );
  }

  final String machineId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MachineTransactionViewmodel(
        context: context,
        couponRepo: CouponVoucherRepo(),
        transactionRepo: TransactionRepo(),
        machineRepo: MachineRepo(),
      ),
      child: MachineStatusContent(
        machineId: machineId,
      ),
    );
  }
}

class MachineStatusContent extends StatefulWidget {
  const MachineStatusContent({
    super.key,
    required this.machineId,
  });
  final String machineId;

  @override
  State<MachineStatusContent> createState() => _MachineStatusContentState();
}

class _MachineStatusContentState extends State<MachineStatusContent>
    with WidgetsBindingObserver {
  TextStyle get _textPrimary => context.textTheme.labelLarge!.copyWith(
    color: AppColors.textPrimary,
  );

  late final MachineTransactionViewmodel _viewmodel;
  ui.Image? _thumbImage;
  bool _isImageLoading = true;
  bool isMachineStarted = false;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewmodel = context.read();
    _viewmodel.attachContext(context);
    // เฝ้า countdown เพื่อเริ่ม poll ตอนเวลาหมด
    _viewmodel.remainingDurationNotifier.addListener(
      _onRemainingDurationChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadThumbImage();
      // Fetch machine detail ครั้งแรก
      await _viewmodel.fetchMachineDetail(widget.machineId);
      // เริ่ม/หยุด timer ตามสถานะหลัง fetch เสร็จ
      if (mounted) {
        _syncAutoCheckTimer();
      }
    });
  }

  @override
  void dispose() {
    // ยกเลิก auto-check timer
    _autoCheckTimer?.cancel();
    _viewmodel.remainingDurationNotifier.removeListener(
      _onRemainingDurationChanged,
    );
    // ViewModel จะจัดการ dispose timer เอง
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// DONG 2026-08-02
  ///
  /// countdown นับจนหมด (เหลือ 00:00) แต่ API ยังรายงานว่าเครื่องทำงานอยู่
  /// ต้องเริ่ม poll เพื่อรอ backend อัพเดท status เป็นเสร็จสิ้น
  /// ไม่งั้นสถานะจะค้างที่ `กำลังทำงาน` จนกว่าผู้ใช้จะ refresh เอง
  void _onRemainingDurationChanged() {
    if (!mounted) return;
    if (_viewmodel.isAwaitingCompletion) {
      _syncAutoCheckTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state case AppLifecycleState.resumed) {
      debugPrint('AppLifecycleState.resumed');
      // ถ้ามีการพับแอพหรือไปแอพอื่นกลับมา จะทำการ fetch ใหม่
      if (mounted) {
        Future.microtask(() async {
          await _viewmodel.fetchMachineDetail(widget.machineId);
          // เริ่ม/หยุด timer ตามสถานะหลัง fetch เสร็จ เหมือน flow อื่นๆ
          if (mounted) _syncAutoCheckTimer();
        });
      }
    }
  }

  /// โหลด SVG/PNG asset และแปลงเป็น ui.Image สำหรับใช้ใน CustomThumbShape
  Future<void> _loadThumbImage() async {
    try {
      // โหลดรูป corgi icon (ปรับตาม asset ที่มี)
      final ByteData data = await rootBundle.load(
        // 'assets/png/ic_paw_2_rounded_green.png',
        Assets.png.brownyProgressCircle.path,
      );
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 60,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      setState(() {
        _thumbImage = frameInfo.image;
        _isImageLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading thumb image: $e');
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  /// Sync auto-check timer ตามสถานะเครื่อง
  /// - ยังไม่เริ่มทำงาน (isNotStarted): start timer poll ทุก 3 วิ
  /// - countdown หมดแล้วแต่ API ยังบอกว่าทำงานอยู่: start timer เพื่อรอ status ใหม่
  /// - กำลังทำงาน (countdown ยังเดินอยู่) หรือทำงานเสร็จแล้ว: stop timer
  ///
  /// DONG 2026-08-02
  /// เดิมเช็คด้วย `!isBusy` ทำให้ตอนเครื่องทำงานเสร็จ (status กลับมาเป็น Vacant)
  /// timer ถูกสั่งให้เริ่มใหม่และยิง API ทุก 3 วิไปเรื่อยๆ ไม่มีวันหยุด
  void _syncAutoCheckTimer() {
    final machineDetail = _viewmodel.machineDetailNotifier.value;
    if (machineDetail == null) return;

    if (_shouldKeepPolling(machineDetail)) {
      _startAutoCheckTimer();
    } else {
      _stopAutoCheckTimer();
    }
  }

  /// ยังต้อง poll สถานะต่อหรือไม่ — จริงเมื่อกำลังรอ state เปลี่ยนจากฝั่ง backend
  bool _shouldKeepPolling(MachineDetailResponse machineDetail) =>
      machineDetail.isNotStarted || _viewmodel.isAwaitingCompletion;

  /// กด "ตรวจสอบสถานะ" จาก inline not-started panel
  Future<void> _onCheckStatusPressed() async {
    AppOverlays.showLoading(context);
    await Future.delayed(const Duration(seconds: 1, milliseconds: 5));
    await _viewmodel.fetchMachineDetail(widget.machineId);
    AppOverlays.hideLoading();
    if (!mounted) return;
    _syncAutoCheckTimer();
  }

  /// กด "แจ้งปัญหาการใช้งาน" จาก inline not-started panel
  Future<void> _onReportProblemPressed() async {
    await ContactPage.goToPage(
      context,
      ContactProvider.helpAndProblemNoti,
    );
    if (!mounted) return;
    await _viewmodel.fetchMachineDetail(widget.machineId);
    if (!mounted) return;
    _syncAutoCheckTimer();
  }

  /// เริ่ม Timer เพื่อ auto-check สถานะเครื่องทุกๆ 3 วินาที
  void _startAutoCheckTimer() {
    // ยกเลิก timer เก่าก่อน (ถ้ามี)
    _autoCheckTimer?.cancel();

    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // เช็คสถานะเครื่อง
      await _viewmodel.fetchMachineDetail(widget.machineId);

      final machineDetail = _viewmodel.machineDetailNotifier.value;
      if (machineDetail != null && !_shouldKeepPolling(machineDetail)) {
        // เครื่องเริ่มทำงานแล้ว หรือทำงานเสร็จไปแล้ว หยุด timer
        _stopAutoCheckTimer();
      }
    });
  }

  /// หยุด Timer
  void _stopAutoCheckTimer() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      persistentFooterDecoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: AppColors.defatultShadow,
      ),
      persistentFooterButtons: [
        // ปุ่มกลับสู่หน้าหลัก
        ValueListenableBuilder<MachineDetailResponse?>(
          valueListenable: _viewmodel.machineDetailNotifier,
          builder: (context, machineDetail, child) {
            final notStarted =
                machineDetail == null || machineDetail.isNotStarted;
            return Container(
              padding: EdgeInsets.only(
                left: AppDims.size_16.w,
                right: AppDims.size_16.w,
                top: AppDims.size_8.h,
              ),
              child: ElevatedButton(
                onPressed: notStarted
                    ? _onCheckStatusPressed
                    : () {
                        context.safePop();
                      },
                child: AppText(
                  notStarted
                      ? // ตรวจสอบสถานะ
                        context.wording.checkStatus
                      // กลับสู่หน้าหลัก
                      : context.wording.backToMainPage,
                  style: context.textTheme.headlineSmall!.copyWith(
                    fontSize: AppDims.size_14.sp,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            );
          },
        ),
      ],
      body: ValueListenableBuilder<MachineDetailResponse?>(
        valueListenable: _viewmodel.machineDetailNotifier,
        builder: (context, machineDetail, child) {
          // ตรวจสอบ loading (machineDetail == null)
          if (machineDetail == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // เช็คสถานะเครื่องครั้งแรก (เฉพาะครั้งเดียว)
          // ย้ายมาทำใน initState แล้ว ไม่ต้องทำที่นี่
          //
          // DONG 2026-08-02
          // เดิมใช้ `!isBusy` ทำให้ตอนเครื่องทำงานเสร็จ (status กลับมาเป็น Vacant)
          // เด้งกลับไปแสดง panel "เริ่มการทำงานเครื่อง" แทน timeline + สรุปรายการ
          final notStarted = machineDetail.isNotStarted;

          // แสดง UI ปกติ
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh โดยเรียก API ใหม่
              await _viewmodel.fetchMachineDetail(widget.machineId);
              if (mounted) _syncAutoCheckTimer();
            },
            child: Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Fixed Header with Machine Image
                        _buildFixedHeader(machineDetail),

                        // Title เครื่องซัก, สาขา
                        _mainTitle(machineDetail),

                        if (notStarted) ...[
                          // Inline panel แทน dialog เดิม -- ผู้ใช้กด back จาก AppBar ได้
                          _buildNotStartedPanel(),
                        ] else ...[
                          if (machineDetail.isDryer) ...[
                            machineDetail
                                .getDryerExtendingTimeDisplay(
                                  context.languageCode,
                                )
                                .image(),
                          ],
                          AppDims.vericalPadding_32,

                          // Progress Timeline
                          ..._buildTimelineProgress(context, machineDetail),

                          _divider(),

                          // Summary Transaction
                          _summary(machineDetail),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
      ),
      child: Divider(),
    );
  }

  List<Widget> _buildTimelineProgress(
    BuildContext context,
    MachineDetailResponse machineDetail,
  ) {
    return [
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
        ),
        child: Row(
          children: [
            Assets.svg.icPawRoundedGreen.svg(
              width: 30.w,
            ),
            Expanded(
              child: _isImageLoading
                  ? SizedBox(height: 4.h)
                  // Progress การทำงานของเครื่อง - ใช้ ValueListenableBuilder อัพเดทเฉพาะ Slider
                  : ValueListenableBuilder<Duration?>(
                      valueListenable: _viewmodel.remainingDurationNotifier,
                      builder: (context, remainingDuration, child) {
                        bool isProcessing = remainingDuration != Duration.zero;
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: AppDims.size_4.h,
                            thumbShape: CustomThumbShape(
                              thumbImage: _thumbImage,
                              isProcessing: isProcessing,
                              // label: '20 นาที',
                              label: _viewmodel.getBubbleLabel(
                                context.languageCode,
                              ),
                              lableStyle: AppTextNumberStyles.labelSmall
                                  .copyWith(
                                    color: AppColors.textWhite,
                                  ),
                              bubbleColor: _viewmodel.getBubbleColor(),
                            ),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 0,
                            ),
                            // สีสำหรับ disabled slider
                            disabledActiveTrackColor: AppColors.primary,
                            disabledInactiveTrackColor: AppColors.ci7,
                            // ลบ padding ซ้าย-ขวา ด้วย custom track shape
                            trackShape: CustomSliderTrackShape(),
                            padding: EdgeInsets.zero,
                          ),
                          child: Slider(
                            min: 0,
                            max: _viewmodel.totalDurationInSeconds,
                            onChanged: null, // null = disabled
                            value: _viewmodel.getSliderValue(
                              context.languageCode,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ValueListenableBuilder(
              valueListenable: _viewmodel.remainingDurationNotifier,
              builder: (context, remainingDuration, child) {
                if (remainingDuration == Duration.zero) {
                  return Assets.svg.icChecked2.svg(
                    width: 30.w,
                  );
                }
                return Assets.svg.icCheckedTrans.svg(
                  width: 30.w,
                );
              },
            ),
          ],
        ),
      ),
      AppDims.vericalPadding_2,

      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
        ),
        child: Row(
          children: [
            Column(
              children: [
                AppText(
                  // เริ่มต้น
                  context.wording.start,
                  style: _textPrimary.copyWith(
                    fontSize: AppDims.size_12.sp,
                  ),
                ),
                AppText(
                  machineDetail.startTime?.formatForShow('HH:mm') ?? '-',
                  style: _textPrimary.copyWith(
                    color: AppColors.gray500,
                    fontSize: AppDims.size_12.sp,
                  ),
                ),
              ],
            ),
            Spacer(),
            Column(
              children: [
                AppText(
                  // สำเร็จ
                  context.wording.completed,
                  style: _textPrimary.copyWith(
                    fontSize: AppDims.size_12.sp,
                  ),
                ),
                AppText(
                  machineDetail.finishDatatime.orEmpty,
                  style: _textPrimary.copyWith(
                    color: AppColors.gray500,
                    fontSize: AppDims.size_12.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      AppDims.vericalPadding_16,
    ];
  }

  Widget _buildFixedHeader(MachineDetailResponse machineDetail) {
    return Container(
      height: 365.h, // กำหนดความสูงเท่าเดิม (ตาม SliverAppBar expandedHeight)
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.png.bgMachine.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: AppText(
                  context.wording.startOperation, // เดิม: เริ่มต้นทำงาน
                  style: context.appBarTextThemeWhite,
                ),
              ),
            ),

            // Machine Model Image
            Padding(
              padding: EdgeInsets.only(
                top: AppDims.size_42.h,
                bottom: AppDims.size_42.h,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 56.w),
                  Image.network(
                    machineDetail.machineImage.orEmpty,
                    errorBuilder: (_, _, _) => SizedBox(),
                  ),
                  Container(
                    padding: EdgeInsets.only(right: AppDims.size_16.w),
                    width: 56.w,
                    height: 87.h,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Machine No
                        Stack(
                          children: [
                            Assets.png.icPaw2RoundedGreen.image(
                              width: AppDims.size_39.w,
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: AlignmentGeometry.center,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 2.0.w,
                                    top: 8.0.h,
                                  ),
                                  child: AppText(
                                    machineDetail.machineNo.toString(),
                                    style: context.textTheme.headlineSmall!
                                        .copyWith(
                                          fontSize: AppDims.size_16.sp,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppDims.vericalPadding_8,
                        ValueListenableBuilder(
                          valueListenable: _viewmodel.machineProgramsNotifier,
                          builder: (context, result, child) {
                            return Container(
                              width: AppDims.size_40.h,
                              height: result.data?.selectedProgram == null
                                  ? null
                                  : AppDims.size_40.h,
                              padding: EdgeInsets.symmetric(
                                vertical: AppDims.size_8.h,
                                horizontal: AppDims.size_13.w,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ci3,
                                shape: BoxShape.circle,
                              ),
                              child: machineDetail.programImage.orEmpty.isEmpty
                                  ? AppText(
                                      '?',
                                      style: context.textTheme.labelLarge!
                                          .copyWith(
                                            color: AppColors.primary,
                                            fontSize: AppDims.size_24.sp,
                                          ),
                                    )
                                  : Image.network(
                                      // result.data!.selectedProgram!.image!,
                                      machineDetail.programImage.orEmpty,
                                      errorBuilder: (_, _, _) => SizedBox(),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Background Radius
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppContainerRadius(
                height: AppDims.size_24.h,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainTitle(MachineDetailResponse machineDetail) {
    return Column(
      children: [
        // Title เครื่องซัก
        AppText(
          machineDetail.getMachineNameDisplay(context.languageCode),
          style: context.textTheme.headlineMedium,
        ),
        AppDims.vericalPadding_4,

        // สาขา
        AppText(
          machineDetail.getStoreNameDisplay(context.languageCode),
          style: context.textTheme.bodyMedium!.copyWith(
            color: AppColors.gray500,
          ),
        ),

        AppDims.vericalPadding_24,
      ],
    );
  }

  Widget _summary(MachineDetailResponse machineDetail) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDims.vericalPadding_16,
          // detail
          // Order ID
          _lineSummay(
            title: 'Order ID',
            tailing: machineDetail.receiptNo.orEmpty,
          ),
          AppDims.vericalPadding_16,
          // บริการ
          _lineSummay(
            // บริการ
            title: context.wording.services,
            // บริการที่เลือก
            tailing: machineDetail.getProgramNameDisplay(context.languageCode),
          ),
          AppDims.vericalPadding_16,
          // สถานะ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                // สถานะ
                context.wording.status,
                style: _textPrimary.copyWith(fontSize: AppDims.size_16.sp),
              ),
              Spacer(),
              Row(
                children: [
                  Container(
                    width: AppDims.size_12.w,
                    height: AppDims.size_12.h,
                    decoration: BoxDecoration(
                      color: machineDetail.getColorByStatus,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppDims.horizonPadding_8,

                  AppText(
                    machineDetail.getStatusDisplay(context.languageCode),
                    style: _textPrimary,
                  ),
                ],
              ),
            ],
          ),

          AppDims.vericalPadding_16,
          // เวลาที่เหลือโดยประมาณ - ใช้ ValueListenableBuilder อัพเดทแบบ realtime
          ValueListenableBuilder<Duration?>(
            valueListenable: _viewmodel.remainingDurationNotifier,
            builder: (context, remainingDuration, child) {
              return _lineSummay(
                // เวลาที่เหลือโดยประมาณ
                title: context.wording.approximateRemainingTime,
                tailing: _viewmodel.getFormattedRemainingTime(
                  context.languageCode,
                ),
                textPriceColor: AppColors.primary,
              );
            },
          ),
          AppDims.vericalPadding_16,
        ],
      ),
    );
  }

  /// Inline panel แสดงเมื่อเครื่องยังไม่เริ่มทำงาน (แทน dialog ที่ block ทั้งหน้า)
  /// ผู้ใช้สามารถกด back จาก AppBar ได้ปกติ ป้องกันกรณีเครื่องส่ง status ไม่ได้
  Widget _buildNotStartedPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_24.w,
        vertical: AppDims.size_8.h,
      ),
      child: Column(
        children: [
          Assets.png.brownyWashy.image(
            height: 95.h,
            fit: BoxFit.contain,
          ),
          AppDims.vericalPadding_16,
          AppText(
            // เริ่มการทำงานเครื่อง
            context.wording.startMachineOperation,
            style: context.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          AppDims.vericalPadding_8,
          AppText(
            // กรุณากดปุ่มที่หน้าเครื่องเพื่อเริ่มการทำงาน
            context.wording.pleasePressMachineButton,
            style: context.textTheme.bodyMedium!.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
          AppDims.vericalPadding_16,
          OutlinedButton(
            onPressed: _onReportProblemPressed,
            child: AppText(
              // แจ้งปัญหาการใช้งาน
              context.wording.reportProblem,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall!.copyWith(
                fontSize: AppDims.size_14.sp,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineSummay({
    required String title,
    required String tailing,
    Color? textPriceColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          style: _textPrimary.copyWith(fontSize: AppDims.size_16.sp),
        ),

        AppText(
          tailing,
          style: _textPrimary,
        ),
      ],
    );
  }
}

/// Custom Thumb Shape สำหรับ Slider ที่แสดงสถานะเครื่องซัก/อบ
///
/// Component นี้ประกอบด้วย:
/// 1. Speech Bubble (กล่องข้อความสีเขียว) - แสดง label เช่น "21 นาที" ด้านบน
/// 2. Triangle Tail (หางสามเหลี่ยม) - เชื่อมต่อ bubble กับ thumb
/// 3. White Circle Background (วงกลมพื้นหลังสีขาว) - ขนาด 32px
/// 4. Green Border (ขอบสีเขียว) - หนา 2px รอบวงกลม
/// 5. Paw Icon (ไอคอนรอยเท้า) - ขนาด 24x24 px อยู่ตรงกลาง
class CustomThumbShape extends SliderComponentShape {
  /// รูปภาพที่จะแสดงเป็น thumb (ควรโหลดเป็น ui.Image ก่อน)
  final ui.Image? thumbImage;

  /// ข้อความที่จะแสดงใน speech bubble ด้านบน เช่น "21 นาที"
  final String label;

  /// สีพื้นหลังของ bubble (เขียวสำหรับปกติ, แดงสำหรับ error)
  final Color bubbleColor;

  final bool isProcessing;

  CustomThumbShape({
    this.thumbImage,
    required this.label,
    required this.lableStyle,
    required this.isProcessing,
    this.bubbleColor = const Color(0xFF4CAF50),
  });

  final TextStyle? lableStyle;

  /// กำหนดขนาดของ thumb component
  ///
  /// - Width: 40px (พอดีกับ thumb)
  /// - Height: 30px (พอดีกับไอคอนข้างๆ - speech bubble จะวาดข้างนอก layout space)
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(40, 30);
  }

  /// วาด custom thumb shape ทั้งหมดบน canvas
  ///
  /// ลำดับการวาด:
  /// 1. Speech bubble (กล่องข้อความด้านบน)
  /// 2. Triangle tail (หางชี้ลงมา)
  /// 3. Label text (ข้อความใน bubble)
  /// 4. White circle (วงกลมพื้นหลัง)
  /// 5. Green border (ขอบวงกลม)
  /// 6. Thumb image (ไอคอนรอยเท้า)
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    if (!isProcessing) return;

    final Canvas canvas = context.canvas;

    // ========== ขั้นตอนที่ 1: คำนวณขนาด bubble จากความยาวของ label ==========
    // วัดความกว้างของข้อความก่อน
    final TextSpan measureSpan = TextSpan(
      text: label,
      style: lableStyle,
    );
    final TextPainter measurePainter = TextPainter(
      text: measureSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    measurePainter.layout();

    // คำนวณขนาด bubble ให้พอดีกับข้อความ + padding
    final double textWidth = measurePainter.width;
    final double textHeight = measurePainter.height;
    final double horizontalPadding = 8.w; // padding ซ้าย-ขวา
    final double verticalPadding = 6.h; // padding บน-ล่าง

    final double bubbleWidth = textWidth + (horizontalPadding * 2);
    final double bubbleHeight = textHeight + (verticalPadding * 2);
    final double bubbleTop = center.dy - 35; // ตำแหน่ง Y (อยู่เหนือ thumb)

    // ========== ขั้นตอนที่ 2: วาด Speech Bubble ==========
    // สร้าง rounded rectangle สำหรับ bubble
    final RRect bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, bubbleTop),
        width: bubbleWidth,
        height: bubbleHeight,
      ),
      Radius.circular(4.r), // มุมโค้ง
    );

    // สร้าง paint สำหรับระบายสี bubble (ใช้สีที่ส่งเข้ามา)
    final Paint bubblePaint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill; // ระบายเต็ม

    // วาด bubble ลงบน canvas
    canvas.drawRRect(bubbleRect, bubblePaint);

    // ========== ขั้นตอนที่ 2: วาดหาง bubble (Triangle Tail) ==========
    // สร้างรูปสามเหลี่ยมชี้ลงมาเชื่อม bubble กับ thumb พร้อม radius ที่ปลายแหลม
    final Path trianglePath = Path();
    final double tipRadius = 1.r; // รัศมีที่ปลายแหลม (1px)

    // กำหนดจุดสำคัญของสามเหลี่ยม
    final double leftX = center.dx - 8; // จุดซ้าย X
    final double rightX = center.dx + 8; // จุดขวา X
    final double topY = bubbleTop + bubbleHeight / 2 - 4; // จุดบน Y
    final double tipY = bubbleTop + bubbleHeight / 2 + 8; // ปลายแหลม Y

    trianglePath.moveTo(leftX, topY); // เริ่มที่จุดซ้ายบน
    trianglePath.lineTo(
      center.dx - tipRadius,
      tipY - tipRadius,
    ); // เส้นลงไปใกล้ปลาย (ซ้าย)

    // ใช้ quadratic bezier curve สร้างความโค้งมนที่ปลายแหลม
    trianglePath.quadraticBezierTo(
      center.dx,
      tipY, // control point (ปลายแหลมจริง)
      center.dx + tipRadius,
      tipY - tipRadius, // end point (ขวา)
    );

    trianglePath.lineTo(rightX, topY); // เส้นขึ้นไปจุดขวาบน
    trianglePath.close(); // ปิด path กลับไปจุดเริ่มต้น

    // วาดหางด้วยสีเดียวกับ bubble
    canvas.drawPath(trianglePath, bubblePaint);

    // ========== ขั้นตอนที่ 3: วาดข้อความใน bubble ==========
    // วาดข้อความให้อยู่ตรงกลาง bubble (ใช้ measurePainter ที่คำนวณไว้แล้ว)
    measurePainter.paint(
      canvas,
      Offset(
        center.dx - measurePainter.width / 2, // จัดกึ่งกลางแนวนอน
        bubbleTop - measurePainter.height / 2, // จัดกึ่งกลางแนวตั้ง
      ),
    );

    // ========== ขั้นตอนที่ 4: วาด Thumb Image (ไอคอนรอยเท้า) ==========
    if (thumbImage != null) {
      // กรณีมีรูปภาพ: วาด icon ขนาด 24x24 ตรงกลาง (เหลือ padding 4px รอบด้าน)
      final double imageSize = 24.w; // ขนาด icon 24x24 px

      // วาดรูปด้วย drawImageRect เพื่อ scale ให้พอดี
      canvas.drawImageRect(
        thumbImage!,
        // Source rect: ใช้รูปต้นฉบับทั้งหมด
        Rect.fromLTWH(
          0,
          0,
          thumbImage!.width.toDouble(),
          thumbImage!.height.toDouble(),
        ),
        // Destination rect: วาดให้อยู่กึ่งกลางขนาด 24x24
        Rect.fromCenter(
          center: Offset(center.dx, center.dy),
          width: imageSize,
          height: imageSize,
        ),
        Paint()
          ..filterQuality = FilterQuality.high, // ใช้ quality สูงเพื่อความคมชัด
      );
    } else {
      // Fallback: กรณีไม่มีรูป ให้วาดวงกลมสีเขียวแทน
      final Paint circlePaint = Paint()
        ..color = AppColors.ci3
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 12, circlePaint);
    }
  }
}

/// Custom Slider Track Shape ที่ไม่มี horizontal padding
/// ทำให้ track ยาวเต็มความกว้างของ slider
class CustomSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );

    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackRadius = trackHeight / 5;

    // วาด inactive track (ส่วนที่ยังไม่เสร็จ)
    final Rect inactiveTrackRect = Rect.fromLTRB(
      thumbCenter.dx,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );
    final RRect inactiveTrackRRect = RRect.fromRectAndRadius(
      inactiveTrackRect,
      Radius.circular(trackRadius),
    );
    context.canvas.drawRRect(inactiveTrackRRect, inactivePaint);

    // วาด active track (ส่วนที่เสร็จแล้ว)
    final Rect activeTrackRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    final RRect activeTrackRRect = RRect.fromRectAndRadius(
      activeTrackRect,
      Radius.circular(trackRadius),
    );
    context.canvas.drawRRect(activeTrackRRect, activePaint);
  }
}
