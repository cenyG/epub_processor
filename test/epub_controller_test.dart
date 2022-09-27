import 'dart:io';

import 'package:epub_processor/epub_processor.dart';
import 'package:test/test.dart';

final sep = Platform.pathSeparator;

void main() {
  final epubsPath = Directory(['test', 'epubs'].join(sep)).absolute.path;
  final epubs = ['intelekt.epub'];

  test('controller', () async {
    for (var epub in epubs) {
      final name = epub.split('.').first;

      final epubPath = [epubsPath, epub].join(sep);
      final tmpPath = [epubsPath, 'tmp', name].join(sep);
      final distPath = [epubsPath, 'gen', name].join(sep);

      final EpubPresenter epubPresenter = await EpubProcessor.process(
          epubPath: epubPath, dstDir: distPath, tmpDir: tmpPath, force: true, wipeTmp: false);

      final controller = EpubController(epubPresenter: epubPresenter);
      await controller.init();

      var elem = await controller.next();
      do {
        if (elem!.tag != 'img') {
          assert(elem.size == elem.text.length);
        }
        elem = await controller.next();
      } while (elem != null);

      print(controller.value());
    }
  }, timeout: Timeout(Duration(hours: 5)));

  test('controller bookmark', () async {
    for (var epub in epubs) {
      final name = epub.split('.').first;

      final epubPath = [epubsPath, epub].join(sep);
      final tmpPath = [epubsPath, 'tmp', name].join(sep);
      final distPath = [epubsPath, 'gen', name].join(sep);

      final EpubPresenter epubPresenter = await EpubProcessor.process(
          epubPath: epubPath, dstDir: distPath, tmpDir: tmpPath, force: true, wipeTmp: false);

      final controller = EpubController(epubPresenter: epubPresenter);
      await controller.init();

      controller.saveBookmark(1, 1, 1);
      controller.saveBookmark(2, 2, 2);
      controller.saveBookmark(3, 3, 3);
      controller.saveBookmark(4, 4, 4);
      controller.saveBookmark(5, 5, 5);

      await Future.delayed(Duration(seconds: 10));
    }
  }, timeout: Timeout(Duration(hours: 5)));
}
