import AppIntents
import intelligence

@available(iOS 16, *)
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: ExampleAppIntent(),
                phrases: [
                    "Draw a \(\.$target) in \(.applicationName)"
                ]
            ),
            AppShortcut(
                intent: ExampleAsyncAppIntent(),
                phrases: [
                    "Execute a task in \(.applicationName)",
                    "Run a command using \(.applicationName)",
                    "Tell \(.applicationName) to do something",
                    "Start an action in \(.applicationName)",
                ]
            ),
        ]
    }
}
