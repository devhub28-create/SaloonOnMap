import 'package:api_client/api_client.dart';

import '../network/admin_api_service.dart';

String adminErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is AdminApiException) return error.message;
  if (error is DioException) {
    final responseMessage = error.response?.data is Map
        ? (error.response?.data as Map)['message']
        : null;
    if (responseMessage is List && responseMessage.isNotEmpty) {
      return responseMessage.join(', ');
    }
    if (responseMessage != null &&
        responseMessage.toString().trim().isNotEmpty) {
      return responseMessage.toString();
    }
    switch (error.response?.statusCode) {
      case 400:
        return 'Some information is invalid. Review the form and try again.';
      case 401:
        return 'Your admin session has expired. Please sign in again.';
      case 403:
        return 'Your role does not have permission to perform this action.';
      case 404:
        return 'This feature is not available on the connected server.';
      case 409:
        return 'This change conflicts with newer platform data. Refresh and retry.';
      case 500:
      case 502:
      case 503:
        return 'The platform service is temporarily unavailable.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Unable to reach the platform service. Check the server connection.';
    }
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isNotEmpty && text.length <= 180 && !text.contains('DioException')) {
    return text;
  }
  return fallback;
}
