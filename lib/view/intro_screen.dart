import 'package:ai_dress_up/utils/custom_widgets/deep_press_unpress.dart';
import 'package:ai_dress_up/utils/custom_widgets/my_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_review/in_app_review.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/global_variables.dart';
import 'package:flutter/material.dart';
import '../utils/consts.dart';
import '../utils/utils.dart';
import 'bottom_navigation_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  bool rate = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> introPages = [];

    if (GlobalVariables.showRateUsScreen && GlobalVariables.showIntroScreen) {
      introPages.add({
        'bg': 'rate_us_bg.png',
        'title': getTranslated(context)!.shareYourFeedbackToHelpUsImprove,
        'subtitle': getTranslated(
          context,
        )!.yourRatingsHelpUsGrowAndImproveShareYourFeedbackToHelpUsServeYouBetter,
      });
      FirebaseAnalyticsService.logEvent(eventName: "rate_us".toUpperCase());
    } else {
      if (GlobalVariables.showIntroScreen) {
        introPages.addAll([
          {
            'bg': 'rate_us_bg.png',
            'title': getTranslated(context)!.turningPhotosIntoVideoCreations,
            'subtitle': getTranslated(
              context,
            )!.discoverHowToBringStaticPhotosToLifeByTransformingThemIntoDynamicEngagingVideos,
          },
        ]);
        FirebaseAnalyticsService.logEvent(eventName: "Intro_screen".toUpperCase());
      }

      if (GlobalVariables.showRateUsScreen) {
        introPages.add({
          'bg': 'rate_us_bg.png',
          'title': getTranslated(context)!.shareYourFeedbackToHelpUsImprove,
          'subtitle': getTranslated(
            context,
          )!.yourRatingsHelpUsGrowAndImproveShareYourFeedbackToHelpUsServeYouBetter,
        });
        FirebaseAnalyticsService.logEvent(eventName: "rate_us".toUpperCase());
      }
    }

    if (introPages.isEmpty) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BottomNavigationScreen()),
        );
      });
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          itemCount: introPages.length,
          onPageChanged: (index) => setState(() => currentPage = index),
          itemBuilder: (context, index) {
            final page = introPages[index];

            return Container(
              width: getWidth(context),
              height: getHeight(context),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('$defaultImagePath${page['bg']}'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 100.w),
                    child: Text(
                      page['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 80.sp,
                      ),
                    ),
                  ),

                  10.verticalSpace,

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50.w),
                    child: Text(
                      page['subtitle']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 50.sp,color: Color(0xff6F6F6F)),
                    ),
                  ),

                  80.verticalSpace,

                  SafeArea(
                    top: false,
                    child: MyButton(
                      onTap: () async {
                        bool isLastPage = currentPage == introPages.length - 1;

                        if (isLastPage) {
                          if (GlobalVariables.showRateUsScreen && !rate) {
                            InAppReview inapp = InAppReview.instance;

                            if (await inapp.isAvailable()) {
                              inapp.requestReview();
                            }

                            setState(() => rate = true);
                            return;
                          }

                          GlobalVariables.showIntroScreen = false;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BottomNavigationScreen(),
                            ),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      text: _buttonText(introPages),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _buttonText(List introPages) {
    bool isLast = currentPage == introPages.length - 1;

    if (!isLast) return getTranslated(context)!.continues;

    if (GlobalVariables.showRateUsScreen && !rate) {
      return getTranslated(context)!.rateUs;
    }

    return getTranslated(context)!.continues;
  }
}
