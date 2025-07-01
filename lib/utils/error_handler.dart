class ErrorHandler {
  static String getReadableError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('429')) {
      return 'Too many requests. Please wait a moment and try again.';
    } else if (errorStr.contains('401') || errorStr.contains('403')) {
      return 'Please log in to Spotify again.';
    } else if (errorStr.contains('network') || errorStr.contains('socket')) {
      return 'Please check your internet connection and try again.';
    } else if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorStr.contains('billboard')) {
      return 'Unable to load Billboard chart. The date may not be available.';
    } else if (errorStr.contains('spotify')) {
      return 'Spotify service temporarily unavailable. Please try again.';
    }
    return 'Something went wrong. Please try again later.';
  }
}
