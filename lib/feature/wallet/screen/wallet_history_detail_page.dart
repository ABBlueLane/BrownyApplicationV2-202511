import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/response/wallet_history_response.dart';
import 'package:browny_applications_new/feature/wallet/widgets/wallet_history_item_widget.dart';

class WalletHistoryDetailPage extends StatelessWidget {
  const WalletHistoryDetailPage({
    super.key,
    required this.historyGroups,
  });

  final List<WalletHistoryGroup> historyGroups;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          // ประวัติการทำรายการ
          context.wording.transactionHistory,
          style: context.textTheme.titleLarge!.copyWith(
            color: AppColors.black2A,
          ),
        ),
        leading: BackButton(
          color: AppColors.black2A,
          onPressed: () => context.safePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: historyGroups.isEmpty
            ? Center(
                child: AppText(
                  // ไม่มีประวัติการทำรายการ
                  context.wording.noTransactionHistory,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDims.size_16.w,
                  vertical: AppDims.size_16.h,
                ),
                itemCount: historyGroups.length,
                separatorBuilder: (context, index) => AppDims.vericalPadding_24,
                itemBuilder: (context, groupIndex) {
                  final group = historyGroups[groupIndex];
                  return _buildGroupSection(context, group);
                },
              ),
      ),
    );
  }

  /// สร้าง Section สำหรับแสดง Group ของเดือน
  Widget _buildGroupSection(BuildContext context, WalletHistoryGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - แสดงเดือน ปี
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: AppText(
            group.formatGroupDate(context.languageCode),
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        // List ของ items ภายใต้ group
        ...group.items.sortByDateDesc().map((history) {
          return _buildSingleItem(
            context,
            title: history.getDescriptionDisplay(context.languageCode),
            date:
                history.dateTime?.formatDateDDMMMMyyyyHHmmMinText(
                  context.languageCode,
                  pattern: 'dd MMM yyyy - HH:mm:ss',
                ) ??
                '',
            amount: history.getAmountDisplay,
            isIncome: !history.isPurchase && !history.isRefund,
          );
        }),
      ],
    );
  }

  /// สร้าง Single Item สำหรับแสดงประวัติรายการ
  Widget _buildSingleItem(
    BuildContext context, {
    required String title,
    required String date,
    required String amount,
    required bool isIncome, // true = เงินเข้า, false = เงินออก
  }) {
    return WalletHistoryItemWidget(
      title: title,
      date: date,
      amount: amount,
      isIncome: isIncome,
    );
  }
}
