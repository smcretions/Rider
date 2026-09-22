import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/presentation/components/text/small_text.dart';
import 'package:toastification/toastification.dart';

class CustomSnackBar {
  static const int _defaultDuplicateToastCooldownSeconds = 3;
  static const int _unauthorizedToastCooldownSeconds = 6;
  static const int _noInternetToastCooldownSeconds = 4;
  static final Map<String, DateTime> _toastCooldownMap = {};

  static void error({
    required List<String> errorList,
    int duration = 5,
    bool dismissAll = true,
    int? preventDuplicateForSeconds,
  }) {
    final sourceMessages = errorList.isEmpty ? <String>[MyStrings.somethingWentWrong.tr] : errorList;

    final messagesToShow = sourceMessages
        .map((element) => StringConverter.removeQuotationAndSpecialCharacterFromString(element.tr.trim()))
        .where((element) => element.isNotEmpty)
        .toSet()
        .where(
          (element) => _shouldShowToastMessage(
            element,
            seconds: preventDuplicateForSeconds,
          ),
        )
        .toList();

    if (messagesToShow.isEmpty) return;

    if (dismissAll) {
      toastification.dismissAll();
    }

    for (final tempMessage in messagesToShow) {
      toastification.show(
        context: Get.context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(
          tempMessage,
          maxLines: 10,
          style: Get.theme.textTheme.bodyMedium?.copyWith(
            color: MyColor.colorWhite,
          ),
        ),
        alignment: Alignment.topCenter,
        foregroundColor: MyColor.colorWhite,
        primaryColor: MyColor.redCancelTextColor,
        showProgressBar: false,
        autoCloseDuration: Duration(seconds: duration),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        applyBlurEffect: false,
      );
    }
  }

  static void success({
    required List<String> successList,
    int duration = 5,
    bool dismissAll = false,
    int? preventDuplicateForSeconds,
  }) {
    String message = successList.isEmpty ? MyStrings.somethingWentWrong.tr : successList.map((element) => element.tr).join('\n');
    message = StringConverter.removeQuotationAndSpecialCharacterFromString(message);

    if (!_shouldShowToastMessage(
      message,
      seconds: preventDuplicateForSeconds,
    )) {
      return;
    }

    if (dismissAll) {
      toastification.dismissAll();
    }
    toastification.show(
      context: Get.context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: Text(
        message,
        maxLines: 10,
        style: Get.theme.textTheme.bodyMedium?.copyWith(
          color: MyColor.colorWhite,
        ),
      ),
      alignment: Alignment.topCenter,
      foregroundColor: MyColor.colorWhite,
      primaryColor: MyColor.greenSuccessColor,
      showProgressBar: false,
      autoCloseDuration: Duration(seconds: duration),
      borderRadius: BorderRadius.circular(Dimensions.largeRadius),
      applyBlurEffect: false,
    );
  }

  static void showToast({
    required String message,
    int duration = 2,
    bool dismissAll = false,
    int? preventDuplicateForSeconds,
  }) {
    final normalizedMessage = StringConverter.removeQuotationAndSpecialCharacterFromString(
      message.trim(),
    );

    if (!_shouldShowToastMessage(
      normalizedMessage,
      seconds: preventDuplicateForSeconds ?? duration,
    )) {
      return;
    }

    if (dismissAll) {
      toastification.dismissAll();
    }

    toastification.showCustom(
      context: Get.context, // optional if you use ToastificationWrapper
      autoCloseDuration: Duration(seconds: duration),
      alignment: Alignment.bottomCenter,
      builder: (BuildContext context, ToastificationItem holder) {
        return Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
              color: MyColor.greenSuccessColor,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space10,
              vertical: Dimensions.space8,
            ),
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.space10,
              vertical: Dimensions.space10,
            ),
            child: SmallText(
              text: normalizedMessage,
              textStyle: regularDefault.copyWith(color: MyColor.colorWhite),
            ),
          ),
        );
      },
    );
  }

  static bool _shouldShowToastMessage(
    String message, {
    int? seconds,
  }) {
    final normalizedMessage = StringConverter.removeQuotationAndSpecialCharacterFromString(message.trim());

    if (normalizedMessage.isEmpty) return false;

    final cooldownSeconds = seconds ?? _resolveToastCooldownSeconds(normalizedMessage);
    final storageKey = normalizedMessage.toLowerCase();
    final now = DateTime.now();
    final cutoffMillis = cooldownSeconds * 1000;

    _toastCooldownMap.removeWhere(
      (_, shownAt) => now.difference(shownAt).inMilliseconds > cutoffMillis * 2,
    );

    final lastShownAt = _toastCooldownMap[storageKey];
    if (lastShownAt != null && now.difference(lastShownAt).inMilliseconds < cutoffMillis) {
      return false;
    }

    _toastCooldownMap[storageKey] = now;
    return true;
  }

  static int _resolveToastCooldownSeconds(String message) {
    final normalized = message.toLowerCase();
    if (normalized == MyStrings.unAuthorized.toLowerCase()) {
      return _unauthorizedToastCooldownSeconds;
    }
    if (normalized == MyStrings.noInternet.toLowerCase()) {
      return _noInternetToastCooldownSeconds;
    }
    return _defaultDuplicateToastCooldownSeconds;
  }
}
