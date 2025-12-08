import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../l10n/app_localizations.dart';

AppLocalizations? getTranslated(BuildContext context) {
  return AppLocalizations.of(context);
}

void showLog(String msg) {
  if (kDebugMode) {
    print(msg);
  }
  log(msg);
}

void showToast(String msg) {
  Fluttertoast.showToast(msg: msg, gravity: ToastGravity.CENTER);
}

// void showSnackBar(BuildContext context, String message) {
//   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       backgroundColor: Colors.black,
//       content: CustomText(
//         label: message,
//         size: 36.sp,
//         color: Colors.white,
//         weight: FontWeight.w700,
//         family: 'medium',
//       )));
// }

void navigateTo(BuildContext context, Widget widget) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
}

void navigateToReplace(BuildContext context, Widget widget) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => widget),
  );
}

void navigateToAndRemoveUntil(BuildContext context, Widget widget) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => widget),
    (Route<dynamic> route) => false,
  );
}

class ConnectivityService {
  static Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}

double getWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double getHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

// Future<bool> isInternetConnected() {
//   return Connectivity().checkConnectivity().then((connectivityResult) {
//     return connectivityResult.contains(ConnectivityResult.none) ? false : true;
//   });
// }

// void showNoInternetDialog(Function onRetry, BuildContext context) {
//   showDialog(
//     barrierDismissible: false,
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//             backgroundColor: Colors.white,
//             content: Wrap(
//               children: [
//                 Column(
//                   children: [
//                     CustomText(
//                       label: getTranslated(context)?.noInternet ?? "Delete",
//                       size: 56.sp,
//                       color: Colors.black,
//                       weight: FontWeight.w700,
//                       family: 'bold',
//                       align: TextAlign.center,
//                       overflow: TextOverflow.visible,
//                     ),
//                     SizedBox(
//                       height: 20.h,
//                     ),
//                     CustomText(
//                       label: getTranslated(context)?.internetWarning ??
//                           "Are you sure?",
//                       size: 36.sp,
//                       maxLines: 2,
//                       color: const Color(0xFF696969),
//                       family: 'regular',
//                       weight: FontWeight.w700,
//                       align: TextAlign.center,
//                       overflow: TextOverflow.visible,
//                     ),
//                     SizedBox(
//                       height: 50.w,
//                     ),
//                     Consumer<MainApiProvider>(
//                         builder: (context, value, child) {
//                       return PressUnpress(
//                           height: 150.h,
//                           width: double.infinity,
//                           image: "dg_delete_btn_unpress.png",
//                           onTap: () {
//                             Navigator.pop(context);
//                             onRetry();
//                           },
//                           child: Center(
//                             child: CustomText(
//                                 label: getTranslated(context)?.retry ?? "Retry",
//                                 size: 56.sp,
//                                 color: Color(0xFF000000),
//                                 family: 'medium'),
//                           ));
//                     })
//                   ],
//                 ),
//               ],
//             ));
//       });
// }
