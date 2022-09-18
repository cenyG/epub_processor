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

  EpubController(
      {required this.epubPresenter,
      this.currentSpineIndex = 0,
      this.currentLineIndex = 0});

  init() async {
    final currentSpine = epubPresenter.spine[currentSpineIndex];
    final currentLocation = epubPresenter.getPath(currentSpine.id);
    await _lines(currentLocation).then((value) => currentChapter = value);

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

    return _lines(nextLocation).then((value) => nextChapter = value);
  }

  _loadPrevChapter() {
    if (currentSpineIndex == 0) {
      prevChapter = List.empty();
      return;
    }

    final prevSpine = epubPresenter.spine[currentSpineIndex - 1];
    final prevLocation = epubPresenter.getPath(prevSpine.id);

    return _lines(prevLocation).then((value) => prevChapter = value);
  }

  Future<List<TextLine>> _lines(String path) {
    return File(path)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .map((line) {
      final parts = line.split(':');
      return TextLine(parts[0], int.parse(parts[1]), parts[2]);
    }).toList();
  }
}
