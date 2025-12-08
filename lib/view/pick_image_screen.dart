import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/utils.dart';

class ImagePickerHelper {
  final BuildContext context;
  static const String _recentImagesKey = 'recent_selected_images';
  static const String _firstTimeKey = 'pick_image_open_first_time';
  static const int _maxRecentImages = 15;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const List<String> demoImagePaths = [
    '${defaultImagePath}pick_demo_image_1.png',
    '${defaultImagePath}pick_demo_image_2.png',
  ];

  ImagePickerHelper(this.context);

  /// Check if this is the first time opening image picker
  Future<bool> _isFirstTime() async {
    try {
      final value = await _secureStorage.read(key: _firstTimeKey);
      showLog('First time value is ${value}');
      return value == null || value == 'true';
    } catch (e) {
      debugPrint('❌ Error reading first time flag: $e');
      return false;
    }
  }

  /// Mark image picker as opened
  Future<void> _markAsOpened() async {
    try {
      showLog('mark open method');
      await _secureStorage.write(key: _firstTimeKey, value: 'false');
    } catch (e) {
      debugPrint('❌ Error writing first time flag: $e');
    }
  }

  /// Show image picker dialog with camera, gallery, and recent options
  Future<File?> showImagePickerDialog() async {
    final isFirstTime = await _isFirstTime();

    return await showModalBottomSheet<File>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xffF3F3F3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(60.r)),
            ),
            padding: EdgeInsets.all(40.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Color(0xffCCCCCC),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                if (!isFirstTime) 60.verticalSpace,

                if (isFirstTime) ...[
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        '${defaultImagePath}close.png',
                        width: 100.w,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 40.h),
                    decoration: BoxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Text(
                            getTranslated(
                              context,
                            )!.createYourFirstDressChangeInJustAFewClick,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 75.sp,
                              height: 0,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        60.verticalSpace,
                        Text(
                          getTranslated(context)!.whatShouldWorkBest,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 70.sp,
                          ),
                        ),
                        Text(
                          getTranslated(context)!.fullyVisibleFaceGoodLighting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 50.sp,
                            color: Color(0xff7B7B7B),
                          ),
                        ),
                        Image.asset('${defaultImagePath}ok_image.png'),
                        80.verticalSpace,
                        Text(
                          getTranslated(context)!.whatWillNotWork,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 70.sp,
                          ),
                        ),
                        Text(
                          getTranslated(
                            context,
                          )!.bAndWSideAnglesRotatedAndCoveredFaces,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 50.sp,
                            color: Color(0xff7B7B7B),
                          ),
                        ),
                        20.verticalSpace,
                        Image.asset('${defaultImagePath}not_ok_image.png'),
                        80.verticalSpace,
                      ],
                    ),
                  ),
                ],

                Row(
                  children: [
                    Expanded(
                      child: NewDeepPressUnpress(
                        onTap: () async {
                          if (isFirstTime) {
                            await _markAsOpened();
                          }
                          final file = await _capturePhoto();
                          if (file != null && context.mounted) {
                            Navigator.pop(context, file);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 60.h,
                            horizontal: 20.w,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60.r),
                            image: DecorationImage(
                              image: AssetImage(
                                '${defaultImagePath}pick_image_bg.png',
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                '${defaultImagePath}camera_pick.png',
                                height: 80.h,
                              ),
                              20.horizontalSpace,
                              Flexible(
                                child: Text(
                                  getTranslated(context)!.camera,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 45.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    30.horizontalSpace,
                    Expanded(
                      child: NewDeepPressUnpress(
                        onTap: () async {
                          if (isFirstTime) {
                            await _markAsOpened();
                          }
                          final file = await _selectFromGallery();
                          if (file != null && context.mounted) {
                            Navigator.pop(context, file);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 60.h,
                            horizontal: 20.w,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60.r),
                            image: DecorationImage(
                              image: AssetImage(
                                '${defaultImagePath}pick_image_bg.png',
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                '${defaultImagePath}gallery_pick.png',
                                height: 80.h,
                              ),
                              20.horizontalSpace,
                              Flexible(
                                child: Text(
                                  getTranslated(context)!.gallery,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 45.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isFirstTime) 50.verticalSpace,

                40.verticalSpace,

                if (!isFirstTime)
                  _RecentImagesSection(
                    onImageSelected: (file) {
                      if (context.mounted) {
                        Navigator.pop(context, file);
                      }
                    },
                    secureStorage: _secureStorage,
                    isFirstTime: isFirstTime,
                    onMarkAsOpened: _markAsOpened,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Convert asset image to File
  static Future<File?> _convertAssetToFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${tempDir.path}/demo_$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      showLog('❌ Error converting asset to file: $e');
      return null;
    }
  }

  /// Request Camera Permission
  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.camera.request();

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        showToast('Camera permission is required to capture photos');
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        title: 'Camera Permission Required',
        message:
            'Please enable camera permission from app settings to capture photos.',
      );
      return false;
    }

    return false;
  }

  /// Request Gallery/Photos Permission
  Future<bool> _requestGalleryPermission() async {
    PermissionStatus status;

    // For Android 13+ (API 33+), use photos permission
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        status = await Permission.photos.status;

        if (status.isGranted) {
          return true;
        }

        if (status.isDenied) {
          status = await Permission.photos.request();
        }
      } else {
        // For older Android versions, use storage permission
        status = await Permission.storage.status;

        if (status.isGranted) {
          return true;
        }

        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }
    } else {
      // For iOS, use photos permission
      status = await Permission.photos.status;

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (status.isDenied) {
        status = await Permission.photos.request();
      }
    }

    if (status.isGranted || status.isLimited) {
      return true;
    } else if (status.isDenied) {
      showToast('Gallery permission is required to select photos');
      return false;
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        title: 'Gallery Permission Required',
        message:
            'Please enable gallery/photos permission from app settings to select photos.',
      );
      return false;
    }

    return false;
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  /// Show permission dialog
  void _showPermissionDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Color(0xff6C63FF)),
            ),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(
              color: const Color(0xff1E1E1E),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('${defaultImagePath}loader.json', height: 200.h),
                20.verticalSpace,
                const Text(
                  'Processing image...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Crop the selected image
  Future<File?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xff6C63FF),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error cropping image: $e');
      return null;
    }
  }

  /// Compress image if larger than 5MB
  Future<File> _compressImageIfNeeded(File imageFile) async {
    const int maxSizeInBytes = 5 * 1024 * 1024; // 5 MB

    final fileSize = await imageFile.length();

    if (fileSize <= maxSizeInBytes) {
      showLog(
        '✅ Image size OK: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      return imageFile;
    }

    showLog(
      '⚠️ Image too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB. Compressing...',
    );

    try {
      // Show loading indicator
      showToast('Compressing image...');

      final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

      if (image == null) {
        showLog('❌ Failed to decode image for compression');
        return imageFile;
      }

      // Start with 85% quality
      int quality = 85;
      List<int>? compressedBytes;

      // Compress until under 5MB or quality is too low
      while (quality > 20) {
        compressedBytes = img.encodeJpg(image, quality: quality);

        if (compressedBytes.length <= maxSizeInBytes) {
          break;
        }

        quality -= 10;
      }

      // If still too large, resize the image
      if (compressedBytes != null && compressedBytes.length > maxSizeInBytes) {
        showLog('🔄 Still too large, resizing image...');

        final resizedImage = img.copyResize(
          image,
          width: (image.width * 0.8).toInt(),
        );

        compressedBytes = img.encodeJpg(resizedImage, quality: 80);
      }

      // Save compressed image
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await compressedFile.writeAsBytes(compressedBytes!);

      final compressedSize = await compressedFile.length();
      showLog(
        '✅ Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      showToast('Image compressed successfully');

      return compressedFile;
    } catch (e) {
      showLog('❌ Compression error: $e');
      return imageFile;
    }
  }

  /// Save image to permanent storage and add to recent
  Future<File> _saveImagePermanently(File imageFile) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final recentImagesDir = Directory('${appDir.path}/recent_images');

      // Create directory if it doesn't exist
      if (!await recentImagesDir.exists()) {
        await recentImagesDir.create(recursive: true);
      }

      // Create unique filename
      final fileName = 'recent_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = '${recentImagesDir.path}/$fileName';

      // Copy image to permanent location
      final permanentFile = await imageFile.copy(permanentPath);

      // Add to recent images list
      await _addToRecentImages(permanentFile.path);

      return permanentFile;
    } catch (e) {
      showLog('❌ Error saving image permanently: $e');
      return imageFile;
    }
  }

  /// Add image path to recent images
  Future<void> _addToRecentImages(String imagePath) async {
    try {
      // Get existing recent images
      final recentImagesJson = await _secureStorage.read(key: _recentImagesKey);
      List<String> recentImages = [];

      if (recentImagesJson != null) {
        final decoded = jsonDecode(recentImagesJson);
        recentImages = List<String>.from(decoded);
      }

      // Remove if already exists (to move it to front)
      recentImages.remove(imagePath);

      // Add to front
      recentImages.insert(0, imagePath);

      // Keep only last 15 images
      if (recentImages.length > _maxRecentImages) {
        // Delete old image files
        for (int i = _maxRecentImages; i < recentImages.length; i++) {
          try {
            final oldFile = File(recentImages[i]);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (e) {
            showLog('Error deleting old image: $e');
          }
        }

        recentImages = recentImages.take(_maxRecentImages).toList();
      }

      // Save updated list
      await _secureStorage.write(
        key: _recentImagesKey,
        value: jsonEncode(recentImages),
      );

      showLog('✅ Added to recent images: $imagePath');
    } catch (e) {
      showLog('❌ Error adding to recent images: $e');
    }
  }

  /// Capture photo from camera
  Future<File?> _capturePhoto() async {
    try {
      // Request camera permission first
      final hasPermission = await _requestCameraPermission();

      if (!hasPermission) {
        return null;
      }

      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) {
        return null;
      }

      if (!context.mounted) return null;

      // Show crop screen
      final croppedFile = await _cropImage(photo.path);

      if (croppedFile == null) {
        return null;
      }

      if (!context.mounted) return null;

      // Show loading dialog for compression
      _showLoadingDialog();

      // Compress image if needed
      final compressedFile = await _compressImageIfNeeded(croppedFile);

      // Save to permanent storage and add to recent
      final permanentFile = await _saveImagePermanently(compressedFile);

      // Hide loading dialog
      _hideLoadingDialog();

      return permanentFile;
    } catch (e) {
      debugPrint('❌ Error capturing photo: $e');
      if (context.mounted) {
        _hideLoadingDialog();
      }
      return null;
    }
  }

  /// Select photo from gallery
  Future<File?> _selectFromGallery() async {
    try {
      // Request gallery permission first
      final hasPermission = await _requestGalleryPermission();

      if (!hasPermission) {
        return null;
      }

      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo == null) {
        return null;
      }

      if (!context.mounted) return null;

      // Show crop screen
      final croppedFile = await _cropImage(photo.path);

      if (croppedFile == null) {
        return null;
      }

      if (!context.mounted) return null;

      // Show loading dialog for compression
      _showLoadingDialog();

      // Compress image if needed
      final compressedFile = await _compressImageIfNeeded(croppedFile);

      // Save to permanent storage and add to recent
      final permanentFile = await _saveImagePermanently(compressedFile);

      // Hide loading dialog
      _hideLoadingDialog();

      return permanentFile;
    } catch (e) {
      debugPrint('❌ Error selecting from gallery: $e');
      if (context.mounted) {
        _hideLoadingDialog();
      }
      return null;
    }
  }
}

/// Recent Images Section Widget
class _RecentImagesSection extends StatefulWidget {
  final Function(File) onImageSelected;
  final FlutterSecureStorage secureStorage;
  final bool isFirstTime;
  final VoidCallback onMarkAsOpened;

  const _RecentImagesSection({
    required this.onImageSelected,
    required this.secureStorage,
    required this.isFirstTime,
    required this.onMarkAsOpened,
  });

  @override
  State<_RecentImagesSection> createState() => _RecentImagesSectionState();
}

class _RecentImagesSectionState extends State<_RecentImagesSection> {
  List<String> _recentImagePaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentImages();
  }

  /// Load recent images from secure storage
  Future<void> _loadRecentImages() async {
    try {
      final recentImagesJson = await widget.secureStorage.read(
        key: ImagePickerHelper._recentImagesKey,
      );

      if (recentImagesJson != null) {
        final decoded = jsonDecode(recentImagesJson);
        final paths = List<String>.from(decoded);

        // Filter out paths that don't exist anymore
        final existingPaths = <String>[];
        for (final path in paths) {
          if (await File(path).exists()) {
            existingPaths.add(path);
          }
        }

        setState(() {
          _recentImagePaths = existingPaths;
          _isLoading = false;
        });

        // Update storage if any paths were removed
        if (existingPaths.length != paths.length) {
          await widget.secureStorage.write(
            key: ImagePickerHelper._recentImagesKey,
            value: jsonEncode(existingPaths),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      showLog('❌ Error loading recent images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.h),
          child: CircularProgressIndicator(
            color: Color(0xff6C63FF),
            strokeWidth: 3.w,
          ),
        ),
      );
    }

    // Always show recent section if there are demo images, even if no user images
    final hasDemoImages = ImagePickerHelper.demoImagePaths.isNotEmpty;
    final hasRecentImages = _recentImagePaths.isNotEmpty;

    if (!hasDemoImages && !hasRecentImages) {
      return SizedBox.shrink();
    }

    final totalImages =
        ImagePickerHelper.demoImagePaths.length + _recentImagePaths.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          getTranslated(context)!.recent,
          style: TextStyle(
            fontSize: 50.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        30.verticalSpace,
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 600.h),
          child: GridView.builder(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 1,
            ),
            itemCount: totalImages,
            itemBuilder: (context, index) {
              // Show demo images first, then recent images
              final isDemoImage =
                  index < ImagePickerHelper.demoImagePaths.length;

              if (isDemoImage) {
                final assetPath = ImagePickerHelper.demoImagePaths[index];

                // Debug log
                debugPrint('🖼️ Loading demo image from: $assetPath');

                return NewDeepPressUnpress(
                  onTap: () async {
                    showLog('there is first time: ${widget.isFirstTime}');
                    // Mark as opened when any recent image is selected
                    if (widget.isFirstTime) {
                      widget.onMarkAsOpened();
                    }

                    // Convert asset to file when demo image is selected
                    final file = await ImagePickerHelper._convertAssetToFile(
                      assetPath,
                    );
                    if (file != null) {
                      widget.onImageSelected(file);
                    } else {
                      showToast('Failed to load demo image');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(color: Color(0xffE0E0E0), width: 2.w),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                '❌ Error loading demo image: $assetPath',
                              );
                              debugPrint('❌ Error: $error');
                              debugPrint('❌ StackTrace: $stackTrace');

                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xffF5F5F5),
                                      Color(0xffE0E0E0),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 60.sp,
                                      color: Color(0xff9E9E9E),
                                    ),
                                    10.verticalSpace,
                                    Text(
                                      'Demo',
                                      style: TextStyle(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff757575),
                                      ),
                                    ),
                                    5.verticalSpace,
                                    Text(
                                      'Image not found',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        color: Color(0xff9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Align(
                            alignment: AlignmentGeometry.bottomCenter,
                            child: Container(
                              margin: EdgeInsets.only(bottom: 20.h),
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 20.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Demo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 35.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Recent images
                final recentIndex =
                    index - ImagePickerHelper.demoImagePaths.length;
                final imagePath = _recentImagePaths[recentIndex];
                return NewDeepPressUnpress(
                  onTap: () {
                    if (widget.isFirstTime) {
                      widget.onMarkAsOpened();
                    }
                    final file = File(imagePath);
                    if (file.existsSync()) {
                      widget.onImageSelected(file);
                    } else {
                      showToast('Image no longer exists');
                      // Remove from list
                      setState(() {
                        _recentImagePaths.removeAt(recentIndex);
                      });
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Icon(
                            Icons.broken_image,
                            size: 80.sp,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
        40.verticalSpace,
      ],
    );
  }
}
