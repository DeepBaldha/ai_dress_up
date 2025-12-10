import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:lottie/lottie.dart';
import '../ads/ads_load_util.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/firebase_analytics_service.dart';
import 'package:flutter/material.dart';
import '../utils/consts.dart';
import '../utils/utils.dart';
import 'dart:io';

import '../view_model/image_result_provider.dart';

class ImageResultFullScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final bool autoSave;
  final String from;

  const ImageResultFullScreen({
    required this.imagePath,
    required this.autoSave,
    required this.from,
    super.key,
  });

  @override
  ConsumerState<ImageResultFullScreen> createState() =>
      _ImageResultFullScreenState();
}

class _ImageResultFullScreenState extends ConsumerState<ImageResultFullScreen> {
  bool _isSaved = false;

  bool _isSavingToGallery = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoSave) {
      _autoSaveImage();
    }
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(
        eventName: 'IMAGE_RESULT_SCREEN_${widget.from}'.toUpperCase(),
      );
    });
  }

  Future<void> _autoSaveImage() async {
    if (_isSaved) return;
    _isSaved = true;

    await ref
        .read(imageResultProvider)
        .saveImage(imagePath: widget.imagePath, title: "Generated Image");
  }

  Future<void> _saveImageToGallery() async {
    if (_isSavingToGallery) {
      showLog('⚠️ Already saving image, skipping.');
      return;
    }

    setState(() {
      _isSavingToGallery = true;
    });

    try {
      showLog('📥 Saving image: ${widget.imagePath}');

      final success = await GallerySaver.saveImage(widget.imagePath);

      if (success ?? false) {
        showToast('Image successfully saved to gallery');
      } else {
        showToast('Error saving image to gallery');
      }
    } catch (e) {
      showLog('❌ Error saving image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save image: $e')),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToGallery = false;
        });
      }
    }
  }

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 800.w,
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 60.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(80.r),
                image: DecorationImage(
                  image: AssetImage('${defaultImagePath}delete_dialog_bg.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Spacer(),
                      NewDeepPressUnpress(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          '${defaultImagePath}close.png',
                          width: 100.w,
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    '${defaultImagePath}delete_icon_dialog.png',
                    height: 300.h,
                  ),
                  50.verticalSpace,
                  Text(
                    getTranslated(context)!.areYouSureYouWantToDeleteThisImage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 50.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  60.verticalSpace,

                  NewDeepPressUnpress(
                    onTap: () async {
                      Navigator.pop(context);

                      final provider = ref.read(imageResultProvider);
                      final images = provider.images;

                      final index = images.indexWhere(
                        (img) => img.imagePath == widget.imagePath,
                      );

                      if (index != -1) {
                        await provider.deleteImage(index);
                        showToast("Image deleted");
                      } else {
                        showToast("Image not found");
                      }

                      if (mounted) {
                        if (widget.from == "history") {
                          Navigator.pop(context);
                        } else if (widget.from == 'denzo_image') {
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Container(
                      width: 600.w,
                      padding: EdgeInsets.symmetric(vertical: 35.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(150),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFFF7271), Color(0xFFEF4B4A)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          getTranslated(context)!.delete,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 50.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  30.verticalSpace,
                  NewDeepPressUnpress(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      getTranslated(context)!.cancel,
                      style: TextStyle(color: Color(0xff626262)),
                    ),
                  ),
                  40.verticalSpace,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              NewDeepPressUnpress(
                onTap: () {
                  AdsLoadUtil.onShowAds(context, () {
                    if (widget.from == 'history') {
                      Navigator.pop(context);
                    } else if (widget.from == 'denzo_image') {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  });
                },
                child: Image.asset(
                  '${defaultImagePath}back.png',
                  width: 100.w,
                  fit: BoxFit.fill,
                ),
              ),
              30.horizontalSpace,
              Expanded(
                child: Text(
                  getTranslated(context)!.preview,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 75.sp, letterSpacing: 0.4),
                ),
              ),
              NewDeepPressUnpress(
                onTap: () {
                  showDeleteDialog(context);
                },
                child: Image.asset(
                  '${defaultImagePath}delete.png',
                  width: 90.w,
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 80.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100.r),
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: getHeight(context) * 0.65,
                      ),
                    ),
                  ),
                  50.verticalSpace,
                  NewDeepPressUnpress(
                    onTap: _saveImageToGallery,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 70.h),
                      height: 180.h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(150),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            '${defaultImagePath}download.png',
                            color: Colors.white,
                            width: 70.w,
                          ),
                          30.horizontalSpace,
                          Text(
                            getTranslated(context)!.downloadImage,
                            style: TextStyle(
                              fontSize: 60.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSavingToGallery)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        '${defaultImagePath}loader.json',
                        height: 300.h,
                      ),
                      40.verticalSpace,
                      Text(
                        'Saving to gallery...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 50.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
