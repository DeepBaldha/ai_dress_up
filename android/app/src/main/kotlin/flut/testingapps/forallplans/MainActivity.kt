package flut.testingapps.forallplans

import android.content.Intent
import android.provider.Settings
import android.content.Context
import android.graphics.Color
import flut.testingapps.forallplans.R
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import com.facebook.FacebookSdk
import com.facebook.LoggingBehavior
import com.facebook.appevents.AppEventsLogger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.graphics.drawable.GradientDrawable
import android.net.wifi.WifiManager
import android.os.Build
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RatingBar
import android.widget.TextView
import android.widget.Toast
import android.telephony.TelephonyManager
import android.util.Log

class MainActivity: FlutterActivity() {

    private fun setText(myText: String) {
        Toast.makeText(this, myText, Toast.LENGTH_SHORT).show()
    }

    private val CHANNEL = "nativeChannel"

    private var startColor: String = "#FFFFFF"
    private var endColor: String = "#FFFFFF"
    private var backgroundColor: String = "#FFFFFF"
    private var headLineTextColor: String = "#000000"
    private var bodyTextColor: String = "#000000"
    private var buttonTextColor: String = "#000000"

    companion object {
        private const val HOTSPOT_CHANNEL = "com.example.app/hotspot"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call: MethodCall, result ->
                when (call.method) {
                    "setToast" -> {
                        try {
                            val fb_appid = call.argument<String>("fb_appid")!!
                            val fb_token = call.argument<String>("fb_token")!!
                            startColor = call.argument<String>("btnBgColorG1")!!
                            endColor = call.argument<String>("btnBgColorG2")!!
                            backgroundColor = call.argument<String>("nativeBGColor")!!
                            headLineTextColor = call.argument<String>("headerTextColor")!!
                            bodyTextColor = call.argument<String>("bodyTextColor")!!
                            buttonTextColor = call.argument<String>("btnTextColor")!!

                            // Uncomment below line for debugging
//                             setText("fb_appid : $fb_appid, fb_token : $fb_token")

                            FacebookSdk.setApplicationId(fb_appid)
                            Log.d("TAG", "Fb app id is $fb_appid")
                            FacebookSdk.setClientToken(fb_token)
                            Log.d("TAG", "fb token id is $fb_token")
                            FacebookSdk.sdkInitialize(this@MainActivity)
                            FacebookSdk.setAutoInitEnabled(true)
                            FacebookSdk.fullyInitialize()
                            FacebookSdk.setAutoLogAppEventsEnabled(true)
                            FacebookSdk.addLoggingBehavior(LoggingBehavior.APP_EVENTS)
                            AppEventsLogger.newLogger(this@MainActivity).applicationId

                            // Register ad factories here, after initializing properties
                            GoogleMobileAdsPlugin.registerNativeAdFactory(
                                flutterEngine,
                                "smallNativeAds",
                                NativeAdFactorySmall(layoutInflater, startColor, endColor, backgroundColor, headLineTextColor, bodyTextColor, buttonTextColor)
                            )
                            GoogleMobileAdsPlugin.registerNativeAdFactory(
                                flutterEngine,
                                "bigNativeAds",
                                NativeAdFactoryBig(layoutInflater, startColor, endColor, backgroundColor, headLineTextColor, bodyTextColor, buttonTextColor)
                            )

                            GoogleMobileAdsPlugin.registerNativeAdFactory(
                                flutterEngine,
                                "full",
                                NativeAdFactoryFull(layoutInflater, startColor, endColor, backgroundColor, headLineTextColor, bodyTextColor, buttonTextColor)
                            )

                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                        result.success(true)
                    }

                    "getCountryCode" -> {
                        try {
                            var countryCode: String? = null

                            // Try SIM country first
                            val tm = getSystemService(TELEPHONY_SERVICE) as android.telephony.TelephonyManager
                            countryCode = tm.simCountryIso
                            if (countryCode.isNullOrEmpty()) {
                                // Fallback to network country
                                countryCode = tm.networkCountryIso
                            }
                            if (countryCode.isNullOrEmpty()) {
                                // Last fallback to locale
                                countryCode = resources.configuration.locales[0].country
                            }

                            result.success(countryCode?.uppercase()) // ensure two-letter uppercase like "IN"
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "Could not get country code.", null)
                        }
                    }
                }
            }

        flutterEngine.plugins.add(GoogleMobileAdsPlugin())
        super.configureFlutterEngine(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "smallNativeAds")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "bigNativeAds")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "full")
    }

}


