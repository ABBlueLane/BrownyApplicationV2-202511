import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/feature/articles/models/article_detail_model.dart';
import 'package:browny_applications_new/feature/articles/screens/article_detail_page.dart';
import 'package:browny_applications_new/feature/home/models/banner_model.dart';
import 'package:browny_applications_new/feature/home/viewmodel/home_page_viewmodel.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({
    super.key,
    required this.viewModel,
  });

  final HomePageViewmodel viewModel;

  static final pagePath = '/articles_page';
  static final pageName = 'articles_page';

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  // ========================================
  // State Variables
  // ========================================

  int _selectedCategoryId = 0; // 0 = all
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppOverlays.showLoading(context);
      await widget.viewModel.fetchBanners();

      if (!mounted) return;

      AppOverlays.hideLoading();
      if (widget.viewModel.highlighSelected != null) {
        await ArticleDetailPage.goToPage(
          context,
          widget.viewModel,
          // ArticleDetailModel.fromBannerHighlightData(
          //   widget.viewModel.highlighSelected!,
          // ),
        );
        // await context.pushNamed(
        //   ArticleDetailPage.pageName,
        //   extra: ArticleDetailModel.fromBannerHighlightData(
        //     widget.viewModel.highlighSelected!,
        //   ),
        // );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: FlexibleSpaceBar(
          background: Assets.png.bgAppBar.image(
            fit: BoxFit.cover,
          ),
        ),
        title: AppText(
          'Browny Club',
          style: context.textTheme.titleLarge!.copyWith(
            color: AppColors.textWhite,
          ),
        ),
        leading: BackButton(
          color: AppColors.textWhite,
          onPressed: () => context.safePop(),
        ),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ========================================
          // Top Padding
          // ========================================
          SliverToBoxAdapter(
            child: AppDims.vericalPadding_16,
          ),

          // ========================================
          // Banner Section
          // ========================================
          SliverToBoxAdapter(
            child: _buildBannerSection(),
          ),

          // ========================================
          // Padding after Banner
          // ========================================
          SliverToBoxAdapter(
            child: AppDims.vericalPadding_16,
          ),

          // ========================================
          // Articles List Section (Header + List)
          // ========================================
          SliverFillRemaining(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                boxShadow: AppColors.shadowOnlyTop,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDims.vericalPadding_24,

                  // Section Title - กิจกรรม
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDims.size_16.w,
                    ),
                    child: AppText(
                      // กิจกรรม
                      context.wording.activities,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontSize: AppDims.size_16.sp,
                      ),
                    ),
                  ),

                  AppDims.vericalPadding_16,

                  // Categories Filter
                  _buildCategoriesFilter(),

                  AppDims.vericalPadding_16,

                  // Articles List
                  _buildArticlesList(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BrownyBottomNav(
        currentIndex: 0,
        onTap: BrownyBottomNav.onTapAppDefault,
      ),
    );
  }

  // ========================================
  // Banner Section
  // ========================================

  Widget _buildBannerSection() {
    return ValueListenableBuilder(
      valueListenable: widget.viewModel.bannerHighlightNotifier,
      builder: (context, result, _) {
        if (result.isLoading) {
          return SizedBox(
            height: 260.h,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (result.isEmpty || !result.isSuccess) {
          return SizedBox(
            height: 260.h,
            child: Center(
              child: AppText(
                'ไม่มีข้อมูล Banner',
                style: context.textTheme.bodyMedium,
              ),
            ),
          );
        }

        final banners = result.data!;

        return SizedBox(
          height: 196.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
            scrollDirection: Axis.horizontal,
            itemCount: banners.length,
            separatorBuilder: (context, index) => AppDims.horizonPadding_12,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return GestureDetector(
                onTap: () {
                  if (banner.isExternalLink) {
                    LaunchHelper.openUrlInBrowser(banner.target.orEmpty);
                  } else {
                    widget.viewModel.onBannerHighLightSelected(
                      context,
                      redirect: false,
                      highlight: ArticleDetailModel.fromBannerHighlightData(
                        banner,
                      ),
                    );
                    ArticleDetailPage.goToPage(
                      context,
                      widget.viewModel,
                    );
                  }
                },
                child: _buildBannerCard(banner),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBannerCard(BannerHighLightModel banner) {
    final locale = context.languageCode;
    final imageUrl = banner.image?.getByLocaleCode(locale) ?? '';
    final title = banner.title?.getByLocaleCode(locale) ?? '';
    final categoryName = banner.category?.name?.getByLocaleCode(locale) ?? '';
    final dateText = banner.dateTime != null
        ? banner.dateTime!.formatDateLocale(locale, pattern: 'MMM dd, yyyy')
        : '';

    return SizedBox(
      width: 250.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          Container(
            // width: 250.w,
            height: 135.h,
            decoration: BoxDecoration(
              color: AppColors.gray400,
              borderRadius: BorderRadius.circular(AppDims.size_12.r),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppDims.size_12.r),
                    child: Image.network(
                      width: double.infinity,
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) => Center(
                        child: Icon(
                          Icons.image,
                          size: 48.r,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.image,
                      size: 48.r,
                      color: AppColors.gray500,
                    ),
                  ),
          ),

          AppDims.vericalPadding_8,

          // Banner Title
          AppText(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          AppDims.vericalPadding_4,

          // Banner Category and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (categoryName.isNotEmpty) ...[
                AppText(
                  categoryName,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (dateText.isNotEmpty) AppDims.horizonPadding_8,
              ],
              if (dateText.isNotEmpty)
                AppText(
                  dateText,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: AppDims.size_10,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // Categories Filter
  // ========================================

  Widget _buildCategoriesFilter() {
    return ValueListenableBuilder(
      valueListenable: widget.viewModel.categoriesNotifier,
      builder: (context, result, _) {
        if (result.isLoading || result.isEmpty || !result.isSuccess) {
          return SizedBox(height: 25.h);
        }

        final locale = context.languageCode;
        final categories = result.data!;

        return SizedBox(
          height: 25.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1, // +1 สำหรับ "ทั้งหมด"
            separatorBuilder: (context, index) => AppDims.horizonPadding_8,
            itemBuilder: (context, index) {
              // First item is "ทั้งหมด" (All)
              if (index == 0) {
                return _buildCategoryChip(
                  // ทั้งหมด
                  label: context.wording.all,
                  isSelected: _selectedCategoryId == 0,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = 0;
                      _isExpanded = false;
                    });
                  },
                );
              }

              // Other categories
              final category = categories[index - 1];
              final categoryId = category.id ?? 0;
              final categoryName = category.name?.getByLocaleCode(locale) ?? '';

              return _buildCategoryChip(
                label: categoryName,
                isSelected: _selectedCategoryId == categoryId,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = categoryId;
                    _isExpanded = false;
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppDims.size_8.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray400,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppDims.size_4.r),
        ),
        child: Center(
          child: AppText(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // Articles List
  // ========================================

  Widget _buildArticlesList() {
    return ValueListenableBuilder(
      valueListenable: widget.viewModel.bannerNotifier,
      builder: (context, result, _) {
        if (result.isLoading) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppDims.size_32.h),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (result.isEmpty || !result.isSuccess) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDims.size_16.w,
              vertical: AppDims.size_32.h,
            ),
            child: Center(
              child: AppText(
                // ไม่มีข้อมูลบทความ
                context.wording.noArticlesData,
                style: context.textTheme.bodyMedium,
              ),
            ),
          );
        }

        // Filter articles ตาม category ที่เลือก
        var articles = result.data!;
        if (_selectedCategoryId != 0) {
          articles = articles
              .where((article) => article.category?.id == _selectedCategoryId)
              .toList();
        }

        if (articles.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDims.size_16.w,
              vertical: AppDims.size_32.h,
            ),
            child: Center(
              child: AppText(
                // ไม่มีบทความในหมวดหมู่นี้
                context.wording.noArticlesInCategory,
                style: context.textTheme.bodyMedium,
              ),
            ),
          );
        }

        // แสดงเฉพาะ 6 รายการแรก หรือทั้งหมดถ้า expanded
        final displayArticles = _isExpanded
            ? articles
            : articles.take(6).toList();

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: AppDims.size_16.w),
              itemCount: displayArticles.length,
              separatorBuilder: (context, index) => AppDims.vericalPadding_16,
              itemBuilder: (context, index) {
                final article = displayArticles[index];
                return GestureDetector(
                  onTap: () {
                    if (article.isExternalLink) {
                      LaunchHelper.openUrlInBrowser(article.target.orEmpty);
                    } else {
                      widget.viewModel.onBannerHighLightSelected(
                        context,
                        redirect: false,
                        highlight: ArticleDetailModel.fromBannerData(article),
                      );
                      ArticleDetailPage.goToPage(context, widget.viewModel);
                      // context.pushNamed(
                      //   ArticleDetailPage.pageName,
                      //   extra: ArticleDetailModel.fromBannerData(article),
                      // );
                    }
                  },
                  child: _buildArticleCard(article),
                );
              },
            ),
            // Load More Button
            if (articles.length > 6 && !_isExpanded) _buildLoadMoreButton(),

            // Bottom Padding
            AppDims.vericalPadding_24,
          ],
        );
      },
    );
  }

  Widget _buildArticleCard(BannerModel article) {
    final locale = context.languageCode;
    final imageUrl = article.image?.getByLocaleCode(locale) ?? '';
    final title = article.title?.getByLocaleCode(locale) ?? '';
    final categoryName = article.category?.name?.getByLocaleCode(locale) ?? '';
    final dateText = article.dateTime != null
        ? article.dateTime!.formatDateLocale(locale, pattern: 'MMM dd, yyyy')
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Article Image
        Container(
          width: 120.w,
          height: 80.h,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDims.size_8.r),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppDims.size_8.r),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) => Center(
                      child: Icon(
                        Icons.image,
                        size: 32.r,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.image,
                    size: 32.r,
                    color: AppColors.gray500,
                  ),
                ),
        ),

        AppDims.horizonPadding_12,

        // Article Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(AppDims.size_4.w),
                    decoration: BoxDecoration(
                      color: AppColors.bareBackground,
                      borderRadius: BorderRadius.circular(AppDims.size_4.r),
                    ),
                    child: Center(
                      child: AppText(
                        categoryName,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                          fontSize: AppDims.size_10,
                        ),
                      ),
                    ),
                  ),
                  AppText(
                    dateText,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: AppDims.size_10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              AppDims.vericalPadding_4,

              // Title
              AppText(
                title,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black2A,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              AppDims.vericalPadding_4,
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // Load More Button
  // ========================================

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
        vertical: AppDims.size_16.h,
      ),
      child: Center(
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = true;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                // ดูเพิ่มเติม
                context.wording.viewMore,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppDims.horizonPadding_4,
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 20.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
