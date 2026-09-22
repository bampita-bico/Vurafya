String parseApiError(dynamic data, {String fallback = 'Request failed'}) {
  if (data == null) return fallback;
  if (data is String) return data;
  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is Map && first['msg'] != null) {
      return first['msg'].toString();
    }
  }
  if (data is Map) {
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
    if (data['message'] != null) return data['message'].toString();
  }
  return fallback;
}
