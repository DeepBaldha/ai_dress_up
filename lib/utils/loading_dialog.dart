import 'package:ai_dress_up/utils/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

/// A blocking loading dialog that prevents any user interaction.
/// Use [showBlockingLoader(context)] to display and [hideBlockingLoader(context)] to dismiss.
class LoadingDialog {
  static bool _isDialogVisible = false;

  static void show(
    BuildContext context, {
    String message = "Generating",
    String? secondMessage,
  }) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('${defaultImagePath}loader.json', width: 300.w),
                  50.horizontalSpace,
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 60.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  30.verticalSpace,
                  if (secondMessage != null)
                    Text(
                      secondMessage,
                      style: TextStyle(color: Colors.white, fontSize: 50.sp),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (_isDialogVisible) {
      _isDialogVisible = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
