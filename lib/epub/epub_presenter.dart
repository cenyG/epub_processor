part of epub_processor;

@JsonSerializable()
class EpubPresenter {
  EpubPresenter(this.metadata, this.manifest, this.spine, this.baseDir);

  Metadata metadata;
  Map<String, ManifestItem> manifest;
  List<SpineItem> spine;
  String baseDir;

  String getPath(String id) {
    return [baseDir, manifest[id]!.href].join(_sep);
  }

  factory EpubPresenter.fromJson(Map<String, dynamic> json) =>
      _$EpubPresenterFromJson(json);
  Map<String, dynamic> toJson() => _$EpubPresenterToJson(this);
}
