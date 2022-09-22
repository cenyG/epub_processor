part of epub_processor;

class TextLine {
  TextLine(this.tag, this.size, this.text);

  String tag;
  int size;
  String text;
}

class EpubController {
  final EpubPresenter epubPresenter;

  int currentSpineIndex;
  int currentLineIndex;

  late List<TextLine> prevChapter;
  late List<TextLine> currentChapter;
  late List<TextLine> nextChapter;

  EpubController({required this.epubPresenter, this.currentSpineIndex = 0, this.currentLineIndex = 0});

  init() async {
    final currentSpine = epubPresenter.spine[currentSpineIndex];
    final currentLocation = epubPresenter.getPath(currentSpine.id);
    await _chapterLines(currentLocation).then((value) => currentChapter = value);

    await _loadPrevChapter();
    await _loadNextChapter();
  }

  TextLine value() {
    return currentChapter[currentLineIndex];
  }

  Future<TextLine?> next() async {
    final linesCount = currentChapter.length - 1;

    if (currentLineIndex == linesCount) {
      if (nextChapter.isEmpty) {
        return null;
      }
      prevChapter = currentChapter;
      currentChapter = nextChapter;
      currentSpineIndex = currentSpineIndex + 1;
      currentLineIndex = 0;
      await _loadNextChapter();
    } else {
      currentLineIndex++;
    }

    return currentChapter[currentLineIndex];
  }

  Future<TextLine?> prev() async {
    if (currentLineIndex == 0) {
      if (prevChapter.isEmpty) {
        return null;
      }
      nextChapter = currentChapter;
      currentChapter = prevChapter;
      currentSpineIndex = currentSpineIndex - 1;
      currentLineIndex = currentChapter.length;
      await _loadPrevChapter();
    } else {
      currentLineIndex--;
    }

    return currentChapter[currentLineIndex];
  }

  _loadNextChapter() {
    final chaptersCount = epubPresenter.spine.length;

    if (currentSpineIndex == chaptersCount - 1) {
      nextChapter = List.empty();
      return;
    }

    final nextSpine = epubPresenter.spine[currentSpineIndex + 1];
    final nextLocation = epubPresenter.getPath(nextSpine.id);

    return _chapterLines(nextLocation).then((value) => nextChapter = value);
  }

  _loadPrevChapter() {
    if (currentSpineIndex == 0) {
      prevChapter = List.empty();
      return;
    }

    final prevSpine = epubPresenter.spine[currentSpineIndex - 1];
    final prevLocation = epubPresenter.getPath(prevSpine.id);

    return _chapterLines(prevLocation).then((value) => prevChapter = value);
  }

  Future<List<TextLine>> _chapterLines(String chapterPath) {
    return File(chapterPath)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .where((str) => str.isNotEmpty)
        .map((line) {
          final firstIndex = line.indexOf(':');
          final secondIndex = line.indexOf(':', firstIndex + 1);

          final part1 = line.substring(0, firstIndex);
          final part2 = line.substring(firstIndex + 1, secondIndex);
          var part3 = line.substring(secondIndex + 1);

          if (part1 == 'img') {
            final lastIndex = chapterPath.lastIndexOf(sep);
            final currentPath = chapterPath.substring(0, lastIndex);
            part3 = [currentPath, part3].join(sep);
          }

          return TextLine(part1, int.parse(part2), part3);
        })
        .toList()
        .then((list) {
          list.add(TextLine('end_chapter', 0, ''));
          return list;
        });
  }
}
