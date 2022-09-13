import 'dart:io';

import 'package:epub_processor/epub_processor.dart';
import 'package:test/test.dart';

void main() {
  final epubsPath = Directory('test/epubs').absolute.path;
  final epubs = ['1.epub', '2.epub', '3.epub'];

  test('process', () async {
    for (var epub in epubs) {
      final name = epub.split('.').first;

      final epubPath = '$epubsPath/$epub';
      final tmpPath = '$epubsPath/tmp/$name';
      final distPath = '$epubsPath/gen/$name';

      final start = DateTime.now().millisecondsSinceEpoch;
      final processor = await EpubProcessor.process(
          epubPath: epubPath, dstDir: distPath, tmpDir: tmpPath);
      final end = DateTime.now().millisecondsSinceEpoch;

      print('Time to process: ${end - start}ms');
    }
  });
}
