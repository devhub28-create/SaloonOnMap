import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  test('AppColors brand constants are set', () {
    expect(AppColors.primaryGold, isNotNull);
    expect(AppColors.darkNeutral, isNotNull);
  });
}
