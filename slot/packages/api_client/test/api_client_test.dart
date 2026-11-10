import 'package:flutter_test/flutter_test.dart';

import 'package:api_client/api_client.dart';

void main() {
  test('accepts an explicit API base URL', () {
    final client = ApiClient(baseUrl: 'https://example.test/api/v1');
    expect(client.dio.options.baseUrl, 'https://example.test/api/v1');
  });
}
