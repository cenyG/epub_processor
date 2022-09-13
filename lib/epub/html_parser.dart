part of epub_processor;

class HtmlParser {
  static String parseHtml(String htmlStr) {
    final document = XmlDocument.parse(htmlStr);
    final body = document.findAllElements('body').first;

    final lines = _parseLines(body.childElements);

    return lines.join('\n');
  }

  static List<String> _parseLines(Iterable<XmlElement> xmlElements) {
    List<String> lines = [];

    for (var elem in xmlElements) {
      if (elem.qualifiedName == 'div') {
        if (elem.childElements.isNotEmpty) {
          lines.addAll(_parseLines(elem.childElements));
        } else {
          lines.add(['div', elem.text.replaceAll('\n', ' ')].join(':'));
        }
      } else if (elem.qualifiedName == 'img') {
        lines.add(['img', elem.getAttribute('src') ?? ''].join(':'));
      } else if (elem.qualifiedName == 'br') {
        lines.add(['br', ''].join(':'));
      } else {
        lines.add(
            [elem.qualifiedName, elem.text.replaceAll('\n', ' ')].join(':'));
      }
    }

    return lines;
  }
}
