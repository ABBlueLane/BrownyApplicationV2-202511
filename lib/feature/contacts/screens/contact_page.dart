import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/feature/contacts/models/contact_model.dart';
import 'package:browny_applications_new/feature/contacts/repository/contact_repo.dart';
import 'package:browny_applications_new/feature/contacts/viewmodel/contact_viewmodel.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({
    super.key,
    this.provider,
  });

  final List<ContactProvider>? provider;

  static final pagePath = '/contact_page';
  static final pageName = 'contact_page';

  /// util function route to pageName
  static Future<T?> goToPage<T>(
    BuildContext context, [
    List<ContactProvider>? provider,
  ]) async {
    return await context.pushNamed(
      ContactPage.pageName,
      extra: provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ContactViewmodel(
        context: context,
        repo: ContactRepo(),
      ),
      child: _ContactContent(
        provider: provider ?? ContactProvider.values,
      ),
    );
  }
}

class _ContactContent extends StatefulWidget {
  const _ContactContent({
    required this.provider,
  });

  final List<ContactProvider> provider;

  @override
  State<_ContactContent> createState() => __ContactContentState();
}

class __ContactContentState extends State<_ContactContent> {
  late final ContactViewmodel _viewmodel;

  @override
  void initState() {
    super.initState();
    _viewmodel = context.read();
    _viewmodel.attachContext(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _viewmodel.fetchContact(widget.provider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bareBackground,
      appBar: AppBar(
        flexibleSpace: FlexibleSpaceBar(
          background: Assets.png.bgAppBar.image(
            fit: BoxFit.cover,
          ),
        ),
        title: AppText(
          // ศูนย์ความช่วยเหลือ
          context.wording.helpCenter,
          style: context.textTheme.titleLarge!.copyWith(
            color: AppColors.textWhite,
          ),
        ),
        leading: BackButton(
          color: AppColors.textWhite,
          onPressed: () => context.safePop(),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: _viewmodel.contactNotifier,
            builder: (context, result, child) {
              if (result.isLoading) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (result.hasError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: AppText(context.wording.errorUi),
                  ),
                );
              }

              final data = result.data.orEmpty;
              return Container(
                margin: EdgeInsets.all(16.r),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: AppColors.background,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      context.wording.helpAndSupport,
                      style: context.textTheme.labelLarge!.copyWith(
                        fontSize: AppDims.size_16.sp,
                      ),
                    ),
                    AppDims.vericalPadding_16,

                    ...data.map(
                      (e) => _cardContact(e),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cardContact(ContactModel data) {
    return ListTile(
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.zero,
      leading: _getContactLeading(data),
      title: _getContactTitle(data),
      subtitle: _getContactSubTitle(data),
      trailing: Assets.svg.icArrowForward.svg(),
      onTap: () async {
        if (data.type == ContactType.call) {
          final launched = await LaunchHelper.makePhoneCall(data.data);
          if (mounted && !launched) {
            AppOverlays.showBrownyDialog(
              context,
              title: context.wording.errorOccurred,
              // ข้อมูลติดต่อไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง,
              message: context.wording.invalidContactInfoError,
            );
          }
          return;
        }
        // final launched = await LaunchHelper.openFacebook('brownywash');
        final launched = await LaunchHelper.openUrlInBrowser(data.data);
        if (mounted && !launched) {
          AppOverlays.showBrownyDialog(
            context,
            title: context.wording.errorOccurred,
            // ข้อมูลติดต่อไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง,
            message: context.wording.invalidContactInfoError,
          );
        }
      },
    );
  }

  Widget _getContactLeading(ContactModel data) {
    switch (data.provider) {
      case ContactProvider.problemLink:
        return Icon(
          size: 24.w,
          Icons.language_rounded,
        );

      case ContactProvider.facebookLink:
        return Assets.iconProfilePreferences.facebook.image(
          width: 24.w,
        );

      case ContactProvider.lineLink:
        return Assets.iconProfilePreferences.icLine.svg(
          width: 24.w,
        );

      case ContactProvider.youtubeLink:
        return Assets.iconProfilePreferences.youtube.image(
          width: 24.w,
        );

      case ContactProvider.tiktokLink:
        return Assets.iconProfilePreferences.tiktok.image(
          width: 24.w,
        );

      case ContactProvider.registerTermsLink:
        return SizedBox();

      case ContactProvider.brownyCareContact:
        return Assets.iconProfilePreferences.icCalling.svg(
          width: 24.w,
        );
    }
  }

  Widget _getContactTitle(ContactModel data) {
    return AppText(
      data.provider.getNameDisplay(context.languageCode),
      style: context.textTheme.labelLarge!.copyWith(
        color: AppColors.textBare,
      ),
    );
  }

  Widget? _getContactSubTitle(ContactModel data) {
    if (data.provider == ContactProvider.brownyCareContact) {
      return AppText(
        '${context.wording.callPhoneNumber} ${data.data}',
        style: context.textTheme.labelMedium!.copyWith(
          color: AppColors.gray500,
        ),
      );
    }
    return null;
  }
}
