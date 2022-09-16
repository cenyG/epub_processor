part of epub_processor;

final _sep = Platform.pathSeparator;

class EpubProcessor {
  EpubProcessor._(
      {required this.epubPath, required this.dstDir, required this.tmpDir}) {
    epubPresenter = EpubPresenter(Metadata(), {}, [], dstDir);
  }

  String epubPath;
  String tmpDir;
  String dstDir;

  late EpubPresenter epubPresenter;

  static Future<EpubPresenter> process(
      {required String epubPath,
      required String dstDir,
      required String tmpDir,
      force = false}) async {
    if (!force) {
      final oldImport = await _checkOldImports(epubPath, dstDir);
      if (oldImport != null) return oldImport;
    }

    final zip = await File(epubPath).rename('$epubPath.zip');
    await extractFileToDisk(zip.path, tmpDir);
    zip.rename(epubPath);

    final processor =
        EpubProcessor._(epubPath: epubPath, dstDir: dstDir, tmpDir: tmpDir);

    await processor._loadMeta();
    await Future.wait([processor._parseHtmlFiles(), processor._copyContent()]);
    await processor._writeCheckSum();
    await processor._serializeJson();
    await processor._wipeUselessItems();

    return processor.epubPresenter;
  }

  static Future<EpubPresenter?> fromJson(String dstDir) {
    return _deserializeJson(dstDir);
  }

  static Future<EpubPresenter?> _checkOldImports(epubPath, dstDir) async {
    if (await Directory(dstDir).exists() &&
        await _checkSumEquals(epubPath, dstDir)) {
      return await _deserializeJson(dstDir);
    }
  }

  static Future<bool> _checkSumEquals(String epubPath, String dstDir) async {
    final checkSumFile = File('$dstDir/CHECK_SUM');
    if (!await checkSumFile.exists()) {
      return false;
    }

    final prevCheckSum = await checkSumFile.readAsString();
    final currentCheckSum = await getFileChecksum(File(epubPath));

    return prevCheckSum == currentCheckSum;
  }

  static Future<EpubPresenter?> _deserializeJson(String dstDir) async {
    final tmp = dstDir.split(_sep);
    final jsonName = '${tmp[tmp.length - 1]}.json';

    final jsonFile = File([dstDir, jsonName].join(_sep));
    if (!await jsonFile.exists()) {
      print('json file not exists');
      return null;
    }

    return EpubPresenter.fromJson(jsonDecode(await jsonFile.readAsString()));
  }

  _wipeUselessItems() {
    return Directory(tmpDir).delete(recursive: true);
  }

  _serializeJson() async {
    final tmp = dstDir.split(_sep);
    final jsonName = '${tmp[tmp.length - 1]}.json';

    final jsonFile =
        await File([dstDir, jsonName].join(_sep)).create(recursive: true);
    await jsonFile.writeAsString(jsonEncode(epubPresenter.toJson()));
  }

  _writeCheckSum() async {
    final checkSum = await getFileChecksum(File(epubPath));
    await File('$dstDir/CHECK_SUM').writeAsString(checkSum);
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
    epubPresenter.metadata = Metadata(
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
        epubPresenter.manifest[id] =
            ManifestItem(id: id, href: href, mediaType: mediaType);
      }
    }
  }

  _loadSpine(XmlElement? root) {
    if (root == null) throw Exception('no spine found');

    epubPresenter.spine = root.childElements.map((element) {
      final id = element.getAttribute('idref') ?? '';
      final linear = element.getAttribute('linear') ?? '';
      final properties = element.getAttribute('properties') ?? '';

      return SpineItem(id: id, linear: linear, properties: properties);
    }).toList();
  }

  Future _parseHtmlFiles() async {
    for (var element in epubPresenter.spine) {
      final contentLocalPath = epubPresenter.manifest[element.id]!.href;
      final contentFile = File('$tmpDir/$contentLocalPath');
      final content = await contentFile.readAsString();

      final resStr = HtmlParser.parseHtml(content, dstDir);
      final resultFile =
          await File('$dstDir/$contentLocalPath').create(recursive: true);
      resultFile.writeAsString(resStr);
    }
  }

  Future _copyContent() async {
    final hrefs = epubPresenter.manifest.values
        .where((e) => !e.href.endsWith('.html') && !e.href.endsWith('.xhtml'))
        .map((e) => e.href)
        .toList();

    await Future.forEach(hrefs, (href) async {
      final srcPath = '$tmpDir/$href';
      final dstPath = '$dstDir/$href';

      final dstFile = File(dstPath);
      if (!await dstFile.exists()) {
        await dstFile.create(recursive: true);
      }
      await File(srcPath).copy(dstPath);
    });
  }

  String _metaTagText(XmlElement root, String tag) =>
      root.findAllElements(tag).firstOrNull?.text ?? '';
}
