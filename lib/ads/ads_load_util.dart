import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../utils/custom_widgets/loading_screen.dart';
import '../utils/custom_widgets/shimmer_widget.dart';
import '../utils/global_variables.dart';
import '../utils/utils.dart';
import 'ads_variable.dart';

class AdsLoadUtil extends GetxController {
  late SharedPreferences prefs;
  // late AppLifecycleReactor appLifecycleReactor;

  ///-----------_FOR BANNER AD IMPLEMENTATION ------------------------------------
  ///REFER: FILE NAMED: ads_banner_utils.dart or intro screen

  /*loadAppOpenAd() async {
    showLog("Load from BG...");
    AppOpenAdManager appOpenAdManager = AppOpenAdManager()
      ..loadAd(AdsVariable.HVG_normal_openAd);
    appLifecycleReactor = AppLifecycleReactor(
      appOpenAdManager: appOpenAdManager,
    );
    AppLifecycleReactor(appOpenAdManager: appOpenAdManager)
        .listenToAppStateChanges();
  }*/

  ///---------- load and show open ad in splash
  void loadAndShowOpenAd(
    Function onDismissed,
    String adId,
    Function loadPreLoadAds,
  ) {
    AppOpenAd.load(
      adUnitId: adId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) async {
          await loadPreLoadAds();
          showLog(
            "Ad Loaded:=====================================================================",
          );
          ad.show();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              showLog('Ad showed full screen content');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              showLog('$ad onAdFailedToShowFullScreenContent=======:- $error');

              Future.delayed(const Duration(seconds: 3), () {
                //Navigator.of(context).pop();
                onDismissed();
              });
            },
            onAdDismissedFullScreenContent: (ad) {
              onDismissed();

              ///CHANGES TO LOAD PRE LOAD AFTER SPLASH DISMISSED
              //TODO: CHANGES
              AdsLoadUtil.loadPreInterstitialAd(
                adId: AdsVariable.HVG_pre_interstitialAd,
              );
              showLog('$ad onAdDismissedFullScreenContent========:-');
            },
          );
        },
        onAdFailedToLoad: (error) {
          Future.delayed(const Duration(seconds: 3), () {
            onDismissed();
          });
          showLog(
            "Ad Not Loaded:=====================================================================",
          );
          showLog(error.toString());
        },
      ),
    );
  }

  /// ------- Load Common Inter (Mine) -----------------------------
  static InterstitialAd? _interstitialAd;
  static String interstitialId = "";
  static bool isAdLoaded = false;

  static loadPreInterstitialAd({required String adId}) {
    interstitialId = adId;
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
    }
    InterstitialAd.load(
      adUnitId: adId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          isAdLoaded = true;
          showLog("Pre Inter Loaded");
        },
        onAdFailedToLoad: (error) {
          isAdLoaded = false;
          showLog("Pre Inter Failed $error");
        },
      ),
    );
  }

  static void showInterstitial({required Function onDismissed}) {
    if (GlobalVariables.isPremiumUser) {
      onDismissed();
      return;
    }
    if (isAdLoaded && _interstitialAd != null) {
      showLog("IT IS PRE LOADED");
      AdsVariable.isShowingAd = true;

      loadingScreen.show();
      // Delay showing the ad for 1500 milliseconds
      Future.delayed(const Duration(milliseconds: 500), () {
        // Close the loading dialog
        // Show the ad
        _interstitialAd!.show();
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
          loadingScreen.hide();
        });

        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdImpression: (ad) {
            showLog("onAdImpression---> true");
            Future.delayed(const Duration(milliseconds: 500), () {
              onDismissed();
            });
          },
          onAdDismissedFullScreenContent: (ad) {
            AdsVariable.isShowingAd = false;

            showLog("onAdDismissedFullScreenContent---> true");

            ad.dispose();
            _interstitialAd!.dispose().then(
              (value) => loadPreInterstitialAd(adId: interstitialId),
            );
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            AdsVariable.isShowingAd = false;

            showLog("onAdFailedToShowFullScreenContent---> Error $error");
            ad.dispose();
            _interstitialAd!.dispose().then(
              (value) => loadPreInterstitialAd(adId: interstitialId),
            );
            onDismissed();
          },
        );
      });
    } else {
      loadAndShow(
        adId: AdsVariable.HVG_pre_interstitialAd,
        onDismissed: onDismissed,
      );
    }
  }

  /// ------ Splash screen inter load & show --------------------------------------------
  InterstitialAd? splashInterAd;

  static void onShowAds(BuildContext context, Function onComplete) {
    if (GlobalVariables.isPremiumUser) {
      onComplete();
      return;
    } else {
      if (AdsVariable.currentClick % AdsVariable.click == 0 &&
          AdsVariable.HVG_pre_interstitialAd != '11') {
        AdsLoadUtil.showInterstitial(
          onDismissed: () {
            onComplete();
          },
        );
      } else {
        onComplete();
      }
    }
    AdsVariable.currentClick++;
  }

  loadInterSplash(
    Function() loadPreLoadAds,
    Function() navigateScreen,
    String adUnitId,
  ) async {
    prefs = await SharedPreferences.getInstance();
    showLog('>> SHOW INTER CALL <<');
    showLog('>> SHOW INTER CALL <<');
    showLog(
      'AdsVariable.appOpenSplashIOS >>${AdsVariable.HVG_splash_interstitialAd}',
    );

    if (!GlobalVariables.isPremiumUser) {
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) async {
            showLog("AD LOADED");

            splashInterAd = ad;
            splashInterAd!.show();

            ///CHANGES IT FROM onAdShowedFullScreenContent To onAdLoaded
            //TODO: CHANGES
            await loadPreLoadAds();

            ad.fullScreenContentCallback = FullScreenContentCallback(
              // Called when the ad showed the full screen content.
              onAdShowedFullScreenContent: (ad) async {
                showLog("onAdShowedFullScreenContent loadInterSplash");
                showLog("onAdShowedFullScreenContent loadInterSplash");
              },
              // Called when an impression occurs on the ad.
              onAdImpression: (ad) async {
                showLog("onAdImpression loadInterSplash");
                showLog("onAdImpression loadInterSplash");
                Future.delayed(const Duration(milliseconds: 500)).then((value) {
                  navigateScreen();
                });
              },

              // Called when the ad failed to show full screen content.
              //
              onAdFailedToShowFullScreenContent: (ad, err) async {
                // Dispose the ad here to free resources.
                ad.dispose();
                await loadPreLoadAds();
                showLog("onAdFailedToShowFullScreenContent loadInterSplash");
                showLog("onAdFailedToShowFullScreenContent loadInterSplash");
              },
              // Called when the ad dismissed full screen content.
              onAdDismissedFullScreenContent: (ad) async {
                // Dispose the ad here to free resources.

                ///CHANGES TO LOAD PRE LOAD AFTER SPLASH DISMISSED
                //TODO: CHANGES
                //AdsLoadUtil.loadPreInterstitialAd(adId: AdsVariable.HVG_pre_interstitialAd);
                ad.dispose();
                showLog("onAdDismissedFullScreenContent loadInterSplash");
              },
              // Called when a click is recorded for an ad.
              onAdClicked: (ad) {
                showLog("onAdClicked loadInterSplash");
              },
            );

            showLog('$ad loaded.loadInterSplash ');
            // Keep a reference to the ad so you can show it later.
          },

          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) async {
            showLog('InterstitialAd failed to load loadInterSplash: $error');
            showLog('InterstitialAd failed to load loadInterSplash: $error');
            await loadPreLoadAds();
            navigateScreen();
          },
        ),
      );
    }
  }

  static void loadAndShow({
    required String adId,
    required Function onDismissed,
  }) {
    showLog("IT IS LOAD AND SHOW");
    isAdLoaded = false;
    AdsVariable.isShowingAd = true;
    loadingScreen.show();

    if (_interstitialAd != null) {
      showInterstitial(onDismissed: onDismissed);
    } else {
      interstitialId = adId;
      if (_interstitialAd != null) {
        _interstitialAd!.dispose();
      }
      InterstitialAd.load(
        adUnitId: adId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialAd!.show();
            Future.delayed(const Duration(milliseconds: 500)).then((value) {
              loadingScreen.hide();
            });

            _interstitialAd!
                .fullScreenContentCallback = FullScreenContentCallback(
              onAdImpression: (ad) {
                Future.delayed(Duration(seconds: 1), () {
                  onDismissed();
                });
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                AdsVariable.isShowingAd = false;

                showLog("Ad Reloaded");
                loadPreInterstitialAd(adId: AdsVariable.HVG_pre_interstitialAd);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                AdsVariable.isShowingAd = false;

                showLog("Ad Reloaded");
                loadPreInterstitialAd(adId: AdsVariable.HVG_pre_interstitialAd);
                onDismissed();
              },
            );
          },
          onAdFailedToLoad: (error) {
            loadingScreen.hide();
            onDismissed();
          },
        ),
      );
    }
  }

  /// --------------------- Native ads load ------------------------------
  ///
  /// FOR OTHER ADS TAKE STATIC VARIABLES AS MUCH AS YOU WANT TO SHOW ADS
  /// EXAMPLE:
  /// static NativeAd? homeNativeAd (Declare it in AdsVariable File (Recommended))
  /// now wherever I want to preload this homeNativeAd
  /// I will pass
  /// AdsVariable.homeNativeAd = await AdsLoadUtil().loadNative(AdsVariable.HVG_home_nativeAd, false);
  /// --------------------- Native ads load ------------------------------
  static NativeAd? nativeAd;
  static RxBool isNativeAdLoaded = false.obs;
  static RxBool isNativeAdFailed = false.obs;

  Future<NativeAd> loadNative(String adUnitId, bool isSmallNative) async {
    showLog("isSmallNative--->$isSmallNative");
    isNativeAdLoaded.value = false;
    nativeAd = NativeAd(
      adUnitId: adUnitId.toString(),
      factoryId: isSmallNative ? 'smallNativeAds' : 'bigNativeAds',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          nativeAd = ad as NativeAd?;
          isNativeAdLoaded.value = true;
          showLog('isLoaded loadNative');
        },
        onAdFailedToLoad: (ad, error) {
          showLog('onAdFailedToLoad loadNative');
          nativeAd!.dispose();
          isNativeAdLoaded.value = false;
          isNativeAdFailed.value = true;
        },
      ),
      request: const AdRequest(),
    );
    await nativeAd!.load();
    return nativeAd!;
  }

  static NativeAd? introNativeAd;
  static RxBool isIntroNativeAdLoaded = false.obs;
  static RxBool isIntroNativeAdFailed = false.obs;

  Future<NativeAd> loadIntroNative(String adUnitId) async {
    showLog('Full native');
    isIntroNativeAdLoaded.value = false;
    introNativeAd = NativeAd(
      adUnitId: adUnitId.toString(),
      factoryId: 'full',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          introNativeAd = ad as NativeAd?;
          isIntroNativeAdLoaded.value = true;
          showLog('isLoaded loadNative');
        },
        onAdFailedToLoad: (ad, error) {
          showLog('onAdFailedToLoad loadNative');
          introNativeAd!.dispose();
          isIntroNativeAdLoaded.value = false;
          isIntroNativeAdFailed.value = true;
        },
      ),
      request: const AdRequest(),
    );
    await introNativeAd!.load();
    return introNativeAd!;
  }
}

