import 'package:ai_dress_up/view/web_view_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ads/ads_variable.dart';
import '../ads/const.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/custom_widgets/loading_screen.dart';
import '../utils/firebase_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:lottie/lottie.dart';

import '../utils/global_variables.dart';
import '../utils/utils.dart';
import '../view_model/credit_provider.dart';
import 'bottom_navigation_screen.dart';

class CreditPremiumScreen extends ConsumerStatefulWidget {
  const CreditPremiumScreen({
    Key? key,
    required this.from,
    required this.onDone,
  }) : super(key: key);
  final String from;
  final Function() onDone;

  @override
  ConsumerState<CreditPremiumScreen> createState() =>
      _CreditPremiumScreenState();
}

class _CreditPremiumScreenState extends ConsumerState<CreditPremiumScreen> {
  Package? selectedPackage;
  Map<String, Package>? availablePackages;
  Package? firstCoinPackage;
  Package? secondCoinPackage;
  Package? thirdCoinPackage;
  Package? fourthCoinPackage;
  Package? fifthCoinPackage;
  Offerings? _offerings;
  List<Package> packages = [];
  bool isInitialized = false;
  int planIndex = 0;

  final List<String> packageIdentifiers = [
    'ai_appsforcoins_300',
    'ai_appsforcoins_500',
    'ai_appsforcoins_300',
    'ai_appsforcoins_500',
    'ai_appsforcoins_300',
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(
        eventName: 'CREDIT_PREMIUM_SCREEN_${widget.from.toUpperCase()}',
      );
      planIndex = packageIdentifiers.indexOf(AdsVariable.selectedCreditPlan);
      if (planIndex < 0) planIndex = 0;
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

  Future<void> fetchData() async {
    Offerings? offerings;
    try {
      offerings = await Purchases.getOfferings();
      showLog("Offerings...");
      printJson(offerings.all);
      showLog("Offerings...");

      final availablePackagesList = offerings.current?.availablePackages ?? [];

      availablePackages = {
        for (var package in availablePackagesList) package.identifier: package,
      };

      showLog("Available packages count: ${availablePackages?.length}");

      packages = [];
      for (String identifier in packageIdentifiers) {
        Package? package = _getPackageByStoreIdentifier(identifier);
        if (package != null) {
          packages.add(package);
        }
      }

      showLog("Mapped packages count: ${packages.length}");

      // Set default selected package
      if (packages.isNotEmpty) {
        int matchedIndex = packages.indexWhere(
          (pkg) =>
              pkg.storeProduct.identifier == AdsVariable.selectedCreditPlan,
        );

        if (matchedIndex != -1) {
          selectedPackage = packages[matchedIndex];
        } else {
          selectedPackage = packages.first;
        }

        _updateGlobalPackageReferences();

        setState(() {
          isInitialized = true;
        });
      }
    } on PlatformException catch (e) {
      showLog("Platform exception: $e");
      setState(() {
        isInitialized = true;
        packages = [];
      });
    } catch (e) {
      showLog("Error fetching data: $e");
      setState(() {
        isInitialized = true;
        packages = [];
      });
    }

    if (!mounted) return;
    setState(() {
      _offerings = offerings;
    });
  }

  Package? _getPackageByStoreIdentifier(String storeIdentifier) {
    if (availablePackages == null) return null;

    try {
      final entry = availablePackages!.entries.firstWhereOrNull(
        (entry) => entry.value.storeProduct.identifier == storeIdentifier,
      );
      return entry?.value;
    } catch (e) {
      showLog("Error retrieving package $storeIdentifier: $e");
      return null;
    }
  }

  void _updateGlobalPackageReferences() {
    if (packages.isEmpty) return;

    firstCoinPackage = packages.isNotEmpty ? packages[0] : null;
    secondCoinPackage = packages.length > 1 ? packages[1] : null;
    thirdCoinPackage = packages.length > 2 ? packages[2] : null;
    fourthCoinPackage = packages.length > 3 ? packages[3] : null;
    fifthCoinPackage = packages.length > 4 ? packages[4] : null;
  }

  // Deprecated - kept for backward compatibility
  MapEntry<String, Package>? getPackageByIdentifier(String identifier) {
    if (availablePackages != null) {
      try {
        final packageEntry = availablePackages!.entries.firstWhere(
          (entry) => entry.value.storeProduct.identifier == identifier,
        );
        return packageEntry;
      } catch (e) {
        showLog("Error retrieving package $identifier: $e");
        return null;
      }
    }
    return null;
  }

  int getCreditsFromPackage(Package package) {
    final index = packages.indexOf(package);
    switch (index) {
      case 0:
        return GlobalVariables.firstPlanCredit;
      case 1:
        return GlobalVariables.secondPlanCredit;
      case 2:
        return GlobalVariables.thirdPlanCredit;
      case 3:
        return GlobalVariables.fourthPlanCredit;
      case 4:
        return GlobalVariables.fifthPlanCredit;
      default:
        return 0;
    }
  }

  double calculateDiscount(Package package) {
    if (packages.isEmpty || packages.length < 2) return 0;

    final firstPackage = packages.first;
    int firstCredits = getCreditsFromPackage(firstPackage);
    double firstPrice = firstPackage.storeProduct.price;

    int currentCredits = getCreditsFromPackage(package);
    double currentPrice = package.storeProduct.price;

    if (firstCredits == 0 || currentCredits == 0) return 0;

    double perCreditFirst = firstPrice / firstCredits;
    double perCreditCurrent = currentPrice / currentCredits;

    double discount = (100 - ((perCreditCurrent * 100) / perCreditFirst));
    return discount < 0 ? 0 : discount;
  }

  bool isPackageSelected(Package package) {
    return selectedPackage?.identifier == package.identifier;
  }

  Future<void> continueTap() async {
    showLog("PACKAGE IS $selectedPackage");
    loadingScreen.show("");

    try {
      await Purchases.purchase(PurchaseParams.package(selectedPackage!));
      initPlatformState();
    } on PlatformException catch (e) {
      loadingScreen.hide();
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        showLog('User cancelled');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        showLog('User not allowed to purchase');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        showLog('Payment is pending');
      }
    } catch (e) {
      loadingScreen.hide();
    }
  }