//class NativeAdFactoryBig : NativeAdFactory {
//    private var layoutInflater: LayoutInflater
//
//    constructor(layoutInflater: LayoutInflater) {
//        this.layoutInflater = layoutInflater
//    }
//
//    override fun createNativeAd(
//        nativeAd: NativeAd?,
//        customOptions: MutableMap<String, Any>?
//    ): NativeAdView {
//        val adView = layoutInflater.inflate(R.layout.big_template, null) as NativeAdView
//
//        val startColor = "#0CA7B8"
//        val endColor = "#E6736B"
//        val backgroundColor = "#202020"
//        val starColor = "#E6736B"
//
//        //Background color
//        adView.circular_layout_background = adView.findViewById(R.id.circular_layout_background)
//        val cornerRadius = 20f * resources.displayMetrics.density
//        val gradientDrawable = GradientDrawable().apply {
//            shape = GradientDrawable.RECTANGLE
//            setColor(Color.parseColor(backgroundColor))
//            this.cornerRadius = cornerRadius
//        }
//        adView.circular_layout_background.background = gradientDrawable
//
//        // Set the media view.
//        adView.mediaView = adView.findViewById(R.id.native_ad_media)
//
//        // Set other ad assets.
//        adView.headlineView = adView.findViewById(R.id.ad_headline)
//        adView.bodyView = adView.findViewById(R.id.ad_body)
//
//        // Button Background
//        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
//        val gradientDrawable = GradientDrawable(
//            GradientDrawable.Orientation.TR_BL, // 135 degrees
//            intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
//        )
//        gradientDrawable.cornerRadius = 14f * resources.displayMetrics.density
//        adView.callToActionView.background = gradientDrawable
//
//        adView.iconView = adView.findViewById(R.id.ad_app_icon)
//        // "Ad" Text background
//        adView.priceView = adView.findViewById(R.id.native_ad_attribution_small)
////        val startColor = "#0CA7B8"
////        val endColor = "#E6736B"
//        val gradientDrawable2 = GradientDrawable(
//            GradientDrawable.Orientation.TR_BL, // 135 degrees
//            intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
//        ).apply {
//            cornerRadii = floatArrayOf(
//                10f * resources.displayMetrics.density, 10f * resources.displayMetrics.density, // top-left radius
//                0f, 0f, // top-right radius
//                0f, 0f, // bottom-right radius
//                5f * resources.displayMetrics.density, 5f * resources.displayMetrics.density  // bottom-left radius
//            )
//        }
//        adView.priceView.background = gradientDrawable2
//
//        // Star Color
//        adView.starRatingView = adView.findViewById(R.id.ad_stars)
//        val color = Color.parseColor(starColor)
//        adView.starRatingView.progressTintList = ColorStateList.valueOf(color)
//        /*adView.storeView = adView.findViewById(R.id.ad_store)*/
//        /*adView.advertiserView = adView.findViewById(R.id.ad_advertiser)*/
//
//        // The headline and mediaContent are guaranteed to be in every NativeAd.
//        (adView.headlineView as TextView).text = nativeAd?.headline
//        adView.mediaView?.mediaContent = nativeAd?.mediaContent
//
//        // These assets aren't guaranteed to be in every NativeAd, so it's important to
//        // check before trying to display them.
//        if (nativeAd?.body == null) {
//            adView.bodyView?.visibility = View.INVISIBLE
//        } else {
//            adView.bodyView?.visibility = View.VISIBLE
//            (adView.bodyView as TextView).text = nativeAd.body
//        }
//
//        if (nativeAd?.callToAction == null) {
//            adView.callToActionView?.visibility = View.INVISIBLE
//        } else {
//            adView.callToActionView?.visibility = View.VISIBLE
//            (adView.callToActionView as Button).text = nativeAd.callToAction
//        }
//
//        if (nativeAd?.icon == null) {
//            adView.iconView?.visibility = View.GONE
//        } else {
//            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon!!.drawable)
//            adView.iconView?.visibility = View.VISIBLE
//        }
//
//        /* if (nativeAd?.price == null) {
//             adView.priceView?.visibility = View.INVISIBLE
//         } else {
//             adView.priceView?.visibility = View.VISIBLE
//             (adView.priceView as TextView).text = nativeAd.price
//         }*/
//
//        /*   if (nativeAd?.store == null) {
//               adView.storeView?.visibility = View.INVISIBLE
//           } else {
//               adView.storeView?.visibility = View.VISIBLE
//               (adView.storeView as TextView).text = nativeAd.store
//           }*/
//
//        if (nativeAd?.starRating == null) {
//            adView.starRatingView?.visibility = View.INVISIBLE
//        } else {
//            (adView.starRatingView as RatingBar).rating = nativeAd.starRating!!.toFloat()
//            adView.starRatingView?.visibility = View.VISIBLE
//        }
//
//        /* if (nativeAd?.advertiser == null) {
//             adView.advertiserView?.visibility = View.INVISIBLE
//         } else {
//             adView.advertiserView?.visibility = View.VISIBLE
//             (adView.advertiserView as TextView).text = nativeAd.advertiser
//         }*/
//
//        // This method tells the Google Mobile Ads SDK that you have finished populating your
//        // native ad view with this native ad.
//        if (nativeAd != null) {
//            adView.setNativeAd(nativeAd)
//        }
//        return adView
//    }
//}

