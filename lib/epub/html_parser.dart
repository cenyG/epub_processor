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
            final text = elem.text.replaceAll('\n', ' ');
            walker(text.length, [tag, text.length, text].join(':'));
          }
          break;
        case 'img':
          final href = elem.getAttribute('src') ?? '';
          walker(0, [tag, 0, href].join(':'));
          break;
        case 'p':
          var text = elem.text.replaceAll('\n', ' ').trim();
          text = '\t$text';
          walker(text.length, [tag, text.length, text].join(':'));
          break;
        default:
          final text = elem.text.replaceAll('\n', ' ').trim();
          walker(text.length, [tag, text.length, text].join(':'));
          break;
      }
    }
  }
}
