import AVFoundation
import Flutter
import UIKit

public class IntelligencePlugin: NSObject, FlutterPlugin {
  public static let notifier = SelectionsPushOnlyStreamHandler()

  private let speechSynthesizer = AVSpeechSynthesizer()

  public static func extendAppLifetime() {
    if UIApplication.shared.applicationState == .active {
      return
    }
    let application = UIApplication.shared
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    backgroundTask = application.beginBackgroundTask(withName: "ExtendAppLife") {
      print("⏳ Background task time expired. Ending task.")
      application.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }

    DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
      print("✅ App stayed alive for 30 seconds. Ending background task.")
      application.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }
  }

  public static func configureAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()

    // Check if the session is already configured
    if audioSession.category == .playback && audioSession.mode == .spokenAudio {
      print("⚠️ Audio session is already configured. Skipping setup.")
      return
    }

    do {
      try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try audioSession.setActive(true)
    } catch {
      print("❌ Failed to configure audio session: \(error.localizedDescription)")
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "intelligence", binaryMessenger: registrar.messenger())
    let instance = IntelligencePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(
      name: "intelligence/links", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(notifier)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "populate":
      handlePopulate(call, result: result)
    case "backgroundResponse":
      handleBackgroundResponse(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func handlePopulate(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      if let args = call.arguments as? String {
        let populateArgument = try JSONDecoder().decode(
          PopulateArgument.self, from: Data(args.utf8))
        let storageItems = populateArgument.items.map { item in
          return item.forStorage()
        }
        IntelligencePlugin.storage.set(items: storageItems)
        if #available(iOS 18.0, *) {
          IntelligencePlugin.spotlightCore.index(items: storageItems)
        }
        result(true)
      }
    } catch {
      result(
        FlutterError(
          code: "POPULATE_ARGUMENT_PARSING",
          message: ".populate called with missing or malformed argument",
          details: nil
        ))
    }
  }

  func handleBackgroundResponse(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if UIApplication.shared.applicationState == .active {
      return
    }
    print("📢 `backgroundResponse` method was called!")

    if let message = call.arguments as? String {
      print("Voiceover will speak: \(message)")

      let utterance = AVSpeechUtterance(string: message)
      utterance.voice = AVSpeechSynthesisVoice(
        identifier: "com.apple.ttsbundle.siri_female_en-US_compact")

      do {
        try speakUtterance(utterance)  // ✅ Voiceover will speak only in background буде говорити тільки у background
        print("📢 Voiceover is speaking (Background Mode)")

        result(true)
      } catch {
        print("❌ Speech synthesis failed: \(error.localizedDescription)")
        result(
          FlutterError(
            code: "SPEECH_SYNTHESIS_ERROR", message: "Failed to synthesize speech",
            details: error.localizedDescription))
      }
    } else {
      print("📢 `backgroundResponse` method was called else")
      result(
        FlutterError(code: "INVALID_ARGUMENT", message: "Argument must be a string", details: nil))
    }
  }

  func speakUtterance(_ utterance: AVSpeechUtterance) throws {
    guard AVSpeechSynthesizer().isSpeaking == false else {
      throw NSError(
        domain: "SpeechError", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Voiceover is already speaking."])
    }

    self.speechSynthesizer.speak(utterance)
  }

  public static let storage = IntelligenceStorage()
  @available(iOS 18.0, *)
  public static let spotlightCore = IntelligenceSearchableItems()
}

struct PopulateArgument: Decodable {
  let items: [PopulateItem]
}

struct PopulateItem: Decodable {
  let id: String
  let representation: String

  func forStorage() -> IntelligenceItem {
    return (id: id, representation: representation)
  }
}

public class SelectionsPushOnlyStreamHandler: NSObject, FlutterStreamHandler {
  var sink: FlutterEventSink?
  var selectionsBuffer: [String] = []

  public func push(_ selection: String) {
    selectionsBuffer.append(selection)
    if let sink = sink {
      flushSelectionsBuffer(sink)
    }
  }

  func flushSelectionsBuffer(_ sink: FlutterEventSink) {
    for link in selectionsBuffer {
      sink(link)
    }
    selectionsBuffer = []
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    flushSelectionsBuffer(events)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
