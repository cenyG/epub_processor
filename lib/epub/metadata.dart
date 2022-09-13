part of epub_processor;

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
}

class ManifestItem {
  ManifestItem({this.id = '', this.href = '', this.mediaType = ''});

  String id;
  String href;
  String mediaType;
}

class SpineItem {
  SpineItem({this.id = '', this.linear = '', this.properties = ''});

  String id;
  String linear;
  String properties;
}