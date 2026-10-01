import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/content_localize_data.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/authentication/screen/authentication_page.dart';
import 'package:browny_applications_new/feature/authentication/viewmodel/authentication_viewmodel.dart';
import 'package:browny_applications_new/feature/profile/screen/profile_page.dart';
import 'package:browny_applications_new/feature/profile/viewmodel/change_contact_viewmodel.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

class ChangeContactPage extends StatelessWidget {
  const ChangeContactPage({
    super.key,
    required this.field,
  });

  static const pagePath = '/change_contact';
  static const pageName = 'change_contact';
  static const kField = 'field';

  final ChangeContactField field;

  static Future<T?> goToPage<T>(
    BuildContext context, {
    required ChangeContactField field,
  }) async {
    final customer = context.read<CustomerProvider>().current;
    if (customer.isGuest) {
      return await AuthenticationPage.goToPage(
        context,
        process: AuthenProcess.login,
      );
    }

    // เว็บ: ถ้ายังไม่มีอีเมลต้องเพิ่มในหน้า profile ก่อน
    if (field == ChangeContactField.email &&
        customer.email.orEmpty.trim().isEmpty) {
      await AppOverlays.showBrownyDialog(
        context,
        title: context.wording.pleaseAddEmailFirstTitle,
        message: context.wording.pleaseAddEmailFirstMessage,
        confirmText: context.wording.ok,
      );
      if (!context.mounted) return null;
      return await ProfilePage.goToPage(context);
    }

    return await context.pushNamed(
      ChangeContactPage.pageName,
      extra: {ChangeContactPage.kField: field},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChangeContactViewModel(
        context: context,
        field: field,
      ),
      child: const _ChangeContactContent(),
    );
  }
}

class _ChangeContactContent extends StatefulWidget {
  const _ChangeContactContent();

  @override
  State<_ChangeContactContent> createState() => _ChangeContactContentState();
}

