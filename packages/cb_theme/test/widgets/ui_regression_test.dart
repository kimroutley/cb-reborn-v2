import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CBNeonBackground falls back to global background asset',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CBNeonBackground(
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image;

    expect(provider, isA<AssetImage>());
    expect(
      (provider as AssetImage).assetName,
      CBTheme.globalBackgroundAsset,
    );
  });

  testWidgets('CBRoleIDCard renders safely for every catalog role',
      (tester) async {
    for (final role in roleCatalog) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CBRoleIDCard(role: role),
          ),
        ),
      );

      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Role card should render without exceptions for ${role.id}',
      );
    }
  });

  testWidgets('CBGuideScreen renders all Club Bible tabs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CBGuideScreen(),
      ),
    );

    expect(find.text('MANUAL'), findsOneWidget);
    expect(find.text('OPERATIVES'), findsOneWidget);
    expect(find.text('INTEL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
