import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import '../ads/ads_variable.dart';
import '../model/image_item_model.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import 'package:ai_dress_up/utils/consts.dart';
import '../utils/custom_widgets/carousel.dart';
import 'package:ai_dress_up/utils/utils.dart';
import 'package:flutter/material.dart';
import '../utils/custom_widgets/retrying_network_image.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/global_variables.dart';
import '../view_model/image_data_provider.dart';
import 'cloth_category_screen.dart';
import 'cloth_change_screen.dart';

class AiOutfitChangerScreen extends ConsumerStatefulWidget {
  const AiOutfitChangerScreen({super.key});

  @override
  ConsumerState<AiOutfitChangerScreen> createState() => _AiOutfitChangerScreenState();
}

class _AiOutfitChangerScreenState extends ConsumerState<AiOutfitChangerScreen> {
  late VideoPlayerController _womenVideoController;
  late VideoPlayerController _menVideoController;

  final List<Map<String, String>> bannerItems = [
    {
      "image": "https://imagizer.imageshack.com/img924/3168/cOdQsK.png",
      "title": "Wedding Outfit",
      "subtitle": "Get the Perfect Look Instantly",
    },
    {
      "image": "https://imagizer.imageshack.com/img923/2176/CMs1SL.png",
      "title": "Party Dress",
      "subtitle": "Try The New Looks Instantly",
    },
    {
      "image": "https://imagizer.imageshack.com/img924/8586/HuDW71.png",
      "title": "Trending Style",
      "subtitle": "Try The New Looks Instantly",
    },
  ];

  @override
  void initState() {
    super.initState();

    showLog('🎬 AI Outfit Changer Screen Initialized');
    showLog('👤 User From: ${AdsVariable.userFrom}');

    FirebaseAnalyticsService.logEvent(eventName: "AI_OUTFIT_CHANGER_HOME_${AdsVariable.userFrom}");

    _womenVideoController = VideoPlayerController.asset(
      '${defaultImagePath}woman_animation.mp4',
    );

    _menVideoController = VideoPlayerController.asset(
      '${defaultImagePath}man_animation.mp4',
    );

    _initializeVideo(_womenVideoController);
    _initializeVideo(_menVideoController);

    showLog('📦 Will load Men/Women type: ${getMenWomenImageType()}');
    showLog('📦 Will load Category type: ${getCategoryImageType()}');
  }

