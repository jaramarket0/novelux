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
  // Utterance → id passed from Dart, echoed back in callbacks
  private var utteranceIds: [ObjectIdentifier: String] = [:]

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
        let pitch = args["pitch"] as? Double ?? 1.0
        let id = args["id"] as? String ?? "utterance"
        let voice = args["voice"] as? String
        self.speak(text: text, speed: speed, lang: lang, pitch: pitch, id: id, voiceId: voice)
        result(nil)
      case "getVoices":
        result(AVSpeechSynthesisVoice.speechVoices().map { v in
          ["name": v.identifier, "label": v.name, "locale": v.language,
           "network": false, "quality": v.quality == .enhanced ? 400 : 300]
        })
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

  private func speak(text: String, speed: Double, lang: String, pitch: Double = 1.0,
                     id: String = "utterance", voiceId: String? = nil) {
    guard !text.isEmpty else { return }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("TTS audio session setup failed: \(error)")
    }

    speechSynthesizer.stopSpeaking(at: .immediate)

    let utterance = AVSpeechUtterance(string: text)
    if let voiceId, let v = AVSpeechSynthesisVoice(identifier: voiceId) {
      utterance.voice = v
    } else {
      utterance.voice = AVSpeechSynthesisVoice(language: lang)
    }
    utterance.rate = min(max(Float(speed) * AVSpeechUtteranceDefaultSpeechRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
    utterance.pitchMultiplier = Float(min(max(pitch, 0.5), 2.0))
    utteranceIds[ObjectIdentifier(utterance)] = id
    utterance.postUtteranceDelay = 0.0

    speechSynthesizer.speak(utterance)
  }

  private func stopSpeaking() {
    speechSynthesizer.stopSpeaking(at: .immediate)
  }

  private func idFor(_ utterance: AVSpeechUtterance) -> String {
    utteranceIds[ObjectIdentifier(utterance)] ?? "utterance"
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    ttsChannel?.invokeMethod("onStart", arguments: ["id": idFor(utterance)])
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    let id = idFor(utterance)
    utteranceIds.removeValue(forKey: ObjectIdentifier(utterance))
    ttsChannel?.invokeMethod("onDone", arguments: ["id": id])
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    let id = idFor(utterance)
    utteranceIds.removeValue(forKey: ObjectIdentifier(utterance))
    ttsChannel?.invokeMethod("onError", arguments: ["id": id])
  }

  // Word being spoken, for highlighting
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange,
                         utterance: AVSpeechUtterance) {
    ttsChannel?.invokeMethod("onRange", arguments: [
      "id": idFor(utterance), "start": characterRange.location,
      "end": characterRange.location + characterRange.length,
    ])
  }
}
