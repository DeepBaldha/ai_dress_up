import 'package:ai_dress_up/view/premium_screen.dart';
import 'package:ai_dress_up/view/tem.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ai_dress_up/view/video_home_screen.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_dress_up/view/trending_screen.dart';
import 'package:ai_dress_up/view/setting_screen.dart';
import '../view_model/video_data_provider.dart';
import '../utils/shared_preference_utils.dart';
import '../view_model/credit_provider.dart';
import 'ai_outfit_changer_screen.dart';
import 'package:flutter/material.dart';
import '../ads/ads_variable.dart';
import '../utils/consts.dart';
import 'creation_screen.dart';
import '../utils/utils.dart';
import 'credit_premium_screen.dart';

class BottomTabNotification extends Notification {}

class BottomNavigationScreen extends ConsumerStatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  ConsumerState<BottomNavigationScreen> createState() =>
      _BottomNavigationScreenState();
}

class _BottomNavigationScreenState
    extends ConsumerState<BottomNavigationScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  late List<Widget> _screens;

  List<Widget> _buildScreensByUserOrigin() {
    final from = AdsVariable.userFrom;
    showLog("HomeScreen → userFrom = $from");

    return [
      TrendingVideoScreen(),
      const VideoHomeScreen(),
      AiOutfitChangerScreen(),
      // LoadingProgressTestScreen(),
      CreationScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();

    showLog('deep');

    /// Decide first tab based on installer
    _screens = _buildScreensByUserOrigin();

    _pageController = PageController(initialPage: 0);

    setFirstTime();

    /// Load FB data (Google & Playstore triggered earlier in splash)
    Future.microtask(
      () => ref
          .read(videoDataProvider(VideoDataType.homeFacebook).notifier)
          .fetchVideoData(),
    );
  }

  Future<void> setFirstTime() async {
    await SharedPreferenceUtils.saveBoolean("firstTime", false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _handleHomeTabNotification(BottomTabNotification notification) {
    if (_currentIndex != 0) {
      _onNavItemTapped(0);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<NavigationItem> navItems = [
      NavigationItem(
        selectedImage: '${defaultImagePath}bottom_trending_selected.png',
        unselectImage: '${defaultImagePath}bottom_trending_unselect.png',
        label: getTranslated(context)!.trending,
      ),
      NavigationItem(
        selectedImage: '${defaultImagePath}bottom_video_selected.png',
        unselectImage: '${defaultImagePath}bottom_video_unselect.png',
        label: getTranslated(context)!.aiVideo,
      ),
      NavigationItem(
        selectedImage: '${defaultImagePath}bottom_dress_selected.png',
        unselectImage: '${defaultImagePath}bottom_dress_unselect.png',
        label: getTranslated(context)!.aiDress,
      ),
      NavigationItem(
        selectedImage: '${defaultImagePath}bottom_creation_selected.png',
        unselectImage: '${defaultImagePath}bottom_creation_unselect.png',
        label: getTranslated(context)!.myCreation,
      ),
    ];

    return NotificationListener<BottomTabNotification>(
      onNotification: _handleHomeTabNotification,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                '${defaultImagePath}screen_background_image.png',
                fit: BoxFit.fill,
              ),
            ),
            SafeArea(
              top: _currentIndex == 0 ? false : true,
              child: Column(
                children: [
                  if (_currentIndex != 0) _buildStaticAppBar(),
                  Expanded(
                    child: PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: _screens,
                    ),
                  ),
                  _buildCustomNavBar(navItems),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavBar(List<NavigationItem> navItems) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffe5e5e5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, -5),
            blurRadius: 20,
            spreadRadius: 1.5,
          ),
        ],
      ),

      padding: EdgeInsets.only(bottom: 10.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final segmentWidth = totalWidth / navItems.length;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              final dx = details.localPosition.dx;
              int tappedIndex = (dx / segmentWidth).floor();
              tappedIndex = tappedIndex.clamp(0, navItems.length - 1);
              _onNavItemTapped(tappedIndex);
            },
            child: Row(
              children: List.generate(
                navItems.length,
                (index) => _buildNavItem(
                  item: navItems[index],
                  isSelected: _currentIndex == index,
                  onTap: () => _onNavItemTapped(index),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required NavigationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: NewDeepPressUnpress(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.only(bottom: 10.h),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isSelected) ...[40.verticalSpace],
                Image.asset(
                  isSelected ? item.selectedImage : item.unselectImage,
                  width: isSelected ? 100.w : 90.w,
                ),
                10.verticalSpace,
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Color(0xffF88B69)
                        : const Color(0xff949494),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticAppBar() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 50.w, top: 20.h, bottom: 20.h),
      child: Row(
        children: [
          _currentIndex == 0
              ? Image(
                  image: AssetImage(
                    '${defaultImagePath}video_heading_white.png',
                  ),
                  width: 400.w,
                )
              : _currentIndex == 1
              ? Image(
                  image: AssetImage('${defaultImagePath}video_heading.png'),
                  width: 400.w,
                )
              : _currentIndex == 2
              ? Image(
                  image: AssetImage('${defaultImagePath}outfit_heading.png'),
                  width: 400.w,
                )
              : Text(
                  getTranslated(context)!.myCreation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 100.sp,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w500,
                  ),
                ),

          if (_currentIndex == 0 ||
              _currentIndex == 1 ||
              _currentIndex == 2) ...[
            Expanded(child: Container()),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.w,
                    vertical: 15.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      NewDeepPressUnpress(
                        onTap: () {
                          navigateTo(
                            context,
                            CreditPremiumScreen(from: 'home', onDone: () {}),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 30.w,
                            vertical: 15.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Color(0xffDDDDDD),
                              width: 5.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                '${defaultImagePath}coin.png',
                                width: 60.w,
                              ),
                              20.horizontalSpace,
                              Consumer(
                                builder: (context, ref, _) {
                                  return Text(
                                    ref.watch(creditProvider).toString(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 55.sp,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      30.horizontalSpace,
                      NewDeepPressUnpress(
                        onTap: () {
                          navigateTo(
                            context,
                            PremiumScreen(from: 'home', onDone: () {}),
                          );
                        },
                        child: Container(
                          height: 115.h,
                          width: 115.h,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                '${defaultImagePath}home_pro_button.png',
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      30.horizontalSpace,
                      NewDeepPressUnpress(
                        onTap: () {
                          navigateTo(context, SettingScreen());
                        },
                        child: Container(
                          height: 115.h,
                          width: 115.h,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                '${defaultImagePath}setting_button.png',
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class NavigationItem {
  final String selectedImage;
  final String unselectImage;
  final String label;

  NavigationItem({
    required this.selectedImage,
    required this.unselectImage,
    required this.label,
  });
}
