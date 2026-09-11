import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/response/popup_response.dart';
import 'package:carousel_slider/carousel_slider.dart';

typedef PopupDialogDismissCallback = void Function(bool dismissPopupForToday);
typedef PopupImagePressedCallback = void Function(PopupData popup);

/// Widget สำหรับแสดง Popup Dialog
///
/// รองรับ:
/// - แสดงรูปภาพและข้อความตามภาษา (รองรับหลาย popups)
/// - CarouselSlider สำหรับแสดงหลาย popups
/// - Dot indicator แสดงซ้อนทับที่ bottom center
/// - ปุ่ม "ไม่แสดงอีกในวันนี้"
/// - Event เมื่อกดที่รูป popup
/// - ปุ่มปิด
class PopupDialog extends StatefulWidget {
  final List<PopupData> popups;
  final String locale; // 'th', 'en', 'zh'
  final PopupDialogDismissCallback? onDismiss;
  final PopupImagePressedCallback? onPopupImagePressed;

  const PopupDialog({
    super.key,
    required this.popups,
    required this.locale,
    this.onDismiss,
    this.onPopupImagePressed,
  });

  @override
  State<PopupDialog> createState() => _PopupDialogState();

  /// Helper method: แสดง popup dialog
  ///
  /// ใช้ในหน้า HomePage หรือหน้าอื่นๆ
  static Future<void> show({
    required BuildContext context,
    required List<PopupData> popups,
    required String locale,
    PopupDialogDismissCallback? onDismiss,
    PopupImagePressedCallback? onPopupImagePressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopupDialog(
        popups: popups,
        locale: locale,
        onDismiss: onDismiss,
        onPopupImagePressed: onPopupImagePressed,
      ),
    );
  }
}

class _PopupDialogState extends State<PopupDialog> {
  bool _dismissPopupForToday = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Spacer(),
                Expanded(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // CarouselSlider
                      CarouselSlider.builder(
                        itemCount: widget.popups.length,
                        itemBuilder: (context, index, realIndex) {
                          final popup = widget.popups[index];
                          final imageUrl =
                              popup.image.getByLocaleCode(widget.locale) ?? '';

                          return GestureDetector(
                            onTap: () {
                              widget.onPopupImagePressed?.call(popup);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16.r),
                              ),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.fill,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: AppColors.gray500,
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        options: CarouselOptions(
                          aspectRatio: 0.75, // อัตราส่วนกว้าง:สูง (เช่น 3:4)
                          viewportFraction: 1,
                          enableInfiniteScroll: widget.popups.length > 1,
                          autoPlay: widget.popups.length > 1,
                          autoPlayInterval: const Duration(seconds: 3),
                          autoPlayAnimationDuration: const Duration(
                            milliseconds: 800,
                          ),
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                        ),
                      ),

                      // Dot indicator
                      if (widget.popups.length > 1)
                        Positioned(
                          bottom: 8.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.popups.length,
                              (index) => Container(
                                width: 8.w,
                                height: 8.h,
                                margin: EdgeInsets.symmetric(horizontal: 4.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentIndex == index
                                      ? AppColors.primary
                                      : AppColors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentGeometry.topStart,
                    child: GestureDetector(
                      // visualDensity: VisualDensity.compact,
                      onTap: () {
                        context.safePop();
                        widget.onDismiss?.call(_dismissPopupForToday);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: AppDims.size_8.w),
                        child: Assets.svg.icClosePopup.svg(
                          width: 20.w,
                          height: 20.h,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppDims.vericalPadding_10,

            CustomCheckboxTile(
              onChanged: (value) {
                setState(() {
                  _dismissPopupForToday = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCheckboxTile extends StatefulWidget {
  const CustomCheckboxTile({
    super.key,
    this.onChanged,
  });

  final ValueChanged<bool?>? onChanged;

  @override
  State<CustomCheckboxTile> createState() => _CustomCheckboxTileState();
}

class _CustomCheckboxTileState extends State<CustomCheckboxTile> {
  bool _isChecked = false; // สร้างตัวแปรเก็บสถานะไว้ที่นี่

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isChecked = !_isChecked; // สลับสถานะเมื่อกด
          widget.onChanged?.call(_isChecked);
        });
      },
      child: Container(
        // กำหนด Padding ตามที่คุณต้องการ
        padding: EdgeInsets.symmetric(
          horizontal: AppDims.size_16.w,
          vertical: AppDims.size_5.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDims.size_32.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ส่วนของ Custom Checkbox Box
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(2),
              child: _isChecked
                  ? Assets.svg.icCheckboxCheckedReg.svg(
                      width: AppDims.size_14.w,
                    )
                  : Assets.svg.icCheckboxReg.svg(
                      width: AppDims.size_14.w,
                    ),
            ),
            AppDims.horizonPadding_12,
            // ส่วนของข้อความ
            AppText(
              // ปิดการแสดงหน้าสำหรับวันนี้
              context.wording.hideForToday,
              style: context.textTheme.labelMedium!.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
