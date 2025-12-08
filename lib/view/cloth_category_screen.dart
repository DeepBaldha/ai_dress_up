import 'package:ai_dress_up/utils/custom_widgets/deep_press_unpress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../utils/firebase_analytics_service.dart';
import '../view_model/credit_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../ads/ads_load_util.dart';
import 'cloth_change_screen.dart';
import '../utils/consts.dart';

class ClothCategoryScreen extends StatefulWidget {
  final String title;
  final List<Map<String, String>> clothItems;

  const ClothCategoryScreen({
    super.key,
    required this.title,
    required this.clothItems,
  });

  @override
  State<ClothCategoryScreen> createState() => _ClothCategoryScreenState();
}

class _ClothCategoryScreenState extends State<ClothCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(eventName: "CLOTH_CATEGORY_SCREEN");
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xfff3f3f3),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              NewDeepPressUnpress(
                onTap: () {
                  AdsLoadUtil.onShowAds(context, () {
                    Navigator.pop(context);
                  });
                },
                child: Image.asset('${defaultImagePath}back.png', width: 100.w),
              ),
              40.horizontalSpace,
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 65.sp),
                ),
              ),

              NewDeepPressUnpress(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.w,
                    vertical: 15.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0xffDDDDDD),
                      width: 5.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset('${defaultImagePath}coin.png', width: 60.w),
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
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),

          child: GridView.builder(
            itemCount: widget.clothItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 25.h,
              childAspectRatio: 0.70,
            ),

            itemBuilder: (context, index) {
              final url = widget.clothItems[index]["url"]!;
              final name = widget.clothItems[index]["name"]!;

              return NewDeepPressUnpress(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClothChangeScreen(
                        clothItems: widget.clothItems,
                        selectedIndex: index,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50.r),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: Lottie.asset(
                              '${defaultImagePath}loader.json',
                              width: 150.w,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade900,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 40.sp,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 15.h,
                        left: 0,
                        right: 0,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 45.sp,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 10),
                            ],
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
      ),
    );
  }
}
