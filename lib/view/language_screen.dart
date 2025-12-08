import 'dart:async';
import 'package:ai_dress_up/utils/custom_widgets/my_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../ads/ads_load_util.dart';
import '../ads/ads_variable.dart';
import '../main.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/global_variables.dart';
import '../utils/shared_preference_utils.dart';
import '../utils/utils.dart';
import '../view_model/premium_provider.dart';
import 'bottom_navigation_screen.dart';
import 'intro_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.from});
  final String from;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English (Default)';
  String _selectedLocaleCode = 'en';

  @override
  void initState() {
    super.initState();
    _initLanguageSettings();
    _loadNativeAd();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(
        eventName: 'LANGUAGE_SCREEN_${widget.from}'.toUpperCase(),
      );
    });
  }

  Future<void> _initLanguageSettings() async {
    await _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    String? savedLocale = await SharedPreferenceUtils.getString("locale");
    if (kDebugMode) {
      showLog(
        "LanguageScreen: _loadSavedLocale - Saved locale from prefs: $savedLocale",
      );
    }

    if (savedLocale != null && savedLocale.isNotEmpty) {
      setState(() {
        _selectedLocaleCode = savedLocale;
      });
      _updateSelectedLanguageFromLocale(savedLocale);
    } else {
      showLog(
        "LanguageScreen: _loadSavedLocale - No saved locale found, defaulting to English",
      );
      _updateSelectedLanguageFromLocale('en');
    }
  }

  void _updateSelectedLanguageFromLocale(String localeCode) {
    showLog(
      "LanguageScreen: _updateSelectedLanguageFromLocale - Called with locale: $localeCode",
    );
    try {
      final language = languagesList.firstWhere(
        (lang) => lang.languageCode == localeCode,
        orElse: () {
          showLog(
            "LanguageScreen: _updateSelectedLanguageFromLocale - Locale '$localeCode' not found in languagesList, defaulting to English",
          );
          return languagesList.firstWhere((lang) => lang.languageCode == 'en');
        },
      );

      setState(() {
        _selectedLanguage = language.language;
        _selectedLocaleCode = language.languageCode;
        GlobalVariables.languageCode = language.languageCode;
        showLog(
          "LanguageScreen: _updateSelectedLanguageFromLocale - Updated selectedLanguage to: $_selectedLanguage, selectedLocaleCode to: $_selectedLocaleCode",
        );
      });
    } catch (e) {
      showLog("LanguageScreen: _updateSelectedLanguageFromLocale - Error: $e");
    }
  }

  void _loadNativeAd() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (AdsVariable.nativeAdLanguage == null) {
        showLog(
          "LanguageScreen: Native Ad: ${AdsVariable.HVG_language_nativeAd}",
        );
        AdsVariable.nativeAdLanguage = await AdsLoadUtil().loadNative(
          AdsVariable.HVG_language_nativeAd,
          false,
        );
        setState(() {}); // Rebuild to show the ad if loaded
      } else {
        showLog("LanguageScreen: Native Ad already loaded.");
      }
    });
  }

  @override
  void dispose() {
    if (AdsVariable.nativeAdLanguage != null) {
      AdsVariable.nativeAdLanguage!.dispose();
      AdsVariable.nativeAdLanguage = null;
    }
    AdsLoadUtil.isNativeAdLoaded.value = false;
    showLog("LanguageScreen: dispose - Native ad disposed.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent popping without explicit action
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          height: getHeight(context),
          width: getWidth(context),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                '${defaultImagePath}screen_background_image.png',
              ),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 50.w),
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.from == 'setting') ...[
                            NewDeepPressUnpress(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Image.asset(
                                '${defaultImagePath}back.png',
                                width: 100.w,
                              ),
                            ),
                            20.horizontalSpace,
                          ],
                          Expanded(
                            child: Text(
                              getTranslated(context)!.selectALanguage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 65.sp),
                            ),
                          ),
                          NewDeepPressUnpress(
                            onTap: () async {
                              MyApp.setLocale(
                                context,
                                Locale(_selectedLocaleCode),
                              );
                              GlobalVariables.languageCode =
                                  _selectedLocaleCode;

                              await SharedPreferenceUtils.saveString(
                                "locale",
                                _selectedLocaleCode,
                              );
                              if (widget.from == 'setting') {
                                Navigator.pop(context);
                              } else {
                                if (GlobalVariables.showIntroScreen) {
                                  navigateToReplace(
                                    context,
                                    const IntroScreen(),
                                  );
                                } else if (GlobalVariables.showRateUsScreen) {
                                  navigateToReplace(
                                    context,
                                    const IntroScreen(),
                                  );
                                } else {
                                  navigateToReplace(
                                    context,
                                    const BottomNavigationScreen(),
                                  );
                                }
                              }
                            },
                            child: Icon(Icons.done, color: Colors.white),
                            /*child: Image.asset(
                    height: 70.h,
                    '${defaultImagePath}language_done.png',
                  ),*/
                          ),
                        ],
                      ),
                      50.verticalSpace,
                      Expanded(
                        child: ListView.builder(
                          itemCount: languagesList.length,
                          itemBuilder: (context, index) {
                            final language = languagesList[index];
                            final isSelected =
                                language.languageCode == _selectedLocaleCode;
                            return NewDeepPressUnpress(
                              onTap: () {
                                showLog(
                                  "LanguageScreen: Language tapped: ${language.language}, localeCode: ${language.languageCode}",
                                );
                                setState(() {
                                  _selectedLanguage = language.language;
                                  _selectedLocaleCode = language.languageCode;
                                  GlobalVariables.languageCode =
                                      language.languageCode;
                                  showLog(
                                    "LanguageScreen: Updated state - selectedLanguage: $_selectedLanguage, selectedLocaleCode: $_selectedLocaleCode",
                                  );
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 40.h),
                                height: 200.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.r),
                                  image: DecorationImage(
                                    image: AssetImage(
                                      isSelected
                                          ? '${defaultImagePath}language_selected.png'
                                          : '${defaultImagePath}language_unselect.png',
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(30.h),
                                      child: Image.asset(language.flagImage),
                                    ),
                                    10.horizontalSpace,
                                    SizedBox(
                                      width: getWidth(context) * 0.6,
                                      child: Text(
                                        language.language,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 55.sp,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      250.verticalSpace,
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30.h,
                  right: 0,
                  left: 0,
                  child: MyButton(
                    onTap: () async {
                      MyApp.setLocale(context, Locale(_selectedLocaleCode));
                      GlobalVariables.languageCode = _selectedLocaleCode;

                      await SharedPreferenceUtils.saveString(
                        "locale",
                        _selectedLocaleCode,
                      );
                      if (widget.from == 'setting') {
                        Navigator.pop(context);
                      } else {
                        if (GlobalVariables.showIntroScreen) {
                          navigateToReplace(context, const IntroScreen());
                        } else if (GlobalVariables.showRateUsScreen) {
                          navigateToReplace(context, const IntroScreen());
                        } else {
                          navigateToReplace(
                            context,
                            const BottomNavigationScreen(),
                          );
                        }
                      }
                    },
                    text: getTranslated(context)!.continues,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: (AdsVariable.HVG_language_nativeAd != "11")
            ? Consumer(
                builder: (context, ref, child) {
                  final isPurchased = ref.watch(premiumProvider);
                  return isPurchased
                      ? const SizedBox(height: 0)
                      : ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: NativeAdsWidget(
                            showNativeAd: AdsVariable.nativeAdLanguage,
                            isSmallNative: false,
                          ),
                        );
                },
              )
            : const SizedBox(height: 0),
      ),
    );
  }
}
