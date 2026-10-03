import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmovie/widgets/native_ad_panel.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('native panel fits $size and survives fullscreen', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adKey = GlobalKey();
      var fullscreen = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                body: Column(
                  children: [
                    const Expanded(child: SizedBox.expand()),
                    Flexible(
                      flex: fullscreen ? 0 : 1,
                      fit: FlexFit.tight,
                      child: Offstage(
                        offstage: fullscreen,
                        child: NativeAdPanel(child: SizedBox(key: adKey)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      final element = adKey.currentContext;
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(adKey)).width, lessThanOrEqualTo(560));
      expect(tester.getSize(find.byKey(adKey)).height, 360);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final value in [true, false, true, false]) {
        update(() => fullscreen = value);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(adKey.currentContext, same(element));
      }
    });
  }
}
