import AppIntents
import AVFoundation
import intelligence
import UIKit

@available(iOS 16, *)
struct ExampleAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Draw shape"
    static var openAppWhenRun: Bool = false // change to true if you want intent to open the app
    
    @Parameter(title: "Shape")
    var target: RepresentableEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        IntelligencePlugin.configureAudioSession() 
        IntelligencePlugin.extendAppLifetime()
        IntelligencePlugin.notifier.push(target.id)
        return .result()
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Draw \(\.$target)")
    }
}

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExampleAppIntent(),
            phrases: [
                "Draw a \(\.$target) in \(.applicationName)"
            ]
        )
    }
}