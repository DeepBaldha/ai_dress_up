import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import 'package:ai_dress_up/utils/consts.dart';
import '../utils/custom_widgets/carousel.dart';
import 'package:ai_dress_up/utils/utils.dart';
import 'package:flutter/material.dart';
import '../utils/firebase_analytics_service.dart';
import 'cloth_category_screen.dart';
import 'cloth_change_screen.dart';

class AiOutfitChangerScreen extends StatefulWidget {
  const AiOutfitChangerScreen({super.key});

  @override
  State<AiOutfitChangerScreen> createState() => _AiOutfitChangerScreenState();
}

class _AiOutfitChangerScreenState extends State<AiOutfitChangerScreen> {
  late VideoPlayerController _womenVideoController;
  late VideoPlayerController _menVideoController;

  @override
  void initState() {
    super.initState();

    FirebaseAnalyticsService.logEvent(eventName: "AI_OUTFIT_CHANGER_HOME");

    _womenVideoController = VideoPlayerController.asset(
      '${defaultImagePath}woman_animation.mp4',
    );

    _menVideoController = VideoPlayerController.asset(
      '${defaultImagePath}woman_animation.mp4',
    );

    _initializeVideo(_womenVideoController);
    _initializeVideo(_menVideoController);
  }

  void _initializeVideo(VideoPlayerController controller) async {
    await controller.initialize();

    if (!mounted) return;

    controller
      ..setLooping(true)
      ..setVolume(0);

    // Important: ensure it's ready BEFORE calling play
    controller.addListener(() {
      if (controller.value.isInitialized && !controller.value.isPlaying) {
        controller.play();
      }
    });

    setState(() {});
  }

  void _openClothScreen(List<Map<String, String>> list, int selectedIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClothChangeScreen(clothItems: list, selectedIndex: selectedIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BannerCarousel(
                imageUrls: [
                  "https://imagizer.imageshack.com/img924/3168/cOdQsK.png",
                  "https://imagizer.imageshack.com/img923/2176/CMs1SL.png",
                  "https://imagizer.imageshack.com/img924/8586/HuDW71.png",
                ],
                titles: ["Wedding Outfit", "Party Dress", "Trending Style"],
                subtitles: [
                  "Get the Perfect Look Instantly",
                  "Try The New Looks Instantly",
                  "Try The New Looks Instantly",
                ],
              ),
              50.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        if (_womenVideoController.value.isInitialized)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: SizedBox(
                              height: 400.h,
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _womenVideoController.value.size.width,
                                  height: _womenVideoController.value.size.height,
                                  child: VideoPlayer(_womenVideoController),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('${defaultImagePath}outfit_change_women_button_bg.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.only(
                            bottom: 20.h,
                            left: 20.w,
                            right: 20.w,
                          ),
                          height: 400.h,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: 70.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context)!.womanDress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 50.sp,
                                    ),
                                  ),
                                  Container(
                                    height: 60.h,
                                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(150),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 50.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  50.horizontalSpace,

                  Expanded(
                    child: Stack(
                      children: [
                        if (_womenVideoController.value.isInitialized)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: SizedBox(
                              height: 400.h,
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _womenVideoController.value.size.width,
                                  height: _womenVideoController.value.size.height,
                                  child: VideoPlayer(_womenVideoController),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('${defaultImagePath}outfit_change_men_button_bg.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.only(
                            bottom: 20.h,
                            left: 20.w,
                            right: 20.w,
                          ),
                          height: 400.h,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: 70.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context)!.womanDress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 50.sp,
                                    ),
                                  ),
                                  Container(
                                    height: 60.h,
                                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(150),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 50.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              40.verticalSpace,
              for (var entry in outfitCategories.entries) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 60.sp, color: Colors.black),
                      ),
                    ),

                    NewDeepPressUnpress(
                      onTap: () {
                        final items = entry.value;
                        final fullList = items;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClothCategoryScreen(
                              title: entry.key,
                              clothItems: fullList,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 25.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Color(0xffDDDDDD),
                            width: 8.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              getTranslated(context)!.more,
                              style: TextStyle(color: Color(0xff7C7C7C)),
                            ),
                            15.horizontalSpace,
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 50.sp,
                              color: Color(0xff7C7C7C),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                30.verticalSpace,
                SizedBox(
                  height: 600.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.value.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final items = entry.value;

                      final List<String> list = items
                          .map((e) => e["url"]!)
                          .toList();
                      final List<String> nameList = items
                          .map((e) => e["name"]!)
                          .toList();

                      final imageUrl = list[index];
                      final String imageName = nameList[index];
                      final List<Map<String, String>> fullList = items;

                      return NewDeepPressUnpress(
                        onTap: () => _openClothScreen(fullList, index),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30.r),
                              child: CachedNetworkImage(
                                width: 450.w,
                                imageUrl: imageUrl,
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
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20.h,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      imageName,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 50.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                60.verticalSpace,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _womenVideoController.dispose();
    _menVideoController.dispose();
    super.dispose();
  }
}
