import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ai_dress_up/utils/utils.dart';
import 'package:flutter/material.dart';

class BannerCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> titles;
  final List<String> subtitles;

  const BannerCarousel({
    super.key,
    required this.imageUrls,
    required this.titles,
    required this.subtitles,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: widget.imageUrls.length,
      options: CarouselOptions(
        height: 500.h,
        autoPlay: true,
        viewportFraction: 1,
        enlargeCenterPage: true,
        autoPlayInterval: const Duration(seconds: 4),
        onPageChanged: (index, reason) {
          setState(() => _current = index);
        },
      ),
      itemBuilder: (context, index, realIndex) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(30.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.cover,
              ),

              Positioned(
                left: 25.w,
                top: 50.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titles[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 54.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      widget.subtitles[index],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 32.sp,
                      ),
                    ),

                    SizedBox(height: 30.h),

                    Container(
                      padding: EdgeInsets.only(
                        left: 50.w,
                        right: 30.w,
                        top: 25.h,
                        bottom: 25.h,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xff000000).withValues(alpha: 0.15),
                        border: Border.all(color: Color(0xffFFFFFF)),
                        borderRadius: BorderRadius.circular(60.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslated(context)!.tryNow,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40.sp,
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 40.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 10.h,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 5.w),
                      width: _current == index ? 40.w : 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: _current == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
