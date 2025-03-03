import Flutter
import UIKit
import AppIntents

/// Protocol for handling asynchronous operation results in AppIntents
public protocol AsyncOperationResult: IntentResult {
    var success: Bool { get }
    var message: String { get }
    
    static func success(_ message: String) -> Self
    static func failure(_ message: String) -> Self
}

/// Default implementation of AsyncOperationResult
public struct DefaultAsyncOperationResult: AsyncOperationResult {
    public let success: Bool
    public let message: String
    
    public static func success(_ message: String = "Operation completed successfully") -> Self {
        DefaultAsyncOperationResult(success: true, message: message)
    }
    
    public static func failure(_ message: String = "Operation failed") -> Self {
        DefaultAsyncOperationResult(success: false, message: message)
    }
    
    public func result() -> IntentResult {
        return .result()
    }
}

public class IntelligencePlugin: NSObject, FlutterPlugin {
  public static let notifier = SelectionsPushOnlyStreamHandler()
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "intelligence", binaryMessenger: registrar.messenger())
    let instance = IntelligencePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(name: "intelligence/links", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(notifier)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "populate":
      handlePopulate(call, result: result)
    case "operationResult":
      handleOperationResult(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  func handleOperationResult(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if let args = call.arguments as? [String: Any],
       let success = args["success"] as? Bool,
       let message = args["message"] as? String {
        IntelligencePlugin.notifier.handleOperationResult(success: success, message: message)
        result(true)
    } else {
        result(FlutterError(
            code: "INVALID_OPERATION_RESULT",
            message: "Invalid operation result arguments",
            details: nil
        ))
    }
  }
  
  func handlePopulate(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      if let args = call.arguments as? String {
        let populateArgument = try JSONDecoder().decode(PopulateArgument.self, from: Data(args.utf8))
        let storageItems = populateArgument.items.map() { item in
          return item.forStorage()
        }
        IntelligencePlugin.storage.set(items: storageItems)
        if #available(iOS 18.0, *) {
          IntelligencePlugin.spotlightCore.index(items: storageItems)
        }
        result(true)
      }
    } catch {
      result(FlutterError(
        code: "POPULATE_ARGUMENT_PARSING",
        message: ".populate called with missing or malformed argument",
        details: nil
      ))
    }
  }
  
  public static let storage = IntelligenceStorage()
  @available(iOS 18.0, *)
  public static let spotlightCore = IntelligenceSearchableItems()
}

struct PopulateArgument: Decodable {
  let items: [PopulateItem]
}

struct PopulateItem: Decodable {
  let id: String;
  let representation: String;
  
  func forStorage() -> IntelligenceItem {
    return (id: id, representation: representation)
  }
}

public class SelectionsPushOnlyStreamHandler: NSObject, FlutterStreamHandler {
  var sink: FlutterEventSink?
  var resultHandler: ((Bool, String) -> Void)?
  var selectionsBuffer: [String] = []
  
  public func push(_ selection: String) {
    selectionsBuffer.append(selection)
    if let sink {
      flushSelectionsBuffer(sink)
    }
  }
  
  public func handleOperationResult(success: Bool, message: String) {
    resultHandler?(success, message)
    resultHandler = nil  // Clear the handler after use
  }
  
  public func setResultHandler(_ handler: @escaping (Bool, String) -> Void) {
    self.resultHandler = handler
  }
  
  func flushSelectionsBuffer(_ sink: FlutterEventSink) {
    for link in selectionsBuffer {
      sink(link)
    }
    selectionsBuffer = []
  }
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    flushSelectionsBuffer(events)
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
