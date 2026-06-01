/// Thrown when Gemini parsing fails or returns invalid data.
class AiServiceException implements Exception {
  AiServiceException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AiServiceException: $message';
}
