import 'dart:async';

import 'package:ai_dress_up/view/bottom_navigation_screen.dart';
import 'package:ai_dress_up/view_model/image_data_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:no_screenshot/no_screenshot.dart';
import '../utils/consts.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/global_variables.dart';
import 'package:flutter/material.dart';
import '../ads/ads_splash_utils.dart';
import '../ads/ads_load_util.dart';
import '../ads/ads_variable.dart';
import '../utils/shared_preference_utils.dart';
import '../utils/utils.dart';
import '../view_model/credit_provider.dart';
import '../view_model/free_usage_provider.dart';
import '../view_model/image_result_provider.dart';
import '../view_model/video_data_provider.dart';
import '../view_model/video_result_provider.dart';
import 'intro_screen.dart';
import 'language_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _noScreenshot = NoScreenshot.instance;
  double progressValue = 0;
  bool trackingDialogOpen = false;
  bool isAdLoaded = false;

  void navigatingToNextActivity() async {
    await SharedPreferenceUtils.getFirstTime("firstTime").then((value) async {
      showLog("First time : $value");
      showLog(value.toString());
      // TODO: when submit
      if (value == true) {
        showLog('TRUE');
        await Future.delayed(const Duration(seconds: 2));
        if (GlobalVariables.showLanguageScreen) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LanguageScreen(from: 'SPLASH'),
            ),
          );
        } else {
          if (GlobalVariables.showIntroScreen) {
            navigateToReplace(context, const IntroScreen());
          } else if (GlobalVariables.showRateUsScreen) {
            navigateToReplace(context, const IntroScreen());
          } else {
            navigateToReplace(context, const BottomNavigationScreen());
          }
        }
        GlobalVariables.isFirstTime = true;

        await ref.read(creditProvider.notifier).reloadCredit();

        final credit = ref.watch(creditProvider);

        showLog('There is credit of user is : $credit');
        if (credit == 0) {
          showLog('need to add some credit');
          await ref
              .read(creditProvider.notifier)
              .addCredit(GlobalVariables.freeCredits);

          await ref.read(creditProvider.notifier).reloadCredit();
        }
      } else {
        GlobalVariables.isFirstTime = false;

        //TODO: when submit

        /*await ref
            .read(creditProvider.notifier)
            .addCredit(500);

        await ref.read(creditProvider.notifier).reloadCredit();*/

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BottomNavigationScreen(),
          ),
        );
      }
    });
  }

  void loadPreLoadAds() async {
    showLog("Call Method loadPreLoadAds");
    await SharedPreferenceUtils.getFirstTime("firstTime").then((onValue) async {
      showLog("AdsVariable.isFirstTime---->$onValue");
      if (onValue == true && GlobalVariables.showLanguageScreen) {
        AdsVariable.nativeAdLanguage = await AdsLoadUtil().loadNative(
          AdsVariable.HVG_language_nativeAd,
          false,
        );
        AdsVariable.nativeAdIntro = await AdsLoadUtil().loadIntroNative(
          AdsVariable.HVG_intro_nativeAd,
        );
        showLog(
          "AdsVariable.nativeAdLanguage --->${AdsVariable.nativeAdLanguage}",
        );
      } else {}
    });
  }

  void disableScreenshot() async {
    //TODO: when submit
    bool result = await _noScreenshot.screenshotOn();
    showLog('Screenshot Off: $result');
  }

  @override
  void initState() {
    super.initState();
    //TODO: when submit
    WidgetsBinding.instance.addPostFrameCallback((callback) async {
      FirebaseAnalyticsService.logEvent(eventName: 'SPLASH_SCREEN');
      disableScreenshot();
      await AdsSplashUtils().getOnlineIds(
        preLoads: () {
          loadPreLoadAds();
        },
        navigateScreen: () {
          navigatingToNextActivity();
        },
      );

      //TODO: when submit
      // await ref.read(creditProvider.notifier).setCredit(500);

      await ref.read(creditProvider.notifier).reloadCredit();

      showLog('user is from got ${AdsVariable.userFrom}');

      _loadAllBackgroundData();
      /*if (AdsVariable.userFrom.toLowerCase() == 'facebook') {
        Future.microtask(
          () => ref
              .read(videoDataProvider(VideoDataType.homeFacebook).notifier)
              .fetchVideoData(),
        );
        Future.microtask(
              () => ref
              .read(imageDataProvider(ImageDataType.facebookMenWomenImages).notifier)
              .fetchImageData(),
        );
        Future.microtask(
              () => ref
              .read(imageDataProvider(ImageDataType.playstoreCategoryImages).notifier)
              .fetchImageData(),
        );
      } else if (AdsVariable.userFrom == 'google') {
        Future.microtask(
          () => ref
              .read(videoDataProvider(VideoDataType.homeGoogle).notifier)
              .fetchVideoData(),
        );
        Future.microtask(
              () => ref
              .read(imageDataProvider(ImageDataType.googleMenWomenImages).notifier)
              .fetchImageData(),
        );
        Future.microtask(
              () => ref
              .read(imageDataProvider(ImageDataType.googleCategoryImages).notifier)
              .fetchImageData(),
        );
      } else if (AdsVariable.userFrom == 'other') {
        Future.microtask(
          () => ref
              .read(videoDataProvider(VideoDataType.homeNormal).notifier)
              .fetchVideoData(),
        );
        Future.microtask(
              () => ref
              .read(imageDataProvider(ImageDataType.playstoreMenWomenImages).notifier)
              .fetchImageData(),
        );
        Future.microtask(
              () => ref
              .read(imageDataProvider(ImageDataType.playstoreCategoryImages).notifier)
              .fetchImageData(),
        );
      }
      await ref.watch(imageResultProvider).loadImages();
      await ref.watch(videoResultProvider).loadVideos();
      await ref.read(freeVideoUsageProvider.notifier).refresh();*/
    });
  }

  void _loadAllBackgroundData() {
    unawaited(ref.read(imageResultProvider).loadImages());
    unawaited(ref.read(videoResultProvider).loadVideos());
    unawaited(ref.read(freeVideoUsageProvider.notifier).refresh());

    if (AdsVariable.userFrom.toLowerCase() == 'facebook') {
      unawaited(
        ref
            .read(videoDataProvider(VideoDataType.homeFacebook).notifier)
            .fetchVideoData(),
      );

      unawaited(
        ref
            .read(
              imageDataProvider(ImageDataType.facebookMenWomenImages).notifier,
            )
            .fetchImageData(),
      );

      unawaited(
        ref
            .read(
              imageDataProvider(ImageDataType.facebookCategoryImages).notifier,
            )
            .fetchImageData(),
      );
    }

    if (AdsVariable.userFrom == 'google') {
      unawaited(
        ref
            .read(videoDataProvider(VideoDataType.homeGoogle).notifier)
            .fetchVideoData(),
      );

      unawaited(
        ref
            .read(
              imageDataProvider(ImageDataType.googleMenWomenImages).notifier,
            )
            .fetchImageData(),
      );

      unawaited(
        ref
            .read(
              imageDataProvider(ImageDataType.googleCategoryImages).notifier,
            )
            .fetchImageData(),
      );
    }

    if (AdsVariable.userFrom == 'other') {
      unawaited(
        ref
            .read(videoDataProvider(VideoDataType.homeNormal).notifier)
            .fetchVideoData(),
      );

      unawaited(
        ref
            .read(
              imageDataProvider(ImageDataType.playstoreMenWomenImages).notifier,
            )
            .fetchImageData(),
      );

      unawaited(
        ref
            .read(
              imageDataProvider(ImageDataType.playstoreCategoryImages).notifier,
            )
            .fetchImageData(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Container(
          height: Get.height,
          width: Get.width,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('${defaultImagePath}splash_bg.png'),
            ),
          ),
          child: Column(
            children: [
              Spacer(),
              /*Center(
                child: Column(
                  children: [
                    Image.asset(
                      '${defaultImagePath}splash_logo.png',
                      height: 350.h,
                    ),
                    50.verticalSpace,
                    Image.asset('${defaultImagePath}VAIDEO.png', width: 450.w),
                  ],
                ),
              ),*/
              Spacer(),
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Lottie.asset(
                      height: 300.h,
                      '${defaultImagePath}loader.json',
                    ),
                    Text(
                      getTranslated(context)!.aiVideoAndClothChanger,
                      style: TextStyle(
                        fontSize: 60.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
