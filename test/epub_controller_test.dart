import 'dart:io';

import 'package:epub_processor/epub_processor.dart';
import 'package:test/test.dart';

final sep = Platform.pathSeparator;

void main() {
  final epubsPath = Directory(['test', 'epubs'].join(sep)).absolute.path;
  final epubs = ['molek.epub'];

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

      for (var element in controller.currentChapter) {
        if (element.tag != 'img') {
          assert(element.size == element.text.length);
        }
      }

      for (var element in controller.nextChapter) {
        if (element.tag != 'img') {
          assert(element.size == element.text.length);
        }
      }

      print(controller.value());
    }
  }, timeout: Timeout(Duration(hours: 5)));
}