class NativeAdFactorySmall : NativeAdFactory {
    private var layoutInflater: LayoutInflater
    private var startColor: String
    private var endColor: String
    private var backgroundColor: String
    private var headLineTextColor: String
    private var bodyTextColor: String
    private var buttonTextColor: String

    constructor(layoutInflater: LayoutInflater, startColor : String, endColor : String, backgroundColor: String, headLineTextColor: String, bodyTextColor: String, buttonTextColor: String) {
        this.layoutInflater = layoutInflater
        this.startColor = startColor
        this.endColor = endColor
        this.backgroundColor = backgroundColor
        this.headLineTextColor = headLineTextColor
        this.bodyTextColor = bodyTextColor
        this.buttonTextColor = buttonTextColor

    }

    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.small_template_new, null) as NativeAdView
//        val startColor = "#FFEB3B"
//        val endColor = "#FF5722"
//        val backgroundColor = "#2196F3"
//
//        val headLineTextColor = "#9C27B0"
//        val bodyTextColor = "#9C27B0"
//        val buttonTextColor = "#9C27B0"

        // Background color
        val circularLayoutBackground: LinearLayout = adView.findViewById(R.id.circular_layout_background)
        val cornerRadius = 20f * adView.context.resources.displayMetrics.density
        val backgroundGradientDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(Color.parseColor(backgroundColor))
            this.cornerRadius = cornerRadius
        }
        circularLayoutBackground.background = backgroundGradientDrawable

        // Set the media view.
        /*adView.mediaView = adView.findViewById(R.id.ad_media)*/

        // Set other ad assets.
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        (adView.headlineView as? TextView)?.setTextColor(Color.parseColor(headLineTextColor))

        adView.bodyView = adView.findViewById(R.id.ad_body)
        (adView.bodyView as? TextView)?.setTextColor(Color.parseColor(bodyTextColor))

        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        val buttonGradientDrawable = GradientDrawable(
            GradientDrawable.Orientation.TR_BL, // 135 degrees
            intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
        )
        buttonGradientDrawable.cornerRadius = 14f * adView.context.resources.displayMetrics.density
        adView.callToActionView?.background = buttonGradientDrawable
        //Text Color
        (adView.callToActionView as? Button)?.setTextColor(Color.parseColor(buttonTextColor))

        adView.iconView = adView.findViewById(R.id.ad_app_icon)

        // "Ad" Text background
        adView.priceView = adView.findViewById(R.id.native_ad_attribution_small)
        val priceGradientDrawable = GradientDrawable(
            GradientDrawable.Orientation.TR_BL, // 135 degrees
            intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
        ).apply {
            cornerRadii = floatArrayOf(
                10f * adView.context.resources.displayMetrics.density, 10f *  adView.context.resources.displayMetrics.density, // top-left radius
                0f, 0f, // top-right radius
                0f, 0f, // bottom-right radius
                5f *  adView.context.resources.displayMetrics.density, 5f *  adView.context.resources.displayMetrics.density  // bottom-left radius
            )
        }
        adView.priceView?.background = priceGradientDrawable
        (adView.priceView as? TextView)?.setTextColor(Color.parseColor(buttonTextColor))

        adView.starRatingView = adView.findViewById(R.id.ad_stars)
