part of epub_processor;

class TextLine {
  TextLine(this.tag, this.size, this.text, this.chapter);

  String tag;
  int size;
  String text;

  int chapter;
  late int index;
}

class EpubController {
  final EpubPresenter epubPresenter;

  late LinkedList chapters;
  late LinkedListIterator lineIteratorForward;
  late LinkedListIterator lineIteratorBackward;
  late Bookmark bookmark;

  EpubController({required this.epubPresenter});

  Future? prevChaptersLoading;
  Future? nextChaptersLoading;

  init() async {
    chapters = LinkedList();

    await _loadBookmark();

    await _chapterLines(bookmark.chapter).then((value) {
      if (value != null) chapters.append(value);
    });

    await _chapterLines(bookmark.chapter - 1).then((value) {
      if (value != null) chapters.unshift(value);
    });

    await _chapterLines(bookmark.chapter + 1).then((value) {
      if (value != null) chapters.append(value);
    });

    lineIteratorForward = chapters.iter.find(bookmark.chapter, bookmark.line);
    lineIteratorBackward = chapters.iter.find(bookmark.chapter, bookmark.line);
  }

  File get bookmarkFile {
    return File([epubPresenter.baseDir, 'bookmark.json'].join(sep));
  }

  TextLine value() {
    return lineIteratorForward.current();
  }

  Future<TextLine?> next() async {
    if (!lineIteratorForward.hasNextChapter && nextChaptersLoading == null) {
      nextChaptersLoading = _loadNextChapter().then((value) => nextChaptersLoading = null);
    }
    if (!lineIteratorForward.hasNext && nextChaptersLoading != null) {
      await nextChaptersLoading;
    }

    return lineIteratorForward.next();
  }

  Future<TextLine?> prev() async {
    if (!lineIteratorBackward.hasPrevChapter && prevChaptersLoading == null) {
      prevChaptersLoading = _loadPrevChapter().then((value) => prevChaptersLoading = null);
    }
    if (!lineIteratorBackward.hasPrev && prevChaptersLoading != null) {
      await prevChaptersLoading;
    }

    return lineIteratorBackward.prev();
  }

  saveBookmark(int chapter, int line, int symbol) {
    bookmark = Bookmark(chapter: chapter, line: line, symbol: symbol);

    EasyDebounce.debounce('save-bookmark', Duration(seconds: 2), () async {
      print('$bookmark saved');

      if (!await bookmarkFile.exists()) {
        await bookmarkFile.create(recursive: true);
      }
      bookmarkFile.writeAsString(json.encode(bookmark.toJson()));
    });
  }

  _loadBookmark() async {
    if (await bookmarkFile.exists()) {
      print('loading bookmars');
      bookmark = Bookmark.fromJson(await readJsonFile(bookmarkFile));
    } else {
      bookmark = Bookmark();
    }
  }

  Future _loadNextChapter() {
    final lastChapter = chapters.last!.value.first.chapter;
    return _chapterLines(lastChapter + 1).then((value) {
      if (value != null) chapters.append(value);
    });
  }

  Future _loadPrevChapter() {
    final firstChapter = chapters.first!.value.first.chapter;
    return _chapterLines(firstChapter - 1).then((value) {
      if (value != null) chapters.unshift(value);
    });
  }

  Future<List<TextLine>?> _chapterLines(int spineIndex) async {
    if (spineIndex < 0 || spineIndex > epubPresenter.spine.length - 1) {
      return null;
    }

    final spine = epubPresenter.spine[spineIndex];
    final href = epubPresenter.getPath(spine.id);

    final res = await File(href)
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
            final lastIndex = href.lastIndexOf(sep);
            final currentPath = href.substring(0, lastIndex);
            part3 = [currentPath, part3].join(sep);
          }

          return TextLine(part1, int.parse(part2), part3, spineIndex);
        })
        .toList()
        .then((list) {
          list.add(TextLine('end_chapter', 0, '', spineIndex));
          return list;
        });

    for (var i = 0; i < res.length; i++) {
      res[i].index = i;
    }

    return res;
  }
}
