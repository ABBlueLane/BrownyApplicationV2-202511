import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/api_model_index.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:browny_applications_new/feature/authentication/error/authen_exception.dart';
import 'package:browny_applications_new/feature/profile/repository/contact_change_repo.dart';

enum ChangeContactField { email, phone }

enum ChangeContactStep { enterNew, verifyOldOtp, verifyNewOtp }

class ChangeContactViewModel extends AppViewModelFormFieldValidation {
  ChangeContactViewModel({
    required super.context,
    required this.field,
    ContactChangeRepo? repo,
  }) : repo = repo ?? ContactChangeRepo() {
    final current = currentCustomerProvider.current;
    currentValue = field == ChangeContactField.email
        ? current.email.orEmpty
        : current.phone.orEmpty;
    isAddFlow = currentValue.trim().isEmpty;
  }

  final ContactChangeRepo repo;
  final ChangeContactField field;

  final formKey = GlobalKey<FormState>();
  final newValueController = TextEditingController();
  final otpController = TextEditingController();

  late final String currentValue;
  late final bool isAddFlow;

  ChangeContactStep step = ChangeContactStep.enterNew;
  int? changeId;
  String? otpUsername;
  String? refCode;
  String? otpError;

  String get fieldApiValue =>
      field == ChangeContactField.email ? 'email' : 'phone';

  bool get isEmail => field == ChangeContactField.email;

  String get newValue => newValueController.text.trim();

  void goToStep(ChangeContactStep next) {
    step = next;
    otpController.clear();
    otpError = null;
    notifyListeners();
  }

  String? validateNewValue(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return isEmail
          ? context.wording.pleaseEnterNewEmail
          : context.wording.pleaseEnterPhone;
    }
    if (isEmail && !isValidEmail(text)) {
      return context.wording.pleaseEnterValidEmail;
    }
    if (!isEmail && !isValidPhoneThai(text)) {
      return context.wording.pleaseEnterValidEmailOrPhone;
    }
    return null;
  }

  Future<UiResult<ContactChangeData>> requestOtp() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return UiResult.empty();
    }

    final customerId = currentCustomerProvider.current.id;
    if (customerId == null || customerId.isEmpty) {
      return UiResult.error(error: UserUnauthorized());
    }

    final errorFallback = context.wording.errorOccurred;
    final result = await repo.requestChange(
      ContactChangeRequest(
        id: customerId,
        field: fieldApiValue,
        newValue: newValue,
      ),
    );

    if (result.hasError) {
      return UiResult.error(error: result.error);
    }
    if (!result.isSuccess || result.data.data == null) {
      return UiResult.error(
        error: Exception(result.data.message ?? errorFallback),
      );
    }

    final data = result.data.data!;
    changeId = data.changeId;
    otpUsername = data.username;
    refCode = data.refCode;

    if (data.step == 'verify_old') {
      goToStep(ChangeContactStep.verifyOldOtp);
    } else {
      goToStep(ChangeContactStep.verifyNewOtp);
    }

    return UiResult.success(data: data);
  }

  Future<UiResult<ContactChangeData>> verifyOldOtp(String otp) async {
    return _submitOtp(
      otp: otp,
      submit: repo.verifyOld,
      onSuccess: (data) {
        otpUsername = data.username;
        refCode = data.refCode;
        goToStep(ChangeContactStep.verifyNewOtp);
      },
    );
  }

  Future<UiResult<ContactChangeData>> confirmOtp(String otp) async {
    return _submitOtp(
      otp: otp,
      submit: repo.confirm,
      onSuccess: _applyConfirmedProfile,
    );
  }

  Future<UiResult<ContactChangeData>> _submitOtp({
    required String otp,
    required Future<RepoResult<ContactChangeResponse>> Function(
      ContactChangeOtpRequest request,
    ) submit,
    required void Function(ContactChangeData data) onSuccess,
  }) async {
    final trimmed = otp.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      otpError = context.wording.pleaseEnterValidOtp4Digits;
      notifyListeners();
      return UiResult.empty();
    }

    final customerId = currentCustomerProvider.current.id;
    if (customerId == null || customerId.isEmpty || changeId == null) {
      return UiResult.error(error: UserUnauthorized());
    }

    otpError = null;
    notifyListeners();

    final errorFallback = context.wording.errorOccurred;
    final result = await submit(
      ContactChangeOtpRequest(
        id: customerId,
        changeId: changeId!,
        otp: trimmed,
      ),
    );

    if (result.hasError) {
      otpError = result.error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return UiResult.error(error: result.error);
    }
    if (!result.isSuccess || result.data.data == null) {
      final message = result.data.message ?? errorFallback;
      otpError = message;
      notifyListeners();
      return UiResult.error(error: Exception(message));
    }

    onSuccess(result.data.data!);
    return UiResult.success(data: result.data.data!);
  }

  void _applyConfirmedProfile(ContactChangeData data) {
    final current = currentCustomerProvider.current;
    currentCustomerProvider.newUser = current.copyWith(
      email: data.email ?? current.email,
      phone: data.phone ?? current.phone,
    );
  }

  @override
  void dispose() {
    newValueController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
