import 'dart:async';
import 'dart:io';

import 'package:ai_dress_up/view/web_view_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/const.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/utils.dart';
import 'bottom_navigation_screen.dart';
import 'language_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool clickHandle = false;
  Timer? timer;
  Timer? _debounceTimer;

  void clickHandleTimer() {
    setState(() {
      clickHandle = true;
      //submitRating(context, iosAppId);
    });
    Future.delayed(const Duration(seconds: 1), () async {
      setState(() {
        clickHandle = false;
      });
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(eventName: 'SETTING_SCREEN');
    });
    super.initState();
  }

  void shareApp(String iosAppId) async {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(seconds: 1), () {});

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String packageName = packageInfo.packageName;

    String url;
    if (Platform.isIOS) {
      url = 'https://apps.apple.com/app/id$iosAppId';
    } else {
      url = 'https://play.google.com/store/apps/details?id=$packageName';
    }
    await SharePlus.instance.share(
      ShareParams(text: url, title: 'Check out this app'),
    );
  }

  Future<void> submitRating(BuildContext context, String id) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String packageName = packageInfo.packageName;
    print(packageName);
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final Uri url = Uri.parse('https://apps.apple.com/app/id$id');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch App Store.';
      }
    } else {
      final Uri url = Uri.parse('market://details?id=$packageName');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        final Uri webUrl = Uri.parse(
          'https://play.google.com/store/apps/details?id=$packageName',
        );
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl);
        } else {
          throw 'Could not launch Play Store.';
        }
      }
    }
  }

  void _navigateToHomeTab(BuildContext context) {
    BottomTabNotification().dispatch(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToHomeTab(context);
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xffF3F3F3),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xffF3F3F3),
          title: Row(
            children: [
              NewDeepPressUnpress(
                onTap: () {
                    Navigator.pop(context);
                },
                child: Image.asset('${defaultImagePath}back.png', width: 100.w),
              ),
              40.horizontalSpace,
              Expanded(
                child: Text(
                  getTranslated(context)!.setting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 70.sp),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 50.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                50.verticalSpace,

                NewDeepPressUnpress(
                  onTap: () async {
                    // final result = await Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const CreationScreen()),
                    // );
                    //
                    // if (result == true && mounted) {
                    //   _navigateToHomeTab(context);
                    // }
                  },
                  child: Container(
                    padding: EdgeInsets.only(left: 70.w, right: 50.w),
                    height: 750.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          '${defaultImagePath}setting_premium_button.png',
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(context)!.myCreation,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 70.sp,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          getTranslated(
                            context,
                          )!.youCanViewAllYourCreationsHere,
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                50.verticalSpace,
                SettingOptionTile(
                  onTap: () {
                    navigateTo(context, LanguageScreen(from: 'setting'));
                  },
                  text: getTranslated(context)!.chooseLanguage,
                  imagePath: '${defaultImagePath}setting_language.png',
                ),
                /*50.verticalSpace,
                Text(
                  getTranslated(context)!.customerService,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Gilroy',
                    fontSize: 55.sp,
                  ),
                ),
                50.verticalSpace,
                SettingOptionTile(
                  onTap: () {
                    if (!clickHandle) {
                      clickHandleTimer();
                      shareApp(iosAppId);
                    }
                  },
                  text: getTranslated(context)!.shareApp,
                  imagePath: '${defaultImagePath}setting_share_app.png',
                ),
                50.verticalSpace,
                SettingOptionTile(
                  onTap: () {
                    submitRating(context, iosAppId);
                  },
                  text: getTranslated(context)!.rateUs,
                  imagePath: '${defaultImagePath}setting_rate_us.png',
                ),*/
                50.verticalSpace,
                SettingOptionTile(
                  onTap: () {
                    navigateTo(
                      context,
                      WebViewScreen(
                        url: privacyPolicy,
                        title: getTranslated(context)!.privacyPolicy,
                        log: 'PRIVACY_POLICY',
                      ),
                    );
                  },
                  text: getTranslated(context)!.privacyPolicy,
                  imagePath: '${defaultImagePath}setting_privacy_policy.png',
                ),
                50.verticalSpace,
                /*SettingOptionTile(
                      onTap: () {},
                      text: getTranslated(context)!.gdpr,
                      imagePath: '${defaultImagePath}setting_gdpr.png',
                    ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingOptionTile extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final String imagePath;

  const SettingOptionTile({
    Key? key,
    required this.onTap,
    required this.text,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NewDeepPressUnpress(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 10.w,
          right: 60.w,
          top: 10.h,
          bottom: 10.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, height: 200.h),
            20.verticalSpace,
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 55.sp)),
            ),
            Image.asset('${defaultImagePath}next_arrow.png', height: 100.h),
          ],
        ),
      ),
    );
  }
}
