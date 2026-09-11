import 'dart:async';

import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/response/customer_qr_response.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:browny_applications_new/feature/authentication/repository/customer_data_repo.dart';
import 'package:browny_applications_new/feature/transactions/repository/machine_transaction_repo.dart';
import 'package:browny_applications_new/feature/lucky_scan/screens/lucky_scan_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/coupons_evoucher/coupon_voucher_page.dart';
import 'package:browny_applications_new/feature/transactions/screens/machines/machine_transaction_page_2.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

enum ScannerProcess {
  // Scan เพื่อสั่งทำงานเครื่อง
  machine,
  // Scan เพื่อสั่งทำงานเครื่อง แต่ต้องการ result ถ้าเครื่องพร้อมใช้บริการ
  machineButNeedResult,
  // ต้องการแค่ Result จากการ Detect
  needResult,
}

class ScannerViewModel extends AppViewModel {
  ScannerViewModel({
    required super.context,
    required this.process,
    required CustomerDataSourceMixin repo,
  }) : _repo = repo;

  final CustomerDataSourceMixin _repo;
  final MachineTransactionDataSourceMixin _machRepo = MachineRepo();

  // ========= valueNotifier, controller =========
  final ScannerProcess process;

  late final ValueNotifier<UiResult<CustomerQRResponse>> _qrNotifier =
      ValueNotifier(
        UiResult.loading(),
      );
  ValueListenable<UiResult<CustomerQRResponse>> get qrNotifier => _qrNotifier;

  // Mobile Scanner Controller
  late MobileScannerController cameraController;

  // Flash state
  final ValueNotifier<bool> isFlashOn = ValueNotifier<bool>(false);

  // Tab state (0 = Scan QR, 1 = Browny ID)
  final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

  // Scanning state
  bool _isScanning = true;

  // Image Picker
  final ImagePicker _imagePicker = ImagePicker();

  /// Initialize camera with permissions
  Future<void> initializeCamera({
    required VoidCallback onPermissionDenied,
  }) async {
    try {
      // Request camera permission
      final hasPermission = await PermissionHelper.hasCameraPermission();
      if (!hasPermission) {
        final status = await PermissionHelper.requestCameraPermission();
        if (status != handler.PermissionStatus.granted) {
          // Show error dialog or navigate back
          onPermissionDenied.call();
          return;
        }
      }
      await cameraController.start();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  /// Toggle flash on/off
  Future<void> toggleFlash() async {
    try {
      unawaited(cameraController.toggleTorch());
      isFlashOn.value = !isFlashOn.value;
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  /// Pick image from gallery and analyze QR code
  Future<void> pickImageAndScan() async {
    try {
      // Stop scanning temporarily
      _isScanning = false;

      // Request photos permission
      // final hasPermission = await PermissionHelper.hasStoragePermission(
      //   context,
      // );
      // if (!context.mounted) return;

      // if (!hasPermission) {
      //   final status = await PermissionHelper.requestStoragePermission(context);
      //   if (status != handler.PermissionStatus.granted &&
      //       status != handler.PermissionStatus.limited) {
      //     _resumeFlagScanning();
      //     return;
      //   }
      // }

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        // Analyze image for QR code
        final result = await cameraController.analyzeImage(image.path);
        if (result == null || result.barcodes.isEmpty) {
          // No QR code found in image
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                // ไม่พบ QR Code ในรูปภาพ
                content: AppText(context.wording.qrCodeNotFoundInImage),
              ),
            );
          }
          _resumeFlagScanning();
        } else {
          // Detech
          if (context.mounted) {
            // คืน flag. ทันที เพื่อให้เข้าเงื่อนไขใน onQRCodeDetected
            _isScanning = true;
            onQRCodeDetected(result);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(context.wording.errorOccurred),
          ),
        );
        _resumeFlagScanning();
      }
    }
  }

