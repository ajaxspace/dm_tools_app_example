import 'dart:ui' as ui;

import 'package:dm_tools_app_example/ui/app_logo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app logo asset ships in the bundle and decodes as a square image',
      () async {
    final data = await rootBundle.load(AppLogo.assetName);
    expect(data.lengthInBytes, greaterThan(0));

    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();

    expect(frame.image.width, frame.image.height,
        reason: 'the logo must be square');
    expect(frame.image.width, 1024, reason: 'the master logo is 1024px');
  });
}
