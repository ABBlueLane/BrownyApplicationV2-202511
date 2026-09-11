import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/response/store_detail_response.dart';

class StoreBottomSheetDialog extends StatelessWidget {
  const StoreBottomSheetDialog({
    super.key,
    required this.store,
    required this.onStoreSelecte,
  });

  final StoreDataDetail store;
  final ValueSetter<Object> onStoreSelecte;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => context.safePop(),
                icon: CircleAvatar(
                  backgroundColor: AppColors.background.withValues(
                    alpha: 0.5,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppContainerRadius(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDims.size_24.r),
                  topRight: Radius.circular(AppDims.size_24.r),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(AppDims.size_16.r),
                        child: Builder(
                          builder: (context) {
                            final tag = 'hero@${store.id!}';
                            return Column(
                              children: [
                                // Store Image
                                _buildStoreImage(tag),
                                AppDims.vericalPadding_16,

                                // Store Info
                                _buildStoreInfo(context),

                                // Store Service available
                                ..._buildStoreServiceAvailable(context),

                                // Facilities
                                ..._buildFacilities(context),

                                // Select Store button
                                ElevatedButton(
                                  onPressed: () {
                                    onStoreSelecte.call(tag);
                                    // context.pop();
                                  },
                                  child: AppText(
                                    context.wording.chooseStore,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFacilities(BuildContext context) {
    return [
      ElevatedButton.icon(
        onPressed: null,
        icon: Assets.svg.icHeartRoundedGreen.svg(),
        label: AppText(
          // 'สิ่งอำนวยความสะดวก',
          context.wording.facilities,
          style: context.textTheme.labelLarge!.copyWith(
            fontSize: AppDims.size_16.sp,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          foregroundColor: AppColors.primary,
          alignment: AlignmentDirectional.centerStart,
          padding: EdgeInsets.zero,
          disabledBackgroundColor: AppColors.transparent,
          overlayColor: AppColors.transparent,
        ),
      ),
      SizedBox(
        height: AppDims.size_64.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final service = store.services![index];
            return Container(
              padding: EdgeInsets.symmetric(
                vertical: AppDims.size_2.h,
                horizontal: AppDims.size_1.w,
              ),
              child: Column(
                children: [
                  Image.network(
                    width: AppDims.size_50.w,
                    service.icon!,
                  ),
                  AppDims.vericalPadding_6,

                  AppText(
                    service.name?.getTextByLocale(
                          context.languageCode,
                        ) ??
                        '',
                    style: context.textTheme.labelSmall!.copyWith(
                      fontSize: AppDims.size_10.sp,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => AppDims.horizonPadding_8,
          itemCount: store.services.orEmpty.length,
        ),
      ),
    ];
  }

  List<Widget> _buildStoreServiceAvailable(BuildContext context) {
    return [
      ElevatedButton.icon(
        onPressed: null,
        icon: Assets.svg.icPawRoundedGreen.svg(),
        label: AppText(
          // 'บริการ',
          context.wording.services,
          style: context.textTheme.labelLarge!.copyWith(
            fontSize: AppDims.size_16.sp,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          foregroundColor: AppColors.primary,
          alignment: AlignmentDirectional.centerStart,
          padding: EdgeInsets.zero,
          disabledBackgroundColor: AppColors.transparent,
          overlayColor: AppColors.transparent,
        ),
      ),
      Row(
        children: [
          // เครื่องซัก
          Stack(
            children: [
              Assets.services.storeWasher.image(
                width: AppDims.size_109.w,
                height: AppDims.size_106.h,
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AppText(
                    // 'เครื่องซัก',
                    context.wording.washer,
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  margin: EdgeInsets.all(8.0.r),
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0.r,
                    horizontal: 4.r,
                  ),
                  width: AppDims.size_24.w,
                  decoration: BoxDecoration(
                    color: AppColors.ci3,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppText(
                      store.totalWashers.toString(),
                      style: context.textTheme.headlineSmall!.copyWith(
                        fontSize: AppDims.size_14.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppDims.horizonPadding_8,

          // เครื่องอบ
          Stack(
            children: [
              Assets.services.storeDryer.image(
                width: AppDims.size_109.w,
                height: AppDims.size_106.h,
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AppText(
                    // เครื่องอบ,
                    context.wording.dryer,
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  margin: EdgeInsets.all(8.0.r),
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0.r,
                    horizontal: 4.r,
                  ),
                  width: AppDims.size_24.w,
                  decoration: BoxDecoration(
                    color: AppColors.ci3,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppText(
                      store.totalDryers.toString(),
                      style: context.textTheme.headlineSmall!.copyWith(
                        fontSize: AppDims.size_14.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  Row _buildStoreInfo(BuildContext context) {
    return Row(
      children: [
        // Avatar Store
        CircleAvatar(
          radius: 29,
          child: ClipOval(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    store.icon.orEmpty,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        AppDims.horizonPadding_16,

        // Name, Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              AppText(
                store.getStoreNameDisplay(
                  context.languageCode,
                ),
                style: context.textTheme.headlineLarge!.copyWith(
                  fontSize: AppDims.size_16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              AppDims.vericalPadding_2,
              // Type Description
              AppText(
                store.getTypeNameDisplay(
                  context.languageCode,
                ),
                style: context.textTheme.labelLarge!.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              AppDims.vericalPadding_2,
              // Rating, Distance
              Row(
                children: [
                  // Star Icon
                  Icon(
                    Icons.star,
                    color: AppColors.yellow2,
                  ),
                  AppDims.horizonPadding_6,

                  // Rating Value
                  AppText(
                    store.ratingValue.toString(),
                    style: context.textTheme.labelLarge!.copyWith(
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppDims.horizonPadding_8,

                  // Distance and Navigator
                  GestureDetector(
                    onTap: () {
                      // Open Map
                      LaunchHelper.openMap(
                        store.latitudeValue,
                        store.longitudeValue,
                        label: store.getStoreNameDisplay(
                          context.languageCode,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDims.size_6.h,
                        horizontal: AppDims.size_8.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ci3,
                        borderRadius: BorderRadius.circular(
                          AppDims.size_30.r,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon Map Arrow
                          Assets.svg.icMapsArrow.svg(),
                          AppDims.horizonPadding_6,

                          // Distance
                          AppText(
                            store.getDistaceDisplay(
                              context.languageCode,
                            ),
                            style: context.textTheme.labelMedium!.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreImage(Object heroTag) {
    return Hero(
      tag: heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDims.size_16.r,
        ),
        child: Container(
          height: 185.h,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                store.image.orEmpty,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showDialog(
    BuildContext context,
    StoreDataDetail store,
    ValueSetter<Object> onStoreSelecte,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: AppColors.transparent,
      useRootNavigator: true,
      builder: (dialogContext) => StoreBottomSheetDialog(
        store: store,
        onStoreSelecte: onStoreSelecte,
      ),
    );
  }
}
