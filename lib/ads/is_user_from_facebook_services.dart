import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

import '../utils/firebase_analytics_service.dart';
import '../utils/global_variables.dart';
import '../utils/shared_preference_utils.dart';
import '../utils/utils.dart';

List<String> blockedCountries = GlobalVariables.blockedCountriesForFacebookContent;
const String installReferFromFaceBook = "fromFaceBook";
const String installReferFromUnity = "fromUnity";
const String installReferFromGoogleAd = "fromGoogleAd";

Future<void> getInstalledReferrer() async {
  // when submit
  // await SharedPreferenceUtils.setIsFacebookInstaller(true);
  // await SharedPreferenceUtils.setIsUnityInstaller(true);
  // await SharedPreferenceUtils.setIsGoogleAdInstaller(true);
  // return;
  // when submit
  bool? facebook = await SharedPreferenceUtils.getIsFacebookInstaller();
  bool? unity = await SharedPreferenceUtils.getIsUnityInstaller();
  bool? googleAds = await SharedPreferenceUtils.getIsGoogleAdInstaller();

  if (facebook == null || unity == null || googleAds == null) {
    switch (await checkInstallReferrer()) {
      case installReferFromFaceBook:
        await SharedPreferenceUtils.setIsFacebookInstaller(true);
        await SharedPreferenceUtils.setIsUnityInstaller(false);
        // await SharedPreferenceUtils.setIsGoogleAdInstaller(false);
        FirebaseAnalyticsService.logEvent(eventName: "USER");
      case installReferFromUnity:
        await SharedPreferenceUtils.setIsUnityInstaller(true);
        await SharedPreferenceUtils.setIsFacebookInstaller(false);
        // await SharedPreferenceUtils.setIsGoogleAdInstaller(false);
        FirebaseAnalyticsService.logEvent(eventName: "USER");
      case installReferFromGoogleAd:
        await SharedPreferenceUtils.setIsGoogleAdInstaller(true);
        await SharedPreferenceUtils.setIsUnityInstaller(false);
        await SharedPreferenceUtils.setIsFacebookInstaller(false);
        FirebaseAnalyticsService.logEvent(eventName: "USER");
    }
  }

  showLog("getInstalledReferrer2");


  if ((await SharedPreferenceUtils.getIsGoogleAdInstaller() ?? false) &&
      !(await SharedPreferenceUtils.getIsGoogleAdInstallChecked() ?? false)) {
    showLog("getInstalledReferrer3");
    await _checkDeepLink();
    showLog("getInstalledReferrer4");
    if (await SharedPreferenceUtils.getIsGoogleAdInstaller() ?? false) {
      String? countryCode = await getCountryFromNative();
      if (countryCode != null) {
        if (!blockedCountries.contains(countryCode)) {
          await SharedPreferenceUtils.setIsGoogleAdInstaller(true);
          await SharedPreferenceUtils.setIsUnityInstaller(false);
          await SharedPreferenceUtils.setIsFacebookInstaller(false);
          FirebaseAnalyticsService.logEvent(eventName: "USER");
          showLog('Google Ad install detected via deep linking');
        } else {
          await SharedPreferenceUtils.setIsGoogleAdInstaller(false);
          showLog('Google Ad install detected via deep linking but country is not in allowed list');
        }
      }
    }
    SharedPreferenceUtils.setIsGoogleAdInstallChecked(true);
  }

  showLog("getInstalledReferrer5");
}

Future<void> _checkDeepLink() async {
  try {
    final appLinks = AppLinks();
    final link = await appLinks.getLatestLinkString();
    showLog("🔗 Initial deep link: $link");

    if (link != null && (link.contains("aiphoto://promo.") || link.contains("flutterbranchsdk"))) {
      await SharedPreferenceUtils.setIsGoogleAdInstaller(true);
      await SharedPreferenceUtils.setIsUnityInstaller(false);
      await SharedPreferenceUtils.setIsFacebookInstaller(false);
      showLog("✅ Detected Google Ads install via deep link");
    }
  } catch (e) {
    showLog("❌ Deep link check failed: $e");
  }
}

Future<String> checkInstallReferrer() async {
  if (Platform.isAndroid) {
    try {
      final result = await PlayInstallReferrer.installReferrer;
      final referrer = result.installReferrer?.toLowerCase() ?? '';
      showLog('Install Referrer: $referrer');

      // Check if referrer is from Facebook
      if (GlobalVariables.fbAdUtm.any((item) => referrer.contains(item))) {
        // Now check the country
        final countryCode = await getCountryFromNative();
        showLog('User country code: $countryCode');
        if (countryCode != null && !blockedCountries.contains(countryCode.toUpperCase())) {
          showLog('Installed via Facebook AND from allowed country');
          return installReferFromFaceBook;
        } else {
          showLog('Facebook Ad install detected but country is not in allowed list');
        }
      } else if (referrer.contains('unity')) {
        showLog("Installed via Unity Ads");
        // Now check the country
        final countryCode = await getCountryFromNative();
        showLog('User country code: $countryCode');
        if (countryCode != null && !blockedCountries.contains(countryCode.toUpperCase())) {
          showLog('Installed via UNITY AND from allowed country');
          return installReferFromUnity;
        } else {
          showLog('UNITY Ad install detected but country is not in allowed list');
        }
      }
      else if (referrer.contains('utm_medium=organic')) {
        FirebaseAnalyticsService.logEvent(eventName: "ORGANIC");
      } else {
        for (var i in GlobalVariables.googleAdUtm) {
          if (referrer.contains(i)) {
            showLog("Installed via Google Ads");
            // Now check the country
            final countryCode = await getCountryFromNative();
            showLog('User country code: $countryCode');
            if (countryCode != null && !blockedCountries.contains(countryCode.toUpperCase())) {
              showLog('Installed via Google AND from allowed country');
              return installReferFromGoogleAd;
            } else {
              showLog('Google Ad install detected but country is not in allowed list');
            }
          }
        }
        showLog('No referrer found');
      }
    } catch (e) {
      showLog('Failed to get install referrer: $e');
    }
  }
  return "";
}

Future<String?> getCountryFromNative() async {
  const MethodChannel channel = MethodChannel('nativeChannel');
  try {
    final String? code = await channel.invokeMethod('getCountryCode');
    showLog("USER COUNTRY=> $code");
    return code;
  } on PlatformException catch (e) {
    showLog("Failed to get country code: '${e.message}'.");
    return null;
  }
}
