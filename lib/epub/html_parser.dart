part of epub_processor;

class HtmlInfo {
  int size = 0;
  StringBuffer lines = StringBuffer();
}

class HtmlParser {
  static HtmlInfo parseHtml(String htmlStr) {
    final document = XmlDocument.parse(htmlStr);
    final body = document.findAllElements('body').first;

    final htmlInfo = HtmlInfo();
    _parseLines(body.childElements, (size, str) {
      htmlInfo.lines.writeln(str);
      htmlInfo.size += size;
    });

    return htmlInfo;
  }

  static _parseLines(Iterable<XmlElement> xmlElements, Function(int size, String str) walker) {
    for (var elem in xmlElements) {
      final tag = elem.qualifiedName;

      switch (tag) {
        case 'div':
          if (elem.childElements.isNotEmpty) {
            _parseLines(elem.childElements, walker);
          } else {
            _defaultBehavior(elem, walker);
          }
          break;
        case 'ul':
          _parseLines(elem.childElements, walker);
          break;
        case 'img':
          final href = elem.getAttribute('src') ?? '';
          walker(0, [tag, 0, href].join(':'));
          break;
        case 'p':
          var text = elem.text.replaceAll(RegExp('(\r\n|\r|\n)'), ' ').trim();
          text = '\t$text';
          walker(text.length, [tag, text.length, text].join(':'));
          break;
        default:
          _defaultBehavior(elem, walker);
          break;
      }
    }
  }

  static _defaultBehavior(XmlElement elem, Function(int size, String str) walker) {
    final text = elem.text.replaceAll(RegExp('(\r\n|\r|\n)'), ' ').trim();
    walker(text.length, [elem.qualifiedName, text.length, text].join(':'));
  }
}
