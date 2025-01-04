import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sentry/app/app.locator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SpeechServiceTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
