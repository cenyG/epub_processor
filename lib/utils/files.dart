import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

final sep = Platform.pathSeparator;

Future<String> getFileChecksum(File file) async {
  final fileLength = await file.length();
  final hash = await file.openRead().transform(crypto.sha256).first;

  return '$hash:$fileLength';
}

String getFileName(String path) {
  final tmpSplit = path.split(sep);
  final name = tmpSplit[tmpSplit.length - 1];

  return name;
}

Future<Map<String, dynamic>> readJsonFile(File json) async {
  return jsonDecode(await json.readAsString());
}