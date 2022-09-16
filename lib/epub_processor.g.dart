// GENERATED CODE - DO NOT MODIFY BY HAND

part of epub_processor;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpubPresenter _$EpubPresenterFromJson(Map<String, dynamic> json) =>
    EpubPresenter(
      Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
      (json['manifest'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, ManifestItem.fromJson(e as Map<String, dynamic>)),
      ),
      (json['spine'] as List<dynamic>)
          .map((e) => SpineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EpubPresenterToJson(EpubPresenter instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'manifest': instance.manifest,
      'spine': instance.spine,
    };

Metadata _$MetadataFromJson(Map<String, dynamic> json) => Metadata(
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      creator: json['creator'] as String? ?? '',
      date: json['date'] as String? ?? '',
      identifier: json['identifier'] as String? ?? '',
      language: json['language'] as String? ?? '',
      description: json['description'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      coverId: json['coverId'] as String? ?? '',
    );

Map<String, dynamic> _$MetadataToJson(Metadata instance) => <String, dynamic>{
      'title': instance.title,
      'subject': instance.subject,
      'creator': instance.creator,
      'date': instance.date,
      'identifier': instance.identifier,
      'language': instance.language,
      'description': instance.description,
      'publisher': instance.publisher,
      'coverId': instance.coverId,
    };

ManifestItem _$ManifestItemFromJson(Map<String, dynamic> json) => ManifestItem(
      id: json['id'] as String? ?? '',
      href: json['href'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? '',
    );

Map<String, dynamic> _$ManifestItemToJson(ManifestItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'href': instance.href,
      'mediaType': instance.mediaType,
    };

SpineItem _$SpineItemFromJson(Map<String, dynamic> json) => SpineItem(
      id: json['id'] as String? ?? '',
      linear: json['linear'] as String? ?? '',
      properties: json['properties'] as String? ?? '',
    );

Map<String, dynamic> _$SpineItemToJson(SpineItem instance) => <String, dynamic>{
      'id': instance.id,
      'linear': instance.linear,
      'properties': instance.properties,
    };