  /// Handle QR code scan result
  void onQRCodeDetected(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        // Stop scanning temporarily
        _isScanning = false;

        debugPrint('QR Code detected: ${barcode.rawValue}');

        // Navigate to next page or process the data
        // scan แล้วได้่ค่าเป็นว่าง
        if (barcode.rawValue.orEmpty.isEmpty) {
          AppOverlays.showBrownyDialog(
            context,
            title: context.wording.errorOccurred,
            message: context.wording.errorUi,
          );
          return;
        }

        // Show result
        if (context.mounted) {
          try {
            switch (process) {
              case ScannerProcess.machine:
              case ScannerProcess.machineButNeedResult:
                {
                  // จะได้เป็น URL มา เอามา parse เป็น URI ไว้เช็คเงื่อนไข
                  final uri = Uri.parse(barcode.rawValue!);
                  final segments = uri.pathSegments;

                  // ตรวจสอบประเภท QR Code จาก URL path
                  // Coupon: {url}/coupon/{uuid}
                  if (segments.contains('coupon')) {
                    context.safePop();
                    CouponVoucherPage.goToPage(
                      context,
                      autoCollectQRData: barcode.rawValue!,
                    );
                    return;
                  }

                  // Lucky Scan: {url}/lucky/draw/{uuid}
                  if (segments.contains('lucky') && segments.contains('draw')) {
                    context.safePop();
                    LuckyScanPage.goToPage(
                      context,
                      autoScanQRData: barcode.rawValue!,
                    );
                    return;
                  }

                  // Machine: {url}/wash/dry/{id} (default)
                  // ดึงเอา path สุดท้ายมาใช้ {id}
                  if (segments.isNotEmpty) {
                    AppOverlays.showLoading(context);

                    final machineResult = await _machRepo.checkMachineStatus(
                      // uri.pathSegments.last,
                      barcode.rawValue!,
                    );
                    if (!context.mounted) return;

                    AppOverlays.hideLoading();
                    if (machineResult.hasError || machineResult.isEmpty) {
                      await AppOverlays.showBrownyDialog(
                        context,
                        title: context.wording.errorOccurred,
                        message: context.wording.errorUi,
                        onConfirm: () {
                          if (!context.mounted) return;
                          context.safePop();
                          // Resume scanning after 2 seconds
                          _resumeFlagScanning();
                        },
                      );
                      return;
                    }

                    final machine = machineResult.data;

                    // DONG 2026-06-09
                    // เปลี่ยน Logic เช็คว่าถ้าเครื่อง UnAvailable จะสร้าง wording แจ้งเตือน
                    if (machine.isUnavailable) {
                      String title = '';
                      String message = '';
                      if (machine.isBusy) {
                        // เครื่องกำลังทำงาน
                        title = context.wording.theMachineIsWorking;
                        // กรุณาลองเครื่องอื่น
                        message = context.wording.pleaseTryAnotherMachine;
                      } else if (machine.isMaintenance) {
                        // เครื่องไม่สามารถใช้งานได้ในขณะนี้
                        title = context.wording.machineUnavailableAtTheMoment;
                        // ระบบปิดปรับปรุงชั่วคราว
                        message =
                            context.wording.systemTemporarilyUnderMaintenance;
                      } else if (machine.isInactive) {
                        // เครื่องไม่สามารถใช้งานได้ในขณะนี้
                        title = context.wording.machineUnavailableAtTheMoment;
                        // เครื่องนี้ปิดใช้งานชั่วคราว
                        message = context.wording.machineTemporarilyDisabled;
                      } else {
                        // เครื่องไม่สามารถใช้งานได้ในขณะนี้
                        title = context.wording.machineUnavailableAtTheMoment;
                        // กรุณาลองเครื่องอื่น
                        message = context.wording.pleaseTryAnotherMachine;
                      }
                      await AppOverlays.showBrownyDialog(
                        context,
                        // เครื่องกำลังทำงาน
                        title: title,
                        // กรุณาลองเครื่องอื่น
                        message: message,
                        onConfirm: () {
                          if (!context.mounted) return;
                          context.safePop();
                          // Resume scanning after 2 seconds
                          _resumeFlagScanning();
                        },
                      );
                      return;
                    }

                    if (process == ScannerProcess.machineButNeedResult) {
                      // DONG 2026-04-18
                      // ถ้าเข้า process นี้ จะ pop result machine
                      // กลับไปเพื่อตัดสินใจจากต้นทาง
                      context.safePop(machine);
                      return;
                    }
                    // DONG 2026-04-12
                    // แก้ไขการดึงค่า machineID ให้ดึงจาก response ก่อน
                    // ถ้าไม่ได้ค่อยใช้ segments.last
                    MachineTransactionPage2.goReplacementPage(
                      context,
                      machineId:
                          machine.storeMachineId?.toString() ??
                          uri.pathSegments.last,
                    );
                    return;
                  }
                }
              case ScannerProcess.needResult:
                {
                  context.safePop(barcode.rawValue!);
                  return;
                }
            }
          } catch (_) {}

          // Failed all case
          AppOverlays.showBrownyDialog(
            context,
            title: context.wording.errorOccurred,
            message: context.wording.errorUi,
          );
        }

        // Resume scanning after 2 seconds
        _resumeFlagScanning();

        break;
      }
    }
  }

  /// Resume scanning after 2 seconds
  void _resumeFlagScanning() {
    Future.delayed(const Duration(seconds: 2), () {
      _isScanning = true;
    });
  }

  /// Change tab
  Future<void> onTabChanged(int index) async {
    selectedTab.value = index;
    if (index == 1) {
      await cameraController.pause();
    } else if (!cameraController.value.isRunning) {
      await cameraController.start();
    }
  }

  Future<void> fetchCustomerQRCode() async {
    final result = await _repo.fetchCustomerQR(
      currentCustomerProvider.current.id!,
    );

    if (result.isEmpty || result.hasError) {
      _qrNotifier.value = UiResult.empty();
      return;
    }

    _qrNotifier.value = UiResult.success(data: result.data);
  }

  @override
  void dispose() {
    _isScanning = false;
    _qrNotifier.dispose();
    // cameraController.dispose(); ไป dispose จาก Widget
    isFlashOn.dispose();
    selectedTab.dispose();
    super.dispose();
  }
}