/// Native ads
class NativeAdsWidget extends StatefulWidget {
  final bool isSmallNative;
  final NativeAd? showNativeAd;

  const NativeAdsWidget({
    super.key,
    required this.showNativeAd,
    required this.isSmallNative,
  });

  @override
  State<NativeAdsWidget> createState() => _NativeAdsWidgetState();
}

/// Native ads
class _NativeAdsWidgetState extends State<NativeAdsWidget> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   showLog("AdsLoadUtil.isNativeAdLoaded--->${AdsLoadUtil.isNativeAdLoaded}");
    //   showLog("AdsLoadUtil.nativeAd------->${AdsLoadUtil.nativeAd}");
    //   if (widget.showNativeAd != null) {
    //     setState(() {
    //       //   showNativeAd = AdsLoadUtil.nativeAd;
    //     });
    //     showLog("AdsLoadUtil.nativeAd!.value if ------->${widget.showNativeAd}");
    //   } else {
    //     showLog("AdsLoadUtil.nativeAd!.value else------>");
    //   }
    // });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    showLog("CHECK NULL >> ${AdsLoadUtil.isNativeAdLoaded.value}");
    return Obx(
      () => AdsLoadUtil.isNativeAdLoaded.value && widget.showNativeAd != null
          ? StatefulBuilder(
              builder: (context, setState) {
                return SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.w),
                      color: HexColor(AdsVariable.HVG_nativeBgColor),
                    ),
                    padding: EdgeInsets.only(bottom: 10.w, top: 0.w),
                    width: 1080.w,
                    height: widget.isSmallNative ? 150 : 300,
                    child: AdWidget(ad: widget.showNativeAd!),
                  ),
                );
              },
            )
          : getShimmerWidget(),
    );
  }

  Widget getShimmerWidget() {
    if (AdsLoadUtil.isNativeAdFailed.value) {
      return Container(height: 0);
    } else {
      return widget.isSmallNative
          ? const ShimmerSmallNative()
          : const ShimmerBigNative();
    }
  }
}

