import AppIntents
import intelligence

@available(iOS 16.0, *)
struct AsyncOperationIntent: AppIntent {
    static var title: LocalizedStringResource = "Perform Async Operation"
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Operation ID")
    var operationId: String
    
    @MainActor
    func perform() async throws -> DefaultAsyncOperationResult {
        return try await withCheckedThrowingContinuation { continuation in
            // Set up a timeout
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                continuation.resume(returning: .failure("Operation timed out"))
            }
            
            // Push the operation to Flutter and wait for result
            IntelligencePlugin.notifier.setResultHandler { success, message in
                if success {
                    continuation.resume(returning: .success(message))
                } else {
                    continuation.resume(returning: .failure(message))
                }
            }
            
            // Trigger the operation in Flutter
            IntelligencePlugin.notifier.push(operationId)
        }
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Perform operation \(\.$operationId)")
    }
}

struct AsyncOperationShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AsyncOperationIntent(),
            phrases: [
                "Run operation \(\.$operationId) in \(.applicationName)"
            ]
        )
    }
} 