class _ChangeContactContentState extends State<_ChangeContactContent> {
  late final ChangeContactViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ChangeContactViewModel>();
    _viewModel.attachContext(context);
  }

  String get _pageTitle {
    if (_viewModel.isEmail) {
      return _viewModel.isAddFlow
          ? context.wording.addEmail
          : context.wording.changeEmail;
    }
    return _viewModel.isAddFlow
        ? context.wording.addPhoneNumber
        : context.wording.changePhone;
  }

  Future<void> _handleResult(UiResult result) async {
    if (!mounted) return;
    AppOverlays.hideLoading();

    if (result.isEmpty && !result.hasError) {
      return;
    }

    if (result.hasError) {
      await _showError(result.error);
      return;
    }

    if (!result.isSuccess) {
      await AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        message: context.wording.errorUi,
        confirmText: context.wording.ok,
      );
    }
  }

  Future<void> _showError(Exception error) async {
    String message = context.wording.errorUi;
    if (error is UserDuplicated) {
      message = context.wording.userDuplicated;
    } else if (error is UserUnauthorized) {
      message = context.wording.login;
    } else {
      final raw = error.toString().replaceFirst('Exception: ', '');
      if (raw.isNotEmpty) message = raw;
    }

    await AppOverlays.showBrownyDialog(
      context,
      title: context.wording.contactChangeErrorTitle,
      message: message,
      confirmText: context.wording.ok,
    );
  }

  Future<void> _onRequestOtp() async {
    AppOverlays.showLoading(context);
    final result = await _viewModel.requestOtp();
    await _handleResult(result);
  }

  Future<void> _onVerifyOld(String otp) async {
    AppOverlays.showLoading(context);
    final result = await _viewModel.verifyOldOtp(otp);
    await _handleResult(result);
  }

  Future<void> _onConfirm(String otp) async {
    AppOverlays.showLoading(context);
    final result = await _viewModel.confirmOtp(otp);
    if (!mounted) return;
    AppOverlays.hideLoading();

    if (result.isEmpty && !result.hasError) {
      return;
    }

    if (result.hasError) {
      await _showError(result.error);
      return;
    }

    if (!result.isSuccess) {
      await AppOverlays.showBrownyDialog(
        context,
        title: context.wording.errorOccurred,
        message: context.wording.errorUi,
        confirmText: context.wording.ok,
      );
      return;
    }

    final message = _viewModel.isEmail
        ? context.wording.emailChangedSuccessfully
        : context.wording.phoneChangedSuccessfully;

    final confirmed = await AppOverlays.showBrownyDialog(
      context,
      title: context.wording.contactChangeSuccessTitle,
      message: message,
      confirmText: context.wording.ok,
    );

    if (!mounted) return;
    if (confirmed == true && context.canPop()) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 100.w,
        leading: TextButton.icon(
          onPressed: () {
            if (_viewModel.step == ChangeContactStep.enterNew) {
              context.pop();
              return;
            }
            if (_viewModel.step == ChangeContactStep.verifyNewOtp &&
                !_viewModel.isAddFlow) {
              _viewModel.goToStep(ChangeContactStep.verifyOldOtp);
              return;
            }
            _viewModel.goToStep(ChangeContactStep.enterNew);
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
        title: AppText(
          _pageTitle,
          style: context.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<ChangeContactViewModel>(
          builder: (context, vm, _) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDims.size_24.w,
                vertical: AppDims.size_16.h,
              ),
              child: switch (vm.step) {
                ChangeContactStep.enterNew => _buildEnterNewStep(vm),
                ChangeContactStep.verifyOldOtp => _buildOtpStep(
                  vm,
                  title: context.wording.confirmOTP,
                  buttonText: context.wording.verifyOldContactOtp,
                  onSubmit: _onVerifyOld,
                ),
                ChangeContactStep.verifyNewOtp => _buildOtpStep(
                  vm,
                  title: context.wording.confirmOTP,
                  buttonText: context.wording.confirmAndSave,
                  onSubmit: _onConfirm,
                ),
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnterNewStep(ChangeContactViewModel vm) {
    final placeholder = vm.isEmail
        ? (vm.isAddFlow
              ? context.wording.emailPlaceholderAdd
              : context.wording.newEmailPlaceholder)
        : (vm.isAddFlow
              ? context.wording.phonePlaceholderAdd
              : context.wording.newPhonePlaceholder);

    return Form(
      key: vm.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            '${context.wording.currentContactLabel}: ${vm.currentValue.trim().isEmpty ? context.wording.currentContactNone : vm.currentValue}',
            style: context.textTheme.bodyMedium!.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppDims.vericalPadding_24,
          AppTextFormField(
            controller: vm.newValueController,
            keyboardType: vm.isEmail
                ? TextInputType.emailAddress
                : TextInputType.phone,
            maxLength: vm.isEmail ? null : 10,
            inputFormatters: vm.isEmail
                ? null
                : [FilteringTextInputFormatter.digitsOnly],
            validator: vm.validateNewValue,
            decoration: InputDecoration(
              hintText: placeholder,
              counterText: '',
              fillColor: AppColors.background,
              prefixIcon: const SizedBox.shrink(),
            ),
          ),
          AppDims.vericalPadding_24,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onRequestOtp,
              child: AppText(context.wording.sendOtp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(
    ChangeContactViewModel vm, {
    required String title,
    required String buttonText,
    required Future<void> Function(String otp) onSubmit,
  }) {
    final defaultPinTheme = PinTheme(
      width: 72.w,
      height: 72.h,
      textStyle: AppTextNumberStyles.headlineLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.inputFieldDefaultBorder,
          width: 1,
        ),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: context.textTheme.titleLarge!.copyWith(
              fontSize: AppDims.size_24.sp,
            ),
          ),
          AppDims.vericalPadding_8,
          AppText(
            '${context.wording.otpSentTo} ${vm.otpUsername.orEmpty}',
            style: context.textTheme.bodyMedium!.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppDims.vericalPadding_32,
          Pinput(
            length: 4,
            controller: vm.otpController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyDecorationWith(
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            forceErrorState: vm.otpError != null,
            autofocus: true,
            onCompleted: onSubmit,
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            separatorBuilder: (index) => SizedBox(width: 12.w),
          ),
          AppDims.vericalPadding_24,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onSubmit(vm.otpController.text),
              child: AppText(buttonText),
            ),
          ),
          AppDims.vericalPadding_24,
          Center(
            child: AppText(
              ContentLocalizeData(
                en: 'Referral Code ${vm.refCode.orEmpty}',
                zh: '推荐码 ${vm.refCode.orEmpty}',
                th: 'รหัสอ้างอิง ${vm.refCode.orEmpty}',
              ).getTextByLocale(context.languageCode),
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (vm.otpError != null) ...[
            AppDims.vericalPadding_12,
            Center(
              child: AppText(
                vm.otpError!,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
