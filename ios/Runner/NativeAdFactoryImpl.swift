import Foundation
import UIKit
import google_mobile_ads

class NativeAdFactoryImpl: NSObject, FLTNativeAdFactory {
    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable: Any]? = nil
    ) -> GADNativeAdView? {
        let adView = GADNativeAdView()
        adView.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        adView.clipsToBounds = true
        adView.layer.cornerRadius = 8

        // ── Media view ────────────────────────────────────────────────────────
        let mediaView = GADMediaView()
        mediaView.mediaContent = nativeAd.mediaContent
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        adView.mediaView = mediaView

        // ── "Ad" badge ────────────────────────────────────────────────────────
        let badge = UILabel()
        badge.text = "Ad"
        badge.textColor = .white
        badge.font = UIFont.boldSystemFont(ofSize: 8)
        badge.backgroundColor = UIColor(red: 0.10, green: 0.32, blue: 0.47, alpha: 0.85)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 3
        badge.clipsToBounds = true

        // ── Icon ─────────────────────────────────────────────────────────────
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.layer.cornerRadius = 3
        icon.clipsToBounds = true
        if let iconImage = nativeAd.icon?.image {
            icon.image = iconImage
            icon.isHidden = false
        } else {
            icon.isHidden = true
        }
        adView.iconView = icon

        // ── Headline ──────────────────────────────────────────────────────────
        let headline = UILabel()
        headline.text = nativeAd.headline
        headline.textColor = .white
        headline.font = UIFont.boldSystemFont(ofSize: 11)
        headline.numberOfLines = 1
        adView.headlineView = headline

        // ── CTA button ────────────────────────────────────────────────────────
        let cta = UIButton(type: .system)
        cta.setTitle(nativeAd.callToAction ?? "Learn More", for: .normal)
        cta.titleLabel?.font = UIFont.boldSystemFont(ofSize: 10)
        cta.backgroundColor = UIColor(red: 0.10, green: 0.32, blue: 0.47, alpha: 1.0)
        cta.setTitleColor(.white, for: .normal)
        cta.layer.cornerRadius = 4
        cta.isUserInteractionEnabled = false
        adView.callToActionView = cta

        // ── Layout ────────────────────────────────────────────────────────────
        for v in [mediaView, badge, icon, headline, cta] as [UIView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            adView.addSubview(v)
        }

        NSLayoutConstraint.activate([
            // Media fills top 60%
            mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.heightAnchor.constraint(equalTo: adView.heightAnchor, multiplier: 0.60),

            // Badge top-right of media
            badge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
            badge.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -4),
            badge.widthAnchor.constraint(equalToConstant: 22),
            badge.heightAnchor.constraint(equalToConstant: 14),

            // Icon left of headline
            icon.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 5),
            icon.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 6),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),

            // Headline beside icon
            headline.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            headline.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 4),
            headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -6),

            // CTA below headline
            cta.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 5),
            cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 6),
            cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -6),
            cta.heightAnchor.constraint(equalToConstant: 24),
        ])

        adView.nativeAd = nativeAd
        return adView
    }
}
