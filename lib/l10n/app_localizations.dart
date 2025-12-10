import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @continues.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continues;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @applyOutfit.
  ///
  /// In en, this message translates to:
  /// **'Apply Outfit'**
  String get applyOutfit;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'processing'**
  String get processing;

  /// No description provided for @chooseYourPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose your photo'**
  String get chooseYourPhoto;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate US'**
  String get rateUs;

  /// No description provided for @aiDress.
  ///
  /// In en, this message translates to:
  /// **'AI Dress'**
  String get aiDress;

  /// No description provided for @chooseALanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get chooseALanguage;

  /// No description provided for @selectALanguage.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get selectALanguage;

  /// No description provided for @clothsChanger.
  ///
  /// In en, this message translates to:
  /// **'Cloths changer'**
  String get clothsChanger;

  /// No description provided for @downloadImage.
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get downloadImage;

  /// No description provided for @imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Image preview'**
  String get imagePreview;

  /// No description provided for @deleteVideo.
  ///
  /// In en, this message translates to:
  /// **'Delete Video?'**
  String get deleteVideo;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image?'**
  String get deleteImage;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @newWord.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newWord;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @getCredit.
  ///
  /// In en, this message translates to:
  /// **'Get Credit'**
  String get getCredit;

  /// No description provided for @getMoreCredits.
  ///
  /// In en, this message translates to:
  /// **'Get More Credits'**
  String get getMoreCredits;

  /// No description provided for @getCredits.
  ///
  /// In en, this message translates to:
  /// **'Get Credits'**
  String get getCredits;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful'**
  String get purchaseSuccessful;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @forYear.
  ///
  /// In en, this message translates to:
  /// **'For Year'**
  String get forYear;

  /// No description provided for @forWeek.
  ///
  /// In en, this message translates to:
  /// **'For Week'**
  String get forWeek;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @creditAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Credit Added Successfully'**
  String get creditAddedSuccessfully;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @tryNow.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get tryNow;

  /// No description provided for @aiDressUp.
  ///
  /// In en, this message translates to:
  /// **'AI Dress up'**
  String get aiDressUp;

  /// No description provided for @getThePerfectLookInstantly.
  ///
  /// In en, this message translates to:
  /// **'Get the Perfect Look Instantly'**
  String get getThePerfectLookInstantly;

  /// No description provided for @aiOutfitChanger.
  ///
  /// In en, this message translates to:
  /// **'AI Outfit Changer'**
  String get aiOutfitChanger;

  /// No description provided for @beginYourImageAndVideoMagicToday.
  ///
  /// In en, this message translates to:
  /// **'Begin your image and video magic today.'**
  String get beginYourImageAndVideoMagicToday;

  /// No description provided for @thereIsNoItemHere.
  ///
  /// In en, this message translates to:
  /// **'There are no items here!'**
  String get thereIsNoItemHere;

  /// No description provided for @noImagesHereYet.
  ///
  /// In en, this message translates to:
  /// **'No images here yet.'**
  String get noImagesHereYet;

  /// No description provided for @noVideosHereYet.
  ///
  /// In en, this message translates to:
  /// **'No videos here yet.'**
  String get noVideosHereYet;

  /// No description provided for @generateYourAmazingVideosAndImages.
  ///
  /// In en, this message translates to:
  /// **'Generate your amazing videos and images.'**
  String get generateYourAmazingVideosAndImages;

  /// No description provided for @supportOurProgressWithAFiveStarReviewThankYou.
  ///
  /// In en, this message translates to:
  /// **'Support our progress with a 5-star review, Thank you.'**
  String get supportOurProgressWithAFiveStarReviewThankYou;

  /// No description provided for @helpUsToGrow.
  ///
  /// In en, this message translates to:
  /// **'Help us to grow'**
  String get helpUsToGrow;

  /// No description provided for @shareYourFeedbackToHelpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Share Your Feedback to Help us Improve'**
  String get shareYourFeedbackToHelpUsImprove;

  /// No description provided for @yourRatingsHelpUsGrowAndImproveShareYourFeedbackToHelpUsServeYouBetter.
  ///
  /// In en, this message translates to:
  /// **'Your ratings help us grow and improve!\nShare your feedback to help us serve you better.'**
  String
  get yourRatingsHelpUsGrowAndImproveShareYourFeedbackToHelpUsServeYouBetter;

  /// No description provided for @turningPhotosIntoVideoCreations.
  ///
  /// In en, this message translates to:
  /// **'Turning Photos Into Video Creations'**
  String get turningPhotosIntoVideoCreations;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @someThingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get someThingWentWrong;

  /// No description provided for @seAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seAll;

  /// No description provided for @generateVideo.
  ///
  /// In en, this message translates to:
  /// **'Generate video'**
  String get generateVideo;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @womanDress.
  ///
  /// In en, this message translates to:
  /// **'Woman Dress'**
  String get womanDress;

  /// No description provided for @manFashion.
  ///
  /// In en, this message translates to:
  /// **'Man Fashion'**
  String get manFashion;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @videoGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Video Generated Successfully'**
  String get videoGeneratedSuccessfully;

  /// No description provided for @pendingVideoGeneration.
  ///
  /// In en, this message translates to:
  /// **'Pending video generation'**
  String get pendingVideoGeneration;

  /// No description provided for @youCanSeeProcessInHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'You can see process in home screen'**
  String get youCanSeeProcessInHomeScreen;

  /// No description provided for @cancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel Task?'**
  String get cancelTask;

  /// No description provided for @cancelTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this video generation?'**
  String get cancelTaskMessage;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @videoGeneratedSuccessfullyAndMovedToCreation.
  ///
  /// In en, this message translates to:
  /// **'Video generated successfully and moved to creation'**
  String get videoGeneratedSuccessfullyAndMovedToCreation;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @videoReady.
  ///
  /// In en, this message translates to:
  /// **'Video Ready'**
  String get videoReady;

  /// No description provided for @creation.
  ///
  /// In en, this message translates to:
  /// **'Creation'**
  String get creation;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @aiVideo.
  ///
  /// In en, this message translates to:
  /// **'AI Video'**
  String get aiVideo;

  /// No description provided for @aiVideoAndClothChanger.
  ///
  /// In en, this message translates to:
  /// **'AI Video & Cloth Changer'**
  String get aiVideoAndClothChanger;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @setting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get setting;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @myCreation.
  ///
  /// In en, this message translates to:
  /// **'My creation'**
  String get myCreation;

  /// No description provided for @downloadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Downloading Video'**
  String get downloadingVideo;

  /// No description provided for @youCanViewAllYourCreationsHere.
  ///
  /// In en, this message translates to:
  /// **'You can view all your creations here'**
  String get youCanViewAllYourCreationsHere;

  /// No description provided for @videoSavedToHistory.
  ///
  /// In en, this message translates to:
  /// **'Video saved to history'**
  String get videoSavedToHistory;

  /// No description provided for @downloadVideo.
  ///
  /// In en, this message translates to:
  /// **'Download Video'**
  String get downloadVideo;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture photo'**
  String get capturePhoto;

  /// No description provided for @bAndWSideAnglesRotatedAndCoveredFaces.
  ///
  /// In en, this message translates to:
  /// **'B&W, side angles, rotated and covered faces'**
  String get bAndWSideAnglesRotatedAndCoveredFaces;

  /// No description provided for @whatWillNotWork.
  ///
  /// In en, this message translates to:
  /// **'What won\'t work'**
  String get whatWillNotWork;

  /// No description provided for @fullyVisibleFaceGoodLighting.
  ///
  /// In en, this message translates to:
  /// **'Fully visible face, good lighting'**
  String get fullyVisibleFaceGoodLighting;

  /// No description provided for @whatShouldWorkBest.
  ///
  /// In en, this message translates to:
  /// **'What should work best'**
  String get whatShouldWorkBest;

  /// No description provided for @createYourFirstDressChangeInJustAFewClick.
  ///
  /// In en, this message translates to:
  /// **'Create your first dress change in just a few clicks! 🎉'**
  String get createYourFirstDressChangeInJustAFewClick;

  /// No description provided for @somethingWentWrongMakeSureYouHaveActiveInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong Make Sure You Have Active Internet Connection'**
  String get somethingWentWrongMakeSureYouHaveActiveInternetConnection;

  /// No description provided for @processingWithDot.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingWithDot;

  /// No description provided for @pleasePickImageToChangeOutfit.
  ///
  /// In en, this message translates to:
  /// **'Please pick image to change outfit'**
  String get pleasePickImageToChangeOutfit;

  /// No description provided for @pleasePickImageToGenerateVideo.
  ///
  /// In en, this message translates to:
  /// **'Please pick image to generate video'**
  String get pleasePickImageToGenerateVideo;

  /// No description provided for @premiumBottomDescription.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will be automatically renew at the same price & period you may manage or cancel subscription at any time from your account setting.'**
  String get premiumBottomDescription;

  /// No description provided for @discoverHowToBringStaticPhotosToLifeByTransformingThemIntoDynamicEngagingVideos.
  ///
  /// In en, this message translates to:
  /// **'Discover how to bring static photos to life by transforming them Into dynamic, engaging videos.'**
  String
  get discoverHowToBringStaticPhotosToLifeByTransformingThemIntoDynamicEngagingVideos;

  /// No description provided for @areYouSureYouWantToDeleteThisVideo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Video?'**
  String get areYouSureYouWantToDeleteThisVideo;

  /// No description provided for @areYouSureYouWantToDeleteThisImage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Image?'**
  String get areYouSureYouWantToDeleteThisImage;

  /// No description provided for @yourResultIsOnTheWayJustAFewMinutesToGo.
  ///
  /// In en, this message translates to:
  /// **'Your result is on the way just a few minutes to go'**
  String get yourResultIsOnTheWayJustAFewMinutesToGo;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get generating;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