//        val color = Color.parseColor("#E6736B")
//        adView.starRatingView.progressTintList = ColorStateList.valueOf(color)

        /*adView.storeView = adView.findViewById(R.id.ad_store)*/
        /*adView.advertiserView = adView.findViewById(R.id.ad_advertiser)*/

        // The headline and mediaContent are guaranteed to be in every NativeAd.
        (adView.headlineView as TextView).text = nativeAd?.headline
        /*adView.mediaView?.mediaContent = nativeAd?.mediaContent*/

        // These assets aren't guaranteed to be in every NativeAd, so it's important to
        // check before trying to display them.
        if (nativeAd?.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd?.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd?.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon!!.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        /* if (nativeAd?.price == null) {
             adView.priceView?.visibility = View.INVISIBLE
         } else {
             adView.priceView?.visibility = View.VISIBLE
             (adView.priceView as TextView).text = nativeAd.price
         }*/

        /*   if (nativeAd?.store == null) {
               adView.storeView?.visibility = View.INVISIBLE
           } else {
               adView.storeView?.visibility = View.VISIBLE
               (adView.storeView as TextView).text = nativeAd.store
           }*/

        if (nativeAd?.starRating == null) {
            adView.starRatingView?.visibility = View.INVISIBLE
        } else {
            (adView.starRatingView as RatingBar).rating = nativeAd.starRating!!.toFloat()
            adView.starRatingView?.visibility = View.VISIBLE
        }

        /* if (nativeAd?.advertiser == null) {
             adView.advertiserView?.visibility = View.INVISIBLE
         } else {
             adView.advertiserView?.visibility = View.VISIBLE
             (adView.advertiserView as TextView).text = nativeAd.advertiser
         }*/

        // This method tells the Google Mobile Ads SDK that you have finished populating your
        // native ad view with this native ad.
        if (nativeAd != null) {
            adView.setNativeAd(nativeAd)
        }

        return adView
    }
}

class NativeAdFactoryBig(
    private val layoutInflater: LayoutInflater,
    private val startColor: String,
    private val endColor: String,
    private val backgroundColor: String,
    private val headLineTextColor: String,
    private val bodyTextColor: String,
    private val buttonTextColor: String
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.big_template, null) as NativeAdView
        // Background color for circular layout
        val circularLayoutBackground: LinearLayout = adView.findViewById(R.id.circular_layout_background)
        val cornerRadius = 20f * adView.context.resources.displayMetrics.density
        val backgroundGradientDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(Color.parseColor(backgroundColor))
            this.cornerRadius = cornerRadius
        }
        circularLayoutBackground.background = backgroundGradientDrawable
        // Set the media view
        adView.mediaView = adView.findViewById(R.id.native_ad_media)
        // Set headline text
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        (adView.headlineView as? TextView)?.apply {
            setTextColor(Color.parseColor(headLineTextColor))
            text = nativeAd?.headline ?: "Ad Headline"
        }
        // Set call-to-action button
//        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
//        (adView.callToActionView as? Button)?.apply {
//            val buttonGradientDrawable = GradientDrawable(
//                GradientDrawable.Orientation.TR_BL,
//                intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
//            ).apply {
//                cornerRadius = 50f * adView.context.resources.displayMetrics.density
//            }
//            background = buttonGradientDrawable
//            setTextColor(Color.parseColor(buttonTextColor))
//            text = nativeAd?.callToAction ?: "Install"
//        }
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)

        // Set the background to your drawable image
        val drawable = adView.context.getDrawable(R.drawable.install_button_bg)
        adView.callToActionView?.background = drawable
        // Set text color if needed
        (adView.callToActionView as? Button)?.setTextColor(Color.parseColor(buttonTextColor))
//        val buttonGradientDrawable = GradientDrawable(
//            GradientDrawable.Orientation.TR_BL, // 135 degrees
//            intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
//        )
//        buttonGradientDrawable.cornerRadius = 50f * adView.context.resources.displayMetrics.density
//        adView.callToActionView?.background = buttonGradientDrawable
//        //Text Color
//        (adView.callToActionView as? Button)?.setTextColor(Color.parseColor(buttonTextColor))

        // Set attribution text (Ad label)
        adView.priceView = adView.findViewById(R.id.native_ad_attribution_small)
        (adView.priceView as? TextView)?.apply {
            val priceGradientDrawable = GradientDrawable(
                GradientDrawable.Orientation.TR_BL,
                intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
            ).apply {
                cornerRadii = floatArrayOf(
                    10f * adView.context.resources.displayMetrics.density, 10f * adView.context.resources.displayMetrics.density, // Top-left
                    0f, 0f, // Top-right
                    0f, 0f, // Bottom-right
                    5f * adView.context.resources.displayMetrics.density, 5f * adView.context.resources.displayMetrics.density // Bottom-left
                )
            }
            background = priceGradientDrawable
//            background = ContextCompat.getDrawable(context, R.drawable.install_button_bg)
            setTextColor(Color.parseColor(buttonTextColor))
            text = "Ad"
        }
        // Populate other assets
        nativeAd?.let {
            adView.setNativeAd(it)
        }
        return adView
    }
}

