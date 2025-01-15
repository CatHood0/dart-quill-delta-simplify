import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Represents the result of a successful build from the [QueryDelta] class.
/// This class contains the resulting [Delta] and optionally an error message
/// if the build process encountered an issue.
///
/// The [BuildResult] class is used to return the final [Delta] after applying
/// all conditions and modifications defined in a [QueryDelta].
class BuildResult {
  /// The resulting [Delta] after applying conditions and modifications.
  final Delta delta;

  /// An optional error message. If present, it indicates that an error occurred
  /// during the build process. This can be `null` if the build was successful.
  final String? error;

  BuildResult({
    required this.delta,
    this.error,
  });
}
