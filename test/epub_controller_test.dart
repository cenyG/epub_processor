import 'dart:io';

import 'package:epub_processor/epub_processor.dart';
import 'package:test/test.dart';

final _sep = Platform.pathSeparator;

void main() {
  final epubsPath = Directory(['test', 'epubs'].join(_sep)).absolute.path;
  final epubs = ['1.epub'];

  test('controller', () async {
    for (var epub in epubs) {
      final name = epub.split('.').first;

      final epubPath = [epubsPath, epub].join(_sep);
      final tmpPath = [epubsPath, 'tmp', name].join(_sep);
      final distPath = [epubsPath, 'gen', name].join(_sep);

      final epubPresenter = await EpubProcessor.process(
          epubPath: epubPath, dstDir: distPath, tmpDir: tmpPath, force: true);

      final controller = EpubController(epubPresenter: epubPresenter);
      await controller.init();

      print(controller.value());

    }
  }, timeout: Timeout(Duration(hours: 5)));
}
