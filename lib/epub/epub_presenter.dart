part of epub_processor;

@JsonSerializable()
class EpubPresenter {
  EpubPresenter(this.metadata, this.manifest, this.spine);

  Metadata metadata;
  Map<String, ManifestItem> manifest;
  List<SpineItem> spine;

  factory EpubPresenter.fromJson(Map<String, dynamic> json) =>
      _$EpubPresenterFromJson(json);
  Map<String, dynamic> toJson() => _$EpubPresenterToJson(this);
}
