import AVFoundation
import Flutter
import UIKit
import UserNotifications
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, AVSpeechSynthesizerDelegate {
  private let ttsChannelName = "novelux/tts"
  private let mediaChannelName = "novelux/media_notification"
  private var ttsChannel: FlutterMethodChannel?
  private var mediaChannel: FlutterMethodChannel?
  private let speechSynthesizer = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "novelux_native_ad",
      nativeAdFactory: NativeAdFactoryImpl()
    )

    speechSynthesizer.delegate = self

    if let controller = window?.rootViewController as? FlutterViewController {
      ttsChannel = FlutterMethodChannel(name: ttsChannelName, binaryMessenger: controller.binaryMessenger)
      mediaChannel = FlutterMethodChannel(name: mediaChannelName, binaryMessenger: controller.binaryMessenger)
      setupTtsChannel()
      setupMediaChannel()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupTtsChannel() {
    ttsChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "speak":
        let args = call.arguments as? [String: Any] ?? [:]
        let text = args["text"] as? String ?? ""
        let speed = args["speed"] as? Double ?? 1.0
        let lang = args["lang"] as? String ?? "en-US"
        self.speak(text: text, speed: speed, lang: lang)
        result(nil)
      case "stop", "pause":
        self.stopSpeaking()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupMediaChannel() {
    mediaChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "play", "pause", "stop", "next", "previous", "seekTo", "show", "update", "hide":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func speak(text: String, speed: Double, lang: String) {
    guard !text.isEmpty else { return }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("TTS audio session setup failed: \(error)")
    }

    speechSynthesizer.stopSpeaking(at: .immediate)

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: lang)
    utterance.rate = min(max(Float(speed) * AVSpeechUtteranceDefaultSpeechRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
    utterance.pitchMultiplier = 1.0
    utterance.postUtteranceDelay = 0.0

    speechSynthesizer.speak(utterance)
  }

  private func stopSpeaking() {
    speechSynthesizer.stopSpeaking(at: .immediate)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    ttsChannel?.invokeMethod("onStart", arguments: nil)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    ttsChannel?.invokeMethod("onDone", arguments: nil)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    ttsChannel?.invokeMethod("onError", arguments: nil)
  }
}
