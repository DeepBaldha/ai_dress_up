import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ai_dress_up/utils/consts.dart';
import 'package:flutter/material.dart';

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
      barrierColor: Color(0xfff3f3f3),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 100.w),
                    child: Image.asset(
                      width: double.infinity,
                      '${defaultImagePath}loading_logo_image.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  150.verticalSpace,
                  SizedBox(
                    width: 380.w,
                    height: 380.w,
                    child: FittedBox(
                        fit: BoxFit.contain,
                      child: Image.asset('${defaultImagePath}round_gif.gif'),
                    ),
                  ),
                  100.verticalSpace,
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 60.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  30.verticalSpace,
                  if (secondMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 80.w),
                      child: Text(
                        secondMessage,
                        style: TextStyle(color: Colors.black, fontSize: 60.sp),
                        textAlign: TextAlign.center,
                      ),
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
