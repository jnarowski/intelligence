import 'package:intelligence/model/representable.dart';

import 'intelligence_platform_interface.dart';

/// Result of an asynchronous operation triggered by AppIntents
class OperationResult {
  final bool success;
  final String message;

  const OperationResult({required this.success, required this.message});
}

/// Facilitates communication between your Dart and native layers.
class Intelligence {
  /// Informs the OS about entities available in your application.
  Future<void> populate(List<Representable> items) =>
      IntelligencePlatform.instance.populate(items);

  /// Feeds back the id's of entities selected by the user
  /// in OS flows to the Dart layer.
  Stream<String> selectionsStream() =>
      IntelligencePlatform.instance.selectionsStream();

  /// Sends the result of an asynchronous operation back to AppIntents.
  ///
  /// This should be called in response to an AppIntent that triggered
  /// an asynchronous operation in your app. The result will be reflected
  /// in the Shortcuts app or Siri response.
  ///
  /// Example:
  /// ```dart
  /// void _handleSelection(String id) async {
  ///   try {
  ///     await performAsyncOperation(id);
  ///     await Intelligence().sendOperationResult(
  ///       success: true,
  ///       message: 'Operation completed successfully'
  ///     );
  ///   } catch (e) {
  ///     await Intelligence().sendOperationResult(
  ///       success: false,
  ///       message: e.toString()
  ///     );
  ///   }
  /// }
  /// ```
  Future<void> sendOperationResult({
    required bool success,
    required String message,
  }) => IntelligencePlatform.instance.sendOperationResult(
    success: success,
    message: message,
  );
}
