import 'dart:io';

import 'package:epub_processor/epub_processor.dart';
import 'package:test/test.dart';

final sep = Platform.pathSeparator;

void main() {
  final epubsPath = Directory(['test', 'epubs'].join(sep)).absolute.path;
  final epubs = ['1.epub', '2.epub', '3.epub'];

  test('with cache', () async {
    for (var epub in epubs) {
      final name = epub.split('.').first;

      final epubPath = [epubsPath, epub].join(sep);
      final tmpPath = [epubsPath, 'tmp', name].join(sep);
      final distPath = [epubsPath, 'gen', name].join(sep);

      final start = DateTime.now().millisecondsSinceEpoch;
      await EpubProcessor.process(
          epubPath: epubPath, dstDir: distPath, tmpDir: tmpPath);
      final end = DateTime.now().millisecondsSinceEpoch;

      print('Time to process: ${end - start}ms');
    }
  }, timeout: Timeout(Duration(hours: 5)));

  test('force', () async {
    for (var epub in epubs) {
      final name = epub.split('.').first;

      final epubPath = [epubsPath, epub].join(sep);
      final tmpPath = [epubsPath, 'tmp', name].join(sep);
      final distPath = [epubsPath, 'gen', name].join(sep);

      final start = DateTime.now().millisecondsSinceEpoch;
      await EpubProcessor.process(
          epubPath: epubPath, dstDir: distPath, tmpDir: tmpPath, force: true);
      final end = DateTime.now().millisecondsSinceEpoch;

      print('Time to process: ${end - start}ms');
    }
  }, timeout: Timeout(Duration(hours: 5)));

  test('from json', () async {
    for (var epub in epubs) {
      final name = epub.split('.').first;

      final distPath = [epubsPath, 'gen', name].join(sep);

      final start = DateTime.now().millisecondsSinceEpoch;
      await EpubProcessor.fromJson(distPath);
      final end = DateTime.now().millisecondsSinceEpoch;

      print('Time to process: ${end - start}ms');
    }
  }, timeout: Timeout(Duration(hours: 5)));
}
