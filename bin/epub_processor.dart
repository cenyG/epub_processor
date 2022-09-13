import 'package:epub_processor/epub_processor.dart';

void main() async {

  final epubPath = '../static/epubs/1.epub';
  final tmpPath = '../static/generated/tmp/1';
  final distPath = '../static/generated/1';

  final processor = await EpubProcessor.process(epubPath: epubPath, dstDir: distPath, tmpDir: tmpPath);
}
