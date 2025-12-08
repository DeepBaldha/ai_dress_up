import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:ai_dress_up/ads/store_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/global_variables.dart';
import '../utils/shared_preference_utils.dart';
import '../utils/utils.dart';
import 'ads_load_util.dart';
import 'ads_variable.dart';
import 'const.dart';
import 'is_user_from_facebook_services.dart';

class AdsSplashUtils {
  late SharedPreferences prefs;

  getOnlineIds({
    required Function() preLoads,
    required Function() navigateScreen,
  }) async {
    log("In Get Ads");
    prefs = await SharedPreferences.getInstance();

    if (Platform.isAndroid) {
      await premiumInit();
    }
    configureSDK();

    /// IOS
    ///Assign Value From Stored Values
    AdsVariable.HVG_normal_openAd = prefs.getString("appOpenAd") ?? "11";
    AdsVariable.HVG_splash_interstitialAd =
        prefs.getString("splashInterstitialAd") ?? "11";
    AdsVariable.HVG_pre_interstitialAd =
        prefs.getString("preInterstitialAd") ?? "11";
    AdsVariable.HVG_language_nativeAd =
        prefs.getString("languageNativeAd") ?? "11";

    ///Clicks To Show Ads
    AdsVariable.click = prefs.getInt("click") ?? 2;

    AdsVariable.HVG_nativeBgColor =
        prefs.getString("nativeBgColor") ?? "F6F6F6";
    AdsVariable.HVG_headlineTxtColor =
        prefs.getString("headlineTxtColor") ?? "000000";
    AdsVariable.HVG_bodyTxtColor = prefs.getString("bodyTxtColor") ?? "000000";
    AdsVariable.HVG_buttonTextColor =
        prefs.getString("buttonTxtColor") ?? "FFFFFF";
    AdsVariable.HVG_buttonBgColor =
        prefs.getString("buttonBgColor") ?? "916AF4";

    AdsVariable.HVG_showOpenAdInSplash =
        prefs.getBool("showOpenAdInSplash") ?? false;

    if (await ConnectivityService.checkConnectivity()) {
      try {
        await Firebase.initializeApp().then((value) {
          showLog("Firebase Initialized");
        });
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: const Duration(minutes: 5),
          ),
        );

        await remoteConfig.fetchAndActivate();
        log("Map is ${remoteConfig.getValue("ai_dress_up_v1").asString()}");
        Map<String, dynamic> mapValues1 = jsonDecode(
          remoteConfig.getValue("ai_dress_up_v1").asString(),
        );
        log("map is $mapValues1");

        /// IOS Id setup from Firebase Remote Config
        /// Facebook id setup
        AdsVariable.HVG_facebookId = mapValues1["facebookId"].toString();
        AdsVariable.HVG_facebookToken = mapValues1["facebookToken"].toString();
        AdsVariable.HVG_normal_openAd = mapValues1["appOpenAd"].toString();
        AdsVariable.HVG_splash_interstitialAd =
            mapValues1["splashInterstitialAd"].toString();
        showLog(
          "Splash Interstitial Ad is ${AdsVariable.HVG_splash_interstitialAd}",
        );
        AdsVariable.HVG_pre_interstitialAd = mapValues1["preInterstitialAd"]
            .toString();

        AdsVariable.HVG_language_nativeAd = mapValues1["languageNativeAd"]
            .toString();

        AdsVariable.click = int.parse(mapValues1["click"].toString());

        AdsVariable.HVG_nativeBgColor = mapValues1["nativeBgColor"].toString();
        AdsVariable.HVG_headlineTxtColor = mapValues1["headlineTxtColor"]
            .toString();
        AdsVariable.HVG_bodyTxtColor = mapValues1["bodyTxtColor"].toString();
        AdsVariable.HVG_buttonBgColor = mapValues1["buttonBgColor"].toString();
        AdsVariable.HVG_buttonTextColor = mapValues1["buttonTxtColor"]
            .toString();
        AdsVariable.HVG_showOpenAdInSplash = mapValues1["showOpenAdInSplash"];
        GlobalVariables.showLanguageScreen = mapValues1["showLanguageScreen"];
        GlobalVariables.showIntroScreen = mapValues1["showIntroScreen"];
        GlobalVariables.showRateUsScreen = mapValues1["showRateUsScreen"];
        GlobalVariables.showChestFeature = mapValues1["showCheastOption"];
        GlobalVariables.showImageFeatures = mapValues1["showAllImageFeatures"];

        AdsVariable.HVG_intro_nativeAd = mapValues1["introNativeAd"];

        AdsVariable.selectedPlan = mapValues1['selectedPlan'];
        AdsVariable.selectedCreditPlan = mapValues1['selectedCreditPlan'];

        GlobalVariables.seaArtCookie = mapValues1['seaArtCookie'];
        GlobalVariables.polloCookie = mapValues1['polloCookie'];
        GlobalVariables.polloApiKey = mapValues1['polloApiKey'];
        GlobalVariables.pdfCoApiKey = mapValues1['pdfCoApiKey'];
        GlobalVariables.getImageCredit = mapValues1['imageGenerateCreditCut'];
        GlobalVariables.videoCredit = mapValues1['videoCreditCut'];
        GlobalVariables.freeCredits = mapValues1['freeCredit'];
        GlobalVariables.faceSwapperToken = mapValues1['faceSwapperToken'];
        GlobalVariables.fastFaceSwapKey = mapValues1['fastFaceSwapKey'];
        GlobalVariables.segmindAPIKey = mapValues1['segmindAPIKey'];

        GlobalVariables.firstPlanCredit = mapValues1['firstPlanCredit'];
        GlobalVariables.secondPlanCredit = mapValues1['secondPlanCredit'];
        GlobalVariables.thirdPlanCredit = mapValues1['thirdPlanCredit'];
        GlobalVariables.fourthPlanCredit = mapValues1['fourthPlanCredit'];
        GlobalVariables.fifthPlanCredit = mapValues1['fifthPlanCredit'];
        GlobalVariables.weeklyPlanBonusCredit =
            mapValues1['weeklyPlanBonusCredit'];
        GlobalVariables.yearlyPlanBonusCredit =
            mapValues1['yearlyPlanBonusCredit'];
        showLog(
          'Yearly credit is : ${GlobalVariables.yearlyPlanBonusCredit} weekly is : ${GlobalVariables.weeklyPlanBonusCredit}',
        );
        AdsVariable.showIMTester = mapValues1['isShowIAmTester'];

        GlobalVariables.blockedCountriesForFacebookContent = List<String>.from(
          mapValues1['blockedCountriesForFacebookContent'] ??
              ['US', 'CA', 'GB'],
        );

        GlobalVariables.fbAdUtm = List<String>.from(
          mapValues1['facebookAdUtms'] ??
              ['fbclid', 'facebook', 'meta', 'instagram'],
        );
        GlobalVariables.googleAdUtm = List<String>.from(
          mapValues1['googleAdUtms'] ?? ['cpc'],
        );

        showLog('Google UTMS are : ${GlobalVariables.googleAdUtm} and fb are :${GlobalVariables.fbAdUtm}');

        AdsVariable.testEmail = mapValues1['testerUserId'];

        AdsVariable.testPassword = mapValues1['testerPassword'];

        ///image JSON and base URL
        GlobalVariables.faceSwapJSONURL = mapValues1['imageDataUrl'];
        showLog('Image URL is : ${GlobalVariables.faceSwapJSONURL}');

        final Uri uri = Uri.parse(GlobalVariables.faceSwapJSONURL);
        GlobalVariables.faceSwapBaseURL = uri.resolve('.').toString();
        showLog('Image Base URL is : ${GlobalVariables.faceSwapBaseURL}');

        ///video play store JSON and base URL
        GlobalVariables.videoHomeURL = mapValues1['videoDataUrlPlayStore'];
        showLog(
          'Play store Video Data URL is : ${GlobalVariables.videoHomeURL}',
        );

        final Uri uriVideo = Uri.parse(GlobalVariables.videoHomeURL);
        GlobalVariables.videoHomeBaseURL = uriVideo.resolve('.').toString();
        showLog('Play store Base URL is : ${GlobalVariables.videoHomeBaseURL}');

        ///facebook video JSON and base URL
        GlobalVariables.videoListForFacebookAds =
            mapValues1['videoDataUrlFacebookAds'];
        showLog(
          'Facebook Video Data URL is : ${GlobalVariables.videoListForFacebookAds}',
        );

        final Uri uriVideoFacebook = Uri.parse(
          GlobalVariables.videoListForFacebookAds,
        );
        GlobalVariables.videoFacebookBaseURL = uriVideoFacebook
            .resolve('.')
            .toString();
        showLog(
          'Facebook Base URL is : ${GlobalVariables.videoFacebookBaseURL}',
        );

        ///carousel video JSON and base URL
        GlobalVariables.videoListTrendingURL =
            mapValues1['videoDataUrlTrending'];
        showLog(
          'Video Data URL is : ${GlobalVariables.videoListTrendingURL}',
        );

        final Uri uriVideoCarousel = Uri.parse(
          GlobalVariables.videoListTrendingURL,
        );
        GlobalVariables.videoListTrendingBaseURL = uriVideoCarousel
            .resolve('.')
            .toString();
        showLog(
          'Carousel Base URL is : ${GlobalVariables.videoListTrendingBaseURL}',
        );

        GlobalVariables.videoListForGoogleAds =
            mapValues1['videoDataUrlGoogleAds'];
        showLog(
          'Video Data URL for google Ads is : ${GlobalVariables.videoListForGoogleAds}',
        );
        final Uri uriVideoGoogleAds = Uri.parse(
          GlobalVariables.videoListForGoogleAds,
        );
        GlobalVariables.videoGoogleAdsBaseURL = uriVideoGoogleAds
            .resolve('.')
            .toString();
        showLog(
          'Google Ads Base URL is : ${GlobalVariables.videoGoogleAdsBaseURL}',
        );

        // TODO: when submit

        // await SharedPreferenceUtils.setIsFacebookInstaller(true);

        await getInstalledReferrer();

        bool isFacebookUser =
            await SharedPreferenceUtils.getIsFacebookInstaller() ?? false;
        bool isGoogleAdUser =
            await SharedPreferenceUtils.getIsGoogleAdInstaller() ?? false;
        bool isUnityUser =
            await SharedPreferenceUtils.getIsUnityInstaller() ?? false;

        showLog(
          'facebook : $isFacebookUser google : $isGoogleAdUser unity : $isUnityUser',
        );

        if (isFacebookUser) {
          showLog("User came from Facebook");
          AdsVariable.userFrom = 'facebook';
        } else if (isGoogleAdUser) {
          showLog("User came from Google Ads");
          AdsVariable.userFrom = 'google';
        } else if (isUnityUser) {
          showLog("User came from Unity");
          AdsVariable.userFrom = 'unity';
        } else {
          showLog("User came from other source");
          AdsVariable.userFrom = 'other';
        }

        /// Store firebase remote config data into shared preferences :
        ///

        prefs.setString(
          "nativeBgColor",
          mapValues1["nativeBgColor"].toString(),
        );
        prefs.setString(
          "buttonBgColor",
          mapValues1["buttonBgColor"].toString(),
        );
        prefs.setString(
          "buttonTxtColor",
          mapValues1["buttonTxtColor"].toString(),
        );
        prefs.setString(
          "headlineTxtColor",
          mapValues1["headlineTxtColor"].toString(),
        );
        prefs.setString("bodyTxtColor", mapValues1["bodyTxtColor"].toString());

        prefs.setString("facebookId", mapValues1["facebookId"].toString());
        prefs.setString(
          "facebookToken",
          mapValues1["facebookToken"].toString(),
        );

        prefs.setString("appOpenAd", mapValues1["appOpenAd"] ?? "11");
        prefs.setString(
          "splashInterstitialAd",
          mapValues1["splashInterstitialAd"] ?? "11",
        );
        prefs.setString(
          "preInterstitialAd",
          mapValues1["preInterstitialAd"] ?? "11",
        );
        prefs.setString("introBannerAd", mapValues1["introBannerAd"] ?? "11");
        prefs.setString("homeBannerAd", mapValues1["homeBannerAd"] ?? "11");

        prefs.setString(
          "previewBannerAd",
          mapValues1["previewBannerAd"] ?? "11",
        );
        prefs.setInt("click", mapValues1["click"] ?? 2);
        prefs.setBool(
          "showOpenAdInSplash",
          mapValues1["showOpenAdInSplash"] ?? false,
        );

        /// Facebook id setup
        setupFbAdsId();

        /// In app purchase
        // configureSDK();

        /// GDPR Consent form init
        await initializeGDPR();

        /// Check available purchases
        if (Platform.isIOS) {
          await fetchPurchase();
        }

        if (GlobalVariables.isPremiumUser) {
          Future.delayed(const Duration(seconds: 3), () {
            navigateScreen();
          });
          return;
        }

        ///LOAD AND SHOW OPEN OR SPLASH AD BASED ON CONDITION
        if (AdsVariable.HVG_showOpenAdInSplash) {
          AdsLoadUtil().loadAndShowOpenAd(
            navigateScreen,
            AdsVariable.HVG_normal_openAd,
            preLoads,
          );
        } else {
          AdsLoadUtil().loadInterSplash(
            preLoads,
            navigateScreen,
            AdsVariable.HVG_splash_interstitialAd,
          );
        }
      } on PlatformException catch (exception) {
        Future.delayed(Duration(seconds: 3), () {
          navigateScreen();
        });
        showLog("Exception is $exception");
      } catch (exception) {
        Future.delayed(Duration(seconds: 3), () {
          navigateScreen();
        });
        showLog("Exception is $exception");
      }
    } else {
      log("Not Connected");

      Future.delayed(Duration(seconds: 3), () {
        navigateScreen();
      });

      /// Facebook id setup
    }
  }

  fetchPurchase() async {
    try {
      if (Platform.isIOS) {
        final customerInfo = await Purchases.getCustomerInfo();
        if (customerInfo.entitlements.all[entitlementKey] != null &&
            customerInfo.entitlements.all[entitlementKey]!.isActive == true) {
          GlobalVariables.isPremiumUser = true;
          AdsVariable.resetAdIds();
        } else {
          GlobalVariables.isPremiumUser = false;
        }
      }
      if (GlobalVariables.isPremiumUser) {
        showLog("Purchase ----->${GlobalVariables.isPremiumUser}");
        AdsVariable.resetAdIds();
      }
    } catch (e) {
      showLog("PURCHASE_ERROR >> ${e.toString()}");
    }
  }
}