  Future<void> initPlatformState() async {
    final customerInfo = await Purchases.getCustomerInfo();
    if (customerInfo.entitlements.all[entitlementKey] != null &&
        customerInfo.entitlements.all[entitlementKey]!.isActive == true) {
      AdsVariable.isPurchase = true;
      GlobalVariables.isPremiumUser = true;

      int creditAmount = getCreditsFromPackage(selectedPackage!);
      await ref.read(creditProvider.notifier).addCredit(creditAmount);
      showToast(getTranslated(context)!.creditAddedSuccessfully);
      loadingScreen.hide();

      if (widget.from == "splash") {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BottomNavigationScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
        if (widget.from == 'cloth_changer' ||
            widget.from == 'enhance_image' ||
            widget.from == 'expand_image' ||
            widget.from == 'hair_change' ||
            widget.from == 'reshape_body') {
          if (AdsVariable.showIMTester) {
            widget.onDone();
          } else {
            return;
          }
        }
        widget.onDone();
      }
    } else {
      loadingScreen.hide();
      showToast(getTranslated(context)!.failed);
    }
  }

  void showTesterDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passController = TextEditingController();
    String errorText = '';

    showDialog(
      barrierColor: Colors.black.withValues(alpha: 0.65),
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.symmetric(
                    horizontal: 50.w,
                    vertical: 60.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(80.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 30.h),
                      Text(
                        'Hey Tester!',
                        style: TextStyle(
                          fontSize: 60.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        'Enter your credentials',
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 40.h),

                      _buildInputField(
                        controller: emailController,
                        icon: Icons.email_rounded,
                        hintText: 'Enter Email',
                      ),
                      SizedBox(height: 25.h),

                      _buildInputField(
                        controller: passController,
                        icon: Icons.lock_rounded,
                        hintText: 'Enter Password',
                        obscure: true,
                      ),
                      SizedBox(height: 15.h),

                      // Error text
                      AnimatedOpacity(
                        opacity: errorText.isEmpty ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          errorText,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 34.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 40.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                height: 120.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(48.r),
                                  color: Colors.grey.shade200,
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 40.sp,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 40.w),
                          Expanded(
                            child: NewDeepPressUnpress(
                              onTap: () async {
                                final email = emailController.text.trim();
                                final pass = passController.text.trim();

                                if (email.isEmpty) {
                                  setDialogState(() {
                                    errorText = 'Email cannot be empty';
                                  });
                                } else if (pass.isEmpty) {
                                  setDialogState(() {
                                    errorText = 'Password cannot be empty';
                                  });
                                } else if (email == AdsVariable.testEmail &&
                                    pass == AdsVariable.testPassword) {
                                  showLog('you are tester');
                                  FocusScope.of(context).unfocus();

                                  await Future.delayed(
                                    Duration(microseconds: 200),
                                  );

                                  Navigator.pop(context);
                                  Navigator.pop(context);

                                  await Future.delayed(
                                    Duration(microseconds: 200),
                                  );
                                  widget.onDone();
                                } else {
                                  setDialogState(() {
                                    errorText = 'Invalid credentials';
                                  });
                                }
                              },
                              child: Container(
                                height: 120.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(48.r),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xffEF8744),
                                      Color(0xffDD556A),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Test It',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 40.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscure = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          SizedBox(width: 10.w),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              cursorColor: Colors.black,
              style: TextStyle(color: Colors.black, fontSize: 36.sp),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 34.sp),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: !isInitialized
            ? Center(
                child: Lottie.asset(
                  '${defaultImagePath}loader.json',
                  width: 200.w,
                  height: 200.h,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          '${defaultImagePath}credit_bg.png',
                          fit: BoxFit.fill,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 50.w),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SafeArea(
                                    bottom: false,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 20.w,
                                        top: 30.h,
                                      ),
                                      child: NewDeepPressUnpress(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Image.asset(
                                          '${defaultImagePath}close.png',
                                          width: 90.w,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if(AdsVariable.showIMTester)...[
                                450.verticalSpace
                                ]else...[
                                  500.verticalSpace
                                ],
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 20.w),
                                    child: Text(
                                      getTranslated(context)!.getMoreCredits,
                                      style: TextStyle(
                                        fontSize: 70.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                40.verticalSpace,
                                !isInitialized
                                    ? Lottie.asset(
                                        '${defaultImagePath}loader.json',
                                        height: 500.h,
                                      )
                                    : packages.isEmpty
                                    ? Center(
                                        child: Text(
                                          "Error loading packages",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: packages.length,
                                        itemBuilder: (context, index) {
                                          final package = packages[index];
                                          final isSelected = isPackageSelected(
                                            package,
                                          );
                                          final credits = getCreditsFromPackage(
                                            package,
                                          );
                                          final price =
                                              package.storeProduct.priceString;
                                          final discount = index > 0
                                              ? calculateDiscount(package)
                                              : 0.0;

                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 40.h,
                                            ),
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                NewDeepPressUnpress(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedPackage = package;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 80.w,
                                                    ),
                                                    height: 230.h,
                                                    decoration: BoxDecoration(
                                                      color: !isSelected
                                                          ? Color(0xffFFFFFF)
                                                          : null,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            50.r,
                                                          ),
                                                      image: isSelected
                                                          ? const DecorationImage(
                                                              image: AssetImage(
                                                                '${defaultImagePath}credit_plan_selected.png',
                                                              ),
                                                              fit: BoxFit.fill,
                                                            )
                                                          : null,
                                                      border: !isSelected
                                                          ? Border.all(
                                                              width: 5.w,
                                                              color: Color(
                                                                0xfffeaeaea,
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        10.horizontalSpace,
                                                        Image.asset(
                                                          '${defaultImagePath}credit_icon.png',
                                                          fit: BoxFit.fill,
                                                          width: 60.w,
                                                        ),
                                                        35.horizontalSpace,
                                                        Expanded(
                                                          child: Text(
                                                            '$credits ${getTranslated(context)!.credits}',
                                                            maxLines: 1,
                                                            overflow: TextOverflow
                                                                .ellipsis,
                                                            style: TextStyle(
                                                              letterSpacing: 0.5,
                                                              color: Colors.black,
                                                              fontSize: 58.sp,
                                                              fontWeight:
                                                                  FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              price,
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.black,
                                                                fontSize: 52.sp,
                                                              ),
                                                            ),
                                                            if (discount > 0) ...[
                                                              10.verticalSpace,
                                                              Container(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          15.w,
                                                                      vertical:
                                                                          7.h,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      !isSelected
                                                                      ? Color(
                                                                          0xffEAEAEA,
                                                                        )
                                                                      : Colors
                                                                            .black,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        20.r,
                                                                      ),
                                                                ),
                                                                child: Text.rich(
                                                                  TextSpan(
                                                                    children: [
                                                                      TextSpan(
                                                                        text:
                                                                            '${discount.toStringAsFixed(0)}%',
                                                                        style: TextStyle(
                                                                          color:
                                                                              !isSelected
                                                                              ? Colors.black
                                                                              : Colors.white,
                                                                          fontSize:
                                                                              30.sp,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      TextSpan(
                                                                        text:
                                                                            ' OFF',
                                                                        style: TextStyle(
                                                                          color:
                                                                              !isSelected
                                                                              ? Colors.black
                                                                              : Colors.white,
                                                                          fontSize:
                                                                              29.sp,
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                if (AdsVariable.showIMTester)
                                  if (widget.from == 'generate_video' ||
                                      widget.from == 'generate_face' ||
                                      widget.from == 'cloth_change') ...[
                                    20.verticalSpace,
                                    NewDeepPressUnpress(
                                      onTap: () {
                                        showTesterDialog();
                                      },
                                      child: Text(
                                        'I am Tester',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ],
                                50.verticalSpace,
                                NewDeepPressUnpress(
                                  onTap: continueTap,
                                  child: Container(
                                    height: 180.h,
                                    width: double.infinity,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(150),
                                    ),
                                    child: Center(
                                      child: Text(
                                        getTranslated(context)!.getCredits,
                                        style: TextStyle(
                                          color: Colors.white,
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
                                    getTranslated(
                                      context,
                                    )!.premiumBottomDescription,
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
                                SafeArea(
                                  top: false,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 50.h,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
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
                                              getTranslated(
                                                context,
                                              )!.privacyPolicy,
                                              style: TextStyle(
                                                color: const Color(0xffBEBEBE),
                                                fontWeight: FontWeight.w400,
                                                fontSize: 42.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '  •  ',
                                          style: TextStyle(
                                            color: const Color(0xffBEBEBE),
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
                                              getTranslated(
                                                context,
                                              )!.subscription,
                                              style: TextStyle(
                                                color: const Color(0xffBEBEBE),
                                                fontWeight: FontWeight.w400,
                                                fontSize: 42.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                20.verticalSpace,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
