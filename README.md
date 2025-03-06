# Intelligence

[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](.)
<img src="https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/monterail_logo.svg" alt="Monterail's logo" width="25%" height="100" align="right"/>

Add support for Apple's AppIntents framework to your Flutter application. For details on how to add integration with Siri, Shortcuts app, and Apple Intelligence, see [Recipes](#recipes).

## Installation

Copy and paste the following snippet into your shell when in the target project directory.

```shell
dart pub add intelligence
```

## Usage

To add support for AppIntents framework, you will have to perform one-time setup which differs for different use-cases. See [Recipes](#recipes) for more details.

### iOS Configuration

After installing the package, you need to set the minimum iOS version to 16.0 on XCode.

For more details, follow these steps:

<details>

- Open the iOS project in Xcode

  <img src="https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/recipe1/open_in_xcode.jpg" alt="Open in Xcode" width="60%" />

- Click on Runner & then general tab

  ![Runner & general tab](https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/readme/runner_general_xcode.png)

- Under the General tab & minimum deployments section, set the iOS version to atleast 16.0
  ![iOS version](https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/readme/ios_version.png)

</details>

<br />

Once set up, the plugin will let you act on each App Intent trigger.

E.g. while setting the selection listener in a Stateful widget:

```dart
Intelligence().selectionsStream().listen(_handleSelection);
```

> Note: the `Intelligence` class behaves like a singleton, so you do not have to maintain the same class instance throughout the app/use-case.

## Recipes

List of practical applications of `intelligence` in your project. Click the `Details` dropdown to see the implementation.

### Allow the Shortcuts app to open a specific page in your application

Will let your app to be automated via Shortcuts workflow.

<details>

- Open the iOS project in Xcode

<img src="https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/recipe1/open_in_xcode.jpg" alt="Open in Xcode" width="60%" />

- Add a new Swift file and paste:

```swift
import AppIntents
import intelligence

struct OpenHeartIntent: AppIntent {
  static var title: LocalizedStringResource = "Draw a Heart"
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    IntelligencePlugin.notifier.push("heart")
    return .result()
  }
}
```

Switch out the struct's name, title, and the `.push`ed value to ones that match your use-case.

Once added, your App Intent will show up in the Shortcuts app:

<img src="https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/recipe1/draw_intent.jpeg" alt="Example of a Shortcuts app workflow including an automation step declared in this guide" width="60%" />

</details>

#### Optionally: Add a Siri voice shortcut to for the App Intent

<details>

To trigger the App Intent declared above by speaking a specific phrase to Siri, append:

```swift
struct OpenHeartShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ExampleAppIntent(),
      phrases: [
        "Draw my favorite shape in \(.applicationName)"
      ]
    )
  }
}
```

Once deployed to the device, Siri can understand the trigger phrase and run the App Intent declared above:

<img src="https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/recipe1/siri_command.jpeg" alt="Siri's response to a query 'What can Intelligence do?' including defined phrase to run the App Intent declared in this guide" width="60%" />

</details>

### Let Siri open a specific entity from your app domain

Siri is capable of understanding the entities your application revolves around, letting you implement App Intents with variables.

See full implementation in the [example project](./example/).

<details>

- Define an `AppEntity`. It should contain a unique identifier and a text representation fields, as follows:

```swift
import CoreSpotlight
import AppIntents

struct RepresentableEntity: AppEntity {
  static var defaultQuery: RepresentableQuery = RepresentableQuery()
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Shape")

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(stringLiteral: representation)
  }

  let id: String
  let representation: String
}

extension RepresentableEntity: IndexedEntity {
  var attributeSet: CSSearchableItemAttributeSet {
    let attributes = CSSearchableItemAttributeSet()
    attributes.displayName = self.representation
    return attributes
  }
}
```

- Create a matching `EntityQuery`, like so:

```swift
import AppIntents
import intelligence

struct RepresentableQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [RepresentableEntity] {
    return IntelligencePlugin.storage.get(for: identifiers).map() { item in
      return RepresentableEntity(
        id: item.id,
        representation: item.representation
      )
    }
  }

  func suggestedEntities() async throws -> [RepresentableEntity] {
    return IntelligencePlugin.storage.get().map() { item in
      return RepresentableEntity(
        id: item.id,
        representation: item.representation
      )
    }
  }
}

extension RepresentableQuery: EnumerableEntityQuery {
  func allEntities() async throws -> [RepresentableEntity] {
    return IntelligencePlugin.storage.get().map() { item in
      return RepresentableEntity(
        id: item.id,
        representation: item.representation
      )
    }
  }
}
```

- Create an `AppIntent` using the entity as a parameter.

```swift
import AppIntents
import intelligence

struct ExampleAppIntent: AppIntent {
  static var title: LocalizedStringResource = "Draw shape"
  static var openAppWhenRun: Bool = true

  @Parameter(title: "Shape")
  var target: RepresentableEntity

  @MainActor
  func perform() async throws -> some IntentResult {
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

```

- In your `AppDelegate` file, add the following code to the `didFinishLaunchingWithOptions` method:

```swift
  IntelligencePlugin.storage.attachListener {
    AppShortcuts.updateAppShortcutParameters()
  }
  if #available(iOS 18.0, *) {
    IntelligencePlugin.spotlightCore.attachEntityMapper() { item in
      return RepresentableEntity(
        id: item.id,
        representation: item.representation
      )
    }
  }
```

- In your Dart code, use the `.populate` method to let the operating system know about the entities available in your app:

```dart
await IntelligencePlugin().populate(const [
  Representable(representation: 'Heart', id: 'heart'),
  Representable(representation: 'Circle', id: 'circle'),
  Representable(representation: 'Rectangle', id: 'rectangle'),
  Representable(representation: 'Triangle', id: 'triangle'),
]);
```

> Note: each call to `.populate` overwrites previous entities. Call `.populate([])` once the entities are not accessible anymore, e.g. after a logout.

Result:

![Siri query usage example](https://raw.githubusercontent.com/monterail/intelligence/main/doc/assets/recipe2/query_example.png)

</details>

### Long-Running tasks and Background Responses

Will let your app to provide voiceover responses for long-running intents.

<details>

- Add background capabilities, microphone permissions, Siri usage and Speech Recognition to your app to be able to receive voice responses

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for audio playback.</string>
<key>NSSiriUsageDescription</key>
<string>We need Siri access to interact with voice commands.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to process spoken commands.</string>
```

- Request user to allow microfon access

in pubspec.yaml add permission handling library

```yaml
permission_handler: ^11.4.0
```

example of asking permissions in your app

```dart
class _MyAppState extends State<MyApp> {
  final _intelligencePlugin = Intelligence();
  final _receivedItems = [];

  @override
  void initState() {
    super.initState();
    unawaited(requestPermissions());
    unawaited(init());
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.speech,
    ].request();

    if (statuses[Permission.microphone]!.isDenied ||
        statuses[Permission.speech]!.isDenied) {
      debugPrint("❌ Permissions denied!");
    } else {
      debugPrint("✅ Permissions granted!");
    }
  }
```

- Add voice initialisation to your Intent

In your AppIntent add methods to configure audio session and long-running task

```swift
 @MainActor
    func perform() async throws -> some IntentResult {
        IntelligencePlugin.configureAudioSession() // audio session
        IntelligencePlugin.extendAppLifetime() // extending app lifetime

```

- Example usage

> ⚠️ **Caution:**  
> To ensure voiceover response, your intent must be runnable in the background,  
> otherwise, voiceover won't work.
>
> Be sure the property in your Swift intent is set as below:

```dart
static var openAppWhenRun: Bool = false
```

In `_intelligencePlugin.selectionsStream().listen(_handlerFunction)`, in your `_handlerFunction`
add `_intelligencePlugin.backgroundResponse("response")`

```dart

  void _handleSelection(String taskId) {
    /* replace timer with your long running implementation
    and pass the message to backgroundResponse method
    max await time is 30 seconds */
    Timer(Duration(seconds: 5), () async {
      bool isSuccess = Random().nextBool();
      String statusMessage = isSuccess
          ? "✅ Task $taskId successfully completed"
          : "❌ Task $taskId failed";
      _intelligencePlugin.backgroundResponse(statusMessage);
    });
  }

 _intelligencePlugin.selectionsStream().listen(_handlerFunction);

```

- To use long-running intent in Example, trigger it with following phrases:

```swift
Execute a task in \(.applicationName)
Run a command using \(.applicationName)
Tell \(.applicationName) to do something
Start an action in \(.applicationName)
```

</details>

## Further reading

- [Apple's App Intents docs](https://developer.apple.com/documentation/appintents/)
- [Advanced `intelligence` use-cases](https://www.monterail.com/blog/flutter-development-services-OS-integration)