premiumInit() {
  if (Platform.isIOS || Platform.isMacOS) {
    StoreConfig(store: Store.appStore, apiKey: appleApiKey);
  } else if (Platform.isAndroid) {
    const useAmazon = bool.fromEnvironment("amazon");
    StoreConfig(
      store: useAmazon ? Store.amazon : Store.playStore,
      apiKey: useAmazon ? amazonApiKey : googleApiKey,
    );
  }
}

setupFbAdsId() async {
  log("Call 1");
  const platformMethodChannel = MethodChannel('nativeChannel');
  log("Call 2");
  if (Platform.isIOS) {
    platformMethodChannel.invokeMethod('setToast', {
      'isPurchase': GlobalVariables.isPremiumUser.toString(),
      'facebookId': AdsVariable.HVG_facebookId,
      'facebookToken': AdsVariable.HVG_facebookToken,
      'nativeBGColor': AdsVariable.HVG_nativeBgColor,
      'btnBgColor': AdsVariable.HVG_buttonBgColor,
      'btnTextColor': AdsVariable.HVG_buttonTextColor,
      'headerTextColor': AdsVariable.HVG_headlineTxtColor,
      'bodyTextColor': AdsVariable.HVG_bodyTxtColor,
    });
  } else {
    platformMethodChannel.invokeMethod('setToast', {
      'fb_appid': AdsVariable.HVG_facebookId,
      'fb_token': AdsVariable.HVG_facebookToken,
      'btnBgColorG1': "#${AdsVariable.HVG_buttonBgColor}",
      'btnBgColorG2': "#${AdsVariable.HVG_buttonBgColor}",
      'nativeBGColor': "#${AdsVariable.HVG_nativeBgColor}",
      'headerTextColor': "#${AdsVariable.HVG_headlineTxtColor}",
      'bodyTextColor': "#${AdsVariable.HVG_bodyTxtColor}",
      'btnTextColor': "#${AdsVariable.HVG_buttonTextColor}",
    });
  }
  log("Call 3");
}

