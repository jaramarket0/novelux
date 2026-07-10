package com.daniel.novelux.novelux

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactoryImpl(private val context: Context) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_story_ad, null) as NativeAdView

        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        val iconView = adView.findViewById<ImageView>(R.id.ad_icon)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)

        adView.mediaView = mediaView
        adView.iconView = iconView
        adView.headlineView = headlineView
        adView.callToActionView = ctaView

        headlineView.text = nativeAd.headline
        ctaView.text = nativeAd.callToAction ?: "Learn More"

        nativeAd.mediaContent?.let { mediaView.mediaContent = it }

        // Show icon only when the ad provides one
        val icon = nativeAd.icon
        if (icon?.drawable != null) {
            iconView.setImageDrawable(icon.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
