import AVFoundation
import AppIntents
import UIKit
import intelligence

@available(iOS 16, *)
struct ExampleAsyncAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Execute Custom Task"
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Action to Execute",
        requestValueDialog: "What specific action do you want to run?"
    )
    var task: String

    @MainActor
    func perform() async throws -> some IntentResult {
        IntelligencePlugin.configureAudioSession()
        IntelligencePlugin.extendAppLifetime()
        IntelligencePlugin.notifier.push(task)
        return .result()
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Execute: \(\ExampleAsyncAppIntent.$task)")
    }
}