///Full native ad class Deep Baldha

class FullScreenNativeAdsWidget extends StatefulWidget {
  final NativeAd? showNativeAd;
  final VoidCallback? onClose;

  const FullScreenNativeAdsWidget({
    super.key,
    required this.showNativeAd,
    this.onClose,
  });

  @override
  State<FullScreenNativeAdsWidget> createState() =>
      _FullScreenNativeAdsWidgetState();
}

class _FullScreenNativeAdsWidgetState extends State<FullScreenNativeAdsWidget> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    showLog("CHECK NULL >> ${AdsLoadUtil.isIntroNativeAdLoaded.value}");
    return Obx(
      () =>
          AdsLoadUtil.isIntroNativeAdLoaded.value && widget.showNativeAd != null
          ? StatefulBuilder(
              builder: (context, setState) {
                return SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.w),
                      color: HexColor(AdsVariable.HVG_nativeBgColor),
                    ),
                    padding: EdgeInsets.only(bottom: 10.w, top: 0.w),
                    margin: EdgeInsets.only(top: 5.h),
                    width: getWidth(context),
                    height: getHeight(context),
                    child: AdWidget(ad: widget.showNativeAd!),
                  ),
                );
              },
            )
          : getShimmerWidget(),
    );
  }

  Widget getShimmerWidget() {
    if (AdsLoadUtil.isIntroNativeAdLoaded.value) {
      return Container(height: 0);
    } else {
      return const Center(child: ShimmerFullScreenNative());
    }
  }
}

// Shimmer widget for loading state
class ShimmerFullScreenNative extends StatelessWidget {
  const ShimmerFullScreenNative({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[500]!,
      highlightColor: Colors.grey[300]!,
      child: Container(
        height: getHeight(context),
        decoration: BoxDecoration(
          color: Colors.white38,
          borderRadius: BorderRadius.circular(15),
        ),
        width: Get.width,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Expanded(flex: 5, child: SizedBox()),
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 400.w,
                            height: 400.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: Get.width * 0.4,
                                height: 120.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: Get.width * 0.6,
                                height: 120.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: Get.width * 0.6,
                                height: 120.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 100.w),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: Get.width * 0.9,
                        height: 400.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.w),
                  ],
                ),
              ),
            ),
            const Expanded(flex: 5, child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