class NativeAdFactoryFull : NativeAdFactory {
    private var layoutInflater: LayoutInflater
    private var startColor: String
    private var endColor: String
    private var backgroundColor: String
    private var headLineTextColor: String
    private var bodyTextColor: String
    private var buttonTextColor: String

    constructor(layoutInflater: LayoutInflater, startColor : String, endColor : String, backgroundColor: String, headLineTextColor: String, bodyTextColor: String, buttonTextColor: String) {
        this.layoutInflater = layoutInflater
        this.startColor = startColor
        this.endColor = endColor
        this.backgroundColor = backgroundColor
        this.headLineTextColor = headLineTextColor
        this.bodyTextColor = bodyTextColor
        this.buttonTextColor = buttonTextColor
    }

    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.full_template, null) as NativeAdView

//        val startColor = "#FFEB3B"
//        val endColor = "#FF5722"
//        val backgroundColor = "#2196F3"
//
//        val headLineTextColor = "#9C27B0"
//        val bodyTextColor = "#9C27B0"
//        val buttonTextColor = "#9C27B0"
//        val starColor = "#E6736B"

        // Background color
        val circularLayoutBackground: LinearLayout = adView.findViewById(R.id.circular_layout_background)
        val cornerRadius = 20f * adView.context.resources.displayMetrics.density
        val backgroundGradientDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(Color.parseColor(backgroundColor))
            this.cornerRadius = cornerRadius
        }
        circularLayoutBackground.background = backgroundGradientDrawable

        // Set the media view.
        adView.mediaView = adView.findViewById(R.id.native_ad_media)

        // Set other ad assets.
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        (adView.headlineView as? TextView)?.setTextColor(Color.parseColor(headLineTextColor))

        adView.bodyView = adView.findViewById(R.id.ad_body)
        (adView.bodyView as? TextView)?.setTextColor(Color.parseColor(bodyTextColor))

        // Button Background
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        val buttonGradientDrawable = GradientDrawable(
            GradientDrawable.Orientation.TR_BL, // 135 degrees
            intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
        )
        buttonGradientDrawable.cornerRadius = 14f * adView.context.resources.displayMetrics.density
        adView.callToActionView?.background = buttonGradientDrawable
        //Text Color
        (adView.callToActionView as? Button)?.setTextColor(Color.parseColor(buttonTextColor))

        adView.iconView = adView.findViewById(R.id.ad_app_icon)

        // "Ad" Text background
        adView.priceView = adView.findViewById(R.id.native_ad_attribution_small)
        val priceGradientDrawable = GradientDrawable(
            GradientDrawable.Orientation.TR_BL, // 135 degrees
            intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor))
        ).apply {
            cornerRadii = floatArrayOf(
                10f * adView.context.resources.displayMetrics.density, 10f *  adView.context.resources.displayMetrics.density, // top-left radius
                0f, 0f, // top-right radius
                0f, 0f, // bottom-right radius
                5f *  adView.context.resources.displayMetrics.density, 5f *  adView.context.resources.displayMetrics.density  // bottom-left radius
            )
        }
        adView.priceView?.background = priceGradientDrawable
        (adView.priceView as? TextView)?.setTextColor(Color.parseColor(buttonTextColor))

        // Star Color
        adView.starRatingView = adView.findViewById(R.id.ad_stars)
//        val color = Color.parseColor(starColor)
//        adView.starRatingView.progressTintList = ColorStateList.valueOf(color)

        // Populate ad view
        (adView.headlineView as TextView).text = nativeAd?.headline
        adView.mediaView?.mediaContent = nativeAd?.mediaContent

        if (nativeAd?.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd?.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd?.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon!!.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        if (nativeAd?.starRating == null) {
            adView.starRatingView?.visibility = View.INVISIBLE
        } else {
            (adView.starRatingView as RatingBar).rating = nativeAd.starRating!!.toFloat()
            adView.starRatingView?.visibility = View.VISIBLE
        }

        if (nativeAd != null) {
            adView.setNativeAd(nativeAd)
        }

        return adView
    }
}

