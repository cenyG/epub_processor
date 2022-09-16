library epub_processor;

import 'dart:io';
import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:epub_processor/utils/files.dart';
import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'epub_processor.g.dart';
part 'epub/epub_controller.dart';
part 'epub/epub_processor.dart';
part 'epub/epub_presenter.dart';
part 'epub/metadata.dart';
part 'epub/html_parser.dart';