import 'package:flutter_test/flutter_test.dart';
import 'package:cb_theme/src/typography.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  test('CBTypography loads and has valid styles', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    // Check main text theme
    final theme = CBTypography.textTheme;
    expect(theme, isNotNull);

    // Check specific styles
    expect(theme.displayLarge, isNotNull);
    expect(theme.displayLarge!.fontFamily, contains('Roboto Condensed'));

    expect(theme.bodyLarge, isNotNull);
    expect(theme.bodyLarge!.fontFamily, contains('Roboto'));

    // Check special styles
    expect(CBTypography.code, isNotNull);
    expect(CBTypography.code.fontFamily, contains('Roboto'));

    expect(CBTypography.timer, isNotNull);
    expect(CBTypography.timer.fontFamily, contains('Roboto Condensed'));
    expect(CBTypography.timer.fontFeatures, isNotEmpty);
  });
}
