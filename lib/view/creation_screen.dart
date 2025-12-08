import 'package:ai_dress_up/view/video_history_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../ads/ads_load_util.dart';
import 'package:flutter/material.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/utils.dart';
import 'image_result_history_screen.dart';

class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});

  @override
  State<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends State<CreationScreen> {
  int _selectedToggle = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((callback) {
    //   FirebaseAnalyticsService.logEvent(eventName: 'CREATION_SCREEN');
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: getWidth(context),
          height: getHeight(context),
          padding: EdgeInsets.symmetric(horizontal: 50.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.verticalSpace,
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(getTranslated(context)!.video, 0),
                    _buildToggleButton(getTranslated(context)!.image, 1),
                  ],
                ),
              ),
              30.verticalSpace,
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _selectedToggle = index);
                  },
                  children: [VideoHistoryScreen(), ImageResultHistoryScreen()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String title, int index) {
    final bool isSelected = _selectedToggle == index;

    return NewDeepPressUnpress(
      onTap: () {
        setState(() => _selectedToggle = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 400),
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 70.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 50.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
