part of epub_processor;

class EpubProcessor {
  EpubProcessor._(
      {required this.epubPath, required this.dstDir, required this.tmpDir});

  String epubPath;
  String dstDir;
  String tmpDir;

  late Metadata metadata;
  final Map<String, ManifestItem> manifest = {};
  List<SpineItem> spine = [];

  static Future<EpubProcessor> process(
      {required String epubPath,
      required String dstDir,
      required String tmpDir}) async {
    final zip = await File(epubPath).rename('$epubPath.zip');
    await extractFileToDisk(zip.path, tmpDir);
    zip.rename(epubPath);

    final processor =
        EpubProcessor._(epubPath: epubPath, dstDir: dstDir, tmpDir: tmpDir);

    await processor._loadMeta();
    await Future.wait([processor._parseHtmlFiles(), processor._copyContent()]);

    return processor;
  }

  _loadMeta() async {
    final metaFile = File('$tmpDir/META-INF/container.xml');
    if (!await metaFile.exists()) {
      throw Exception('META-INF/container.xml not exists');
    }

    final meta = await metaFile.readAsString();
    final doc = html.parse(meta);
    final nodeRootfile = doc.querySelector('rootfile');
    if (nodeRootfile == null) {
      throw Exception('Wrong META-INF/container.xml format');
    }

    final opfPath = nodeRootfile.attributes['full-path'];
    if (opfPath == null) {
      throw Exception('Wrong opf no full-path attribute');
    }

    final opfFile = File('$tmpDir/$opfPath');
    if (!await opfFile.exists()) throw Exception('${opfFile.path} not exists');

    final opf = await opfFile.readAsString();
    final opfDocRoot = XmlDocument.parse(opf).root;

    _loadMatadata(opfDocRoot.findAllElements('metadata').firstOrNull);
    _loadManifest(opfDocRoot.findAllElements('manifest').firstOrNull);
    _loadSpine(opfDocRoot.findAllElements('spine').firstOrNull);

    await Directory(dstDir).create(recursive: true);
    await Future.wait([_parseHtmlFiles(), _copyContent()]);
  }

  _loadMatadata(XmlElement? root) {
    if (root == null) throw Exception('no metadata found');

    final coverId = root
        .findAllElements('meta')
        .where((element) {
          final name = element.getAttribute('name');
          return name == 'cover';
        })
        .firstOrNull
        ?.getAttribute('content');
    metadata = Metadata(
        title: _metaTagText(root, 'dc:title'),
        subject: _metaTagText(root, 'dc:subject'),
        creator: _metaTagText(root, 'dc:creator'),
        date: _metaTagText(root, 'dc:date'),
        identifier: _metaTagText(root, 'dc:identifier'),
        language: _metaTagText(root, 'dc:language'),
        description: _metaTagText(root, 'dc:description'),
        publisher: _metaTagText(root, 'dc:publisher'),
        coverId: coverId ?? '');
  }

  _loadManifest(XmlElement? root) {
    if (root == null) throw Exception('no manifest found');

    for (var element in root.childElements) {
      final id = element.getAttribute('id');
      final href = element.getAttribute('href') ?? '';
      final mediaType = element.getAttribute('media-type') ?? '';

      if (id != null) {
        manifest[id] = ManifestItem(id: id, href: href, mediaType: mediaType);
      }
    }
  }

  _loadSpine(XmlElement? root) {
    if (root == null) throw Exception('no spine found');

    spine = root.childElements.map((element) {
      final id = element.getAttribute('idref') ?? '';
      final linear = element.getAttribute('linear') ?? '';
      final properties = element.getAttribute('properties') ?? '';

      return SpineItem(id: id, linear: linear, properties: properties);
    }).toList();
  }

  Future _parseHtmlFiles() async {
    for (var element in spine) {
      final contentLocalPath = manifest[element.id]!.href;
      final contentFile = File('$tmpDir/$contentLocalPath');
      final content = await contentFile.readAsString();

      final resStr = HtmlParser.parseHtml(content);
      final resultFile =
          await File('$dstDir/$contentLocalPath').create(recursive: true);
      resultFile.writeAsString(resStr);
    }
  }

  Future _copyContent() async {
    final hrefs = manifest.values
        .where((e) => !e.href.endsWith('.html'))
        .map((e) => e.href)
        .toList();

    await Future.forEach(hrefs, (href) async {
      final srcPath = '$tmpDir/$href';
      final dstPath = '$dstDir/$href';

      final dstFile = File(dstPath);
      if (!await dstFile.exists()) {
        dstFile.create(recursive: true);
      }
      await File(srcPath).copy(dstPath);
    });
  }

  String _metaTagText(XmlElement root, String tag) =>
      root.findAllElements(tag).firstOrNull?.text ?? '';
}