Future<void> configureSDK() async {
  await Purchases.setLogLevel(LogLevel.debug);
  showLog('==========setLogLevel=============');
  PurchasesConfiguration configuration;
  if (StoreConfig.isForAmazonAppstore()) {
    configuration = AmazonConfiguration(StoreConfig.instance.apiKey);
  } else {
    configuration = PurchasesConfiguration(StoreConfig.instance.apiKey);
  }
  configuration.entitlementVerificationMode =
      EntitlementVerificationMode.informational;
  await Purchases.configure(configuration);
  await Purchases.enableAdServicesAttributionTokenCollection();

  AdsVariable.isConfigured = true;
}

/// GDPR Implementation methods : initializeGDPR, changePrivacyPreferences, loadConsentForm, initializeMobileAds
Future<FormError?> initializeGDPR() async {
  final completer = Completer<FormError?>();
  final params = ConsentRequestParameters(
    consentDebugSettings: ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
      testIdentifiers: [''],
    ),
  );
  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
    () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        await loadConsentForm();
      } else {
        await initializeMobileAds();
      }
      completer.complete();
    },
    (error) {
      completer.complete(error);
    },
  );
  return completer.future;
}

Future<bool> changePrivacyPreferences() async {
  final completer = Completer<bool>();

  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        ConsentForm.loadConsentForm(
          (consentForm) {
            consentForm.show((formError) async {
              await initializeMobileAds();
              completer.complete(true);
            });
          },
          (formError) {
            completer.complete(false);
          },
        );
      } else {
        completer.complete(false);
      }
    },
    (error) {
      completer.complete(false);
    },
  );

  return completer.future;
}

Future<FormError?> loadConsentForm() async {
  final completer = Completer<FormError?>();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  ConsentForm.loadConsentForm(
    (consentForm) async {
      final status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.required) {
        consentForm.show((formError) async {
          completer.complete(loadConsentForm());
          showLog("GDRP IF");
          await preferences.setString('keyvalue', "1");
          AdsVariable.dataGDPR = (preferences.getString('keyvalue'))!;
        });
      } else {
        showLog("GDRP else");
        await preferences.setString('keyvalue', "0");
        AdsVariable.dataGDPR = (preferences.getString('keyvalue'))!;
        await initializeMobileAds();
        completer.complete();
      }
    },
    (FormError? error) {
      completer.complete(error);
    },
  );

  return completer.future;
}

Future<void> initializeMobileAds() async {
  await MobileAds.instance.initialize();
}
