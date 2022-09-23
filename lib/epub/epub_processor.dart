part of epub_processor;

class EpubProcessor {
  EpubProcessor._({required this.epubPath, required this.dstDir, required this.tmpDir}) {
    epubPresenter = EpubPresenter(Metadata(), {}, [], dstDir);
  }

  String epubPath;
  String tmpDir;
  String dstDir;

  String contentDir = '';

  late EpubPresenter epubPresenter;

  static Future<EpubPresenter> process(
      {required String epubPath, required String dstDir, required String tmpDir, force = false, wipeTmp = true}) async {
    for (var element in [Directory(tmpDir), Directory(dstDir)]) {
      if (!element.existsSync()) {
        await element.create(recursive: true);
      }
    }

    if (!force) {
      final oldImport = await _checkOldImports(epubPath, dstDir);
      if (oldImport != null) return oldImport;
    }

    final zip = await File(epubPath).copy([dstDir, '${getRandomString(15)}.zip'].join(sep));
    await extractFileToDisk(zip.path, tmpDir);
    await zip.delete();

    final processor = EpubProcessor._(epubPath: epubPath, dstDir: dstDir, tmpDir: tmpDir);

    await processor._loadMeta();
    await Future.wait([processor._parseHtmlFiles(), processor._copyContent()]);
    await processor._writeCheckSum();
    await processor._serializeJson();
    if (wipeTmp) {
      await processor._wipeUselessItems();
    }

    return processor.epubPresenter;
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

    final tmpLastIndex = opfPath.lastIndexOf('/');
    if (tmpLastIndex > 0) {
      contentDir = opfPath.substring(0, tmpLastIndex);
      epubPresenter.contentDir = contentDir;
    }

    final opfFile = File('$tmpDir/$opfPath');
    if (!await opfFile.exists()) throw Exception('${opfFile.path} not exists');

    final opf = await opfFile.readAsString();
    final opfDocRoot = XmlDocument.parse(opf).root;

    _parseMatadata(opfDocRoot.findAllElements('metadata').firstOrNull);
    _parseManifest(opfDocRoot.findAllElements('manifest').firstOrNull);
    _parseSpine(opfDocRoot.findAllElements('spine').firstOrNull);
  }

  _parseMatadata(XmlElement? root) {
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

  _parseManifest(XmlElement? root) {
    if (root == null) throw Exception('no manifest found');

    for (var element in root.childElements) {
      final id = element.getAttribute('id');
      final href = element.getAttribute('href') ?? '';
      final mediaType = element.getAttribute('media-type') ?? '';

      if (id != null) {
        epubPresenter.manifest[id] = ManifestItem(id: id, href: href, mediaType: mediaType);
      }
    }
  }

  _parseSpine(XmlElement? root) {
    if (root == null) throw Exception('no spine found');

    epubPresenter.spine = root.childElements.map((element) {
      final id = element.getAttribute('idref') ?? '';
      final linear = element.getAttribute('linear') ?? '';
      final properties = element.getAttribute('properties') ?? '';

      return SpineItem(id: id, linear: linear, properties: properties);
    }).toList();
  }

  Future _parseHtmlFiles() async {
    List<Future> waitList = [];

    for (var element in epubPresenter.spine) {
      final contentLocalPath = epubPresenter.manifest[element.id]!.href;
      final contentFile = File([tmpDir, contentDir, contentLocalPath].where((element) => element.isNotEmpty).join(sep));
      final content = await contentFile.readAsString();

      final htmlInfo = HtmlParser.parseHtml(content);
      element.size = htmlInfo.size;

      final resultFile = await File([dstDir, contentDir, contentLocalPath].join(sep)).create(recursive: true);
      waitList.add(resultFile.writeAsString(htmlInfo.lines.toString()));
    }

    return Future.wait(waitList);
  }

  Future _copyContent() async {
    final hrefs = epubPresenter.manifest.values
        .where((e) => !e.href.endsWith('.html') && !e.href.endsWith('.xhtml'))
        .map((e) => e.href)
        .toList();

    await Future.forEach(hrefs, (href) async {
      final srcPath = [tmpDir, contentDir, href].where((element) => element.isNotEmpty).join(sep);
      final dstPath = [dstDir, contentDir, href].where((element) => element.isNotEmpty).join(sep);

      final dstFile = File(dstPath);
      if (!await dstFile.exists()) {
        await dstFile.create(recursive: true);
      }
      await File(srcPath).copy(dstPath);
    });
  }

  _wipeUselessItems() {
    return Directory(tmpDir).delete(recursive: true);
  }

  static Future<EpubPresenter?> _checkOldImports(epubPath, dstDir) async {
    if (await Directory(dstDir).exists() && await _checkSumEquals(epubPath, dstDir)) {
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

  static Future<EpubPresenter?> fromJson(String dstDir) {
    return _deserializeJson(dstDir);
  }

  _serializeJson() async {
    final bookName = dstDir.split(sep).last;
    final jsonName = '$bookName.json';

    final jsonFile = await File([dstDir, jsonName].join(sep)).create(recursive: true);
    await jsonFile.writeAsString(jsonEncode(epubPresenter.toJson()));
  }

  _writeCheckSum() async {
    final checkSum = await getFileChecksum(File(epubPath));
    await File('$dstDir/CHECK_SUM').writeAsString(checkSum);
  }

  static Future<EpubPresenter?> _deserializeJson(String dstDir) async {
    final bookName = dstDir.split(sep).last;
    final jsonName = '$bookName.json';

    final jsonFile = File([dstDir, jsonName].join(sep));
    if (!await jsonFile.exists()) {
      print('json file not exists');
      return null;
    }

    return EpubPresenter.fromJson(jsonDecode(await jsonFile.readAsString()));
  }

  String _metaTagText(XmlElement root, String tag) => root.findAllElements(tag).firstOrNull?.text ?? '';
}
