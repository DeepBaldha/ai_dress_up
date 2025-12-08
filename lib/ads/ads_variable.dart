import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsVariable {

  static int click = 2;
  static String HVG_normal_openAd = "11";

  static String HVG_splash_interstitialAd = "11";
  static String HVG_pre_interstitialAd = "11";

  static String HVG_language_nativeAd = "11";
  static String HVG_intro_nativeAd = "11";

  static bool isPurchase = false;

  static String HVG_nativeBgColor = "090909";
  static String HVG_headlineTxtColor = "ffffff";
  static String HVG_bodyTxtColor = "ffffff";
  static String HVG_buttonBgColor = "ffffff";
  static String HVG_buttonTextColor = "000000";

  static String HVG_facebookId = "";
  static String HVG_facebookToken = "";

  static bool HVG_showOpenAdInSplash = false;
  static bool isConfigured = false;

  static String testEmail = 'user';
  static String testPassword = 'user';
  static bool showIMTester = false;

  static String userFrom = 'normal';

  ///This Variable is Used To Show And Hide GDPR Button in Setting Screen
  static String dataGDPR = "";


  // TODO: when submit
  static String selectedPlan = 'weeklysubscription';
  static String selectedCreditPlan = 'ai_appsforcoins_300';
  static int weeklyBonusCredit = 100;
  static int yearlyBonusCredit = 1000;

  static AppOpenAd? appOpenAd;
  static NativeAd? nativeAdLanguage;
  static NativeAd? nativeAdIntro;
  static bool isShowingAd = false;

  static int currentClick = 0;

  static void resetAdIds() {
    HVG_normal_openAd = "11";

    HVG_splash_interstitialAd = "11";
    HVG_pre_interstitialAd = "11";

    HVG_language_nativeAd = "11";

  }
}