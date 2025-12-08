import 'dart:ui';
import 'package:ai_dress_up/view/web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ads/ads_splash_utils.dart';
import '../ads/ads_variable.dart';
import '../ads/const.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/custom_widgets/loading_screen.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/global_variables.dart';
import '../utils/shared_preference_utils.dart';
import '../utils/utils.dart';
import '../view_model/credit_provider.dart';
import 'bottom_navigation_screen.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key, required this.from, required this.onDone});
  final String from;
  final Function() onDone;

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isInitialized = false;

  PageController pageController = PageController();
  bool isWeekly = AdsVariable.selectedPlan == weeklyIdentifier;
  int planIndex = AdsVariable.selectedPlan == weeklyIdentifier ? 0 : 1;
  bool isWeeklyPlanWithContinue = AdsVariable.selectedPlan == weeklyIdentifier;
  bool isLoading = true;
  Map<String, Package>? availablePackages;
  Map<String, Package>? packageEntry;
  Package? selectedPackage;
  Package? weeklyPackage;
  Package? yearlyPackage;
  Offerings? _offerings;
  int discount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.from == "splash") {
      FirebaseAnalyticsService.logEvent(eventName: "PREMIUM_SCREEN_SPLASH");
    } else if (widget.from == "home") {
      FirebaseAnalyticsService.logEvent(eventName: "PREMIUM_SCREEN_FROM_HOME");
    } else if (widget.from == "showAll") {
      FirebaseAnalyticsService.logEvent(eventName: "PREMIUM_SCREEN_SHOW_ALL");
    } else {
      FirebaseAnalyticsService.logEvent(
        eventName: "PREMIUM_SCREEN_FROM_FEATURE",
      );
    }
    callFirst();
  }

  Future<void> callFirst() async {
    showLog('connection is : ${ConnectivityService.checkConnectivity()}');
    ConnectivityService.checkConnectivity().then((value) async {
      showLog('getting offers1 $value ${AdsVariable.isConfigured}');
      if (value) {
        if (AdsVariable.isConfigured) {
          showLog('getting offers2');
          fetchData();
        } else {
          showLog('getting offers2');
          await configureSDK().then((onValue) {
            fetchData();
          });
        }
      }
    });
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    Offerings? offerings;
    showLog('getting offers3');
    try {
      offerings = await Purchases.getOfferings();
      showLog("Offerings...");
      printJson(offerings.all);
      availablePackages = {
        for (var package in offerings.current?.availablePackages ?? [])
          package.storeProduct.identifier: package,
      };
      showLog("LENGTH IS ${availablePackages?.length}");
      showLog("LENGTH IS ${AdsVariable.selectedPlan}");
      if ((availablePackages?.entries ?? []).length >= 2) {
        weeklyPackage = getPackageByIdentifier(weeklyIdentifier)?.value;
        showLog('Weekly plan is $weeklyPackage');
        yearlyPackage = getPackageByIdentifier(yearlyIdentifier)?.value;
        showLog('Yearly plan is $yearlyPackage');
        if (weeklyPackage == null) {
          isWeeklyPlanWithContinue = false;
          isWeekly = false;
        }
        if (yearlyPackage == null) {
          isWeeklyPlanWithContinue = true;
          isWeekly = true;
        }
        if (yearlyPackage != null && weeklyPackage != null) {
          calculateDiscount();
        }
        if (isWeeklyPlanWithContinue) {
          selectedPackage = weeklyPackage;
          isWeekly = true;
        } else {
          showLog('Selected plan is $selectedPackage');
          selectedPackage = yearlyPackage;

          showLog('Selected plan is $selectedPackage');
          isWeekly = false;
        }
        // MapEntry<String, Package>? packageEntry = getPackageByIdentifier(
        //   AdsVariable.selectedPlan,
        // );
        // selectedPackage = packageEntry?.value;
        setState(() {});
      }
    } on PlatformException catch (e) {
      showLog("$e");
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
      _offerings = offerings;
    });
  }

  void printJson(Map<String, dynamic>? json, [int indentation = 0]) {
    json?.forEach((key, value) {
      showLog('${' ' * indentation}$key: $value');
      if (value is Map<String, dynamic>) {
        printJson(value, indentation + 2);
      }
    });
  }

  void calculateDiscount() {
    double weeklyPrice = weeklyPackage?.storeProduct.price ?? 0;
    double weeklyPriceForYearlyPurchase =
        (yearlyPackage?.storeProduct.price ?? 0) / 52;
    discount = (100 - ((weeklyPriceForYearlyPurchase * 100) / weeklyPrice))
        .truncate();
  }

  MapEntry<String, Package>? getPackageByIdentifier(String identifier) {
    if (availablePackages != null) {
      try {
        final packageEntry = availablePackages!.entries.firstWhere(
          (entry) => entry.value.storeProduct.identifier == identifier,
        );
        return packageEntry;
      } catch (e) {
        showLog("Error retrieving package: $e");
        return null;
      }
    }
    return null;
  }

  Future<void> continueTap() async {
    showLog("PACKAGE IS $selectedPackage");
    loadingScreen.show("loading");

    try {
      final customerInfo = await Purchases.purchase(
        PurchaseParams.package(selectedPackage!),
      );
      showLog("<><><>${customerInfo.customerInfo.activeSubscriptions}");
      CustomerInfo updatedCustomerInfo = await Purchases.getCustomerInfo();
      await initPlatformState(updatedCustomerInfo);
    } on PlatformException catch (e) {
      loadingScreen.hide();
      //Navigator.pop(context);
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        showLog('User cancelled');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        showLog('User not allowed to purchase');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        showLog('Payment is pending');
      }
    }
  }

  Future<void> initPlatformState([CustomerInfo? customerInfo]) async {
    customerInfo ??= await Purchases.getCustomerInfo();
    showLog(
      "SDFSDFSDF=. ${customerInfo.entitlements.all[entitlementKey]?.productIdentifier}",
    );
    showLog(
      "SDFSDFSDF=. ${customerInfo.entitlements.all[entitlementKey]?.isActive}",
    );
    if (customerInfo.entitlements.all[entitlementKey] != null &&
        customerInfo.entitlements.all[entitlementKey]!.isActive == true) {
      AdsVariable.isPurchase = true;
      GlobalVariables.isPremiumUser = true;

      if (isWeekly) {
        await ref
            .read(creditProvider.notifier)
            .addCredit(GlobalVariables.weeklyPlanBonusCredit);
        final currentPurchaseDate = DateTime.parse(
          customerInfo.entitlements.all[entitlementKey]?.latestPurchaseDate ??
              DateTime.now().toIso8601String(),
        );
        await SharedPreferenceUtils.saveString(
          'last_bonus_date',
          currentPurchaseDate.toIso8601String(),
        );
      } else {
        await ref
            .read(creditProvider.notifier)
            .addCredit(GlobalVariables.yearlyPlanBonusCredit);
      }
      showToast(getTranslated(context)!.purchaseSuccessful);
      loadingScreen.hide();
      if (widget.from == "splash" || widget.from == "showAll") {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  BottomNavigationScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    final tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: Curves.ease));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
        widget.onDone();
      }
    } else {
      loadingScreen.hide();
      if (mounted) showToast(getTranslated(context)!.someThingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            height: getHeight(context),
            width: getWidth(context),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('${defaultImagePath}premium_bg.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 100.w,
                  top: 50.h,
                  child: SafeArea(
                    child: NewDeepPressUnpress(
                      onTap: () {
                        if (widget.from.toLowerCase() == 'intro' ||
                            widget.from.toLowerCase() == 'splash') {
                          navigateToReplace(context, BottomNavigationScreen());
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset(
                        '${defaultImagePath}close.png',
                        width: 90.w,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        isLoading
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40.w,
                                  vertical: 30.h,
                                ),
                                child: Lottie.asset(
                                  '${defaultImagePath}loader.json',
                                  height: 300.h,
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 50.w,
                                  vertical: 25.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xffFFFFFF,
                                  ).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(150),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      '${defaultImagePath}coin_show.png',
                                      height: 80.h,
                                    ),
                                    30.horizontalSpace,
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Get ',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 50.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: isWeekly
                                                ? '${GlobalVariables.weeklyPlanBonusCredit}'
                                                : '${GlobalVariables.yearlyPlanBonusCredit}',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 50.sp,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' Credits',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 50.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                        50.verticalSpace,
                        isLoading
                            ? Container(
                                height: 500.h,
                                child: Center(
                                  child: Lottie.asset(
                                    '${defaultImagePath}loader.json',
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  NewDeepPressUnpress(
                                    onTap: () {
                                      setState(() {
                                        isWeekly = false;
                                        selectedPackage = yearlyPackage;
                                      });
                                    },
                                    child: Container(
                                      height: 230.h,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 40.w,
                                      ),
                                      padding: EdgeInsets.only(
                                        left: 150.w,
                                        right: 60.w,
                                        top: 20.h,
                                        bottom: 20.h,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          60.r,
                                        ),
                                        image: DecorationImage(
                                          image: AssetImage(
                                            selectedPackage
                                                        ?.storeProduct
                                                        .identifier ==
                                                    yearlyIdentifier
                                                ? '${defaultImagePath}premium_plan_selected.png'
                                                : '${defaultImagePath}premium_plan_unselect.png',
                                          ),
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${getTranslated(context)!.yearly} ${getTranslated(context)!.plan}',
                                                      style: TextStyle(
                                                        fontSize: 60.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    20.horizontalSpace,
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 25.w,
                                                            vertical: 5.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${discount.toString()}% OFF',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 40.sp,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${getTranslated(context)!.pay} ${yearlyPackage?.storeProduct.priceString ?? '\$1000'} ${getTranslated(context)!.forYear}',
                                                  style: TextStyle(
                                                    fontSize: 42.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              10.verticalSpace,
                                              Text(
                                                yearlyPackage
                                                        ?.storeProduct
                                                        .priceString ??
                                                    "\$1000",
                                                style: TextStyle(
                                                  fontSize: 55.sp,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  40.verticalSpace,
                                  NewDeepPressUnpress(
                                    onTap: () {
                                      setState(() {
                                        isWeekly = true;
                                        selectedPackage = weeklyPackage;
                                      });
                                      showLog(
                                        'msg ${selectedPackage?.storeProduct.identifier}',
                                      );
                                    },
                                    child: Container(
                                      height: 230.h,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 40.w,
                                      ),
                                      padding: EdgeInsets.only(
                                        left: 150.w,
                                        right: 60.w,
                                        top: 20.h,
                                        bottom: 20.h,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          60.r,
                                        ),
                                        image: DecorationImage(
                                          image: AssetImage(
                                            selectedPackage
                                                        ?.storeProduct
                                                        .identifier ==
                                                    weeklyIdentifier
                                                ? '${defaultImagePath}premium_plan_selected.png'
                                                : '${defaultImagePath}premium_plan_unselect.png',
                                          ),
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${getTranslated(context)!.weekly} ${getTranslated(context)!.plan}',
                                                  style: TextStyle(
                                                    fontSize: 60.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  '${getTranslated(context)!.pay} ${weeklyPackage?.storeProduct.priceString ?? '\$1000'} ${getTranslated(context)!.forWeek}',
                                                  style: TextStyle(
                                                    fontSize: 42.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            weeklyPackage
                                                    ?.storeProduct
                                                    .priceString ??
                                                "",
                                            style: TextStyle(
                                              fontSize: 55.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        50.verticalSpace,
                        NewDeepPressUnpress(
                          onTap: () {
                            showLog('selected package is : $selectedPackage');
                            if (!isLoading && selectedPackage != null) {
                              continueTap();
                            }
                          },
                          child: Container(
                            height: 180.h,
                            margin: EdgeInsetsGeometry.symmetric(
                              horizontal: 50.w,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(150),
                            ),
                            child: Center(
                              child: Text(
                                getTranslated(context)!.continues,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Gilroy',
                                  fontSize: 70.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        50.verticalSpace,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Text(
                            getTranslated(context)!.premiumBottomDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xff6C6C6C),
                              height: 0,
                              fontWeight: FontWeight.w400,
                              fontSize: 40.sp,
                            ),
                          ),
                        ),
                        20.verticalSpace,
                        Container(
                          width: double.infinity,
                          height: 50.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              /*Flexible(
                                child: Text(
                                  getTranslated(context)!.restorePlan,
                                  style: TextStyle(
                                    color: Color(0xffBEBEBE),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 42.sp,
                                  ),
                                ),
                              ),
                              Text(
                                '  •  ',
                                style: TextStyle(
                                  color: Color(0xffBEBEBE),
                                  fontSize: 42.sp,
                                ),
                              ),*/
                              Flexible(
                                child: NewDeepPressUnpress(
                                  onTap: () {
                                    navigateTo(
                                      context,
                                      WebViewScreen(
                                        url: privacyPolicy,
                                        title: getTranslated(
                                          context,
                                        )!.privacyPolicy,
                                        log: 'PRIVACY_POLICY',
                                      ),
                                    );
                                  },
                                  child: Text(
                                    getTranslated(context)!.privacyPolicy,
                                    style: TextStyle(
                                      color: Color(0xff6C6C6C),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 42.sp,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '  •  ',
                                style: TextStyle(
                                  color: Color(0xff6C6C6C),
                                  fontSize: 42.sp,
                                ),
                              ),
                              Flexible(
                                child: NewDeepPressUnpress(
                                  onTap: () async {
                                    await launchUrl(
                                      Uri.parse(
                                        "https://play.google.com/store/account/subscriptions",
                                      ),
                                    );
                                  },
                                  child: Text(
                                    getTranslated(context)!.subscription,
                                    style: TextStyle(
                                      color: Color(0xff6C6C6C),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 42.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        20.verticalSpace,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget subscriptionCard({
    required bool isWeeklyCard,
    required String title,
    required String price,
    String? weeklyPrice,
    String? discount,
    required VoidCallback onTap,
  }) {
    final bool isSelected = isWeeklyCard
        ? selectedPackage?.identifier == weeklyIdentifier
        : selectedPackage?.identifier == yearlyIdentifier;

    return NewDeepPressUnpress(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40.w),
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 35.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(60.r),
          image: DecorationImage(
            image: AssetImage(
              isWeeklyCard
                  ? (isSelected
                        ? '${defaultImagePath}week_plan_selected.png'
                        : '${defaultImagePath}week_plan_unselect.png')
                  : (isSelected
                        ? '${defaultImagePath}year_plan_selected.png'
                        : '${defaultImagePath}year_plan_unselect.png'),
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 70.sp,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  if (weeklyPrice != null)
                    Text(
                      weeklyPrice,
                      style: TextStyle(
                        fontSize: 34.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 50.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
