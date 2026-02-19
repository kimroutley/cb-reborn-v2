import 'package:cb_theme/cb_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core audio warmup count is non-zero', () {
    expect(SoundService.coreAudioWarmupUnitCount, greaterThan(0));
  });

  test('core audio warmup completes without throwing', () async {
    await SoundService.warmupCoreAudioAssets();
  });
}
