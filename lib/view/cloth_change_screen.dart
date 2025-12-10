import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ai_dress_up/view/pick_image_screen.dart';
import 'package:lottie/lottie.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/firebase_analytics_service.dart';
import 'package:ai_dress_up/utils/consts.dart';
import '../view_model/cloth_changer_provider.dart';
import '../view_model/credit_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import '../utils/global_variables.dart';
import 'package:flutter/material.dart';
import '../ads/ads_load_util.dart';
import '../utils/utils.dart';
import 'dart:io';

import 'credit_premium_screen.dart';

class ClothChangeScreen extends ConsumerStatefulWidget {
  const ClothChangeScreen({
    super.key,
    required this.clothItems,
    required this.selectedIndex,
  });

  final List<Map<String, String>> clothItems;
  final int selectedIndex;

  @override
  ConsumerState<ClothChangeScreen> createState() => _ClothChangeScreenState();
}

class _ClothChangeScreenState extends ConsumerState<ClothChangeScreen> {
  int selectedIndex = 0;
  late ScrollController _scrollController;
  bool _isUserScrolling = false;
  File? userImage;

  Future<void> _pickImageCheck() async {
    final creditNotifier = ref.read(creditProvider.notifier);
    final requiredCredit = GlobalVariables.clothChangeCredit;

    if (!creditNotifier.canAfford(requiredCredit)) {
      showLog(
        'Need $requiredCredit credit, but you have ${ref.read(creditProvider)}',
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreditPremiumScreen(
            from: 'cloth_change',
            onDone: () async {
              await _pickUserImage();
            },
          ),
        ),
      );
      return;
    }

    await _pickUserImage();
  }

  Future<void> _pickUserImage() async {
    final helper = ImagePickerHelper(context);
    final result = await helper.showImagePickerDialog();
    if (result == null) return;

    setState(() => userImage = File(result.path));
  }

  @override
  void initState() {
    selectedIndex = widget.selectedIndex;

    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollEnd);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsService.logEvent(eventName: 'CLOTH_CHANGE_SCREEN');
      _scrollToSelected();
    });

    super.initState();
  }

  void _scrollToSelected() {
    final itemWidth = 250.w + 30.w;
    final targetOffset = (selectedIndex * itemWidth) - (itemWidth * 1.5);

    _scrollController.animateTo(
      targetOffset < 0 ? 0 : targetOffset,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _onScrollEnd() {
    if (!_scrollController.position.isScrollingNotifier.value) {
      if (!_isUserScrolling) return;
      _isUserScrolling = false;
      _snapToNearestItem();
    }
  }

  void _snapToNearestItem() {
    final itemWidth = 250.w + 30.w;
    final currentOffset = _scrollController.offset;
    final index = (currentOffset / itemWidth).round();

    final targetOffset = index * itemWidth;

    _scrollController.animateTo(
      targetOffset,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handleApplyOutfit() {
    if (userImage == null) {
      // Before picking image, check credit
      _pickImageCheck();
      return;
    }

    _generateClothChange();
  }


  void _generateClothChange() {
    if (userImage == null) {
      showToast(getTranslated(context)!.pleasePickImageToChangeOutfit);
      return;
    }

    final selectedMap = widget.clothItems[selectedIndex];

    final selectedClothUrl = selectedMap["url"]!;
    final selectedClothName = selectedMap["name"]!;

    showLog("Selected Cloth URL = $selectedClothUrl");
    showLog("Selected Cloth Name = $selectedClothName");

    ref
        .read(clothChangeProvider.notifier)
        .generateClothChange(
          context: context,
          humanImage: userImage!,
          garmentImageUrl: selectedClothUrl,
          creditCharge: GlobalVariables.clothChangeCredit,
        );
  }

  @override
  Widget build(BuildContext context) {
    final mainUrl = widget.clothItems[selectedIndex]["url"]!;
    final mainName = widget.clothItems[selectedIndex]["name"]!;

    return Scaffold(
      backgroundColor: Color(0xfff3f3f3),
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
                getTranslated(context)!.clothsChanger,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 65.sp),
              ),
            ),

            // CREDIT BOX (unchanged)
            NewDeepPressUnpress(
              onTap: () {},
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Color(0xffDDDDDD), width: 5.w),
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

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 50.w),
            child: Column(
              children: [
                SizedBox(
                  height: getHeight(context) * 0.59,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.r),
                          child: userImage == null
                              ? CachedNetworkImage(
                                  imageUrl: mainUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Center(
                                    child: Lottie.asset(
                                      '${defaultImagePath}loader.json',
                                      width: 200.w,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade900,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 60.sp,
                                    ),
                                  ),
                                )
                              : Image.file(userImage!, fit: BoxFit.cover),
                        ),
                      ),

                      Positioned(
                        bottom: 20.h,
                        left: 0,
                        right: 0,
                        child: Text(
                          mainName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 60.sp,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                70.verticalSpace,

                SizedBox(
                  height: 440.h,
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (notification.direction == ScrollDirection.idle) {
                        _isUserScrolling = true;
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.clothItems.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedIndex == index;

                        final itemUrl = widget.clothItems[index]["url"]!;
                        final itemName = widget.clothItems[index]["name"]!;

                        return NewDeepPressUnpress(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 30.w),
                            padding: isSelected
                                ? EdgeInsets.all(10.w)
                                : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60.r),
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        Color(0xffFF9F7E),
                                        Color(0xff6891FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                            ),
                            child: Container(
                              padding: isSelected
                                  ? EdgeInsets.all(5.w)
                                  : EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(60.r),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(60.r),
                                    child: CachedNetworkImage(
                                      imageUrl: itemUrl,
                                      width: 350.w,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Center(
                                        child: SizedBox(
                                          width: 120.w,
                                          height: 120.w,
                                          child: Lottie.asset(
                                            '${defaultImagePath}loader.json',
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.grey.shade900,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 60.sp,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // NAME OVERLAY
                                  Positioned(
                                    bottom: 20.h,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      itemName,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 45.sp,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // CREDIT BADGE
                                  Positioned(
                                    top: 20.h,
                                    right: 20.w,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            '${defaultImagePath}coin.png',
                                            width: 40.w,
                                          ),
                                          10.horizontalSpace,
                                          Text(
                                            '${GlobalVariables.clothChangeCredit}',
                                            style: TextStyle(fontSize: 40.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                80.verticalSpace,

                NewDeepPressUnpress(
                  onTap: _handleApplyOutfit,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.h),
                    height: 180.h,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(150),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          '${defaultImagePath}upload_image.png',
                          width: 70.w,
                        ),
                        30.horizontalSpace,
                        Text(
                          userImage == null
                              ? getTranslated(context)!.uploadImage
                              : getTranslated(context)!.applyOutfit,
                          style: TextStyle(
                            fontSize: 60.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                50.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
