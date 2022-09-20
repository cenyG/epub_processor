part of epub_processor;

@JsonSerializable()
class EpubPresenter {
  EpubPresenter(this.metadata, this.manifest, this.spine, this.baseDir);

  Metadata metadata;
  Map<String, ManifestItem> manifest;
  List<SpineItem> spine;
  String baseDir;

  int _size = 0;
  int get size => _size == 0 ? _size = spine.fold(0, (value, element) => element.size + value) : _size;

  String getPath(String id) {
    return [baseDir, manifest[id]!.href].join(sep);
  }

  factory EpubPresenter.fromJson(Map<String, dynamic> json) =>
      _$EpubPresenterFromJson(json);
  Map<String, dynamic> toJson() => _$EpubPresenterToJson(this);
}