  void _initializeVideo(VideoPlayerController controller) async {
    await controller.initialize();

    if (!mounted) return;

    controller
      ..setLooping(true)
      ..setVolume(0);

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

  ImageDataType getMenWomenImageType() {
    showLog('🔍 Getting Men/Women image type for: ${AdsVariable.userFrom}');
    final type = switch (AdsVariable.userFrom.toLowerCase()) {
      'facebook' => ImageDataType.facebookMenWomenImages,
      'google' => ImageDataType.googleMenWomenImages,
      _ => ImageDataType.playstoreMenWomenImages,
    };
    showLog('✅ Selected Men/Women type: $type');
    return type;
  }

  ImageDataType getCategoryImageType() {
    showLog('🔍 Getting Category image type for: ${AdsVariable.userFrom}');
    final type = switch (AdsVariable.userFrom.toLowerCase()) {
      'facebook' => ImageDataType.facebookCategoryImages,
      'google' => ImageDataType.googleCategoryImages,
      _ => ImageDataType.playstoreCategoryImages,
    };
    showLog('✅ Selected Category type: $type');
    return type;
  }

  List<Map<String, String>> convertImageItemsToMap(List<ImageItemModel> items, String baseUrl) {
    showLog('🔄 Converting ${items.length} image items to map format');
    showLog('🌐 Base URL: $baseUrl');
    final result = items.map((item) {
      final fullUrl = baseUrl + item.image;
      showLog('   • ${item.title} -> $fullUrl');
      return {
        "url": fullUrl,
        "name": item.title,
      };
    }).toList();
    showLog('✅ Converted ${result.length} items');
    return result;
  }

  Map<String, List<Map<String, String>>> convertCategoriesToMap(
      List<Category> categories,
      String baseUrl,
      ) {
    showLog('🔄 Converting ${categories.length} categories to map format');
    showLog('🌐 Base URL: $baseUrl');
    final Map<String, List<Map<String, String>>> result = {};

    for (var category in categories) {
      showLog('   📁 Category: ${category.name} (${category.items.length} items)');
      result[category.name] = category.items.map((item) {
        final fullUrl = baseUrl + item.image;
        return {
          "url": fullUrl,
          "name": item.title,
        };
      }).toList();
    }

    showLog('✅ Converted ${result.length} categories');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final menWomenImageType = getMenWomenImageType();
    final categoryImageType = getCategoryImageType();

    final menWomenData = ref.watch(imageDataProvider(menWomenImageType));

    final categoryData = ref.watch(imageDataProvider(categoryImageType));

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
                imageUrls: bannerItems.map((e) => e["image"]!).toList(),
                titles: bannerItems.map((e) => e["title"]!).toList(),
                subtitles: bannerItems.map((e) => e["subtitle"]!).toList(),
                onTap: (index) {
                  final clothItems = bannerItems.map((b) {
                    return {
                      "url": b["image"]!,
                      "name": b["title"]!,
                    };
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClothChangeScreen(
                        clothItems: clothItems,
                        selectedIndex: index,
                      ),
                    ),
                  );
                },
              ),

              50.verticalSpace,

              menWomenData.when(
                data: (data) {
                  showLog('📊 Men/Women data received');
                  showLog('📊 Data type: ${data.runtimeType}');

                  if (data is MenWomenImageModel) {
                    showLog('✅ Data is MenWomenImageModel');
                    showLog('👨 Men items: ${data.men.length}');
                    showLog('👩 Women items: ${data.women.length}');

                    final String baseUrl = _getBaseUrlForMenWomen();
                    final womenClothItems = convertImageItemsToMap(data.women, baseUrl);
                    final menClothItems = convertImageItemsToMap(data.men, baseUrl);

                    showLog('✅ Women cloth items ready: ${womenClothItems.length}');
                    showLog('✅ Men cloth items ready: ${menClothItems.length}');

                    return Row(
                      children: [
                        // Women Section
                        Expanded(
                          child: NewDeepPressUnpress(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClothCategoryScreen(
                                    title: getTranslated(context)!.womanDress,
                                    clothItems: womenClothItems,
                                  ),
                                ),
                              );
                            },
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
                                        image: AssetImage(
                                            '${defaultImagePath}outfit_change_women_button_bg.png'),
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
                        ),

                        50.horizontalSpace,

                        // Men Section
                        Expanded(
                          child: NewDeepPressUnpress(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClothCategoryScreen(
                                    title: getTranslated(context)!.manFashion,
                                    clothItems: menClothItems,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                if (_menVideoController.value.isInitialized)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20.r),
                                    child: SizedBox(
                                      height: 400.h,
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _menVideoController.value.size.width,
                                          height: _menVideoController.value.size.height,
                                          child: VideoPlayer(_menVideoController),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                            '${defaultImagePath}outfit_change_men_button_bg.png'),
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
                                            getTranslated(context)!.manFashion,
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
                        ),
                      ],
                    );
                  } else {
                    showLog('❌ Data is NOT MenWomenImageModel, it is: ${data.runtimeType}');
                  }
                  return SizedBox.shrink();
                },
                loading: () {
                  showLog('⏳ Men/Women data is loading...');
                  return SizedBox(
                    height: 400.h,
                    child: Center(
                      child: Lottie.asset('${defaultImagePath}loader.json'),
                    ),
                  );
                },
                error: (error, stack) {
                  showLog('❌ Error loading men/women data: $error');
                  showLog('❌ Stack trace: $stack');
                  return SizedBox(
                    height: 400.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text('Error loading data'),
                          SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              40.verticalSpace,

              // Categories Section
              categoryData.when(
                data: (data) {
                  showLog('📊 Category data received');
                  showLog('📊 Data type: ${data.runtimeType}');

                  if (data is CategoryImageModel) {
                    showLog('✅ Data is CategoryImageModel');
                    showLog('📁 Categories count: ${data.categories.length}');

                    final String baseUrl = _getBaseUrlForCategory();
                    final outfitCategories = convertCategoriesToMap(data.categories, baseUrl);

                    showLog('✅ Outfit categories ready: ${outfitCategories.length}');

                    return Column(
                      children: [
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
                                final imageUrl = items[index]["url"]!;
                                final String imageName = items[index]["name"]!;
                                final List<Map<String, String>> fullList = items;

                                return NewDeepPressUnpress(
                                  onTap: () => _openClothScreen(fullList, index),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(30.r),
                                        child:  SizedBox(
                                          width: 450.w,
                                          child: RetryingNetworkImage(
                                            imageUrl: imageUrl,
                                            identifier: imageName,
                                            fit: BoxFit.cover,
                                            placeholderType: PlaceholderType.lottie,
                                            maxHeightDiskCache: 600,
                                            maxWidthDiskCache: 450,
                                            memCacheHeight: 600,
                                            memCacheWidth: 450,
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
                    );
                  } else {
                    showLog('❌ Data is NOT CategoryImageModel, it is: ${data.runtimeType}');
                  }
                  return SizedBox.shrink();
                },
                loading: () {
                  showLog('⏳ Category data is loading...');
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.h),
                      child: Lottie.asset('${defaultImagePath}loader.json',height: 500.w),
                    ),
                  );
                },
                error: (error, stack) {
                  showLog('❌ Error loading category data: $error');
                  showLog('❌ Stack trace: $stack');
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.h),
                      child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text('Error loading categories'),
                          SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get base URL for men/women images
  String _getBaseUrlForMenWomen() {
    showLog('🌐 Getting base URL for Men/Women images');
    final url = switch (AdsVariable.userFrom.toLowerCase()) {
      'facebook' => GlobalVariables.clothChangeMenWomenFacebookBaseURL,
      'google' => GlobalVariables.clothChangeMenWomenGoogleBaseURL,
      _ => GlobalVariables.clothChangeMenWomenPlayStoreBaseURL,
    };
    showLog('✅ Base URL: $url');
    return url;
  }

  // Get base URL for category images
  String _getBaseUrlForCategory() {
    showLog('🌐 Getting base URL for Category images');
    final url = switch (AdsVariable.userFrom.toLowerCase()) {
      'facebook' => GlobalVariables.clothChangeImagesFacebookBaseURL,
      'google' => GlobalVariables.clothChangeImagesGoogleBaseURL,
      _ => GlobalVariables.clothChangeImagesPlayStoreBaseURL,
    };
    showLog('✅ Base URL: $url');
    return url;
  }

  @override
  void dispose() {
    _womenVideoController.dispose();
    _menVideoController.dispose();
    super.dispose();
  }
}