part of epub_processor;

class Line {
  Line(this.tag, this.text);

  String tag;
  String text;
}

class EpubController {
  final EpubPresenter epubPresenter;

  int currentSpineIndex;
  int currentLineIndex;

  late List<Line> prevChapter;
  late List<Line> currentChapter;
  late List<Line> nextChapter;

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

  Line value() {
    return currentChapter[currentLineIndex];
  }

  Line? next() {
    final linesCount = currentChapter.length - 1;

    if (currentLineIndex == linesCount) {
      if (nextChapter.isEmpty) {
        return null;
      }
      prevChapter = currentChapter;
      currentChapter = nextChapter;
      currentSpineIndex = currentSpineIndex + 1;
      currentLineIndex = 0;
      _loadNextChapter();
    } else {
      currentLineIndex++;
    }

    return currentChapter[currentLineIndex];
  }

  Line? prev() {
    if (currentLineIndex == 0) {
      if (prevChapter.isEmpty) {
        return null;
      }
      nextChapter = currentChapter;
      currentChapter = prevChapter;
      currentSpineIndex = currentSpineIndex - 1;
      currentLineIndex = currentChapter.length;
      _loadPrevChapter();
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

  Future<List<Line>> _lines(String path) {
    return File(path)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .map((line) {
      final div = line.indexOf(':');
      return Line(line.substring(0, div), line.substring(div + 1));
    }).toList();
  }
}
