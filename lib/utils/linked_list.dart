import 'package:epub_processor/epub_processor.dart';

class Node<T> {
  Node({required this.value, this.prev, this.next});

  T value;
  Node<T>? next;
  Node<T>? prev;
}

class LinkedListIterator {
  Node<List<TextLine>> currentChapter;
  int currentLineIndex;

  LinkedListIterator({required this.currentChapter, this.currentLineIndex = 0});

  bool get hasNextChapter {
    return currentChapter.next != null;
  }

  bool get hasPrevChapter {
    return currentChapter.prev != null;
  }

  bool get hasNext {
    return currentLineIndex < currentChapter.value.length - 1;
  }

  bool get hasPrev {
    return currentLineIndex > 0;
  }

  Node<List<TextLine>> nextChaper() {
    if (hasNextChapter) {
      currentChapter = currentChapter.next!;
      return currentChapter;
    } else {
      throw Exception('end of chaperts next');
    }
  }

  Node<List<TextLine>> prevChaper() {
    if (hasPrevChapter) {
      currentChapter = currentChapter.prev!;
      return currentChapter;
    } else {
      throw Exception('end of chaperts prev');
    }
  }

  TextLine? next() {
    if (hasNext) {
      currentLineIndex++;
    } else if (hasNextChapter) {
      currentChapter = currentChapter.next!;
      currentLineIndex = 0;
    } else {
      return null;
    }

    return currentChapter.value[currentLineIndex];
  }

  TextLine? prev() {
    if (hasPrev) {
      currentLineIndex--;
    } else if (hasPrevChapter) {
      currentChapter = currentChapter.prev!;
      currentLineIndex = currentChapter.value.length - 1;
    } else {
      return null;
    }

    return currentChapter.value[currentLineIndex];
  }

  TextLine current() {
    return currentChapter.value[currentLineIndex];
  }

  LinkedListIterator find(int chapter, int line) {
    if (currentChapter.value.first.chapter != chapter) {
      final incr = chapter > currentChapter.value.first.chapter ? nextChaper : prevChaper;
      do {
        incr();
      } while (currentChapter.value.first.chapter != chapter);
    }
    currentLineIndex = line;
    return this;
  }
}

class LinkedList {
  Node<List<TextLine>>? first;
  Node<List<TextLine>>? last;

  int length = 0;

  _checkEmpty(List<TextLine> val) {
    if (last == null) {
      first = Node(value: val);
      last = first;
      return true;
    }

    return false;
  }

  append(List<TextLine> val) {
    if (!_checkEmpty(val)) {
      final newLast = Node(value: val, prev: last);
      last!.next = newLast;
      last = newLast;
    }
  }

  unshift(List<TextLine> val) {
    if (!_checkEmpty(val)) {
      final newFirst = Node(value: val, next: first);
      first!.prev = newFirst;
      first = newFirst;
    }
  }

  LinkedListIterator get iter {
    if (first == null) {
      throw Exception('empty list');
    }
    return LinkedListIterator(currentChapter: first!);
  }
}
