part of epub_processor;

@JsonSerializable()
class Metadata {
  Metadata(
      {this.title = '',
      this.subject = '',
      this.creator = '',
      this.date = '',
      this.identifier = '',
      this.language = '',
      this.description = '',
      this.publisher = '',
      this.coverId = ''});

  String title;
  String subject;
  String creator;
  String date;
  String identifier;
  String language;
  String description;
  String publisher;
  String coverId;

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);
  Map<String, dynamic> toJson() => _$MetadataToJson(this);
}

@JsonSerializable()
class ManifestItem {
  ManifestItem({this.id = '', this.href = '', this.mediaType = ''});

  String id;
  String href;
  String mediaType;

  factory ManifestItem.fromJson(Map<String, dynamic> json) =>
      _$ManifestItemFromJson(json);
  Map<String, dynamic> toJson() => _$ManifestItemToJson(this);
}

@JsonSerializable()
class SpineItem {
  SpineItem({this.id = '', this.linear = '', this.properties = ''});

  String id;
  String linear;
  String properties;
  factory SpineItem.fromJson(Map<String, dynamic> json) =>
      _$SpineItemFromJson(json);
  Map<String, dynamic> toJson() => _$SpineItemToJson(this);
}
